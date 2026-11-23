/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.sync.AtomicInt64
import std.sync.Barrier
import std.time.DateTime
import std.collection.ArrayList
import std.collection.concurrent.ArrayBlockingQueue
import std.random.Random
import std.runtime.blackBox
import std.runtime.getProcessorCount

protected class ScenarioRunner<S> {
    private let backoffGenerator: BackoffGenerator

    // Per-run seed source for PCT iterations (each iteration draws a fresh
    // seed; the seed is recorded in that iteration's PCTSchedule).
    private let pctSeedRandom: Random = Random()

    protected ScenarioRunner(private let scenario: ConcurrentScenario<S>) {
        backoffGenerator = BackoffGenerator(random: Random())
    }

    protected func executeIterationsWithCallback(
        iterations: Int64,
        callback!: (ScenarioIterationResult, Int64) -> Bool,
    ): Unit {
        // PCT mode: strictly sequential iterations (the token protocol
        // requires serialized actors); every iteration is an independent
        // PCT-armed run with its own seed. Iteration 0 runs first, preserving
        // the callback ordering contract of the stress path.
        // DPOR mode: ONE exploration (the schedule budget is the
        // iterations count; each explored schedule is one full
        // reset/state/verify cycle — runIterationDPOR below).
        let isPctMode = match (scenario.testMode) {
            case PCT => true
            case _ => false
        }
        if (isPctMode) {
            for (iter in 0..iterations) {
                let iterResult = runIterationPCT(iter) // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
                if (!callback(iterResult, iter)) {
                    return
                }
            }
            return
        }

        let isDporMode = match (scenario.testMode) {
            case DPOR => true
            case _ => false
        }
        if (isDporMode) {
            let iterResult = runIterationDPOR(0, maxSchedules: iterations)
            callback(iterResult, 0)
            return
        }

        // Iteration 0 always runs first, sequentially, to calibrate the backoff
        // sigma from the observed actor duration. This preserves the existing
        // calibration step and guarantees iteration 0 is the first result
        // delivered to the callback (existing tests rely on this).
        let firstResult = runIteration(0, backoffGenerator)
        updateBackoffSigma(firstResult.avgDuration.toNanoseconds())

        if (!callback(firstResult, 0)) {
            return
        }

        if (iterations <= 1) {
            return
        }

        if (scenario.parallelIterations) {
            executeIterationsParallel(iterations, callback: callback)
        } else {
            for (iter in 1..iterations) {
                let iterResult = runIteration(iter, backoffGenerator) // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
                if (!callback(iterResult, iter)) {
                    return
                }
            }
        }
    }

    // Parallel dispatch of iterations 1..iterations-1.
    //
    // Strategy (ArrayBlockingQueue + spawn-on-completion): the amount of work
    // is fixed upfront (iterations-1 tasks), so instead of a persistent worker
    // pool we keep at most poolSize concurrent in-flight iterations. Each time
    // a completed result is received from the queue, a replacement iteration
    // is spawned (if any remain and we have not been cancelled). Results are
    // delivered to the callback in completion order (out-of-order relative to
    // the iteration index); the callback is only ever invoked from this single
    // drain thread, so callers do not need to make their callback state
    // thread-safe.
    //
    // Cancellation (callback returned false): once the callback signals
    // false, no further iterations are dispatched and the callback is not
    // invoked again; in-flight iterations are allowed to run to completion
    // (their results are discarded) so that workers do not block forever on
    // resultQueue.add.
    private func executeIterationsParallel( // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
        iterations: Int64,
        callback!: (ScenarioIterationResult, Int64) -> Bool,
    ): Unit {
        let totalParallel = iterations - 1
        let procCount = getProcessorCount()
        // Pool size is derived from the per-iteration actor count so that the
        // total concurrent actor threads (poolSize * threadCount) is roughly
        // equal to the processor count.

        let threadCount = scenario.threadCount
        let poolSize = if (procCount < 1 || threadCount < 1) {
            Int64(1)
        } else if (threadCount >= procCount) {
            Int64(1)
        } else {
            procCount / threadCount
        }

        let resultQueue = ArrayBlockingQueue<ScenarioIterationResult>(poolSize) // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        let cancelled = AtomicInt64(0) // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics

        // Per-iteration backoff. Iteration 0 already used the shared
        // backoffGenerator (and calibrated sigma). Each parallel iteration
        // gets its own BackoffGenerator with the calibrated sigma and a fresh
        // RNG seeded from the shared one — drawn lazily, one seed per
        // dispatch, still sequentially on this same drain thread (so the
        // shared RNG is never touched concurrently by workers and the seed
        // sequence is identical to an upfront preallocation) — so a large
        // `iterations` count no longer allocates the entire seed array
        // before the first iteration even runs (a count near Int64.Max
        // would otherwise attempt an unbounded one-shot allocation).
        // cjlint-ignore -start !G.VAR.02 the variables below thread state across loop/algorithm iterations (accumulators or framework context); narrowing their scopes would change semantics
        let calibratedSigma = backoffGenerator.sigma
        let sharedRandom = backoffGenerator.random

        var nextSeedIdx: Int64 = 0
        var dispatched: Int64 = 0
        var completed: Int64 = 0
        // cjlint-ignore -end

        while (completed < totalParallel) {
            if (cancelled.load() == 0 &&
                nextSeedIdx < totalParallel &&
                dispatched - completed < poolSize)
            {
                let iterNum = nextSeedIdx + 1 // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
                let seed = sharedRandom.nextUInt64()
                let iterBackoff = BackoffGenerator(random: Random(seed), sigma: calibratedSigma) // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
                spawn {
                    // Exceptions/Errors are handled inside runIteration
                    let r = runIteration(iterNum, iterBackoff)
                    resultQueue.add(r)
                }
                dispatched++
                nextSeedIdx++
                continue
            }

            if (completed >= dispatched) {
                break
            }

            let result = resultQueue.remove() // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
            completed++
            if (cancelled.load() == 0) {
                if (!callback(result, result.iteration)) {
                    cancelled.store(1)
                }
            }
        }
    }

    protected func runIteration(
        iteration: Int64,
        backoffGen: BackoffGenerator
    ): ScenarioIterationResult {
        try {
            runIterationBody(iteration, backoffGen)
        } catch (e: Exception) {
            // The iteration failed before producing its own result (the
            // user reset block or state factory throwing, or an unexpected
            // engine failure ahead of the actor phase): synthesize the
            // failed iteration so every dispatched iteration — sequential
            // or parallel — yields exactly one result, and the error
            // surfaces in the report instead of unwinding run() or, under
            // parallel dispatch, hanging the result drain.
            failedIterationResult(iteration, e)
        } catch (e: Error) {
            // The Error family (StackOverflowError, InternalError, OOM —
            // a separate type hierarchy from Exception in Cangjie) gets
            // the same synthesis on this sequential path as the parallel
            // dispatch bracket gives it: without the clause an Error from
            // the reset block or state factory would unwind run() itself.
            failedIterationResult(iteration, Exception("iteration aborted by an Error: ${e}."))
        }
    }

    private func runIterationBody( // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
        iteration: Int64,
        backoffGen: BackoffGenerator
    ): ScenarioIterationResult {
        executeReset()

        // Per-iteration state isolation: each iteration calls the state factory
        // to produce a fresh state instance. For simple ScenarioBuilder<Unit>
        // scenarios, the scenario(name) factory pre-registers { => () } so this
        // call returns the () placeholder. For typed scenarios, this returns a
        // fresh instance of the user's state type S.
        // stateFactory is guaranteed Some by ScenarioBuilder.build().
        // cjlint-ignore -start !G.VAR.02 the variables below thread state across loop/algorithm iterations (accumulators or framework context); narrowing their scopes would change semantics
        let state: S = scenario.stateFactory.getOrThrow()() // cjlint-ignore !G.ERR.03 invariant-guarded extraction: a preceding isNone()/contains() gate (or the ScenarioBuilder contract, see comment) guarantees Some here; None would be a framework bug where throwing is the intended behavior
        // cjlint-ignore -end

        let barrier = Barrier(scenario.threadCount + 1)
        let startSignal = HBClockCounter()
        let history = ConcurrentHistory()
        let futures = ArrayList<Future<ActorExecution>>()

        let counters: ?Array<Int64> = if (let Linearizability <- scenario.consistencyModel) { // cjlint-ignore !G.VAR.02 the declaration must span the enclosing branch/loop: the value is assigned (or produced) in one arm and consumed after it, so the live range is already minimal
            Some(Array<Int64>(scenario.threadCount, { _ => 0 }))
        } else {
            None
        }

        for (actor in scenario.actors) {
            let backoff = backoffGen.next()

            futures.add(spawn {
                executeActorWithHistory(actor, state, barrier, startSignal, backoff, counters, scenario.threadCount)
            })
        }

        barrier.wait()
        startSignal.wait(0)

        // Futures are drained in spawn order (= actor order), so the
        // collected executions index by actor. Every actor's invocations
        // are recorded — including an actor without operations, whose
        // empty slot keeps the history's actor set dense
        // (ConcurrentHistory.actorCount is the key count; a dropped middle
        // actor would silently shrink the loop bound in the partial-order
        // builders and drop every later actor out of the order).
        let actorRuns = ArrayList<ActorExecution>()
        for (i in 0..futures.size) {
            let run = futures[i].get() // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
            actorRuns.add(run)
            history.recordActorInvocations(i, run.invocations)
        }

        var verifyFailed = false
        var consistencyResult: ?ConsistencyValidationResult = None

        try {
            executeAfter(state)
            verifyFailed = !executeVerify(state)

            if (let Some(validator) <- scenario.consistencyValidator) {
                let result = validator.validate(history)
                consistencyResult = Some(result)
                if (!result.isConsistent) {
                    verifyFailed = true
                }
            }
        } catch (e: Exception) {
            consistencyResult = Some(ConsistencyValidationResult(
                consistencyModel: scenario.consistencyModel,
                matchingPermutation: None,
                operationChecks: 0,
                prunedBranches: 0,
                cacheHits: 0,
                history: history,
                partialOrder: PartialOrder(),
                exception: Some(e)
            ))
            verifyFailed = true
        }

        let actorResults = ArrayList<ActorResult>()
        for (i in 0..scenario.threadCount) {
            let run = actorRuns[i]
            // The actor's first user exception, like the PCT/DPOR paths:
            // a scenario whose operations throw must not pass silently in
            // the default mode — the recorded exception makes the actor
            // row a failure (allSucceeded) and renders in the report, so
            // all three modes share one finding semantics.
            actorResults.add(actorResultOf(i, run.startedAt, run.endedAt,
                exception: firstUserExceptionOf(run.invocations)))
        }

        ScenarioIterationResult(
            iteration: iteration,
            failedAfter: verifyFailed,
            actorResults: actorResults.toArray(),
            consistencyValidation: consistencyResult
        )
    }

    // One actor-result row of an iteration summary: the actor's configured
    // name, its really-measured execution window, and its captured user
    // exception (a sync-primitive misuse recorded as the operation's
    // result) when present.
    private func actorResultOf(index: Int64, startedAt: DateTime, endedAt: DateTime,
        exception!: ?Exception = None): ActorResult {
        ActorResult(
            actorId: index,
            actorName: scenario.actors[index].name,
            exception: exception,
            startTime: startedAt,
            endTime: endedAt
        )
    }

    // A failed iteration synthesized from an exception that escaped the
    // iteration's own handling (the user reset block or state factory
    // throwing, or an unexpected engine failure before a result existed):
    // the setup error rides as the single actor-result exception so the
    // report renders it, and the failed flag makes the run verdict honest.
    private func failedIterationResult(iteration: Int64, e: Exception): ScenarioIterationResult {
        let now = DateTime.now()
        let setup = ActorResult(
            actorId: -1,
            actorName: "iteration_setup",
            exception: Some(e),
            startTime: now,
            endTime: now
        )
        ScenarioIterationResult(
            iteration: iteration,
            failedAfter: true,
            actorResults: [setup],
            consistencyValidation: None
        )
    }

    protected func updateBackoffSigma(avgDurationNanos: Int64): Unit {
        // A non-positive average means the wall clock rolled back between
        // the actor start/end measurements (an NTP step, a container
        // suspend/resume): the measurement is garbage, not evidence of an
        // instant iteration, and calibrating from it would poison the
        // backoff sigma with a negative scale. Keep the previous sigma.
        if (avgDurationNanos <= 0) {
            return
        }
        // Float division: the calibration keeps the sub-millisecond
        // remainder of the observed average instead of truncating to whole
        // tens of nanoseconds.
        backoffGenerator.sigma = Float64(avgDurationNanos) / 10.0
    }

    private func executeReset(): Unit {
        if (let Some(block) <- scenario.resetBlock) {
            block()
        }
    }

    private func executeAfter(state: S): Unit {
        if (let Some(block) <- scenario.afterBlock) {
            block(state)
        }
    }

    private func executeVerify(state: S): Bool {
        match (scenario.verifyBlock) {
            case Some(block) => block(state)
            case None => true
        }
    }

    private func executeActorWithHistory( // cjlint-ignore !G.FUN.01 config-carrier signature: the named parameters are the structured configuration/context of this framework step; bundling them into a struct would only move the count
        actor: Actor<S>,
        state: S,
        barrier: Barrier,
        startSignal: HBClockCounter,
        backoff: Int64,
        counters: ?Array<Int64>,
        actorCount: Int64
    ): ActorExecution {
        barrier.wait()
        startSignal.waitSpin(1)

        // The actor's real execution window: opened when the start signal
        // fires (the actor actually begins) — the measured duration
        // includes the backoff and is what the iteration's backoff sigma
        // is calibrated from. The recorder is constructed after the
        // backoff so its vector-clock start snapshot sees live counters
        // (the shared recording core of all three modes — see
        // ActorRecorder); its lazy window-open at the first operation
        // marks the PCT/DPOR actor entry instead, so the stress window
        // boundary is passed to ActorExecution directly.
        let startedAt = DateTime.now()
        performBackoff(backoff)

        let recorder = ActorRecorder<S>(actor, state, counters, actorCount)
        for (i in 0..actor.operations.size) {
            recorder.invokeOp(i)
        }

        ActorExecution(invocations: recorder.invocations, startedAt: startedAt, endedAt: recorder.endedAt)
    }

    private func performBackoff(iterations: Int64): Unit {
        var counter: Int64 = 0
        while (counter < iterations) {
            counter++
        }
        blackBox(counter)
    }

    // -----------------------------------------------------------------------
    // PCT mode.
    //
    // A token protocol with all policy on the Cangjie side: the
    // coordinator (stdx.unittest.concurrent.pct_coordinator.cj) hands a
    // single token to one actor at a time; switches happen at actor
    // operation boundaries, blocking operations and completion. The
    // engine and the whole iteration choreography (actor registration,
    // the operation-boundary scheduling points, the actor-future drain,
    // deadlock verdicts, schedule recording) live in this
    // package and are driven through `runPctWindow`; this
    // runner only composes the per-actor operation closures (with the
    // history recording inside — see ActorRecorder) and runs the same
    // verify/consistency tail as the stress path on the window's report.
    //
    // Instrumentation is compile-time only: code built with --cj-pct
    // (a) gets a PCT grid point after every atomic operation (b) has its
    // std.sync imports redirected to stdx.unittest.sync, wrapper
    // primitives that report lock/wait parks to the coordinator via the
    // pctSyncEnter/pctSyncExit dispatch functions (uncontended fast paths
    // are probed with try* and stay invisible). The runtime is PCT-free.
    // -----------------------------------------------------------------------

    protected func runIterationPCT(iteration: Int64): ScenarioIterationResult { // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
        // The pre-window user code (the reset block and the state factory)
        // gets the stress path's failure semantics: a throw becomes this
        // iteration's failed result — visible in the report, with every
        // completed iteration before it retained — instead of unwinding
        // run() and discarding them. The Error family is bracketed too
        // (same rationale as the parallel dispatch bracket). The window
        // machinery itself deliberately stays fail-fast: an activation
        // failure (an uninstrumented binary) or a recorded protocol
        // failure throws out of run() by design — pinned by
        // pct_uninstrumented_test.
        let state: S = try {
            executeReset()
            scenario.stateFactory.getOrThrow()() // cjlint-ignore !G.ERR.03 invariant-guarded extraction: a preceding isNone()/contains() gate (or the ScenarioBuilder contract, see comment) guarantees Some here; None would be a framework bug where throwing is the intended behavior
        } catch (e: Exception) {
            return failedIterationResult(iteration, e)
        } catch (e: Error) {
            return failedIterationResult(iteration, Exception("iteration aborted by an Error: ${e}."))
        }

        let history = ConcurrentHistory()
        let counters: ?Array<Int64> = if (let Linearizability <- scenario.consistencyModel) { // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
            Some(Array<Int64>(scenario.threadCount, { _ => 0 }))
        } else {
            None
        }

        // Seed source: the runner's per-iteration draw, or the scenario's
        // fixed seed (a reproducible single-iteration run — pctSeed).
        let seed = if (let Some(fixed) <- scenario.pctSeed) {
            fixed
        } else {
            pctSeedRandom.nextUInt64()
        }

        // Initial actors: op sequences as plain closures, with the
        // per-actor recording (vector clocks + invocation log) composed
        // inside each op (ActorRecorder below). The window owns the rest:
        // actors registered in array order (initial
        // actor i takes slot i, deterministic Spawn order), a scheduling
        // decision before every operation, the actor-future drain with
        // deadlock classification and schedule recording.
        let actorCount = scenario.threadCount
        let actorOpsList = ArrayList<Array<() -> Unit>>() // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        let recorders = ArrayList<ActorRecorder<S>>()
        for (actor in scenario.actors) {
            let recorder = ActorRecorder<S>(actor, state, counters, actorCount)
            actorOpsList.add(Array<() -> Unit>(actor.operations.size, { i => { => recorder.invokeOp(i) } }))
            recorders.add(recorder)
        }

        let windowReport = runPctWindow(
            config: PctWindowConfig(
                seed: seed,
                pcpBudget: scenario.pcpBudget,
                pcpFireProb: scenario.pcpFireProb,
                starvationThreshold: scenario.starvationThreshold,
                replaySchedule: scenario.replaySchedule,
                switchBound: scenario.switchBound
            ),
            actors: actorOpsList.toArray()
        )

        let deadlockAbort = windowReport.deadlocked
        let schedule = windowReport.schedule

        // A proven wait-for cycle aborted the iteration: this is the
        // diagnosis, not a crash — fail the iteration with the recorded
        // schedule rather than re-throwing. (The coordinator's own
        // aborted flag was already folded into the report's verdict; the
        // detail message is the first abort's explanation.)
        if (deadlockAbort) {
            match (windowReport.deadlockDetail) {
                case Some(detail) => println("[PCT] ${detail}")
                case None => println("[PCT] scenario \"${scenario.name}\" iteration ${iteration}: " +
                    "deadlock (wait-for cycle) — iteration aborted, every actor unwound")
            }
        }

        // An actor-level exception (an engine-control failure that unwound
        // an actor at an operation boundary, or an Error-family failure
        // the drain's Error bracket converted) fails the whole iteration —
        // the stress path's semantics: a failed result riding the report
        // (with every completed iteration before it retained) instead of
        // unwinding run(). In-operation user exceptions never land here
        // (the op wrappers capture them into recorded results); this
        // carries only actor-boundary failures, and the window's deadlock
        // verdict stays authoritative when both apply.
        if (!deadlockAbort) {
            if (let Some(e) <- windowReport.firstException) {
                printPctSeedHint(schedule, iteration)
                return failedIterationResult(iteration, e)
            }
        }

        // History recording follows the stress path's semantics: every
        // actor's invocations are recorded — a partially unwound actor's
        // completed operations are real observed behavior, and an actor
        // without completed operations still occupies its slot so the
        // history's actor set stays dense (ConcurrentHistory.actorCount is
        // the key count; a dropped middle actor would silently shrink the
        // loop bound in the partial-order builders and drop every later
        // actor out of the order). A deadlocked window skips validation,
        // so its history is never consumed; an actor-level failure
        // already returned above.
        for (i in 0..actorCount) {
            history.recordActorInvocations(i, recorders[i].invocations)
        }

        // The deadlock abort keeps its own verdict path: the failed
        // iteration carries the recorded schedule (the reproduction
        // artifact), not a synthesized setup row.
        if (deadlockAbort) {
            printPctSeedHint(schedule, iteration)
        }

        var verifyFailed = deadlockAbort
        var consistencyResult: ?ConsistencyValidationResult = None

        if (!deadlockAbort) {
            try {
                executeAfter(state)
                verifyFailed = !executeVerify(state)

                if (let Some(validator) <- scenario.consistencyValidator) {
                    let result = validator.validate(history)
                    consistencyResult = Some(result)
                    if (!result.isConsistent) {
                        verifyFailed = true
                    }
                }
            } catch (e: Exception) {
                consistencyResult = Some(ConsistencyValidationResult(
                    consistencyModel: scenario.consistencyModel,
                    matchingPermutation: None,
                    operationChecks: 0,
                    prunedBranches: 0,
                    cacheHits: 0,
                    history: history,
                    partialOrder: PartialOrder(),
                    exception: Some(e)
                ))
                verifyFailed = true
            }
        }

        if (verifyFailed && !deadlockAbort) {
            printPctSeedHint(schedule, iteration) // the abort branch printed it already
        }

        let actorResults = ArrayList<ActorResult>() // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        for (i in 0..scenario.threadCount) {
            let recorder = recorders[i]
            actorResults.add(actorResultOf(i, recorder.startedAt, recorder.endedAt,
                exception: firstUserExceptionOf(recorder.invocations)))
        }

        ScenarioIterationResult(
            iteration: iteration,
            failedAfter: verifyFailed,
            actorResults: actorResults.toArray(),
            consistencyValidation: consistencyResult,
            pctSchedule: Some(schedule)
        )
    }

    // One-line reproduction hint for a failed PCT iteration. The seed alone
    // re-derives the schedule of deterministic programs (every scheduling
    // draw — priority permutation, PCP fire/victim, actor registration
    // ranks — comes from the coordinator's Random(seed)); schedules that
    // depend on wall-clock (unmanaged threads, joins on user-spawned
    // futures, waitUntil(pred, timeout:)) need replaySchedule, which
    // re-applies the recorded events instead of re-deriving them.
    private func printPctSeedHint(schedule: PCTSchedule, iteration: Int64): Unit {
        println("[PCT] scenario \"${scenario.name}\" iteration ${iteration} failed " +
            "(seed=${schedule.seed}): reproduce with .pctSeed(${schedule.seed}) " +
            "(deterministic schedules; use replaySchedule for guaranteed reproduction)")
    }

    // -----------------------------------------------------------------------
    // DPOR mode.
    //
    // One deterministic exploration over the dependency-driven schedule
    // space: each explored schedule is one full PCT window wrapped in the
    // scenario lifecycle (reset + fresh state + composed op closures +
    // verify/consistency tail). The stepped DPOR driver
    // (runDporWindowStepped) owns the explorer and the per-schedule
    // lifecycle; this runner only supplies the hooks.
    // The first failing schedule (verify, consistency, deadlock, or an
    // actor exception) stops the exploration and surfaces as the
    // iteration's failure with the failing schedule as the reproduction
    // artifact. The scenario's `iterations` is the schedule budget.
    // -----------------------------------------------------------------------

    protected func runIterationDPOR(iteration: Int64, maxSchedules!: Int64): ScenarioIterationResult { // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
        let actorCount = scenario.threadCount

        // Per-schedule mutable context shared by the driver hooks (Cangjie
        // lambdas cannot capture mutable locals for deferred calls).
        let ctx = DporScheduleCtx<S>()
        // The exploration-level outcome, written by the afterSchedule
        // hook and read after the driver returns (same capture rule).
        let tracker = DporOutcomeTracker()

        let dporReport = runDporWindowStepped( // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
            config: DporWindowConfig(
                maxSchedules: maxSchedules,
                starvationThreshold: scenario.starvationThreshold,
                switchBound: scenario.switchBound,
                sleepCharMode: scenario.sleepCharMode,
                obstructionPolicy: scenario.obstructionPolicy
            ),
            beforeSchedule: { =>
                executeReset()
                ctx.state = Some(scenario.stateFactory.getOrThrow()()) // cjlint-ignore !G.ERR.03 invariant-guarded extraction: a preceding isNone()/contains() gate (or the ScenarioBuilder contract, see comment) guarantees Some here; None would be a framework bug where throwing is the intended behavior
                ctx.beginSchedule(
                    if (let Linearizability <- scenario.consistencyModel) {
                        Some(Array<Int64>(actorCount, { _ => 0 }))
                    } else {
                        None
                    })
            },
            opsFactory: { =>
                // Fresh per-actor recorders against the fresh state, in
                // actor order (initial actor i takes slot i).
                ctx.state.getOrThrow() // the state factory ran first // cjlint-ignore !G.ERR.03 invariant-guarded extraction: a preceding isNone()/contains() gate (or the ScenarioBuilder contract, see comment) guarantees Some here; None would be a framework bug where throwing is the intended behavior
                let ops = ArrayList<Array<() -> Unit>>()
                for (actor in scenario.actors) {
                    let recorder = ActorRecorder<S>(
                        actor, ctx.state.getOrThrow(), ctx.counters, actorCount) // cjlint-ignore !G.ERR.03 invariant-guarded extraction: a preceding isNone()/contains() gate (or the ScenarioBuilder contract, see comment) guarantees Some here; None would be a framework bug where throwing is the intended behavior
                    ops.add(Array<() -> Unit>(actor.operations.size, { i => { => recorder.invokeOp(i) } }))
                    ctx.recorders.add(recorder)
                }
                ops.toArray()
            },
            afterSchedule: { outcome: DporScheduleOutcome => // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
                let wr = outcome.windowReport
                if (wr.deadlocked) {
                    match (wr.deadlockDetail) {
                        case Some(detail) => println("[DPOR] ${detail}")
                        case None => println("[DPOR] scenario \"${scenario.name}\": deadlock " +
                            "(wait-for cycle) in schedule #${outcome.scheduleIndex}")
                    }
                }

                // History from this schedule's recorders, following the
                // stress path's semantics: every actor's invocations —
                // including a partially unwound actor's completed
                // operations (real observed behavior, validated instead of
                // silently discarded) and an actor without completed
                // operations (its empty slot keeps the history's actor set
                // dense; ConcurrentHistory.actorCount is the key count, so
                // a dropped middle actor would silently drop every later
                // actor out of the partial order).
                let history = ConcurrentHistory()
                for (i in 0..actorCount) {
                    history.recordActorInvocations(i, ctx.recorders[i].invocations)
                }

                // wr.firstException: an actor-level exception (an
                // engine-control failure that unwound an actor at an
                // operation boundary, or an Error-family failure the
                // drain's Error bracket converted). It fails the schedule —
                // the exception then fails the whole iteration through
                // pendingException below — instead of the schedule
                // passing silently and the exploration continuing.
                var failed = wr.deadlocked || wr.firstException.isSome()
                var cons: ?ConsistencyValidationResult = None
                if (!wr.deadlocked) {
                    try {
                        executeAfter(ctx.state.getOrThrow()) // cjlint-ignore !G.ERR.03 invariant-guarded extraction: a preceding isNone()/contains() gate (or the ScenarioBuilder contract, see comment) guarantees Some here; None would be a framework bug where throwing is the intended behavior
                        failed = !executeVerify(ctx.state.getOrThrow()) // cjlint-ignore !G.ERR.03 invariant-guarded extraction: a preceding isNone()/contains() gate (or the ScenarioBuilder contract, see comment) guarantees Some here; None would be a framework bug where throwing is the intended behavior

                        if (let Some(validator) <- scenario.consistencyValidator) {
                            let result = validator.validate(history)
                            cons = Some(result)
                            if (!result.isConsistent) {
                                failed = true
                            }
                        }
                    } catch (e: Exception) {
                        cons = Some(ConsistencyValidationResult(
                            consistencyModel: scenario.consistencyModel,
                            matchingPermutation: None,
                            operationChecks: 0,
                            prunedBranches: 0,
                            cacheHits: 0,
                            history: history,
                            partialOrder: PartialOrder(),
                            exception: Some(e)
                        ))
                        failed = true
                    }
                }

                // A user exception captured as an operation result fails
                // the schedule (see firstUserExceptionOf): the error
                // surfaces with the failing schedule instead of passing as
                // a consistent outcome.
                for (i in 0..actorCount) {
                    if (firstUserExceptionOf(ctx.recorders[i].invocations).isSome()) {
                        failed = true
                    }
                }

                if (failed) {
                    tracker.verifyFailed = true
                    tracker.consistencyResult = cons
                    tracker.failingSchedule = Some(wr.schedule)
                    if (let Some(e) <- wr.firstException) {
                        tracker.pendingException = Some(e)
                    }
                    return false // first failure stops the exploration
                }
                true
            }
        )

        // An actor-level exception is a finding: it fails the whole
        // iteration — the stress path's semantics (a failed result riding
        // the report instead of unwinding run()) — surfaced after the
        // driver has unwound cleanly.
        if (let Some(e) <- tracker.pendingException) {
            return failedIterationResult(iteration, e)
        }

        let actorResults = ArrayList<ActorResult>()
        for (i in 0..scenario.threadCount) {
            if (i < ctx.recorders.size) {
                let recorder = ctx.recorders[i]
                actorResults.add(actorResultOf(i, recorder.startedAt, recorder.endedAt,
                    exception: firstUserExceptionOf(recorder.invocations)))
            } else {
                let now = DateTime.now()
                actorResults.add(actorResultOf(i, now, now))
            }
        }

        let schedule = tracker.failingSchedule ?? dporReport.lastSchedule

        ScenarioIterationResult(
            iteration: iteration,
            failedAfter: tracker.verifyFailed,
            actorResults: actorResults.toArray(),
            consistencyValidation: tracker.consistencyResult,
            pctSchedule: Some(schedule),
            dporReport: Some(dporReport)
        )
    }
}

// One actor's stress-path execution outcome: the recorded invocations plus
// the really-measured execution window (from the start signal to op-loop
// completion), carried out of the actor thread so the iteration result
// reports genuine per-actor timings.
private struct ActorExecution {
    ActorExecution(
        let invocations!: ArrayList<OperationInvocation>,
        let startedAt!: DateTime,
        let endedAt!: DateTime
    ) {}
}

// The first user exception captured as an operation result among
// `invocations`: a sync-primitive misuse thrown through the mediated
// wrappers (a condition wait without holding the owner lock, an acquire
// amount out of range) unwinds the operation and becomes its recorded
// outcome, and surfaces through the actor results as the iteration's
// failure. Engine-control exceptions — the wait-for cycle abort, the
// external-wait rejection, the DPOR obstruction recovery — are outcomes of
// the scheduling protocol, not user failures, and are skipped.
private func firstUserExceptionOf(invocations: ArrayList<OperationInvocation>): ?Exception {
    for (inv in invocations) {
        if (let Some(proxy) <- (inv.result as EqProxy<Exception>)) {
            let e = proxy.value
            if (e is PctDeadlockError || e is PctExternalWaitError || e is ObstructionDetectedException) {
                continue
            }
            return Some(e)
        }
    }
    return None
}

// Per-schedule mutable context of one DPOR exploration (the driver hooks
// close over it; Cangjie lambdas cannot capture mutable locals for
// deferred calls). beginSchedule resets it; opsFactory and afterSchedule
// consume it.
private class DporScheduleCtx<S> {
    var state: ?S = None
    var counters: ?Array<Int64> = None
    let recorders: ArrayList<ActorRecorder<S>> = ArrayList<ActorRecorder<S>>()

    func beginSchedule(counters: ?Array<Int64>): Unit {
        recorders.clear()
        this.counters = counters
    }
}

// Exploration-level outcome of the DPOR hooks (heap-resident so the
// deferred afterSchedule lambda can write it; read after the driver
// returns).
private class DporOutcomeTracker {
    var verifyFailed: Bool = false
    var consistencyResult: ?ConsistencyValidationResult = None
    var failingSchedule: ?PCTSchedule = None
    var pendingException: ?Exception = None
}

// Per-actor operation recording, shared by all three execution modes
// (stress, PCT, DPOR): holds the mutable per-actor state the recording
// shares (the invocation log and the vector-clock counter), so each
// operation composes snapshot-invoke-snapshot-record inside a single
// step. (Cangjie lambdas cannot capture mutable locals for deferred
// calls, so the state lives in this heap object; the PCT/DPOR op
// closures capture it — in those modes the actor's registration park is
// the start gate, so the recorder is constructed before the window and
// composed into the op closures the window scheduler drives between its
// operation-boundary decision points. The stress path constructs it in
// the actor body after the backoff and drives the plain op loop — see
// executeActorWithHistory.)
private class ActorRecorder<S> {
    private let actor: Actor<S>
    private let state: S
    private let sharedCounters: ?Array<Int64>
    private let actorCount: Int64
    let invocations: ArrayList<OperationInvocation> = ArrayList<OperationInvocation>()
    private var localCounter: Int64 = 0
    private var previousResponseVC: ?Array<Int64> = None
    // The actor's real execution window: opened at the first operation
    // (the actor-body entry point the runner controls inside the
    // PCT/DPOR window) and closed after each operation, so the last
    // close marks op-loop completion. Both default to the recorder's
    // construction, so an actor without operations still yields a
    // well-formed (zero-length) window. The stress path measures its own
    // window instead — opened at the start signal with the backoff
    // included — and consumes only endedAt (see executeActorWithHistory).
    var startedAt: DateTime = DateTime.now()
    var endedAt: DateTime = DateTime.now()

    init(actor: Actor<S>, state: S, sharedCounters: ?Array<Int64>, actorCount: Int64) {
        this.actor = actor
        this.state = state
        this.sharedCounters = sharedCounters
        this.actorCount = actorCount
        // The start vector clock (linearizability only): the actor's
        // first invocationVC snapshot.
        if (let Some(sharedCounters) <- this.sharedCounters) {
            localCounter++
            sharedCounters[actor.id] = localCounter
            let startVC = Array<Int64>(actorCount, { j => sharedCounters[j] })
            previousResponseVC = Some(startVC)
        }
    }

    func invokeOp(i: Int64): Unit {
        if (i == 0) {
            startedAt = DateTime.now()
        }
        if (let Some(sharedCounters) <- this.sharedCounters) {
            let invocationVC = previousResponseVC

            let result = actor.operations[i](state)

            localCounter++
            sharedCounters[actor.id] = localCounter
            let responseVC = Array<Int64>(actorCount, { j => sharedCounters[j] })
            previousResponseVC = Some(responseVC)

            invocations.add(OperationInvocation(
                actorId: actor.id,
                operationIndex: i,
                operationName: actor.operationNames[i],
                result: result,
                invocationVC: invocationVC,
                responseVC: Some(responseVC)
            ))
        } else {
            let result = actor.operations[i](state)

            invocations.add(OperationInvocation(
                actorId: actor.id,
                operationIndex: i,
                operationName: actor.operationNames[i],
                result: result
            ))
        }
        endedAt = DateTime.now()
    }
}
