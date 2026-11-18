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
        // RNG seeded from the shared one (drawn sequentially here on the
        // caller thread, so the shared RNG is never touched concurrently by
        // workers).
        // cjlint-ignore -start !G.VAR.02 the variables below thread state across loop/algorithm iterations (accumulators or framework context); narrowing their scopes would change semantics
        let calibratedSigma = backoffGenerator.sigma
        let sharedRandom = backoffGenerator.random
        let seeds = Array<UInt64>(totalParallel, { _ => sharedRandom.nextUInt64() })

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
                let seed = seeds[nextSeedIdx]
                let iterBackoff = BackoffGenerator(random: Random(seed), sigma: calibratedSigma) // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
                spawn {
                    // Every dispatched iteration must enqueue exactly one
                    // result: the drain below counts one per dispatch, so a
                    // spawn that dies without enqueueing (an exception
                    // before runIteration produced its result) would block
                    // the drain forever. runIteration converts its own
                    // failures into failed iteration results; this bracket
                    // is the last-resort guard for anything escaping that.
                    let r = try {
                        runIteration(iterNum, iterBackoff)
                    } catch (e: Exception) {
                        failedIterationResult(iterNum, e)
                    }
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
        // collected executions index by actor.
        let actorRuns = ArrayList<ActorExecution>()
        for (future in futures) {
            let run = future.get() // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
            actorRuns.add(run)
            if (run.invocations.size > 0) {
                let actorId = run.invocations[0].actorId
                history.recordActorInvocations(actorId, run.invocations)
            }
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
            actorResults.add(actorResultOf(i, run.startedAt, run.endedAt))
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
        // fires (the actor actually begins) and closed at op-loop
        // completion. The measured duration is what the iteration's backoff
        // sigma is calibrated from.
        let startedAt = DateTime.now()
        performBackoff(backoff)

        let invocations = ArrayList<OperationInvocation>()
        var localCounter: Int64 = 0
        var previousResponseVC: ?Array<Int64> = None

        if (let Some(sharedCounters) <- counters) {
            localCounter++
            sharedCounters[actor.id] = localCounter
            let startVC = Array<Int64>(actorCount, { j => sharedCounters[j] })
            previousResponseVC = Some(startVC)
        }

        for (i in 0..actor.operations.size) {
            if (let Some(sharedCounters) <- counters) {
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
        }

        ActorExecution(invocations: invocations, startedAt: startedAt, endedAt: DateTime.now())
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
    // history recording inside — see PctOpRecorder) and runs the same
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
        executeReset()
        let state: S = scenario.stateFactory.getOrThrow()() // cjlint-ignore !G.ERR.03 invariant-guarded extraction: a preceding isNone()/contains() gate (or the ScenarioBuilder contract, see comment) guarantees Some here; None would be a framework bug where throwing is the intended behavior

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
        // inside each op (PctOpRecorder below). The window owns the rest:
        // actors registered in array order (initial
        // actor i takes slot i, deterministic Spawn order), a scheduling
        // decision before every operation, the actor-future drain with
        // deadlock classification and schedule recording.
        let actorCount = scenario.threadCount
        let actorOpsList = ArrayList<Array<() -> Unit>>() // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        let recorders = ArrayList<PctOpRecorder<S>>()
        for (actor in scenario.actors) {
            let recorder = PctOpRecorder<S>(actor, state, counters, actorCount)
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

        // History recording mirrors the future-drain semantics: an actor's
        // invocations are recorded only when its future resolved normally —
        // an aborted or exceptionally unwound actor's partial history is
        // discarded.
        for (i in 0..actorCount) {
            let report = windowReport.actorReports[i]
            if (report.aborted || report.exception.isSome()) {
                continue
            }
            let invocations = recorders[i].invocations
            if (invocations.size > 0) {
                let actorId = invocations[0].actorId
                history.recordActorInvocations(actorId, invocations)
            }
        }

        // Actor-body exceptions are collected and re-thrown after cleanup.
        // (The op wrappers capture exceptions into recorded op results, so
        // this path is merely a bonus diagnostic — the window's deadlock
        // verdict is the authoritative one.)
        if (deadlockAbort) {
            printPctSeedHint(schedule, iteration)
        } else if (let Some(e) <- windowReport.firstException) {
            printPctSeedHint(schedule, iteration)
            throw e
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
                    let recorder = PctOpRecorder<S>(
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

                // History from this schedule's recorders (an aborted or
                // exceptionally unwound actor's partial history is
                // discarded, mirroring the PCT future-drain semantics).
                let history = ConcurrentHistory()
                for (i in 0..actorCount) {
                    let actorReport = wr.actorReports[i]
                    if (actorReport.aborted || actorReport.exception.isSome()) {
                        continue
                    }
                    let invocations = ctx.recorders[i].invocations
                    if (invocations.size > 0) {
                        let actorId = invocations[0].actorId
                        history.recordActorInvocations(actorId, invocations)
                    }
                }

                var failed = wr.deadlocked
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

        // An actor-body exception is a finding: surface it after the
        // driver has unwound cleanly.
        if (let Some(e) <- tracker.pendingException) {
            throw e
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

        let schedule = match (tracker.failingSchedule) {
            case Some(s) => s
            case None => dporReport.lastSchedule
        }

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
    let recorders: ArrayList<PctOpRecorder<S>> = ArrayList<PctOpRecorder<S>>()

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

// Per-actor operation recording for the PCT path: holds the mutable
// per-actor state the operation closures share (the invocation log and
// the vector-clock counter), so each operation composes
// snapshot-invoke-snapshot-record inside a single closure that
// `runPctWindow` schedules between its operation-boundary decision
// points. (Cangjie lambdas cannot capture mutable locals for deferred
// calls, so the state lives in this heap object captured by every op
// closure of the actor.) The recording itself is identical to the stress
// path's executeActorWithHistory, minus the barrier/backoff start
// synchronization: in PCT mode the actor's registration park is the
// start gate.
private class PctOpRecorder<S> {
    private let actor: Actor<S>
    private let state: S
    private let sharedCounters: ?Array<Int64>
    private let actorCount: Int64
    let invocations: ArrayList<OperationInvocation> = ArrayList<OperationInvocation>()
    private var localCounter: Int64 = 0
    private var previousResponseVC: ?Array<Int64> = None
    // The actor's real execution window: opened at the first operation
    // (the actor-body entry point the runner controls inside the window)
    // and closed after each operation, so the last close marks op-loop
    // completion. Both default to the recorder's construction, so an
    // actor without operations still yields a well-formed (zero-length)
    // window.
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
