/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.collection.ArrayList

/**
 * Configuration of one PCT window: the exploration parameters and the
 * optional replay plan. The seed fully determines the explored schedule
 * of a deterministic program (every scheduling draw — priority ranks,
 * PCP fire/victim, dynamic-child ranks — comes from the coordinator's
 * `Random(seed)`).
 */
internal struct PctWindowConfig {
    internal PctWindowConfig(
        /** The PCT seed; reproduces the run when passed back in. */
        internal let seed!: UInt64,
        /** Priority-change-point budget (PCT's K). */
        internal let pcpBudget!: Int64 = 2,
        /** Probability a decision point consumes a PCP. */
        internal let pcpFireProb!: Float64 = 0.05,
        /** Grid-poll run that triggers fair scheduling. */
        internal let starvationThreshold!: UInt64 = 10_000u64,
        /** A previously recorded schedule to replay instead of
         *  exploring a fresh one. */
        internal let replaySchedule!: ?PCTSchedule = None,
        /** Per-schedule bound on voluntary (op-boundary/grid)
         *  preemption switches; -1 (default) is unbounded. The PCP
         *  budget bounds priority-change *fires* — one fired PCP can
         *  cascade into several preemptions — while this bounds the
         *  switches themselves. Forced transfers (park/wait handoffs)
         *  and fair-mode anti-starvation yields never count against
         *  it (liveness), and replays reproduce the recorded schedule
         *  verbatim (the count is schedule-stable). */
        internal let switchBound!: Int64 = -1
    ) {}
}

/**
 * The outcome of one PCT window: the recorded schedule plus the window's
 * verdicts. The schedule is present on every non-throwing return —
 * including deadlock-aborted windows (it is the reproduction artifact) —
 * and is replayable through `PctWindowConfig.replaySchedule`.
 */
internal struct PctWindowReport {
    internal PctWindowReport(
        /** The recorded schedule of the window's single iteration. */
        internal let schedule!: PCTSchedule,
        /** The authoritative deadlock verdict (a wait-for cycle abort). */
        internal let deadlocked!: Bool,
        /** The first deadlock-abort message, when one occurred. */
        internal let deadlockDetail!: ?String,
        /** The first actor-level exception (deadlock aborts excluded), in
         *  actor order — `None` when every actor completed normally. It
         *  fails the whole iteration (the stress path's failure
         *  semantics — see the runners); the Error family, a hierarchy
         *  disjoint from Exception in Cangjie, surfaces here as a
         *  descriptive wrapper (see the drain's Error clause in
         *  `runWindowInternal`). */
        internal let firstException!: ?Exception
    ) {}
}

/**
 * Run one multi-actor PCT window: the scheduling harness that drives a
 * set of actors under the PCT token protocol, with a scheduling decision
 * (`pollSelf`) between every pair of consecutive operations of an actor.
 *
 * Each element of `actors` is one initial actor's operation sequence, as
 * plain closures: the window invokes them one at a time on the actor's
 * own thread, inserting the operation-boundary scheduling point before
 * each — everything the operations do internally (recording results into
 * captured structures, invoking user code) is the caller's business and
 * invisible to the harness. Actors are spawned as full dynamic children
 * in array order (initial actor i takes slot i; the window waits for
 * each registration before the next spawn, so the recorded `Spawn` order
 * is deterministic and replayable). User-invoked `spawn`s inside an
 * operation run as unmanaged threads and never register — invisible to
 * the scheduler (see the README, "User-spawned threads"); the window
 * drains its registered actors only.
 *
 * The window reuses the coordinator's full lifecycle: activation guards
 * the `--cj-pct` compilation contract and the single-active-window
 * invariant; a wait-for cycle aborts the iteration (every actor
 * unwinds through `PctDeadlockError`, reported as `deadlocked` — the
 * diagnosis, not a crash); `buildSchedule` fails loudly on protocol
 * violations.
 *
 * Throws on framework misuse only (uninstrumented binary, a leaked
 * previous window, a non-replayable replay schedule, protocol
 * violations) — operation failures never throw here, they travel in
 * `firstException` and fail the iteration. The binary must be compiled with `--cj-pct`; code
 * running outside any window is unmanaged, as in uninstrumented builds.
 *
 * @throws Exception when the replay schedule cannot be loaded (schedules
 * containing Resume events or marked deadlocked are not replayable).
 * @throws Exception on framework misuse reported by the window lifecycle:
 * the binary is not compiled with `--cj-pct`, a previous iteration is
 * still active, or a PCT protocol violation (see `runWindowInternal`).
 */
internal func runPctWindow(
    config!: PctWindowConfig,
    actors!: Array<Array<() -> Unit>>
): PctWindowReport {
    let coord = PctCoordinator(
        seed: config.seed,
        actorCount: actors.size,
        pcpBudget: config.pcpBudget,
        pcpFireProb: config.pcpFireProb,
        starvationThreshold: config.starvationThreshold,
        switchBound: config.switchBound
    )
    if (let Some(s) <- config.replaySchedule) {
        let loadRet = coord.loadReplay(s)
        if (loadRet != 0) {
            throw Exception("PCT replay schedule load failed with code ${loadRet} " +
                "(empty, diverged, deadlocked or Resume-carrying schedules are not replayable; " +
                "a schedule recorded for a different scenario — actor-count mismatch or an " +
                "out-of-range actor slot — is rejected)")
        }
    }
    return runWindowInternal(coord, actors)
}

/**
 * One initial actor's thread body (the spawn closure runWindowInternal
 * starts each initial actor on): the registration, the op loop with a
 * scheduling decision before every operation, and the exit — each
 * coordinator call routed through pctRoute (suppression + one engine
 * region + the failure policy per call; the parks inside the bodies own
 * their drains, so the region composes across them).
 *
 * COMPLETION INVARIANT: childExit(None, ...) runs in the body's finally,
 * BEFORE the actor's future completes (Future.execute's epilogue —
 * result set, notifyAll — runs after the closure returns). The joiner
 * flip the Some route would perform is skipped here because an initial
 * actor's future never escapes the window (the futures list is local to
 * the driver), so no actor can mediated-join it.
 *
 * A recorded registration failure rethrows here (S-08): the child must
 * not fall through unregistered — unmanaged code would run unscheduled
 * (a vacuum window) and could hang the drain — so the failure rides the
 * spawn's future.
 *
 * mtrace note: suppression is per-call now (each route brackets its own
 * coordinator traffic); the op-loop machinery between calls is
 * unsuppressed — a change from the old region-spanning bracket (which
 * suppressed everything but the op bodies), to revisit at
 * mtrace-integration time.
 */
private func runInitialActor(coord: PctCoordinator, actorOps: Array<() -> Unit>): Unit {
    let registered = pctRoute(coord, { => coord.childEnter(None, Thread.currentThread.id) })
    if (registered.isNone()) {
        // S-08: the recorded registration failure must not fall through
        // unregistered — rethrow it so the spawn's future carries it.
        let failure = coord.recordedFailure() ?? Exception("PCT child registration failed.")
        throw failure
    }
    try {
        for (op in actorOps) {
            // PCT decision point between operations: the primary
            // in-actor switch position (optimized builds elide safepoint
            // polls through inlining).
            pctRoute(coord, { => coord.pollSelf() })
            op()
        }
    } finally {
        pctRoute(coord, { => coord.childExit(None, Thread.currentThread.id) })
        // The drain signal always fires — including when the exit's
        // region recorded a failure (the route returned None) — because
        // it runs AFTER the route, outside any engine region (the
        // drainActors handshake is drainMonitor -> engine; a signal
        // under the engine would invert it).
        coord.signalDrain()
    }
}

/**
 * The shared window lifecycle (runPctWindow's body after coordinator
 * construction): activation, the sequential initial-actor spawn loop
 * (the deterministic Spawn order), the future drain with deadlock
 * classification, the registered-actor drain, and the schedule snapshot.
 * The DPOR driver (dpor_report.cj) reuses this with its own coordinator
 * (a DporScheduler injected through the scheduler factory).
 */
/**
 * The shared window lifecycle (runPctWindow's body after coordinator
 * construction); the DPOR driver reuses it with its own coordinator —
 * see runPctWindow for the full contract.
 *
 * @throws Exception when activation fails: the binary is not compiled
 * with `--cj-pct` (code -1), a previous iteration is still active after a
 * leak (code -3), or another activation error code is reported.
 */
internal func runWindowInternal(coord: PctCoordinator, actors: Array<Array<() -> Unit>>): PctWindowReport { // cjlint-ignore !G.FUN.01 single cohesive lifecycle over the length budget: install → spawn → drain → report, every exit path dropping the active-window reference — further splits would scatter that invariant
    // activate() guards the --cj-pct compilation contract and the
    // single-active-window invariant; the dispatch functions route
    // through the active-window reference set below.
    let activateRet = coord.activate()
    if (activateRet != 0) {
        if (activateRet == -1) {
            throw Exception("PCT mode requires the test binary to be compiled with --cj-pct " +
                "(without it, blocking inside actor operations is invisible to the scheduler " +
                "and can hang the iteration)")
        }
        if (activateRet == -3) {
            throw Exception("PCT activation failed: a previous iteration is still active " +
                "(leaked after an exception or registration timeout, or another " +
                "scenario run is in flight concurrently).")
        }
        throw Exception("PCT activation failed with code ${activateRet}.")
    }
    // The active-window span: everything from the reference install to
    // the return runs inside one try/finally, so the finally drops the
    // active-window reference on every exit path — the return, a
    // spawn/registration failure, a drain failure, a buildSchedule
    // protocol failure; otherwise every later window fails activation
    // with "a previous iteration is still active". The clear is OWNED:
    // only a window whose install succeeded may clear, so a concurrent
    // loser's unwinding never wipes the winner's just-installed
    // reference (the winner's dispatches would then absorb into a
    // near-empty "passing" schedule).
    var installed = false // cjlint-ignore !G.VAR.02 set after the install inside the try, read by the finally: the declaration must span both so the clear stays ownership-gated
    try {
        // The authoritative single-active-window install, serialized on
        // the iteration guard: activate()'s -3 check above is advisory
        // (a concurrent run can slip between it and this install), but
        // this one cannot race — the loser fails loudly here, and its
        // finally leaves the winner's reference in place, instead of
        // silently overwriting it.
        let installRet = pctInstallCurrentIteration(coord)
        if (installRet != 0) {
            throw Exception("PCT activation failed: a previous iteration is still active " +
                "(leaked after an exception or registration timeout, or another " +
                "scenario run is in flight concurrently).")
        }
        installed = true

        // Initial actors: full dynamic children through this registration
        // route. The window's own spawn sites carry no compiler
        // instrumentation (this package is precompiled WITHOUT --cj-pct —
        // the compilation-boundary invariant), but the window owns these
        // call sites: childEnter(None, ...) registers each spawned thread as
        // an actor unconditionally, and the window waits for each
        // registration before the next spawn, so registration order — and
        // with it the recorded Spawn order and the slot order — is this
        // sequential spawn order (initial actor i takes slot i). The
        // spawned thread's body is runInitialActor above.
        let futures = ArrayList<Future<Unit>>()
        for (actorOps in actors) {
            futures.add(spawn {
                runInitialActor(coord, actorOps)
            })
            // Token-free (the child parks at its registration gate), so this
            // wait cannot deadlock; the bound covers thread-start failures.
            // Not routed: the registrar's bounded waits must run without
            // the engine lock (see awaitRegisteredActors).
            coord.awaitRegisteredActors(futures.size)
        }
        pctRoute(coord, { => coord.releaseFirst() })

        // Drain all futures (every actor completes: the token keeps flowing
        // through childExit in each actor's finally — or, on a cycle
        // abort, every actor unwinds on the PctDeadlockError the coordinator
        // entries throw, so the futures resolve anyway and the drain
        // completes instead of hanging). Deadlock aborts are classified
        // into the report's verdict; the first other failure — exception
        // or Error — is kept window-level as the iteration's failure (the
        // stress path's semantics: the whole iteration fails on it, no
        // per-actor partial state).
        var deadlocked = false
        var deadlockDetail: ?String = None
        var firstException: ?Exception = None
        for (i in 0..futures.size) {
            try {
                let _ = futures[i].get()
            } catch (e: Exception) {
                if (e is PctDeadlockError) {
                    // A proven wait-for cycle aborted the iteration: this is
                    // the diagnosis, not a crash — keep the first message as
                    // the report's deadlock detail.
                    if (!deadlocked) {
                        deadlockDetail = Some(e.message)
                    }
                    deadlocked = true
                } else if (firstException.isNone()) {
                    firstException = Some(e)
                }
            } catch (e: Error) {
                // The Error family (StackOverflowError, InternalError, OOM —
                // a separate type hierarchy from Exception in Cangjie, so the
                // op-result capture via execResultOf never sees it) escapes
                // the actor's op wrappers and rejects the future. The stress
                // path brackets this family at every dispatch point
                // (runIteration's Error clause); the drain gets the same
                // bracket: the Error becomes the iteration's failure and
                // the drain continues — without it, the raw Error would unwind
                // the drain thread (the token granter), leak every
                // still-parked actor, and surface as an unclassified abort.
                if (firstException.isNone()) {
                    firstException = Some(Exception("actor ${i} aborted by an Error: ${e}."))
                }
            }
        }

        // Drain registered actors beyond the futures list above (a
        // retained route — no producer registers such actors today:
        // user-invoked spawns never register).
        pctRoute(coord, { => coord.drainActors() })

        // The authoritative cycle-abort verdict (op-result capture may
        // have swallowed every PctDeadlockError before the drain).
        if (pctRoute(coord, { => coord.isAborted() }) ?? false) {
            deadlocked = true
        }

        // buildSchedule throws on protocol failures (they fail the window
        // loudly); the surrounding finally drops the active-window
        // reference on that path too.
        let schedule = coord.buildSchedule()

        PctWindowReport(
            schedule: schedule,
            deadlocked: deadlocked,
            deadlockDetail: deadlockDetail,
            firstException: firstException
        )
    } finally {
        if (installed) {
            // Only the installer clears: a failed install (-3) must
            // leave the winner's reference in place — see the span
            // comment above.
            pctInstallCurrentIteration(None)
        }
    }
}
