/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

/**
 * How a segment touched a synchronizing key (see
 * PctBaseScheduler.noteSync). The DPOR dependency oracle is kind-aware
 * for atomics: a shared key is a dependency unless BOTH sides touched
 * it with pure reads (`AtomicRead` notes commute — same-location reads
 * are independent; every other shared-key pair is dependent). Lock,
 * condition and future keys are always dependent in both directions.
 * The race reporter derives release→acquire happens-before edges from
 * the kinds: a segment noting `Release` of a key happens-before a
 * later-closing segment of another actor noting `Acquire` of the same
 * key. Atomics carry no edge (their interleaving is the DPOR oracle's
 * business, not the reporter's — no read-from relation is derivable
 * from key identities alone).
 */
internal enum PctSyncNoteKind <: Equatable<PctSyncNoteKind> {
    | Acquire // an acquire attempt / completed acquire / condition wait / mediated join
    | Release // a release / unlock / notify / condition-wait's lock release / child completion
    | AtomicRead  // an atomic read (a load; a FAILED compare-and-swap)
    | AtomicWrite // an atomic write (a store, swap or RMW; a SUCCESSFUL compare-and-swap)

    public override operator func ==(other: PctSyncNoteKind): Bool { // cjlint-ignore !G.OPR.01 parameterless enum: the language requires this manual == to satisfy Equatable<T>; match-based constructor comparison is the only possible implementation
        match ((this, other)) {
            case (Acquire, Acquire) => true
            case (Release, Release) => true
            case (AtomicRead, AtomicRead) => true
            case (AtomicWrite, AtomicWrite) => true
            case _ => false
        }
    }
}

/**
 * The verdict of the starvation recovery point
 * (PctBaseScheduler.noteGridContinue): `RunOn` — the run continues (streak
 * below the threshold or no gated peer to rescue); `YieldNow` — the
 * policy is YieldFairly and this iteration switches to fair scheduling,
 * the caller's response is the voluntary yield; `Obstruct` — the policy
 * is ThrowObstruction, the caller unwinds out of the engine region and
 * throws the carried exception so it unwinds the obstructed operation
 * (see ObstructionDetectedException).
 */
internal enum GridWallVerdict {
    | RunOn
    | YieldNow
    | Obstruct(ObstructionDetectedException)
}

/**
 * The abstract scheduling policy of one iteration (pct_coordinator.cj owns
 * and drives it): the shared decision-record machinery — the schedule log
 * with its replay-vs-record branching, the virtual clock, the
 * starvation/fair-mode recovery, and the transfer-decision templates.
 *
 * The transfer methods are TEMPLATES: the replay consumption, the
 * grant-target validation, the divergence flag, and the event recording
 * are policy-independent and live here; each fresh PICK is a hook
 * (`pick*` below) that a concrete policy overrides. The default hook
 * bodies are the PCT picks (only the seeded RNG machinery is
 * PctScheduler's own). DporScheduler (dpor_scheduler.cj) overrides the
 * picks with guide-driven decisions.
 *
 * Policy hooks the coordinator drives besides the picks:
 *  - `onDecisionPoint(holder)` — fired at the head of every transfer
 *    decision; PCT runs its priority-change-point machinery there.
 *  - `onDecisionEnter(me, kind, fromGrid)` — fired at the head of every
 *    decision made ON an actor's thread (op boundaries, grid points,
 *    parks, releases, exits, yields); DPOR drains its mtrace segment and
 *    logs the decision there. PCT does nothing.
 *  - `noteSync(me, key, kind)` — fired by the coordinator at every
 *    synchronizing event it mediates (a grid dispatch's atomic identity,
 *    a contended acquire's key, a condition's keys, a release's key, a
 *    completing child's future identity); DPOR attaches the key to the
 *    actor's closing segment. PCT does nothing.
 *  - `childRegistered(child, spawner)` — fired at a child actor's
 *    registration; DPOR records the spawn happens-before edge. PCT does
 *    nothing.
 *
 * Everything is a pure function of the actor table's state plus the
 * policy's own decision state — no parks, no wakes, no token bookkeeping
 * (those are the coordinator's protocol).
 *
 * LOCK CONTRACT: this class is NOT thread-safe on its own. Every method
 * is called by the coordinator under its lock.
 */
internal abstract class PctBaseScheduler {
    protected let table: PctActorTable
    // The recorded event stream + replay state (see PctScheduleLog).
    protected let log = PctScheduleLog()
    // The virtual clock (pct_clock.cj): the logical time and the armed
    // virtual timers; fires only at quiescence (see fireTimer).
    protected let clock = PctClock()

    // Fair-mode anti-starvation (shared by every policy: a serializing
    // scheduler can livelock on an operation that waits for a frozen
    // peer; the recovery is either the voluntary-yield fair mode or the
    // per-op bounded wait — see ObstructionPolicy). See PctScheduler's
    // class doc for the mechanism.
    protected let starvationThreshold: UInt64
    // What happens at the starvation recovery point. PCT schedulers are
    // always YieldFairly (the default below — the liveness mechanism);
    // DPOR schedulers take it from DporWindowConfig (default
    // ThrowObstruction — see ObstructionDetectedException).
    protected let obstructionPolicy: ObstructionPolicy
    protected var starvationPolls: UInt64 = 0
    protected var fairMode: Bool = false
    private var starvationSwitches: UInt64 = 0

    // Voluntary-switch bound (PctWindowConfig.switchBound): the maximum
    // number of voluntary op-boundary/grid preemptions per schedule, or
    // -1 for unbounded. Counted by the internal opBoundarySwitch entry
    // (both record and replay, so the count is schedule-stable);
    // enforced only by the default (PCT) pick policy — DPOR's guided
    // grants are bounded plan-side by the explorer instead. Forced
    // transfers (park/wait/exit handoffs) and fair-mode yields are never
    // counted: they are required for liveness, not exploratory switches.
    protected let switchBound: Int64
    private var voluntarySwitches: UInt64 = 0

    // Decision accounting (reported on the schedule).
    private var gridPoints: UInt64 = 0 // grid dispatches reached
    private var totalPolls: UInt64 = 0

    protected init(starvationThreshold!: UInt64, table!: PctActorTable, switchBound!: Int64 = -1,
        obstructionPolicy!: ObstructionPolicy = YieldFairly) {
        this.starvationThreshold = starvationThreshold
        this.obstructionPolicy = obstructionPolicy
        this.switchBound = switchBound
        this.table = table
    }

    // ------------------------------------------------------------------
    // Policy hooks.
    // ------------------------------------------------------------------

    /**
     * The head of every transfer decision: policy bookkeeping before the
     * replay-or-fresh branch. PCT: the priority-change-point machinery
     * (the RNG draw in record mode, the recorded-event consumption in
     * replay mode). Default: nothing.
     */
    protected open func onDecisionPoint(holder: Int64): Unit {}

    /**
     * The head of a decision made on an actor's own thread: `me`'s
     * segment is closing here (its mtrace events are drainable on this
     * thread) and the decision outcome follows. PCT: nothing. DPOR: the
     * segment drain + the decision log. `kind` is the event kind the
     * decision will record (Switch at op boundaries and grid points —
     * grid points carry the closing segment's atomic key through
     * noteSync); `fromGrid` distinguishes grid polls from op boundaries.
     */
    protected open func onDecisionEnter(me: Int64, kind: PctEventKind, fromGrid: Bool): Unit {}

    /**
     * A synchronizing event the coordinator mediates for `me`: the key
     * the event synchronizes on (the atomic object of a grid dispatch,
     * the mutex/semaphore of a contended acquire or a release, the
     * condition (and lock) of a condition wait, the future of a mediated
     * join or a completing child), and HOW the segment touched it (see
     * [[PctSyncNoteKind]]). Called BEFORE the decision the event
     * terminates in, under the engine lock. PCT: nothing. DPOR:
     * attaches the note to `me`'s closing segment — the key set is the
     * sync partial order's edge set (dependency oracle), the kinds feed
     * the race reporter's release→acquire happens-before edges. (The
     * internal entry routes through the overridable `onSyncKey` hook —
     * `internal` members cannot be `open` in Cangjie.)
     */
    internal func noteSync(me: Int64, key: Object, kind: PctSyncNoteKind): Unit {
        onSyncKey(me, key, kind)
    }

    protected open func onSyncKey(me: Int64, key: Object, kind: PctSyncNoteKind): Unit {}

    /**
     * A child actor registered (its slot claimed, gated at the
     * registration park); `spawner` is the current token holder (-1 for
     * the runner's initial actors — no actor's recorded accesses precede
     * them). Called under the engine lock, BEFORE the registration
     * park. PCT: nothing. DPOR: records the spawn happens-before edge —
     * the spawner's in-progress segment (the one containing the spawn
     * site) into the child's first segment. (Routes through the
     * overridable `onChildRegistered` hook, noteSync-style.)
     */
    internal func childRegistered(child: Int64, spawner: Int64): Unit {
        onChildRegistered(child, spawner)
    }

    protected open func onChildRegistered(child: Int64, spawner: Int64): Unit {}

    /** The iteration's first grant: the highest-priority gated actor. */
    protected open func pickInitial(): Int64 {
        return pickNextGated()
    }

    /**
     * An op-boundary (or grid-point) switch decision: the default keeps
     * the holder running unless a strictly higher-priority gated actor
     * preempts (PCT). A configured switch bound (>= 0) caps the number
     * of such voluntary preemptions per schedule: once spent, the holder
     * always keeps the token here (forced transfers and fair-mode yields
     * still move it — liveness is unaffected). The count is a
     * deterministic function of the decision sequence, so record and
     * replay agree; replay mode never consults this hook anyway (it
     * consumes the recorded event directly).
     */
    protected open func pickOpBoundary(me: Int64): Int64 {
        if (switchBound >= 0 && voluntarySwitches >= UInt64(switchBound)) {
            return -1
        }
        return pickHigherPriorityGated(me)
    }

    /**
     * A token-release decision (a blocking park, an unlock/release/
     * notify yield, an exit): the default grants the highest-priority
     * gated actor — the releaser itself is Gated at this point and
     * competes (PCT).
     */
    protected open func pickTransferAny(me: Int64, kind: PctEventKind): Int64 {
        return pickNextGated()
    }

    /** A fair-mode voluntary yield: the longest-gated (oldest park) actor
     * other than me — NOT a priority or slot-order pick. A fixed-
     * preference pick lets >= 2 waiters spinning against a parked
     * producer (the obstruction-freedom violation fair mode exists to
     * rescue) yield to each other forever and starve it: the producer
     * gated before any waiter's first yield, so park order reaches it
     * first by construction. */
    protected open func pickFairYield(me: Int64): Int64 {
        return pickOldestGatedOther(me)
    }

    /**
     * A spawn registration's priority rank: the default is PCT's seeded
     * draw in [1, max+1] (the rank is recorded in the Spawn event and
     * replay applies it — the base's applySpawnRank performs the
     * insertion).
     */
    protected open func drawSpawnRank(slot: Int64): Int64 {
        // Deterministic default (DPOR): append at the bottom priority.
        return table.maxPriorityOtherThan(slot) + 1
    }

    /** Deadlock recovery pick (external revival; unsound schedules). */
    protected open func pickRevival(): Int64 {
        return pickNextGated()
    }

    /** The drain pick (drainActors' stranded-token push): a pure
     * function of the table, never logged (record/replay must agree
     * without an event). Default: the highest-priority gated actor.
     * (The internal entry routes through the overridable `pickDrain`
     * hook — `internal` members cannot be `open` in Cangjie.) */
    internal func drainPick(): Int64 {
        return pickDrain()
    }

    protected open func pickDrain(): Int64 {
        return pickNextGated()
    }

    // ------------------------------------------------------------------
    // Decision accounting.
    // ------------------------------------------------------------------

    /** One more decision at an actor's op boundary. */
    internal func bumpTotalPolls(): Unit {
        totalPolls += 1u64
    }

    /** One more grid dispatch reached (a --cj-pct binary's fine grid). */
    internal func noteGridPoint(): Unit {
        gridPoints += 1u64
    }

    internal func totalPollCount(): UInt64 {
        return totalPolls
    }

    internal func gridPointCount(): UInt64 {
        return gridPoints
    }

    internal func starvationSwitchCount(): UInt64 {
        return starvationSwitches
    }

    // ------------------------------------------------------------------
    // Starvation recovery (fair mode).
    // ------------------------------------------------------------------

    /** Is this iteration in fair mode (grid points are yields)? */
    internal func isFairMode(): Bool {
        return fairMode
    }

    /**
     * Obstruction detected at the starvation recovery point (the
     * ThrowObstruction branch): the scheduler is about to throw. Default:
     * nothing. The DPOR scheduler records the event (the completed
     * decision whose keep triggered the streak — the position a rescue
     * branch replaces with a grant — and the gated rescue candidates)
     * so the driver can push the peer-grant children (the throw marks
     * the dead-end branch; the planned grants model the
     * wall-resolved completions — a peer on another core making the
     * spinner's wait succeed — that neither the throw nor the race
     * machinery can reach). Called before the exception is built.
     */
    protected open func onObstructionDetected(me: Int64, gatedPeers: Array<Int64>): Unit {}

    /**
     * A fast-mode grid continue by the holder (no token transfer): count
     * the consecutive run and, when it reaches the threshold with a gated
     * peer to rescue, apply the obstruction policy — YieldFairly switches
     * this iteration to fair scheduling (the caller's response to
     * `YieldNow` is the voluntary yield), ThrowObstruction hands back the
     * exception the caller must throw (it is inside an engine region —
     * the throw happens after its release, so the actor's next
     * coordinator entry is safe).
     *
     * The throw branch resets the streak: there is no token transfer to
     * reset it (transferLocked does that on yields), and without the
     * reset the actor's very next scheduling check would re-trigger at
     * the spent counter — every subsequent operation would throw after a
     * single check. With the reset each operation gets its own full
     * bounded wait. The fair branch needs no reset: the yield's
     * transfer resets the streak there.
     */
    internal func noteGridContinue(me: Int64): GridWallVerdict {
        starvationPolls += 1u64
        if (starvationPolls >= starvationThreshold) {
            if (!table.hasGatedPeer(me)) {
                return RunOn
            }
            if (obstructionPolicy == ThrowObstruction) {
                // Guide-uniform: no token transfer, no schedule event —
                // the throw is a deterministic function of the streak
                // counter and the gate state, so replay re-derives it at
                // the same decision. The hook lets the DPOR scheduler
                // record the position + rescue candidates before the
                // unwind (the driver pushes the peer-grant children).
                let polls = starvationPolls
                starvationPolls = 0u64
                onObstructionDetected(me, table.gatedPeersOf(me))
                println("[PCT] actor ${me}: ${starvationThreshold} consecutive grid checks " +
                    "without an operation boundary; obstruction detected — throwing " +
                    "ObstructionDetectedException (the operation waits for a frozen peer " +
                    "the guide never runs; it gives up after the bounded wait instead of " +
                    "fair-yielding)")
                return Obstruct(ObstructionDetectedException(
                    actorId: me, polls: polls, threshold: starvationThreshold))
            }
            fairMode = true
            starvationSwitches += 1u64
            println("[PCT] actor ${me}: ${starvationThreshold} consecutive grid checks " +
                "without an operation boundary; switching to fair scheduling " +
                "(the operation likely waits for a frozen peer — obstruction freedom " +
                "violated, e.g. a spin on an in-flight producer)")
            return YieldNow
        }
        return RunOn
    }

    /** A token transfer or a deadlock record ends the grid-poll run. */
    internal func resetStarvation(): Unit {
        starvationPolls = 0u64
    }

    // ------------------------------------------------------------------
    // Replay helpers.
    // ------------------------------------------------------------------

    // A clean replay consumes recorded events; once diverged (or in
    // record mode) every decision runs fresh and its outcome is logged.
    protected func inCleanReplay(): Bool {
        return log.isReplayMode() && !log.isDiverged()
    }

    protected func isFreshDecision(): Bool {
        return !log.isReplayMode() || log.isDiverged()
    }

    protected func diverge(): Unit {
        log.markDiverged()
    }

    // Validate a consumed replay grant against the live gated set. Most
    // decisions never record to = -1 (a recorded -1 there is a
    // divergence); the park/exit decisions legitimately record it (the
    // token stranded), so only a real target is validated.
    protected func validatedGrant(to: Int64, minusOneOk!: Bool): Int64 {
        if (to != -1 || !minusOneOk) {
            if (!table.isGated(to)) {
                diverge()
                return -1
            }
        }
        return to
    }

    // ------------------------------------------------------------------
    // Transfer decisions (the coordinator's request API). Everything
    // replay-related lives here: the strict/lenient matching, the
    // grant-target validation, the divergence flag, and the event
    // recording. The coordinator executes the token protocol on the
    // returned decision and stays blind to whether it came from a
    // loaded replay, a policy pick, or a DPOR guide.
    // ------------------------------------------------------------------

    /**
     * The iteration's first grant (the runner's releaseFirst): the token
     * starts stranded and moves to the pick's target. Returns the grant
     * target, or -1 when nobody is gated yet (nothing logged). Strict
     * replay match on the initial `Switch(from = -1)`.
     */
    internal func initialSwitch(): Int64 {
        onDecisionEnter(Int64(-1), Switch, false)
        var to: Int64 = -1
        if (inCleanReplay()) {
            if (let Some(ev) <- log.tryConsume(Switch, from: Some(Int64(-1)))) {
                to = validatedGrant(Int64(ev.to), minusOneOk: false)
            } else {
                diverge()
            }
        }
        if (isFreshDecision()) {
            to = pickInitial()
        }
        if (to >= 0) {
            log.logEvent(Switch, -1, to, 0)
        }
        return to
    }

    /**
     * An op-boundary or grid-point switch decision (the coordinator's
     * poll): may move the token to another gated actor. Returns the
     * target, or -1 when the holder keeps running (the common case).
     * The lenient replay match keys on the actor's decision counter (a
     * non-matching peeked event belongs to a later decision); a diverged
     * replay keeps the holder running — no fresh pick on this path, the
     * schedule is flagged at the end.
     */
    internal func opBoundarySwitch(me: Int64, fromGrid!: Bool = false): Int64 {
        onDecisionEnter(me, Switch, fromGrid)
        onDecisionPoint(me)
        var to: Int64 = -1
        if (log.isReplayMode()) {
            if (!log.isDiverged()) {
                if (let Some(ev) <- log.tryConsume(Switch, from: Some(me), step: Some(table.pollCountOf(me)))) {
                    to = validatedGrant(Int64(ev.to), minusOneOk: false)
                }
            }
        } else {
            to = pickOpBoundary(me)
        }
        if (to >= 0) {
            voluntarySwitches += 1u64
            log.logEvent(Switch, me, to, table.pollCountOf(me))
        }
        return to
    }

    /**
     * A fair-mode voluntary yield (the coordinator's yieldToken): the
     * holder parks and the token moves to another gated actor. Returns
     * the target, or -1 when nobody is yieldable (the caller keeps
     * running; nothing logged). Lenient and keyed on the decision
     * counter like the op-boundary switch.
     */
    internal func fairYield(me: Int64): Int64 {
        onDecisionEnter(me, FairYield, false)
        resetStarvation()
        var to: Int64 = -1
        if (inCleanReplay()) {
            if (let Some(ev) <- log.tryConsume(FairYield, from: Some(me), step: Some(table.pollCountOf(me)))) {
                to = validatedGrant(Int64(ev.to), minusOneOk: false)
            }
        }
        if (isFreshDecision()) {
            to = pickFairYield(me)
        }
        if (to >= 0) {
            log.logEvent(FairYield, me, to, table.pollCountOf(me))
        }
        return to
    }

    /**
     * A blocking park transfer (the coordinator's Block/Wait decisions):
     * the token moves to ANY gated actor, a virtual timer fires at the
     * quiescence this park creates (the waiter of the earliest live
     * timer is granted directly — the Timer event precedes this park's
     * own event in the stream), or the token strands (the Deadlock
     * marker is recorded — recovery is a later external wake). Strict
     * replay match accepting the recorded Deadlock alternative; a
     * replayed Deadlock strands exactly like a fresh nobody-gated pick,
     * re-recording the marker.
     */
    internal func blockingTransfer(me: Int64, kind: PctEventKind): PctTransfer {
        onDecisionEnter(me, kind, false)
        onDecisionPoint(me)
        var to: Int64 = -1
        if (inCleanReplay()) {
            // A recorded fire at this strand point: its Timer event sits
            // at the cursor, immediately before this park's own event
            // (the flip must happen before the event's grant target is
            // validated as Gated).
            if (log.peekIsTimer()) {
                if (fireTimer() < 0) {
                    diverge() // the code's timeouts diverged from the record
                }
            }
            if (let Some(ev) <- log.tryConsume(kind, altKind: Some(Deadlock), from: Some(me))) {
                if (ev.kind == Deadlock) {
                    () // replay the deadlock: no transfer, the strand tail re-records it
                } else {
                    to = validatedGrant(Int64(ev.to), minusOneOk: true)
                }
            } else {
                diverge()
            }
        }
        if (isFreshDecision()) {
            to = pickTransferAny(me, kind) // blocking releases the token to ANYONE gated
            if (to < 0) {
                to = fireTimer() // quiescence: the earliest live virtual timer fires
            }
        }
        if (to >= 0) {
            log.logEvent(kind, me, to, table.pollCountOf(me))
            return Grant(to)
        }
        resetStarvation()
        log.logEvent(Deadlock, me, -1, table.pollCountOf(me))
        return Strand(true)
    }

    /**
     * An unlock/release/notify yield (the mediated acquire and
     * condition-wait protocols): the gated releaser competes with the
     * flipped waiters for the token. Returns the grant
     * target (may be `me` — the releaser wins its own yield), or Silent
     * when the fresh pick finds nobody (unreachable in practice: the
     * flipped waiters are gated). Strict replay match on the event kind —
     * a silent unlock never reaches a decision (the coordinator's flip
     * pre-check), so the match cannot diverge a faithful replay.
     */
    internal func unlockTransfer(me: Int64, kind: PctEventKind): PctTransfer {
        onDecisionEnter(me, kind, false)
        onDecisionPoint(me)
        var to: Int64 = -1
        if (inCleanReplay()) {
            if (let Some(ev) <- log.tryConsume(kind, from: Some(me))) {
                to = validatedGrant(Int64(ev.to), minusOneOk: false)
            } else {
                diverge()
            }
        }
        if (isFreshDecision()) {
            to = pickTransferAny(me, kind) // the releaser (now Gated) competes with the flipped waiters
            if (to < 0) {
                // Unreachable in practice (the flipped waiters are Gated);
                // keep the protocol total by attempting a virtual fire
                // before falling silent.
                to = fireTimer()
            }
        }
        if (to < 0) {
            return Silent
        }
        log.logEvent(kind, me, to, table.pollCountOf(me))
        return Grant(to)
    }

    /**
     * An actor's exit transfer (the shared Done/childExit tail): the
     * token moves to any gated actor, or the exit strands (the exitKind
     * event with to = -1 is recorded; a Deadlock follows it iff blocked
     * or waiting actors remained — the flag on Strand). Strict replay
     * match: Done/Complete per the live exit kind (a kind mismatch is a
     * real divergence — the joiner flip is a deterministic function of
     * the schedule), to = -1 is a legitimate recorded outcome, and the
     * trailing recorded Deadlock (a strand with waiters) is consumed
     * leniently to keep the cursor aligned.
     */
    internal func exitTransfer(me: Int64, exitKind: PctEventKind): PctTransfer {
        onDecisionEnter(me, exitKind, false)
        onDecisionPoint(me)
        var to: Int64 = -1
        if (inCleanReplay()) {
            // A recorded virtual fire at this exit's strand point (the
            // Timer event precedes the exit event; see blockingTransfer).
            if (log.peekIsTimer() && fireTimer() < 0) {
                diverge()
            }
            if (let Some(ev) <- log.tryConsume(Done, altKind: Some(Complete), from: Some(me))) {
                if (ev.kind != exitKind) {
                    diverge()
                } else {
                    to = validatedGrant(Int64(ev.to), minusOneOk: true)
                }
                // The trailing recorded Deadlock (a strand with waiters) is
                // consumed leniently to keep the cursor aligned — only a
                // faithful strand consumes it: the kind mismatch above, or
                // a failed grant validation, diverges, and the flag gates
                // this out.
                if (to == -1 && !log.isDiverged()) {
                    let _ = log.tryConsume(Deadlock, from: Some(me))
                }
            } else {
                diverge()
            }
        }
        if (isFreshDecision()) {
            to = pickTransferAny(me, exitKind)
            if (to < 0) {
                // Quiescence at an exit: the earliest live virtual timer
                // fires (the exit event records it as the grant target);
                // only a fireless quiescence strands.
                to = fireTimer()
            }
        }
        if (to >= 0) {
            log.logEvent(exitKind, me, to, table.pollCountOf(me))
            return Grant(to)
        }
        log.logEvent(exitKind, me, -1, table.pollCountOf(me))
        if (table.anyWaitingOrBlocked()) {
            log.logEvent(Deadlock, me, -1, table.pollCountOf(me))
            return Strand(true)
        }
        return Strand(false)
    }

    /**
     * Phase 1 of a spawn registration (childEnter): the slot the child
     * binds, and — in a faithful replay — the priority rank recorded in
     * its Spawn event. The consumed event is re-recorded verbatim (the
     * recorded spawner's identity included) so the replay's own schedule
     * equals the loaded one; a missing event diverges and the
     * registration continues in record mode (a fresh slot; the rank is
     * drawn at apply time).
     */
    internal func spawnDecision(): PctSpawnDecision {
        if (inCleanReplay()) {
            if (let Some(ev) <- log.tryConsume(Spawn)) {
                log.logEvent(Spawn, Int64(ev.from), Int64(ev.to), ev.step)
                return PctSpawnDecision(slot: Int64(ev.to), rank: Int64(ev.step))
            }
            diverge()
        }
        return PctSpawnDecision(slot: table.slotCount(), rank: Int64(-1))
    }

    /**
     * Phase 2 of a spawn registration (after the coordinator registered
     * the slot in the table): apply the rank — the replayed one recorded
     * in the Spawn event, or the policy's draw (the seeded pick in PCT,
     * the deterministic append in DPOR), which is what gets logged in
     * record mode. `spawner` is the live token holder the fresh event is
     * attributed to.
     */
    internal func applySpawnRank(d: PctSpawnDecision, spawner: Int64): Unit {
        if (d.rank >= 0) {
            table.insertPriorityAt(d.slot, d.rank)
            return
        }
        let rank = drawSpawnRank(d.slot)
        table.insertPriorityAt(d.slot, rank)
        log.logEvent(Spawn, spawner, d.slot, UInt64(rank))
    }

    /**
     * Deadlock recovery by a timed waiter's own expiry (onSyncExit): the
     * externally-woken actor claims the stranded token. The Resume event
     * is recorded; a clean replay diverges here (a Resume-free schedule
     * must not deadlock — wall-clock recovery is not replayable).
     */
    internal func recordResumeClaim(me: Int64): Unit {
        if (inCleanReplay()) {
            diverge() // a Resume-free schedule must not deadlock
        }
        log.logEvent(Resume, me, -1, table.pollCountOf(me))
    }

    /**
     * Deadlock recovery by an external releaser (medRelease's non-actor
     * path): pick a gated actor, hand it the stranded token, and record
     * the Resume. Returns the revived actor, or -1 when nobody is gated.
     */
    internal func externalRevival(): Int64 {
        let to = pickRevival()
        if (to >= 0) {
            log.logEvent(Resume, to, -1, table.pollCountOf(to))
        }
        return to
    }

    /**
     * A proven wait-for cycle (the cycle abort): record the Deadlock
     * marker. Deadlocked schedules are rejected at replay load, so there
     * is no replay path here.
     */
    internal func recordProvenDeadlock(me: Int64): Unit {
        log.logEvent(Deadlock, me, -1, table.pollCountOf(me))
        resetStarvation()
    }

    /**
     * Arm a virtual timer for a finite wait: the caller (the coordinator's
     * timed mediated paths — a timed condition wait, a timed future join,
     * a virtual sleep) is parked `Waiting` on `key`; the deadline is fixed
     * at the wait's entry (a barging re-wait never re-arms, so it cannot
     * extend). `nanos` is the wait's budget in logical nanoseconds
     * (Int64.Max = untimed, never armed).
     */
    internal func armTimer(me: Int64, key: Object, nanos: Int64): Unit {
        if (nanos == Int64.Max) {
            return
        }
        clock.arm(me, key, nanos)
    }

    /**
     * The armed-timer list's high-water mark for this window (a
     * diagnostic carried into the recorded schedule): bounded by the
     * waiter count after the clock's arm-time purge, unbounded without
     * it. LOCK HELD (like every clock access).
     */
    internal func timersHighWater(): Int64 {
        return clock.armedHighWater()
    }

    /**
     * The quiescence fire decision, consulted by the strand paths of the
     * transfer decisions before stranding: when a virtual timer is live,
     * advance the clock to its deadline and fire it — the waiter is
     * flipped out of its timed `Waiting` park to `Gated` (wait key
     * cleared, wait-for edge dropped with it), marked timer-fired, the
     * `Timer` event recorded, and the fired actor returned as a direct
     * grant target (the strand-recovery precedent — the fired waiter is
     * the one new runnable actor). A clean replay consumed its recorded
     * counterpart first (kind + from; the earliest-live pick is
     * deterministic, so a faithful replay finds the same entry); a
     * mismatch diverges and the fire proceeds fresh, exactly like any
     * other diverged decision. Returns -1 when no live timer exists
     * (the caller strands). No RNG draws, so replays cannot desync.
     * Single earliest deadline, ties by lowest slot. LOCK HELD.
     */
    internal func fireTimer(): Int64 {
        let e = clock.earliestValid(table) ?? return -1
        if (inCleanReplay()) {
            if (log.tryConsume(Timer, from: Some(e.actor)).isNone()) {
                diverge()
            }
        }
        clock.take(e)
        clock.advanceTo(e.deadline)
        table.markGated(e.actor) // Waiting -> Gated; the grant below marks Running
        table.setTimerFired(e.actor, true)
        log.logEvent(Timer, e.actor, -1, UInt64(e.deadline))
        return e.actor
    }

    /**
     * Load a recorded schedule for replay (see PctScheduleLog). Returns
     * 0 on success, -1 empty, -2 containing Resume events, -3 marked
     * deadlocked, -4 marked diverged, -5 an actor-count mismatch with
     * `expectedActorCount`, -6 an event slot outside the scenario's
     * actor table. Call before spawning any thread.
     */
    internal func loadReplay(schedule: PCTSchedule, expectedActorCount: Int64): Int32 {
        return log.loadForReplay(schedule, expectedActorCount)
    }

    /** The reported schedule's event payload (the coordinator's buildSchedule). */
    internal func scheduleEventsSnapshot(): Array<PctEvent> {
        return log.eventsSnapshot()
    }

    /** The reported schedule's divergence flag (the coordinator's buildSchedule). */
    internal func scheduleDiverged(): Bool {
        return log.isDiverged()
    }

    // ------------------------------------------------------------------
    // Grant picks (pure functions of the table's gated set + priorities;
    // shared building blocks for the policy hooks).
    // ------------------------------------------------------------------

    /** Highest-priority `Gated` actor (block/done/release picks). */
    protected func pickNextGated(): Int64 {
        var best: Int64 = -1
        var bestPrio: Int64 = Int64.Max // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        var i: Int64 = 0
        while (i < table.slotCount()) {
            if (table.isGated(i)) {
                if (table.priorityOf(i) < bestPrio) {
                    bestPrio = table.priorityOf(i)
                    best = i
                }
            }
            i++
        }
        return best
    }

    /** ... iff strictly higher priority than `me` (op-boundary picks). */
    protected func pickHigherPriorityGated(me: Int64): Int64 {
        let myPrio = table.priorityOf(me)
        var best: Int64 = -1
        var bestPrio: Int64 = myPrio // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        var i: Int64 = 0
        while (i < table.slotCount()) {
            if (i != me && table.isGated(i)) {
                if (table.priorityOf(i) < bestPrio) {
                    bestPrio = table.priorityOf(i)
                    best = i
                }
            }
            i++
        }
        return best
    }

    /** Longest-gated (oldest park) `Gated` actor other than `me`
     * (fair-mode yields). Gate order is the monotone stamp of each
     * park-into-Gated — see PctActorTable.gateSeqOf. */
    protected func pickOldestGatedOther(me: Int64): Int64 {
        var best: Int64 = -1
        var bestSeq: UInt64 = UInt64.Max // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        var i: Int64 = 0
        while (i < table.slotCount()) {
            if (i != me && table.isGated(i)) {
                if (table.gateSeqOf(i) < bestSeq) {
                    bestSeq = table.gateSeqOf(i)
                    best = i
                }
            }
            i++
        }
        return best
    }
}
