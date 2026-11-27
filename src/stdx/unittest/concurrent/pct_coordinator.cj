/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.collection.ArrayList
import std.random.Random
import std.sync.Monitor

/**
 * The Cangjie-side PCT coordinator: the token protocol engine of one PCT
 * iteration — every park, every wake, every token transfer — plus the
 * iteration lifecycle (activation, the spawn-driven registration flow,
 * the window drain, the schedule snapshot). The one class every external
 * caller talks to; the policy and storage it drives live in the
 * components it composes:
 *
 *  - PctActorTable (pct_actor_table.cj): the per-actor slot storage —
 *    identity, gates, protocol state, priority ranks, decision counters,
 *    mediated wait registrations, future identities, absorb markers;
 *  - PctScheduler (pct_scheduler.cj): the scheduling policy — the seeded
 *    RNG (registration ranks, PCP draws), the grant picks, the
 *    starvation/fair-mode recovery, and the schedule log (pct_schedule_log.cj)
 *    with it: every decision's event recording and the replay-vs-record
 *    branching are scheduler-internal, so this coordinator requests
 *    decisions (the PctTransfer API) and never sees the log, the replay
 *    cursor, or the divergence flag;
 *  - PctWaitForGraph (pct_wait_graph.cj): the cycle abort's deadlock
 *    detection — tracked lock ownership and the park-time cycle search;
 *  - PctSpawnRegistrar (pct_spawn_registrar.cj): the dynamic-spawn
 *    handshake — the expectation, the bounded registration waits, the
 *    registered-actor count;
 *  - pct_dispatch.cj holds the compiler/wrapper ABI (pctActiveCoord and
 *    the pct* entry points), and pct_children.cj the no-op spawn-site
 *    ABI stubs kept for link compatibility.
 *
 * All PCT decision points are dispatch calls — compiler-emitted in
 * `--cj-pct`-compiled code, or made by the precompiled stdx.unittest.sync
 * wrappers — dispatched through the package-level active-iteration
 * reference:
 *  - `pctGridDispatchRw` after every atomic operation (the fine-grained grid);
 *  - `pctSyncEnter`/`pctSyncExit` around the deliberately unmediated parks
 *    only (timed condition/monitor waits and multiConditionMonitor waits in
 *    the wrappers — their expiry or wake is external by design; contended
 *    lock acquires are mediated instead);
 *  - the runner-driven operation boundaries (pollSelf).
 * This coordinator performs all filtering and dedup by its own state:
 *  - thread-id -> actor mapping (the table, recorded at each actor's
 *    child-entry registration — every actor is a dynamically registered
 *    child, the runner's initial actors included);
 *  - the sync enter proceeds only for the token holder (the transfer
 *    itself is the dedup: after an enter fires, the actor is no longer
 *    `Running`, so any hypothetical re-entrant dispatch is absorbed);
 *  - the sync exit proceeds only for `Blocked` actors (their runtime
 *    park inside a wrapper bracket completed); `Finished` absorbs are
 *    expected (pooled-cjthread reuse);
 *  - any other dispatch-in-state combination increments `protocolViolations`
 *    (it must stay zero; buildSchedule fails loudly otherwise).
 *
 * The framework's own synchronization (the engine lock, the actor
 * gates) is plain std.sync — safe because this package is precompiled
 * WITHOUT `--cj-pct`, so the compiler-inserted dispatch calls exist only
 * in user-binary code and can never re-enter the coordinator through
 * framework-internal parks (enforced by the compilation boundary).
 *
 * Every method below runs inside ONE engine region owned by its caller's
 * route (pctRoute, pct_dispatch.cj — the dispatch entries and the
 * window's lifecycle calls; the primitive lives in pct_engine_lock.cj):
 * the bodies are plain assume-locked code (matching the *Locked helper
 * naming) and never manage the lock themselves — the blocking waits go
 * through drain sections (pctWithTemporarilyUnlocked, owned by
 * PctGate.park and the two monitor waits — a park under the lock would
 * deadlock the grantee), so a route's region composes across a body's
 * parks (the drain releases the region's hold and restores it). Nested
 * bodies are plain nested calls inside the one region (pollSelf's poll,
 * medCondWait's Mesa re-acquire). Wakes run under the lock: a gate open
 * is a non-blocking notify and the gate monitors are leaves, so the
 * woken thread merely contends until the waking region ends. The route's
 * catch delegates to handleException: engine-control aborts (the
 * wait-for cycle abort, the external-wait rejection, the DPOR
 * obstruction recovery) and wrapped user-closure failures
 * (PctUserClosureError, unwrapped at the route) rethrow — they must
 * unwind user code; everything else is recorded as the iteration's
 * protocol failure and the route returns None — the caller applies its
 * degraded value, surfaced by buildSchedule. Exceptions to the routing:
 * buildSchedule (a plain region — its throws ARE the surfacing),
 * awaitRegisteredActors/onSpawnSiteAfter (the registrar's bounded waits
 * must run without the engine lock — the registering child's route
 * needs it), and activate/loadReplay (called before the reference
 * install).
 *
 * Decision sites (all serialized by the engine lock):
 *  - `poll`: op boundaries, decided by the holder itself (ordinary Cangjie
 *    code with direct coordinator access — no runtime involvement);
 *  - `handleBlockEventLocked` (via onSyncEnter): the holder is about to park
 *    in a sync primitive; the token must move (or the deadlock is recorded);
 *  - `handleParkEventLocked` (via onSyncEnter with a future key): the mediated
 *    wait — the holder parks on its own gate instead of the
 *    runtime; the owner's childExit flips it before the completion pick;
 *  - `medAcquire`/`medRelease` (via pctMedAcquire/pctMedUnlock/
 *    pctMedRelease from the stdx.unittest.sync wrappers): the mediated
 *    acquire protocol — contended acquires park on the actor's gate
 *    keyed by the primitive, and unlocks/releases with
 *    waiters are yield points that flip and pick;
 *  - `medCondWait` and the notify-side `medRelease` (via pctCondWait/
 *    pctMedNotify/pctMedNotifyAll): the mediated condition-wait protocol
 *    — a wait releases the inner lock, parks keyed by the condition,
 *    and re-acquires on wake (the two-stage Mesa re-wait);
 *    notifies flip condition waiters (one for `notify`, all for
 *    `notifyAll`) and yield;
 *  - `onSyncExit` (the unblock): the actor's primitive completed; it
 *    re-gates (parks on its gate, in managed frames below the user's
 *    call) or, after deadlock recovery, claims the token and returns
 *    without parking;
 *  - `childExit`: actor completion (every actor is a dynamic child; the
 *    entry wrapper's finally for user children, the runner
 *    closure's for the initial actors), with the mediated-wait flip for
 *    user children;
 *  - `releaseFirst`: the iteration start (the runner thread, after the
 *    initial actors registered).
 *
 * The wait-for cycle abort (deadlock finality): every park runs a wait-for cycle check
 * first (the graph's holder side is the tracked-ownership table maintained
 * by medAcquire/medRelease/medCondWait; its waiter side is the per-actor
 * wait key + edge kind). A cycle closed by a park is a proven deadlock:
 * `abortIterationLocked` logs the `Deadlock` event, wakes every actor
 * parked on its gate (their parks return without a grant), and from then
 * on every actor-side coordinator entry throws `PctDeadlockError`, which
 * unwinds each actor through its child entry (the entry wrapper for
 * user-invoked children, the runner's closure bracket for the initial
 * actors) so its future resolves — the
 * runner's drain completes and the iteration fails with the recorded
 * schedule and the cycle path instead of hanging. Deadlocks without a
 * cycle (a semaphore starved with nobody to release it, a condition
 * nobody notifies) keep the recoverable park + `Deadlock` + `Resume`
 * behavior; they cannot be proven final, because an external thread may
 * still act.
 */
/**
 * The cycle abort's iteration-abort exception. Thrown by every coordinator
 * entry once a wait-for cycle has been detected (and by the detecting park
 * itself): it unwinds the actor's user code through its child entry, and
 * `Future.execute` contains it into the actor's future, so the runner's drain
 * completes instead of hanging on a true deadlock. Internal on purpose —
 * user code must not catch it (a catch-and-continue loop would defeat the
 * abort; the next coordinator entry throws again anyway).
 */
internal class PctDeadlockError <: Exception {
    internal init(message: String) {
        super(message)
    }
}

/**
 * Thrown by the future-wait mediation gate (a retained engine-side
 * entry, currently unreachable — the compiler emits no future-wait
 * gate) when a registered actor tries to join a
 * future owned outside the scenario (a spawn from uninstrumented code, a
 * stray thread, or any completion source the coordinator cannot see): no
 * flip source exists, so the join can never be mediated — it would either
 * park forever (untimed) or really park in the runtime with the schedule
 * blind to it. The wait is rejected instead: the failure is recorded as
 * the iteration's protocol failure (surfaced by buildSchedule even if
 * user code catches the throw) and the error unwinds the actor, which
 * bounds the case and makes it diagnosable.
 * Internal on purpose — user code must not catch it (a catch-and-continue
 * cannot hide the failure: the protocol-failure record fails the
 * iteration at buildSchedule regardless).
 */
internal class PctExternalWaitError <: Exception {
    internal init(message: String) {
        super(message)
    }
}

/**
 * The wrapper for a user closure's own failure (an acquire probe, a
 * condition wait's inner lock release) while it runs inside an engine
 * region: thrown by the closure brackets (medAcquire's probe,
 * medCondWait's release) so nested regions rethrow it verbatim past the
 * protocol-failure record — an engine region cannot know whether it is
 * the outermost one, so the classification must travel with the
 * exception — and unwrapped back to the original at the dispatch route
 * (pctRoute, pct_dispatch.cj): the actor's operation must see its own
 * exception, not a framework failure. Internal on purpose: it exists
 * only between the brackets and the dispatch boundary; user code never
 * sees it.
 */
internal class PctUserClosureError <: Exception {
    internal let inner: Exception

    internal init(inner: Exception) {
        super("${inner}")
        this.inner = inner
    }
}

internal class PctCoordinator {
    // Configuration (one iteration; the schedule-report echo — the live
    // policy state lives in the scheduler).
    private let seed: UInt64
    private let actorCount: Int64
    private let pcpBudget0: Int64

    // Protocol state (under the engine lock, pct_engine_lock.cj).
    // The per-actor slot storage: identity (tids), gates, protocol state,
    // priority ranks, decision counters, mediated wait registrations (key +
    // edge kind), future identities and the mediated-absorb markers —
    // every actor's slot exists here, grown at registration. See
    // pct_actor_table.cj for the storage contract (semantic transitions;
    // lock-free tidToActor).
    private let table = PctActorTable()
    // The cycle abort's wait-for graph: tracked lock ownership plus the
    // park-time cycle search (see pct_wait_graph.cj). The detection half
    // only — the abort action (wave, strand, throw) stays below.
    private let graph = PctWaitForGraph(table: table)
    private var holder: Int64 = -1
    private var deadlocked: Bool = false

    // The scheduling policy: PctBaseScheduler's concrete implementation —
    // PCT's seeded decision stream (RNG, PCP draws, registration ranks)
    // by default, or the factory-injected policy (DPOR's guide-driven
    // scheduler). The grant picks, the starvation/fair-mode recovery,
    // and the schedule log it owns (event recording and the
    // replay-vs-record branching are its internals — this coordinator
    // requests decisions through its transfer API). A pure function of
    // the actor table plus the policy's own state, no parks or wakes.
    // See pct_scheduler_base.cj; driven under `lock` (which is what
    // makes the not-thread-safe RNG single-threaded by construction).
    private let sched: PctBaseScheduler

    // ------------------------------------------------------------------
    // Dynamic actors: actors register dynamically at window start
    // through childEnter — the runner's initial actors, slot i = array
    // order, entering with ident = None (no expectation to match, no
    // join identity; an internal call site the runner owns, unreachable
    // for strays). User-invoked spawns are unmanaged and never register
    // (they run as plain threads, invisible to the scheduler; see
    // pct_children.cj); the dynamic-registration machinery for
    // future-identified children (the spawn-site expectation, the
    // Some(future) childEnter/childExit routes) is retained but
    // currently has no producer. The registration coordination — the
    // expectation, the bounded registration waits, the actor count —
    // lives in the spawn registrar (pct_spawn_registrar.cj).
    // ------------------------------------------------------------------

    private let registrar = PctSpawnRegistrar()
    // Set when a wait-for cycle aborts the iteration (the cycle abort).
    // From that point every actor-side coordinator entry throws
    // PctDeadlockError (the abort wave has already woke every actor parked
    // on its gate), exits complete silently, and the runner fails the
    // iteration with the recorded schedule instead of draining forever.
    private var aborted: Bool = false
    // The actor path of the detected cycle (reported on the schedule).
    private var deadlockCycle: ?Array<Int64> = None
    // Window-close drain: every Finished transition signals this; the
    // draining thread waits on it between token pushes until every slot
    // is Finished.
    private let drainMonitor = Monitor()

    // Dispatch handlers must never throw non-abort exceptions (their calls
    // sit inside user frames; a protocol failure must not unwind into user
    // code); a failure is recorded here and surfaced by buildSchedule.
    // the route does the recording (handleException): any exception
    // engine region that is neither an engine-control abort nor a wrapped
    // user-closure failure (PctUserClosureError) lands here, and the
    // region's caller gets None — its `??` fallback then applies the
    // degraded value.
    private var protocolFailure: ?Exception = None
    // Dispatch calls absorbed in an unexpected protocol state (a live
    // non-holder actor reaching a dispatch, an exit without its Blocked
    // enter, an absorb-marker exit while not Running) — impossible while
    // the token protocol and the compilation boundary hold, so the count
    // must stay zero; non-zero fails the iteration loudly via
    // buildSchedule instead of silently corrupting the schedule.
    private var protocolViolations: Int64 = 0

    /**
     * The engine's exception policy for one region failure, called by the
     * dispatch route's catch (pctRoute in pct_dispatch.cj). Engine-control
     * aborts rethrow — they must unwind user code to the actor boundary;
     * a wrapped user-closure failure never reaches here (the route
     * catches the PctUserClosureError marker first and unwraps it);
     * everything else is a framework-internal failure: recorded into
     * `protocolFailure` under the engine lock (a fresh region — routes
     * are only entered from outside, so the failed region has already
     * released) and surfaced by buildSchedule. The route returns None
     * for the recorded case; the caller applies its degraded value (the
     * ABI entries absorb it; the one lifecycle caller that must not
     * degrade — childEnter's registration, via the spawn closure —
     * rethrows through recordedFailure).
     */
    internal func handleException(e: Exception): Unit {
        if (e is PctDeadlockError || e is ObstructionDetectedException || e is PctExternalWaitError) {
            throw e // the engine-control abort must unwind user code
        }
        pctOnLocked { => protocolFailure = e }
    }

    /**
     * The recorded protocol failure, read under the engine lock (the
     * spawn closure's childEnter rethrow — see runInitialActor).
     */
    internal func recordedFailure(): ?Exception {
        return pctOnLocked { => protocolFailure }
    }

    /**
     * Whether `tid` is bound to one of this window's registered actors —
     * the dispatch route's lock-free absorb filter (see
     * pctActiveCoordForActor). Safe without the engine lock only for the
     * CALLING thread's own tid (its registration is ordered ahead of its
     * own dispatches — see PctActorTable's single-writer/program-order
     * note); cross-thread or state-dependent queries must run inside an
     * engine region.
     */
    internal func isActorTid(tid: Int64): Bool {
        return table.tidToActor(tid).isSome()
    }

    /**
     * Test support (same-module tests only — see stdx.concurrent_test_util
     * and pctInjectProtocolFailureForTest): run one locked region that
     * throws, so the tests can assert the wrapper records the failure,
     * releases the lock, and the iteration fails loudly at buildSchedule
     * instead of hanging. Not a general-purpose API.
     */
    internal func debugInjectProtocolFailure(message: String): Unit {
        // The route's region wraps this; its catch records the throw
        // (handleException) and the entry discards the None.
        throw Exception(message)
    }

    internal init(seed!: UInt64, actorCount!: Int64, pcpBudget!: Int64, pcpFireProb!: Float64,
        starvationThreshold!: UInt64 = 10_000u64,
        switchBound!: Int64 = -1,
        schedulerFactory!: ?(PctActorTable) -> PctBaseScheduler = None) { // cjlint-ignore !G.FUN.01 config-carrier signature: the named parameters are the structured configuration/context of this framework step; bundling them into a struct would only move the count
        this.seed = seed
        this.actorCount = actorCount
        this.pcpBudget0 = pcpBudget
        sched = if (let Some(factory) <- schedulerFactory) {
            factory(table)
        } else {
            PctScheduler(seed: seed, pcpBudget: pcpBudget, pcpFireProb: pcpFireProb,
                starvationThreshold: starvationThreshold, switchBound: switchBound, table: table)
        }
        // Every actor registers dynamically and draws its rank at
        // registration (the scheduler's drawSpawnRank, recorded in its
        // Spawn event), so slots grow at registration (gates included)
        // and the RNG stream is per-registration. actorCount is only
        // the reported initial-actor count.
    }

    /**
     * Load a recorded schedule for replay. Returns 0 on success, -1 for an
     * empty schedule, -2 for schedules containing Resume events (deadlock
     * recovery depends on external wake timing and is not replayable),
     * -3 for schedules marked deadlocked (a cycle abort unwound
     * the actors mid-flight; the trailing decisions never happened).
     * Call before spawning any thread.
     */
    internal func loadReplay(schedule: PCTSchedule): Int32 {
        return sched.loadReplay(schedule, actorCount)
    }

    /**
     * Activate PCT for this coordinator: guard the binary's compilation
     * contract and (advisory) the single-active-iteration invariant.
     * Returns 0 on success, -1 if the binary was not compiled with
     * --cj-pct (blocking inside actor operations would be invisible to
     * the scheduler), -3 if a previous iteration is still active.
     *
     * The -3 check here is advisory only: a concurrent scenario run can
     * slip between this check and the window's install step, so the
     * authoritative, race-free guard is `pctInstallCurrentIteration`
     * (pct_dispatch.cj), which serializes the check-and-set on the
     * iteration guard. A run that loses that race fails its install
     * loudly instead of silently overwriting the active-window reference
     * (whose dispatches would then be tid-filtered into absorption — a
     * near-empty "passing" schedule).
     */
    internal func activate(): Int32 {
        if (!pctInstrumentedBinary) {
            return -1
        }
        if (pctActiveCoord.isSome()) {
            return -3
        }
        return 0
    }

    /**
     * The spawn authority check for the spawn-site brackets: user-code
     * spawns come from the token holder — the only thread running user
     * code inside the window. Anything else is a stray thread (a
     * pre-window spawn whose body is still running); its spawns stay
     * unmanaged. LOCK-FREE (the table's tid map is
     * single-writer/program-order readable).
     */
    private func isSpawnAuthority(tid: Int64): Bool {
        return table.tidToActor(tid) == Some(holder)
    }

    /** Main thread: give the token to the highest-priority actor and wake
     *  it. LOCK HELD (the window's route). */
    internal func releaseFirst(): Unit {
        let pick = sched.initialSwitch()
        if (pick >= 0) {
            transferLocked(pick)
            wake(pick) // under the engine lock: a gate open is a non-blocking notify (the woken thread contends until the route's region ends)
        }
    }

    /**
     * Actor operation boundary: a PCT decision point between consecutive
     * operations (called by the runner's operation loop). The caller must be
     * the token holder. May switch the token away and park the caller until
     * it is granted again. A non-holder poll is a protocol violation:
     * recorded (never thrown into the op loop, which would misclassify an
     * engine failure as the operation's own result) and surfaced by
     * buildSchedule.
     */
    internal func poll(me: Int64, fromGrid!: Bool = false): Unit {
        throwIfAbortedLocked() // cycle abort: unwind at the op boundary
        if (holder != me) {
            throw Exception("PCT protocol violation: op boundary polled by non-holder actor ${me}")
        }
        // Deterministic replay key: holder execution is serialized by the
        // token protocol, so per-actor decision counts are schedule-stable.
        table.bumpPoll(me)
        sched.bumpTotalPolls()
        var to: Int64 = -1
        if (fromGrid && sched.isFairMode()) {
            // Fair scheduling: the grid point is a voluntary yield (budget-
            // free, like blocking; see the scheduler's starvation note).
            to = fairYieldLocked(me) // gates me; -1 = nobody to yield to
        } else {
            to = sched.opBoundarySwitch(me, fromGrid: fromGrid)
            if (to >= 0) {
                table.markGated(me)
                transferLocked(to)
            } else if (fromGrid) {
                // Fast-mode grid continue: the holder keeps the token and
                // runs on — unless the scheduler's grid-continue streak
                // trips the obstruction policy (see
                // applyGridContinuePolicyLocked).
                to = applyGridContinuePolicyLocked(me) // gates me on a yield
            }
        }
        if (to >= 0) {
            wake(to)
            table.park(me) // switch-out / fair-yield park until the token returns (the park owns its drain)
            // Re-granted: holder == me again (the park's drain restored the
            // region's hold; the route releases it when the body ends).
        }
    }

    /**
     * The fast-mode grid-continue policy (LOCK HELD on entry, called
     * from poll): an unbroken run of consecutive grid polls means an
     * operation is waiting for a frozen peer (not obstruction-free)
     * and would livelock once the switch budget is spent — the
     * scheduler counts the run (a deterministic function of the
     * schedule, so replay re-triggers at the same decision) and
     * applies the obstruction policy.
     *
     * Returns -1 when the holder keeps the token and runs on.
     * Returns the grant target when the policy yielded the token: the
     * voluntary fair-mode yield's transfer happened inside, and the caller
     * wakes the target and parks outside the lock. Throws the obstruction
     * exception that unwinds the obstructed operation to its per-op
     * capture — the body's wrapper releases the lock (the actor's next
     * coordinator entry must not deadlock on it).
     */
    private func applyGridContinuePolicyLocked(me: Int64): Int64 {
        match (sched.noteGridContinue(me)) {
            case RunOn => -1
            case YieldNow => fairYieldLocked(me)
            case Obstruct(exc) =>
                throw exc
        }
    }

    /**
     * Fine-grained grid point: a call to `pctGridDispatchRw`
     * (made by the stdx.unittest.sync atomic wrappers after every atomic
     * operation in --cj-pct-compiled
     * code) reached the dispatcher, carrying the atomic object's identity (the
     * sync key of the just-completed atomic operation — the scheduler's
     * dependency bookkeeping; PCT ignores it) and its access class. Non-actor
     * tids are absorbed (the grid fires for every thread in the process);
     * `Finished` absorbs are expected (pooled-cjthread reuse); a registered
     * non-holder actor is a protocol violation (counted loudly, like a
     * sync-wrap absorb); otherwise the holder polls — the same decision core
     * as an operation boundary, so grid decisions share the replay key space.
     * In fair mode (starvation recovery) the grid point is instead a
     * voluntary yield.
     */
    internal func onGridPointRw(key: Object, write: Bool): Unit {
        // LOCK HELD (the entry's route); the poll below runs in the same
        // region — its park drains and restores the hold.
        let me = table.tidToActor(Thread.currentThread.id) ?? return ()
        if (table.isFinished(me)) {
            return
        }
        throwIfAbortedLocked() // cycle abort: unwind at the grid point
        if (holder != me) {
            protocolViolations++
            return
        }
        // The atomic's identity (with its access class) attaches to the
        // segment this grid decision closes (the scheduler's noteSync
        // stash; PCT: no-op).
        sched.noteSync(me, key,
            if (write) { PctSyncNoteKind.AtomicWrite } else { PctSyncNoteKind.AtomicRead })
        sched.noteGridPoint()
        // The grid decision itself: poll may switch the token away (the
        // park drains the region's hold) or throw the DPOR
        // ThrowObstruction recovery — it must unwind user code (the
        // obstructed operation ends as its per-op result; swallowing it
        // here would leave the spinning poll loop running — the wall
        // re-forms every starvationThreshold checks, forever).
        poll(me, fromGrid: true)
    }

    // ------------------------------------------------------------------
    // Sync dispatch entry points (reached through the wrappers'
    // pctSyncEnter/pctSyncExit brackets, on the traversing thread). They
    // may allocate, take the engine lock and log, but MUST NOT
    // throw; failures are recorded and surfaced by buildSchedule.
    // ------------------------------------------------------------------

    /**
     * Sync wrap entry: the calling thread is about to enter a blocking sync
     * intrinsic bracketed by the wrapper package (MCM wait, waitUntil's
     * polling loop, the condition fallback). Non-actor tids are absorbed
     * at the entry's route (pctActiveCoordForActor). For a registered
     * actor this is a real block iff the actor is the current holder;
     * anything else would be a protocol violation (impossible; counted
     * loudly). The runtime park that follows happens inside the wrapped
     * call; onSyncExit is the unblock. LOCK HELD (the entry's route).
     */
    internal func onSyncEnter(tid: Int64): Unit {
        let me = table.tidToActor(tid) ?? return () // not a PCT actor (e.g. the main thread's sleep/future polls)
        throwIfAbortedLocked() // cycle abort: unwind before any park
        if (holder != me) {
            absorbEnterLocked(me)
        } else {
            let wakeTarget = handleBlockEventLocked(me)
            if (wakeTarget >= 0) {
                wake(wakeTarget)
            }
        }
    }

    /**
     * Sync wrap exit: the calling thread's real runtime park inside a
     * wrapper bracket (MCM wait, waitUntil's polling loop, the condition
     * fallback) completed. For a `Blocked` actor this is the unblock: it
     * re-gates — parking on its gate semaphore (a Cangjie frame parked
     * below the user's call — the same managed-frame shape the grid park
     * verified) — or, after deadlock recovery, claims the token and
     * returns without parking. `Finished` actors absorb silently
     * (pooled-cjthread reuse); any other state is counted loudly. The
     * future-wait gate has no exit (it is the only coordinator
     * touchpoint of a mediated future wait, and external-owner waits are
     * rejected before any park).
     */
    internal func onSyncExit(tid: Int64): Unit {
        let me = table.tidToActor(tid) ?? return ()
        let st = table.stateOf(me)
        if (st == Finished) {
            return
        }
        if (aborted) {
            // cycle abort wave: this park (or the runtime park below
            // it, resolving an owner's exceptional future) returned
            // without a grant. Claim nothing, park nowhere — the
            // caller's next coordinator entry throws to finish the
            // unwind.
            return
        }
        if (st != Blocked) {
            protocolViolations++
            return
        }
        if (holder == -1) {
            // Deadlock recovery: claim the token (RESUME), no park.
            sched.recordResumeClaim(me)
            deadlocked = false
            transferLocked(me)
            return // run as holder
        }
        table.markGated(me)
        table.park(me) // re-gate park, in managed frames below the user's call (the park owns its drain)
        // Re-granted: holder == me again (the park's drain restored the hold).
    }

    /**
     * An actor's operation boundary by thread identity — the
     * runner's operation loop calls this from inside the actor body (the
     * actor's slot is assigned at its child-entry registration, so the
     * caller cannot know it; slot == actor.id for initial actors by the
     * sequential spawn order, but this lookup states no such invariant).
     * Unregistered threads (strays) are absorbed; everything else is
     * `poll` on the caller's own slot.
     */
    internal func pollSelf(): Unit {
        poll(table.tidToActor(Thread.currentThread.id) ?? return ())
    }

    // ------------------------------------------------------------------
    // Mediated mutex/semaphore/condition traffic (called from the
    // stdx.unittest.sync wrappers, which are precompiled WITHOUT --cj-pct
    // and therefore dispatch explicitly). The inner std.sync primitive
    // stays authoritative (the
    // de-risking rule): the wrapper probes with tryLock/tryAcquire first,
    // and only a failed probe reaches the coordinator, which owns the park
    // and the wake decision.
    // ------------------------------------------------------------------

    /**
     * A contended acquire by an actor: park on the coordinator gate, keyed
     * by the wrapper object, until the releaser's flip and a token grant
     * make the primitive available; then retry the probe. The probe runs
     * inside the engine region, after the Waiting registration — that
     * ordering closes the lost-wakeup race: a release that landed between
     * the wrapper's failed try-probe and this registration either still
     * holds the lock (probe fails again, we park, the NEXT release flips
     * us) or has completed (probe succeeds here, we proceed without ever
     * parking — silent, no events). A successful probe also records the
     * hold (the cycle abort's wait-for graph); `semantics` says how the key's
     * holders block future waiters (see PctAcquireSemantics).
     *
     * The caller (the wrapper) falls back to the plain bracketed runtime
     * park when this returns false: non-actor threads and binaries without
     * an active coordinator. A granted waiter whose retry probe fails (a
     * non-actor thread acquired in between — the documented mixed-traffic
     * barging limitation) simply re-Waits — the loop re-registers and
     * re-probes under the lock each time.
     *
     * The probe is user code (the wrapper's try operation) and may throw
     * (e.g. a semaphore amount out of the permitted range). Such a failure
     * is the actor's own, not an engine dispatch failure: the wait
     * registration is undone, the engine lock released, and the
     * exception re-thrown so it unwinds the actor's operation (surfacing
     * as that operation's recorded result) while the coordinator stays
     * consistent for every later dispatch.
     */
    internal func medAcquire(key: Object, probe: () -> Bool, semantics: PctAcquireSemantics): Bool { // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
        // LOCK HELD (the entry's route); the non-actor absorb filter
        // already ran at the entry (pctMedAcquire).
        let me = table.tidToActor(Thread.currentThread.id) ?? return false // not a PCT actor: the wrapper's fallback applies
        let edgeKind = graph.edgeKindFor(semantics) // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        // Every acquire attempt notes the key (uncontended acquires
        // are silent — no decision — so the key rides the CURRENT
        // segment's pending set; two segments touching the same lock
        // are dependent however the lock traffic resolved). Inside
        // the lock: the scheduler's state is engine-lock-guarded
        // (every other sched access runs under it), so an unlocked
        // note here would be the one unsynchronized writer.
        sched.noteSync(me, key, PctSyncNoteKind.Acquire)
        while (true) {
            if (table.isFinished(me)) {
                return false // pooled-cjthread reuse: absorb
            }
            throwIfAbortedLocked() // cycle abort: unwind before any park
            if (holder != me || table.stateOf(me) != Running) {
                // Wrapper code runs only on the token holder; anything
                // else would be a protocol violation (counted loudly).
                protocolViolations++
                return false
            }
            table.markWaiting(me, key, edgeKind)
            var probeOk = false
            try {
                // The probe is user code (the wrapper's try operation):
                // its failure is the actor's own — the wrap makes it
                // travel past the protocol-failure record (nested
                // regions rethrow the marker verbatim; the route
                // unwraps it). The pre-registration state is restored
                // first (the actor keeps the token — no transfer
                // happened).
                probeOk = probe()
            } catch (e: Exception) {
                table.markRunning(me)
                throw PctUserClosureError(e)
            }
            if (probeOk) {
                // The primitive became available since the wrapper's
                // try-probe: take it and keep running (no event).
                table.markRunning(me)
                graph.holderAdd(key, me) // cycle abort: track the hold
                // The successful acquire belongs to THIS segment (the
                // attempt note above may have landed in an earlier,
                // parked segment — the race reporter's acquire side).
                sched.noteSync(me, key, PctSyncNoteKind.Acquire)
                return true
            }
            // A cycle abort throws from here — the region's unwind
            // releases the engine lock.
            sched.noteSync(me, key, PctSyncNoteKind.Acquire) // the contended park's key (segment close)
            let wakeTarget = parkDecisionLocked(me)
            if (wakeTarget >= 0) {
                wake(wakeTarget)
            }
            table.park(me) // mediated park: gated until the releaser's flip + a grant (the park owns its drain)
            // Granted: holder == me again (a cycle abort wave instead
            // opens the gate without a grant — the loop top's abort
            // check throws then). The grant followed a flip, so the
            // primitive was released; the under-lock probe retries
            // (the park's drain restored the region's hold).
        }
        return false // unreachable: the loop exits only via return
    }

    /**
     * A PCT actor's virtual sleep (the compiler reroutes the SLEEP
     * intrinsic to pctSleep, which lands here): arm a virtual timer on a
     * per-sleep private key (nothing but the timer can flip it) and park
     * on the coordinator gate — the sleep never touches wall time, and
     * its expiry is the Timer event, a deterministic scheduling decision.
     * Since virtual time advances only at quiescence, a sleep does not
     * delay runnable peers: it parks, and the clock reaches the deadline
     * exactly when nothing else can happen. Returns true when handled
     * (the sleep completed); false when the caller must take the real
     * sleep (non-actor thread — its sleeps are none of the schedule's
     * business). `nanos` of Int64.Max is a forever sleep: no timer, and
     * the park strands at quiescence like any untimed wait.
     */
    internal func medSleep(nanos: Int64): Bool {
        // LOCK HELD (the entry's route); the non-actor absorb filter
        // already ran at the entry (pctSleep).
        let me = table.tidToActor(Thread.currentThread.id) ?? return false // not a PCT actor: the real sleep applies
        if (table.isFinished(me)) {
            return false // pooled-cjthread reuse: absorb
        }
        throwIfAbortedLocked() // cycle abort: unwind before the park
        if (holder != me || table.stateOf(me) != Running) {
            protocolViolations++
            return false
        }
        let key = Object() // per-sleep identity: only its timer can flip it
        sched.armTimer(me, key, nanos)
        let wakeTarget = handleParkEventLocked(me, key) // edge: NoEdge (a sleep waits on nothing)
        if (wakeTarget >= 0) {
            wake(wakeTarget)
        }
        table.park(me) // the virtual sleep park (the park owns its drain)
        // Woken: the timer fired (or a cycle abort wave opened the
        // gate without a grant — the check below throws).
        throwIfAbortedLocked()
        if (table.timerFiredOf(me)) {
            table.setTimerFired(me, false)
        }
        return true
    }

    /**
     * The future-wait mediation gate — the single pre-intrinsic entry of
     * the mediated future wait (the gate has no exit; this call is the
     * only coordinator touchpoint): carries the future object and the
     * wait's timeout (Int64 nanoseconds; Int64.Max — `Future.get()`).
     * When reached, it mediates the wait if the future has a live
     * registered child owner — parks on the coordinator gate (arming a
     * virtual timer for a finite timeout, the expiry the Timer event, a
     * scheduling decision) and returns the budget the wrapped intrinsic
     * may still consume: 1ns (never 0 — some waitqueue paths
     * special-case zero) when the park ended by a fired timer, the full
     * timeout otherwise (the future is complete by construction — the
     * only flip path is the owner's childExit — so the intrinsic
     * returns without parking). A future with no live registered owner
     * is REJECTED: no flip source exists, so the join can never be
     * mediated — the failure is recorded as the iteration's protocol
     * failure (surfaced by buildSchedule even if user code catches the
     * throw) and the error unwinds the actor. Non-actors and
     * no-scenario callers pass the timeout through unchanged. A
     * retained engine-side entry, currently unreachable: the compiler
     * emits no future-wait gate.
     * (Cycle abort wave: the park returns WITHOUT a grant — pass the
     * full budget and let the wrapped intrinsic resolve against the
     * owner's completing future; the next coordinator entry throws.)
     */
    internal func futureGate(tid: Int64, f: Object, timeout: Int64): Int64 { // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
        // LOCK HELD (the entry's route); the non-actor absorb filter
        // already ran at the entry (pctFutureGate).
        let me = table.tidToActor(tid) ?? return timeout // not a PCT actor (e.g. the main thread's future polls)
        throwIfAbortedLocked() // cycle abort: unwind before any park
        // Ownership first: the actionable diagnostic wins over the
        // token anomaly below. In the retained handshake a managed
        // child registers before its spawner proceeds and get()
        // pre-checks completion, so a future with no live registered
        // owner here is exactly the genuinely-external class.
        if (table.liveChildOwner(f).isNone()) {
            let err = PctExternalWaitError(
                "PCT protocol violation: actor #${me} waited on a future owned outside the scenario " +
                "(uninstrumented spawn or stray thread); joins in a PCT scenario must target " +
                "futures spawned inside the scenario")
            protocolFailure = err // surfaced by buildSchedule even if user code catches the throw
            throw err
        }
        if (holder != me) {
            absorbEnterLocked(me)
            return timeout
        }
        if (timeout != Int64.Max) {
            // A finite timed join on a live child: the deadline is
            // a virtual one — arm the timer so the expiry is a
            // scheduling decision, not a wall-clock wake.
            sched.armTimer(me, f, timeout)
        }
        sched.noteSync(me, f, PctSyncNoteKind.Acquire) // the joined future's key (DPOR segments)
        let wakeTarget = handleParkEventLocked(me, f, edge: JoinFuture)
        if (wakeTarget >= 0) {
            wake(wakeTarget)
        }
        table.park(me) // mediated park: gated until the owner's flip + a grant (the park owns its drain)
        var firedNow = table.timerFiredOf(me)
        if (firedNow) {
            table.setTimerFired(me, false)
        }
        if (!firedNow) {
            // The completed join (the join edge's acquire side): the
            // future completed — the note lands in the segment holding
            // the wait's return. Timed-out joins note nothing (their
            // budgeted wait is deliberately racy user code).
            sched.noteSync(me, f, PctSyncNoteKind.Acquire)
        }
        if (firedNow) {
            return 1
        }
        return timeout
    }

    /**
     * An unlock/release/notify with mediated waiters on `key` (called by the
     * wrappers AFTER the inner operation, so the primitive is genuinely
     * available when the flipped waiters retry). Flips up to `maxFlips`
     * waiters (a notify flips a single one). Actor releaser: the yield
     * point of locked decision 1 — waiters flip to Gated, the releaser
     * itself becomes Gated, and the pick grants the token (possibly back
     * to the releaser; unlocks without waiters stay silent). Non-actor
     * releaser: flip only, plus a stranded-token grant (the drainActors
     * precedent) so a recorded deadlock can recover; that revival is
     * wall-clock-timed, so it logs a Resume event and marks the schedule
     * non-replayable, exactly like a timed-wait expiry.
     */
    internal func medRelease(key: Object, kind: PctEventKind, maxFlips!: Int64 = Int64.Max): Unit {
        // LOCK HELD (the entry's route). The entry deliberately does NOT
        // filter non-actors: a non-actor release is an external event
        // the schedule must observe (the external-release revival).
        let meOpt = table.tidToActor(Thread.currentThread.id)
        if (aborted) {
            // cycle abort: the waiters are unwinding (the wave woke
            // them); no flips, no picks, no revival bookkeeping.
            return
        }
        if (meOpt.isNone()) {
            // Non-actor releaser (a thread outside the schedule):
            // forget the key's tracked holders (sound — releases from
            // unmanaged threads cannot be attributed to an actor, and
            // a forgotten holder only misses cycles, never fakes one).
            graph.holderClear(key)
            let flipped = table.flipWaiting(key, max: maxFlips)
            if (flipped > 0 && holder == -1) {
                let revived = sched.externalRevival()
                if (revived >= 0) {
                    deadlocked = false
                    transferLocked(revived)
                    wake(revived)
                    return
                }
            }
            return
        }
        let me = meOpt.getOrThrow() // cjlint-ignore !G.ERR.03 invariant-guarded extraction: a preceding isNone()/contains() gate (or the ScenarioBuilder contract, see comment) guarantees Some here; None would be a framework bug where throwing is the intended behavior
        if (table.isFinished(me)) {
            return // pooled-cjthread reuse: absorb
        }
        if (holder != me) {
            protocolViolations++ // impossible (only the holder runs); loud
            return
        }
        graph.holderRemove(key, me) // cycle abort: one (counted) hold dropped
        // Every release notes the key (a flipless release is silent —
        // no decision — so the key rides the current segment; see
        // medAcquire's matching note).
        sched.noteSync(me, key, PctSyncNoteKind.Release)
        let to = handleUnlockEventLocked(me, key, kind, maxFlips: maxFlips)
        if (to >= 0 && to != me) {
            wake(to)
            table.park(me) // yield park until the token returns (the park owns its drain)
        }
        // to == me (the releaser won its own yield pick) or -1 (no
        // waiters): keep running.
    }

    /**
     * The mediated condition-wait protocol (an actor's
     * `Monitor.wait`/`Condition.wait`, timed or untimed): release the
     * inner lock, park on the coordinator gate keyed by the condition,
     * then Mesa re-acquire.
     *
     * The whole wait is one merged decision: `release` (the inner lock
     * release, one level — condition waits are a lock-depth-one protocol)
     * runs in the engine region after the actor checks, the region's
     * own mediated waiters flip silently (their eligibility IS the release;
     * no Unlock event fires — the wait's park decision subsumes the
     * handoff), and the waiter registers Waiting on `condKey` and parks.
     * A finite `timeout` (virtual time) arms a timer at the wait's entry:
     * the expiry fires at quiescence (the Timer event) and the waiter
     * wakes timed-out — never by wall clock. On a notify-side grant it
     * re-acquires the inner lock through the mediated acquire protocol
     * (`probe`, the owner lock's try operation; a contended re-acquire
     * parks keyed by `lockKey` — the two-stage Mesa re-wait); a timed-out
     * waiter re-acquires the same way (Mesa semantics: the wait returns
     * holding the lock either way). Returns Some(true) when the wait
     * completed by a notify, Some(false) when it timed out (the lock is
     * re-held in both cases), and None when the caller must fall back to
     * the plain bracketed runtime wait (non-actor thread, pooled reuse).
     *
     * The `release` and `probe` closures are user code (the wrapper's
     * inner lock operations) and may throw (e.g. a condition wait without
     * holding the owner lock). Such a failure is the actor's own, not an
     * engine dispatch failure: the engine lock is released (no state
     * has been mutated before the release runs) and the exception is
     * re-thrown so it unwinds the actor's operation, while the coordinator
     * stays consistent for every later dispatch.
     */
    internal func medCondWait(condKey: Object, lockKey: Object, release: () -> Unit, probe: () -> Bool, // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
        timeout!: Duration = Duration.Max): ?Bool {
        // LOCK HELD (the entry's route); the non-actor absorb filter
        // already ran at the entry (pctCondWait).
        let me = table.tidToActor(Thread.currentThread.id) ?? return None // not a PCT actor: the wrapper's fallback applies
        if (table.isFinished(me)) {
            return None // pooled-cjthread reuse: absorb
        }
        throwIfAbortedLocked() // cycle abort: unwind before any park
        if (holder != me || table.stateOf(me) != Running) {
            // Wrapper code runs only on the token holder; anything
            // else would be a protocol violation (counted loudly).
            protocolViolations++
            return None
        }
        // The inner release is user code (the wrapper's lock
        // operation): its failure is the actor's own — the wrap makes
        // it travel past the protocol-failure record (the route
        // unwraps it). Nothing has been mutated yet, so re-throwing
        // leaves the coordinator consistent.
        try {
            release()
        } catch (e: Exception) {
            throw PctUserClosureError(e)
        }
        graph.holderRemove(lockKey, me) // cycle abort: the one-level hold drop
        table.flipWaiting(lockKey) // silent: the park decision below subsumes this handoff
        sched.armTimer(me, condKey, pctDurationNanos(timeout))
        // The wait's park decision closes a segment touching both
        // keys: the condition it parks on (an acquire — the wait) and
        // the lock it released (Mesa).
        sched.noteSync(me, condKey, PctSyncNoteKind.Acquire)
        sched.noteSync(me, lockKey, PctSyncNoteKind.Release)
        let wakeTarget = handleParkEventLocked(me, condKey) // edge: NoEdge (a condition wait)
        if (wakeTarget >= 0) {
            wake(wakeTarget)
        }
        table.park(me) // mediated condition park, timer-fired or notified (the park owns its drain)
        // Woken: a notify-side flip and grant, or a virtual timer fire
        // (or a cycle abort wave — the re-acquire's entry check
        // throws to finish the unwind). Distinguish by the fired
        // marker before the Mesa re-acquire.
        var timedOut = false
        if (table.timerFiredOf(me)) {
            table.setTimerFired(me, false)
            timedOut = true
        }
        // Mesa re-acquire, possibly via a second, lock-keyed mediated
        // wait — for the timed-out path too (the wait returns holding
        // the lock either way). medAcquire is a plain nested call in
        // the SAME region (its park drains the region's hold and
        // restores it), so a user-closure failure or an abort from the
        // re-acquire unwinds through the route's classification
        // directly.
        let reAcquired = medAcquire(lockKey, probe, PctAcquireSemantics.Exclusive)
        if (!reAcquired) {
            return None
        }
        if (!timedOut) {
            // The completed condition wait (the notify edge's acquire
            // side): the note lands in the segment containing the wait
            // return. Timed-out waits note nothing — no notify edge
            // exists for them.
            sched.noteSync(me, condKey, PctSyncNoteKind.Acquire)
        }
        return Some(!timedOut)
    }

    // The mediated unlock/release/notify yield decision. Flips the
    // waiters on `key` (up to `maxFlips`: a notify flips a single waiter),
    // gates the releaser, and asks the scheduler for the yield decision
    // (the pick among all Gated — the flipped waiters and the releaser
    // alike, a priority pick, not first-waker). LOCK HELD; returns the
    // grant target (>= 0; may be `me`), or -1 when nothing flipped or
    // the pick found nobody (silent unlock: the releaser keeps running
    // and nothing is logged).
    private func handleUnlockEventLocked(me: Int64, key: Object, kind: PctEventKind, maxFlips!: Int64 = Int64.Max): Int64 {
        if (table.flipWaiting(key, max: maxFlips) == 0) {
            return -1
        }
        table.markGated(me)
        match (sched.unlockTransfer(me, kind)) {
            case Grant(to) =>
                transferLocked(to)
                return to
            case _ =>
                // Unreachable in practice (the flipped waiters are Gated); keep
                // the protocol total by running on.
                table.markRunning(me)
                return -1
        }
    }

    // ------------------------------------------------------------------
    // Dynamic actors: one entry pair
    // (childEnter/childExit) distinguished by the join identity —
    // None for the initial actors (the runner's internal call sites),
    // Some(future) for future-identified children. Both register
    // through the same core (claimSlotLocked): the spawn decision (slot
    // + rank) is drawn at registration, and the runner waits on the
    // registered count after each initial spawn — which is what makes
    // the Spawn event stream deterministic and replayable. Some(ident)
    // registers against the spawn-site expectation (the stray filter:
    // unmatched threads absorb) and flips joiners at exit; None
    // registers unconditionally (a call site the runner owns,
    // unreachable for strays) with no join identity and no flip — a
    // retained route with no producer today (the compiler emits no
    // spawn interception, so no future-identified child ever registers).
    // ------------------------------------------------------------------

    /** Spawn-site bracket: record the expectation (spawning thread).
     * Retained engine-side entry; currently unreachable (no producer). */
    internal func onSpawnSiteBefore(ident: Object, tid: Int64): Unit {
        // A plain engine region (no route — nothing dispatches here
        // yet); an abort rethrows through pctOnLocked's finally.
        // Authority-gated: inside a window only the token holder
        // (the only thread running user code) executes the
        // spawn-site machinery; anything else is a stray thread (a
        // pre-window spawn whose body is running user code) — absorb,
        // and its whole subtree stays unmanaged.
        if (!isSpawnAuthority(tid)) {
            return
        }
        pctOnLocked { =>
            throwIfAbortedLocked() // cycle abort: unwind before spawning
            registrar.setExpectation(ident)
        }
    }

    /** Spawn-site bracket: bounded wait for the child's registration.
     * Retained engine-side entry; currently unreachable (no producer). */
    internal func onSpawnSiteAfter(tid: Int64): Unit {
        try {
            if (!isSpawnAuthority(tid)) {
                return
            }
            // Wait until the expectation is consumed (the child registered
            // and parked). Registration needs no token, so this park cannot
            // deadlock; the bound covers thread-start failures, which
            // surface as a protocol failure here.
            if (!registrar.awaitRegistration()) {
                pctOnLocked { =>
                    protocolFailure = Exception(
                        "PCT protocol violation: spawned child failed to register within " +
                        "${PctSpawnRegistrar.REGISTRATION_TIMEOUT_MS}ms (thread creation stalled?)")
                }
            }
        } catch (e: Exception) {
            pctOnLocked { => protocolFailure = e }
        }
    }

    /**
     * Child prologue (on the child's thread): register as a dynamic actor
     * and park at the registration gate until the first grant. `ident` is
     * the child's join identity, and it selects the route:
     *  - Some(future) — the future-identified route (retained; no
     *    producer today — the compiler emits no spawn interception):
     *    matched against the spawn-site expectation; unmatched (stray)
     *    threads absorb and run unmanaged, exactly like spawns in
     *    uninstrumented code. The future is recorded as the slot's join
     *    identity (what mediated joiners wait on).
     *  - None — the runner's initial actors: no expectation to match (the
     *    runner owns these call sites; only its closures pass None), so
     *    registration is unconditional and the slot carries no join
     *    identity (an initial actor's future never escapes the runner).
     * The runner waits for each registration (awaitRegisteredActors)
     * before its next spawn, so the Spawn order stays its sequential
     * spawn order.
     */
    internal func childEnter(ident: ?Object, tid: Int64): Unit {
        // LOCK HELD (the spawn closure's route). A recorded registration
        // failure (the route returns None) is rethrown by the CALLER —
        // runInitialActor, via recordedFailure — so the child never falls
        // through unregistered (the S-08 contract).
        if (let Some(id) <- ident) {
            var matched = false
            if (let Some(pending) <- registrar.expectation() && refEq(pending, id)) {
                matched = true
            }
            if (!matched) {
                return
            }
            // Consume the expectation and release the waiting spawner
            // BEFORE parking: the spawner's wait must never depend on a
            // token grant.
            registrar.clearExpectation()
        }
        // The spawn registration decision (replay binds the recorded
        // slot and priority rank; a missing Spawn event means the code
        // spawned where the recorded schedule did not — the scheduler
        // diverges and the registration continues in record mode).
        let d = sched.spawnDecision()
        claimSlotLocked(d, tid, ident)
        // The spawn happens-before edge's spawner side: the token
        // holder's in-progress segment contains the spawn site (-1 for
        // the runner's initial actors; PCT: no-op).
        sched.childRegistered(d.slot, table.runningSlot())
        // The registration tail: the waiting spawner is released in a
        // drained section (notifyRegistered takes spawnMonitor, and the
        // registrar's waits take the engine lock while holding
        // spawnMonitor — the documented spawnMonitor -> engine lock
        // order, which a notify under the engine lock would invert),
        // then the registration park until the first grant (the park
        // owns its own drain; the park cannot deadlock — registration
        // needs no token), then the abort check (a cycle abort wave
        // opened the gate without a grant, so the body must never run).
        pctWithTemporarilyUnlocked { =>
            registrar.notifyRegistered()
        }
        table.park(d.slot) // registration park until the first grant
        // Granted: this slot holds the token; the child entry proceeds.
        throwIfAbortedLocked()
    }

    /**
     * The shared registration core (LOCK HELD): grow the table for the
     * decision's slot, clear a pooled-cjthread predecessor's tid, claim
     * and gate the slot, apply the spawn rank, and count the actor.
     * `ident` is the child's join identity (its own future, what
     * mediated joiners wait on) — None for the runner's initial actors,
     * whose futures never escape the runner and therefore carry no join
     * identity at all.
     */
    private func claimSlotLocked(d: PctSpawnDecision, tid: Int64, ident: ?Object): Unit {
        let slot = d.slot
        table.ensureSlot(slot)
        // Pooled-cjthread reuse: this tid may have belonged to a
        // Finished predecessor — the table clears it and records the
        // tid (a live actor can never share a tid with this child; a
        // live predecessor is a protocol violation).
        if (table.claimTid(slot, tid) >= 0) {
            protocolFailure = Exception(
                "PCT protocol violation: spawn registration tid collision with a live actor")
        }
        table.markGated(slot)
        table.resetPoll(slot)
        if (let Some(f) <- ident) {
            table.setMyFuture(slot, f)
        }
        sched.applySpawnRank(d, holder)
        registrar.noteRegistered()
    }

    /**
     * Child epilogue (finally, on the child's thread): mark the dynamic
     * actor Finished and transfer the token. Never-registered tids absorb
     * (window closed, or the wrapper ran as a no-op stray). `ident` is
     * the child's join identity, selecting the route like childEnter's:
     * Some(future) is the future-identified route (retained; no producer
     * today); None is the runner's initial actors, whose futures never
     * escape the
     * runner (no one can be mediated-waiting on them), so the joiner
     * flip is skipped and the exit always logs Done, never Complete. If
     * the API ever exposes initial futures, a join takes the documented
     * unmediated fallback (Deadlock + Resume, non-replayable) — loud,
     * not silent.
     *
     * The drain signal is the EXIT CALLER's tail (runInitialActor, after
     * its route): it must never run under the engine lock — see
     * signalDrain. A future producer for the Some route must follow the
     * same shape (route the body, signal after).
     *
     * Mediated completion (the Some route): Future.execute completed
     * the future (result set, notifyAll fired) BEFORE this finally, so
     * every actor Waiting on it can be flipped to Gated right here,
     * under the lock, BEFORE the Done/Complete pick — the flip and the
     * pick are one atomic decision, the joiners compete for the very
     * next grant, and no runtime wake can race the schedule. Exits that
     * flipped someone log `Complete` instead of `Done`.
     */
    internal func childExit(ident: ?Object, tid: Int64): Unit {
        // LOCK HELD (the spawn closure's route). The drain signal does
        // NOT fire here: the caller (runInitialActor) signals AFTER its
        // route returns — under the engine lock the signal would invert
        // the drainActors handshake (drainMonitor -> engine).
        let me = table.tidToActor(tid) ?? return ()
        if (table.isFinished(me)) {
            return
        }
        // cycle abort: skip the joiner flip (the wave already woke
        // every waiter) and let finishLocked's abort branch complete
        // the exit silently.
        var flipped = false
        if (let Some(id) <- ident) {
            if (!aborted) {
                flipped = table.flipWaiting(id) > 0
            }
            // The exit's decision closes a segment keyed by the child's
            // future identity (mediated joiners wait on it; the key is
            // harmless when nobody joined). A Release: the completion
            // is the join edge's release side.
            sched.noteSync(me, id, PctSyncNoteKind.Release)
        }
        let to = finishLocked(me, completedWaiters: flipped)
        if (to >= 0) {
            wake(to)
        }
    }

    /**
     * The runner's bounded wait for the initial actor it just spawned:
     * NOT routed — the registrar's bounded waits (spawnMonitor) must run
     * without the engine lock held, or the registering child's own route
     * could never take it (a 10s stall, then a spurious protocol
     * failure); the registrar's predicate checks take the engine lock
     * themselves in brief pctOnLocked pairs.
     * registration is token-free (the child parks at its registration
     * gate), so this cannot deadlock; the bound covers thread-start
     * failures, which surface as a protocol failure. One wait per spawn
     * keeps registration order — and with it the recorded Spawn order —
     * equal to the runner's sequential spawn order.
     */
    internal func awaitRegisteredActors(count: Int64): Unit {
        if (!registrar.awaitSpawnCount(count)) {
            pctOnLocked { =>
                protocolFailure = Exception(
                    "PCT protocol violation: initial actor failed to register within " +
                    "${PctSpawnRegistrar.REGISTRATION_TIMEOUT_MS}ms (thread creation stalled?)")
            }
        }
    }

    /**
     * Window-close drain: run every remaining registered actor — any
     * registered actor beyond the initial actors' futures (a retained
     * route; no producer registers such actors today) — to completion.
     * The draining thread pushes the token to the
     * highest-priority Gated actor whenever it is stranded (holder == -1)
     * and otherwise waits on the drain monitor; the pick is a pure
     * function of the (replayed) priorities, so record and replay agree
     * without logging a drain event. Deadlocks WITH a wait-for cycle
     * never reach the drain (the cycle abort unwinds every actor
     * first); cycle-free ones (a starved semaphore, an unnotified
     * condition) still hang here, exactly like the runner's future drain
     * — they cannot be proven final while an external thread might still
     * act. Call after the initial actors' futures resolved, before
     * buildSchedule.
     */
    internal func drainActors(): Unit {
        // LOCK HELD (the window's route). drainMonitor is held across the
        // engine re-acquisition of the drained wait (drainMonitor ->
        // engine) — safe because the drain signal (childExit's callers,
        // post-route) never takes drainMonitor under the engine; the
        // drain wait runs drained (the engine lock released, drainMonitor
        // released by the wait itself).
        drainMonitor.lock()
        while (true) {
            let allDone = table.allFinished()
            var to: Int64 = -1
            if (!allDone && holder == -1 && !aborted) {
                to = sched.drainPick()
                if (to >= 0) {
                    transferLocked(to)
                }
            }
            if (to >= 0) {
                wake(to)
                continue
            }
            if (allDone) {
                break
            }
            // the drain wait runs with the engine lock released
            pctWithTemporarilyUnlocked { =>
                drainMonitor.wait()
            }
        }
        drainMonitor.unlock()
        // A crashed spawn site (spawn failure) may leave a stale
        // expectation; no child can register after the drain.
        registrar.clearExpectation()
    }

    // ------------------------------------------------------------------
    // Private dynamic-actor helpers ("Locked" = the engine lock is held).
    // ------------------------------------------------------------------

    /**
     * Wake the draining thread (the actor-exit callers run this AFTER
     * their route returns — never under the engine lock: the drainActors
     * handshake holds drainMonitor across its engine re-acquisition
     * (drainMonitor -> engine), so a signal under the engine would
     * invert the order).
     */
    internal func signalDrain(): Unit {
        drainMonitor.lock()
        drainMonitor.notify()
        drainMonitor.unlock()
    }

    /**
     * Did a wait-for cycle abort this iteration? Authoritative abort
     * verdict for the runner — the PctDeadlockError itself may be
     * swallowed by the actor op wrappers (execResultOf captures every
     * exception as the op's recorded result), so the flag, not the
     * exception, is the signal. Call after the drain (every actor
     * Finished; no concurrent writer remains).
     */
    internal func isAborted(): Bool {
        // LOCK HELD (the window's route).
        return aborted
    }

    /**
     * Snapshot the recorded schedule (after all actor futures resolved).
     *
     * @throws Exception on a PCT protocol violation: dispatch events were
     * recorded in an unexpected state (instrumented code ran off-token, or
     * an enter/exit bracket mismatched), or a recorded dispatch failure
     * surfaced.
     */
    internal func buildSchedule(): PCTSchedule {
        // A plain engine region (not a route — plain pctOnLocked): the snapshot has
        // no park and no user closure, and the throws below are the
        // SURFACING (they must reach the runner, not be recorded).
        return pctOnLocked { =>
            let schedule = PCTSchedule(
                seed: seed,
                actorCount: actorCount,
                pcpBudget: pcpBudget0,
                events: sched.scheduleEventsSnapshot(),
                diverged: sched.scheduleDiverged(),
                deadlocked: deadlocked,
                pollCount: sched.totalPollCount(),
                gridPoints: sched.gridPointCount(),
                starvationSwitches: sched.starvationSwitchCount(),
                spawnedActors: registrar.spawnCount(),
                timersHighWater: sched.timersHighWater(),
                deadlockCycle: deadlockCycle
            )
            // A cycle abort already fails the iteration with the schedule
            // (and the abort wave's unusual traversals are expected); the
            // loud protocol guards would only bury the deadlock diagnosis.
            if (!aborted) {
                if (protocolViolations != 0) {
                    // Only the token holder executes dispatch-carrying code,
                    // and every wrap exit matches its enter — the gate-park
                    // protocol and the compilation boundary make any other
                    // dispatch-in-state combination impossible. A non-zero
                    // count means one of those invariants broke, and the
                    // schedule semantics can no longer be trusted.
                    throw Exception("PCT protocol violation: ${protocolViolations} dispatch event(s) in unexpected state " +
                        "(instrumented code ran off-token, or an enter/exit bracket mismatched).")
                }
                if (let Some(e) <- protocolFailure) {
                    throw Exception("PCT protocol dispatch failure: ${e.message}.")
                }
            }
            return schedule
        }
    }

    // ------------------------------------------------------------------
    // Private protocol helpers. "Locked" = the engine lock is held; wakes
    // always happen after unlocking (a woken thread is then the only
    // possible lock taker).
    // ------------------------------------------------------------------

    // Mark `me` Finished and transfer the token (the shared tail of done
    // and childExit). LOCK HELD; returns the actor to wake after
    // unlocking (-1 = nobody). `completedWaiters`: childExit flipped
    // Waiting joiners to Gated before this call — the exit logs `Complete`
    // (the mediated-completion event) instead of `Done` (the flip is
    // a deterministic function of the schedule, so a replayed kind
    // mismatch is a real divergence the scheduler detects).
    private func finishLocked(me: Int64, completedWaiters!: Bool = false): Int64 {
        if (aborted) {
            // cycle abort unwind: complete silently — no flip (the wave
            // already woke every waiter), no event, no pick (every
            // remaining actor is unwinding too; the runner's drain
            // completes on these transitions).
            table.markFinished(me)
            return -1
        }
        table.markFinished(me)
        let exitKind = if (completedWaiters) {
            Complete
        } else {
            Done
        }
        match (sched.exitTransfer(me, exitKind)) {
            case Grant(to) =>
                transferLocked(to)
                return to
            case Strand(strandedWithWaiters) =>
                holder = -1
                if (strandedWithWaiters) {
                    deadlocked = true
                }
                return -1
            case Silent =>
                return -1 // unreachable: exits always record a decision
        }
    }

    // Absorb a sync-wrap enter by a non-holder actor: impossible (a
    // non-holder actor is parked); counted loudly. `Finished` is expected
    // (pooled-cjthread reuse after completion).
    private func absorbEnterLocked(me: Int64): Unit {
        if (!table.isFinished(me)) {
            protocolViolations++
        }
    }

    // The holder is about to park inside a sync primitive: the token must
    // move (or the deadlock is recorded). LOCK HELD; returns the actor to
    // wake after unlocking (-1 = nobody).
    private func handleBlockEventLocked(me: Int64): Int64 {
        table.markBlocked(me)
        match (sched.blockingTransfer(me, Block)) {
            case Grant(to) =>
                transferLocked(to)
                return to
            case Strand(_) =>
                // Nobody gated: recovery happens when an external wake
                // (timed wait expiry) later unblocks an actor, whose
                // sync-wrap exit claims the token (RESUME).
                holder = -1
                deadlocked = true
                return -1
            case Silent =>
                return -1 // unreachable: blocks always record a decision
        }
    }

    // The holder is entering a mediated wait (a future join whose
    // owner is a live registered child, a condition wait, a virtual
    // sleep): record Waiting with the wait key, then the same token move
    // (or deadlock record) as a block. The caller parks on its own gate
    // after this returns; its only wake is a token grant — for a join,
    // the owner's completion flip (childExit); for a sleep, the timer
    // fire. LOCK HELD; returns the actor to wake after unlocking
    // (-1 = nobody).
    private func handleParkEventLocked(me: Int64, key: Object,
        edge!: PctWaitEdgeKind = NoEdge): Int64 {
        table.markWaiting(me, key, edge)
        return parkDecisionLocked(me)
    }

    // The mediated-park decision core (state and key already recorded):
    // the wait-for cycle check first (a wait-for cycle closed by this
    // park is a proven deadlock — the abort unlocks, waves every parked
    // actor and throws, never returning), then the scheduler's Wait
    // transfer. LOCK HELD; returns the actor to wake after unlocking
    // (-1 = nobody).
    private func parkDecisionLocked(me: Int64): Int64 {
        if (!aborted) {
            if (let Some(cycle) <- graph.detectCycle(me)) {
                abortIterationLocked(me, cycle) // unlocks and throws
            }
        }
        match (sched.blockingTransfer(me, Wait)) {
            case Grant(to) =>
                transferLocked(to)
                return to
            case Strand(_) =>
                // Nobody gated: recovery is possible only if the waited
                // key's owner later acts externally — the waited child
                // itself resumes and completes (its childExit flips this
                // waiter), or a non-actor thread releases the primitive
                // (the flip plus the stranded-token grant in medRelease
                // revive it).
                holder = -1
                deadlocked = true
                return -1
            case Silent =>
                return -1 // unreachable: parks always record a decision
        }
    }

    // ------------------------------------------------------------------
    // The wait-for cycle abort. The cycle DETECTION lives in the
    // wait-for graph (pct_wait_graph.cj: tracked ownership + the park-time
    // BFS); this section is the protocol response — the abort gate every
    // actor-side entry checks, and the wave that unwinds the iteration.
    // LOCK HELD for everything in this section.
    // ------------------------------------------------------------------

    /**
     * Abort check for actor-side coordinator entries. LOCK HELD; throws
     * once the iteration has aborted — the enclosing route
     * region releases the lock on the unwind.
     *
     * @throws PctDeadlockError when the iteration has aborted after a
     * detected wait-for deadlock.
     */
    private func throwIfAbortedLocked(): Unit {
        if (aborted) {
            throw PctDeadlockError("PCT iteration aborted after a detected wait-for deadlock.")
        }
    }

    /**
     * Abort the iteration on a detected wait-for cycle (the cycle abort).
     * Records the cycle, logs the `Deadlock` event, strands the token,
     * wakes every actor parked on its gate (Waiting or Gated — their
     * parks return without a grant and every coordinator entry throws
     * PctDeadlockError from there, unwinding each actor through its
     * child entry so its future resolves and the runner's drain
     * completes), and throws out of the detector's own park path.
     * LOCK HELD on entry; the caller route
     * releases on the throw; never returns. The wave's wakes run under
     * the lock — safe: a woken thread only contends on the mutex until
     * the aborting region ends.
     */
    private func abortIterationLocked(me: Int64, cycle: Array<Int64>): Unit {
        aborted = true
        deadlocked = true
        deadlockCycle = Some(cycle)
        sched.recordProvenDeadlock(me)
        holder = -1
        let waved = ArrayList<Int64>()
        var i: Int64 = 0
        while (i < table.slotCount()) {
            if (i != me && (table.isWaiting(i) || table.isGated(i))) {
                waved.add(i)
            }
            i++
        }
        var w: Int64 = 0
        while (w < Int64(waved.size)) {
            wake(waved[w])
            w++
        }
        var cycleStr = "" // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        var c: Int64 = 0
        while (c < Int64(cycle.size)) {
            if (c > 0) {
                cycleStr += "->"
            }
            cycleStr += "${cycle[c]}"
            c++
        }
        throw PctDeadlockError("PCT deadlock: wait-for cycle ${cycleStr} " +
            "(actor ${me}'s park closed it); iteration aborted, every actor unwound.")
    }

    // Fair-mode yield decision core: gate the holder and pick the
    // longest-gated (oldest park) other gated actor — park order, not a
    // fixed preference, so >= 2 waiters cannot starve the parked producer
    // they all spin against. Like blocking (and unlike a preemption) it
    // consumes no PCP budget, because the holder gives up the token of
    // its own accord. LOCK HELD; returns the grant target (the caller
    // wakes it and parks outside the lock), or -1 when nobody can take
    // the token (keep running — the deadlock detector covers stuck
    // cases).
    private func fairYieldLocked(me: Int64): Int64 {
        table.markGated(me)
        let to = sched.fairYield(me)
        if (to < 0) {
            table.markRunning(me)
            return -1
        }
        transferLocked(to)
        return to
    }

    private func transferLocked(to: Int64): Unit {
        table.markRunning(to)
        holder = to
        sched.resetStarvation() // the new holder's grid-poll run starts fresh
    }

    // Wake a granted target: every park (registration, op-boundary switch
    // and post-block re-gate) sits on the actor's own gate, so the grant
    // is a plain open from Cangjie.
    private func wake(to: Int64): Unit {
        table.openGate(to)
    }
}
