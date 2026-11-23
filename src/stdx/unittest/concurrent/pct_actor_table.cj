/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.sync.Monitor
import std.collection.ArrayList

/**
 * The PCT actor table: the per-actor slot storage of one PCT iteration
 * (pct_coordinator.cj owns and drives it).
 *
 * Every actor — all dynamically registered through childEnter —
 * occupies one slot: a growable set of parallel arrays holding its
 * identity (thread id), gate, protocol state, priority rank, decision
 * counter, mediated wait registration (key + edge kind), future
 * identity, and the mediated-absorb marker.
 *
 * LOCK CONTRACT: this class is NOT thread-safe on its own. Every method
 * is called by the coordinator under its lock, with ONE exception —
 * `tidToActor`, whose lock-free snapshot protocol is documented on the
 * method. State transitions are semantic (`markWaiting`/`markRunning`/
 * ...): each performs the full consistent mutation, so the parallel
 * arrays can never disagree (e.g. `markRunning` clears the wait
 * registration; `markGated` does too, making "Gated ⇒ no wait
 * registration" hold by construction).
 *
 * The table stores; it decides nothing. Scheduling policy (RNG, PCP,
 * picks) lives in the coordinator/scheduler; protocol decisions live in
 * the coordinator.
 */

/**
 * Actor states (coordinator-owned; the single source of protocol truth).
 */
internal enum PctActorState <: Equatable<PctActorState> {
    | Unused
    | Gated // parked on its gate semaphore (registration, switch-out, post-block)
    | Running // token holder
    | Blocked // parked inside a sync primitive (its sync-wrap enter fired)
    | Waiting // mediated wait: parked on its gate inside the sync-wrap
    // ENTER (not inside a runtime primitive), keyed by the waited object
    // (waitKey); woken only by the key owner's completion flip
    | Finished

    public override operator func ==(other: PctActorState): Bool { // cjlint-ignore !G.OPR.01 parameterless enum: the language requires this manual == to satisfy Equatable<T>; match-based constructor comparison is the only possible implementation
        match ((this, other)) {
            case (Unused, Unused) => true
            case (Gated, Gated) => true
            case (Running, Running) => true
            case (Blocked, Blocked) => true
            case (Waiting, Waiting) => true
            case (Finished, Finished) => true
            case _ => false
        }
    }
}

/**
 * Park-until-grant gate: the actor-side half of every token hand-off. A
 * granted actor may still be returning through managed frames when the
 * grant fires, so `open` must be safe in either order (an open before the
 * park is simply consumed by the loop). Built on a real std.sync Monitor:
 * precompiled std code, so the parks never re-enter the PCT dispatch.
 */
private class PctGate {
    private let monitor = Monitor()
    private var opened = false

    /** Park the calling actor until a grant consumes the flag. The whole
     * gate protocol runs in a drain section (pct_engine_lock.cj): the
     * blocking wait must never hold the engine lock — the grantee's next
     * region would deadlock on a lock the parked actor still holds — and
     * the drain is owned HERE, not at each call site, so the invariant is
     * structural. The gate monitor is a leaf (nothing acquires the engine
     * lock while holding it), so the non-blocking parts are safe under
     * the engine lock on either side of the section. Must be called from
     * inside a region (every park site is). */
    public func park(): Unit {
        pctWithTemporarilyUnlocked { =>
            monitor.lock()
            while (!opened) {
                monitor.wait()
            }
            opened = false
            monitor.unlock()
        }
    }

    /** Grant one park: wake a parked actor or arm the next one. */
    public func openGate(): Unit {
        monitor.lock()
        opened = true
        monitor.notify()
        monitor.unlock()
    }
}

internal class PctActorTable {
    // cjthread id per actor (>= 1; 0 = not yet started), recorded at each
    // actor's child-entry registration on its own thread. The sync
    // dispatchers pass the calling thread's own id; every lookup that
    // MATTERS is for the calling thread's own entry (same-thread program
    // order), so plain array reads are safe. Growable: every actor
    // appends its slot at registration (all actors are dynamically
    // registered children); the arrays are rebuilt double-size under the
    // engine lock (pct_engine_lock.cj), and readers
    // snapshot the array reference before scanning (element identity —
    // gate objects, tids — is preserved across the copy).
    private var actorTids: Array<Int64>
    // Park-until-grant gates, one per actor: parked on by the actor
    // (registration, op-boundary switch-out, post-block re-gate) and opened
    // by every grant. The open-flag protocol is safe in either order
    // (grant-before-park is consumed by the loop). Growable, like actorTids.
    private var gates: Array<PctGate>
    private var state: Array<PctActorState>
    private var priority: Array<Int64> // 1 = highest; mutated by PCP/promote
    private var pollCount: Array<UInt64> // per-actor decision counter (replay key)
    // Per-slot stamp of the most recent park-into-Gated, from a monotone
    // counter: the fair-mode yield picks the longest-gated (oldest park)
    // peer. A fixed-preference pick — highest priority in PCT, lowest slot
    // in DPOR — lets >= 2 waiters spinning against a parked producer yield
    // to each other forever and starve it (the multi-waiter livelock);
    // park order reaches the producer first by construction.
    private var gateSeq: Array<UInt64>
    private var gateSeqCounter: UInt64 = 0u64
    // Mediated waits: what each Waiting actor is waiting on — the key it
    // parked under (a joined future, a condition, a wrapper's
    // mutex/semaphore, a virtual-sleep timer key); None otherwise.
    // The owner's completion (childExit, which runs after execute() set
    // the result and fired notifyAll) flips every Waiting actor with a
    // refEq-matching key to Gated BEFORE its own Done/Complete pick — one
    // atomic decision, so the joiner competes for the very next grant and
    // no runtime wake can race the schedule.
    private var waitKey: Array<?Object>
    // The edge semantics of each Waiting actor's park in the cycle
    // abort's wait-for graph (set with waitKey at park time, cleared
    // with it at the flip). The cycle detector follows these edges.
    private var waitEdge: Array<PctWaitEdgeKind>
    // Each dynamic child's future identity (recorded at registration; a
    // retained route with no producer — no future-identified child
    // registers today). The mediated-wait decision scans it: a waiter
    // whose future has a live registered child owner is mediated (the
    // owner's childExit is the guaranteed completion observer);
    // everything else (external owner, already-exited owner, timed
    // wait) keeps the runtime-park fallback.
    private var myFuture: Array<?Object>
    // The virtual-timer fired marker: set (under the engine lock)
    // when a PctClock timer fires this actor — flipping it out of its
    // timed Waiting park and granting it the token — and consumed by the
    // actor's own wake path (the timed wrapper/mediated loop reads it to
    // distinguish "woken because the deadline passed" from "woken by a
    // notify/completion flip").
    private var timerFired: Array<Bool>
    // Slots in use: every registered actor so far — the runner's initial
    // actors (spawned sequentially by the runner in actor order, so
    // initial actor i takes slot i), plus any child registering with a
    // future identity (a retained route; no producer today —
    // user-invoked spawns never register). All iteration bounds use
    // this, not actorCount.
    private var slots: Int64

    internal init() {
        gates = []
        actorTids = []
        state = []
        priority = []
        pollCount = []
        waitKey = []
        waitEdge = []
        myFuture = []
        timerFired = []
        gateSeq = []
        slots = 0
    }

    /** How many actor slots are in use (every registered actor so far). */
    internal func slotCount(): Int64 {
        return slots
    }

    /**
     * Grow the table to cover `slot` (called at registration; a replay may
     * re-bind a recorded slot below the current count, which never
     * shrinks). Rebuilds every array double-size; element identity (gate
     * objects, tids, priorities) is preserved: the arrays are copied, and
     * lock-free readers (tidToActor) hold snapshots. NOTE: `slots` is
     * published BEFORE the arrays are swapped, so a lock-free reader can
     * momentarily see the torn pair — tidToActor bounds its scan by the
     * snapshot's own length for exactly that reason.
     */
    internal func ensureSlot(slot: Int64): Unit {
        if (slot >= slots) {
            slots = slot + 1
        }
        let cap = Int64(state.size)
        if (slots <= cap) {
            return
        }
        var newCap = if (cap == 0) {
            Int64(1)
        } else {
            cap
        }
        while (newCap < slots) {
            newCap = newCap * 2
        }
        state = Array<PctActorState>(newCap, { i => if (i < cap) { state[i] } else { Unused } })
        actorTids = Array<Int64>(newCap, { i => if (i < cap) { actorTids[i] } else { 0 } })
        priority = Array<Int64>(newCap, { i => if (i < cap) { priority[i] } else { 0 } })
        pollCount = Array<UInt64>(newCap, { i => if (i < cap) { pollCount[i] } else { 0u64 } })
        waitKey = Array<?Object>(newCap, { i => if (i < cap) { waitKey[i] } else { None } })
        waitEdge = Array<PctWaitEdgeKind>(newCap, { i => if (i < cap) { waitEdge[i] } else { NoEdge } })
        myFuture = Array<?Object>(newCap, { i => if (i < cap) { myFuture[i] } else { None } })
        timerFired = Array<Bool>(newCap, { i => if (i < cap) { timerFired[i] } else { false } })
        gateSeq = Array<UInt64>(newCap, { i => if (i < cap) { gateSeq[i] } else { 0u64 } })
        gates = Array<PctGate>(newCap, { i => if (i < cap) { gates[i] } else { PctGate() } })
    }

    // ------------------------------------------------------------------
    // Identity.
    // ------------------------------------------------------------------

    // cjthread id -> actor index; 0 (unregistered) never matches a real
    // tid (ids are >= 1). LOCK-FREE (the one exception to the lock
    // contract): entries are written once by each actor on its own
    // thread, and every lookup that matters is the calling thread's own
    // entry (same-thread program order). The array reference is
    // snapshotted before scanning, and the scan is bounded by the
    // SNAPSHOT'S OWN LENGTH, never by `slots`: ensureSlot publishes the
    // new `slots` before swapping in the grown arrays, so a lock-free
    // reader can see the torn pair (new bound, old array) — indexing by
    // `slots` would go out of bounds on a table mid-grow (or still
    // empty, before the first registration). The snapshot's length is
    // always self-consistent; an entry beyond it can only be one this
    // reader registered itself (its own ensureSlot/setTid precede the
    // read in program order, so its entry is in the snapshot), and the
    // uninitialized tail entries (tid 0) never match a real tid.
    internal func tidToActor(tid: Int64): ?Int64 {
        let tids = actorTids
        let n = tids.size
        var i: Int64 = 0
        while (i < n) {
            if (tids[i] == tid) {
                return Some(i)
            }
            i++
        }
        return None
    }

    /** Record `slot`'s owning thread id (registration, on its own thread). */
    internal func setTid(slot: Int64, tid: Int64): Unit {
        actorTids[slot] = tid
    }

    /**
     * Claim `tid` for `slot` (registration, on the child's thread):
     * clears any pooled-cjthread predecessor's stale tid and reports
     * the first LIVE predecessor still holding the tid, if any — a
     * live actor can never share a tid with the registering child, so
     * the caller turns a hit into a protocol failure. Returns the live
     * predecessor's slot, or -1.
     */
    internal func claimTid(slot: Int64, tid: Int64): Int64 {
        var live: Int64 = -1
        var i: Int64 = 0
        while (i < slotCount()) {
            if (i != slot && tidOf(i) == tid) {
                if (!isFinished(i) && live < 0) {
                    live = i
                }
                clearTid(i)
            }
            i += 1
        }
        setTid(slot, tid)
        return live
    }

    /** Forget a slot's thread id (pooled-cjthread reuse cleanup). */
    internal func clearTid(slot: Int64): Unit {
        actorTids[slot] = 0
    }

    internal func tidOf(slot: Int64): Int64 {
        return actorTids[slot]
    }

    // ------------------------------------------------------------------
    // Protocol state: queries.
    // ------------------------------------------------------------------

    internal func stateOf(slot: Int64): PctActorState {
        return state[slot]
    }

    /** The stamp of the actor's most recent park-into-Gated (monotone;
     * smaller = gated longer). Read by the fair-mode yield's pick. */
    internal func gateSeqOf(slot: Int64): UInt64 {
        return gateSeq[slot]
    }

    internal func isGated(slot: Int64): Bool {
        return slot >= 0 && slot < slots && state[slot] == Gated
    }

    internal func isWaiting(slot: Int64): Bool {
        return slot >= 0 && slot < slots && state[slot] == Waiting
    }

    internal func isFinished(slot: Int64): Bool {
        return slot >= 0 && slot < slots && state[slot] == Finished
    }

    /** Any other actor parked on its gate (a fair-scheduling candidate)? */
    internal func hasGatedPeer(me: Int64): Bool {
        var i: Int64 = 0
        while (i < slots) {
            if (i != me && state[i] == Gated) {
                return true
            }
            i++
        }
        return false
    }

    /** The other actors parked on their gates (the obstruction-rescue
     * candidates at a starvation switch — the peers a rescue branch can
     * grant; mirrors hasGatedPeer's condition). */
    internal func gatedPeersOf(me: Int64): Array<Int64> {
        let out = ArrayList<Int64>()
        var i: Int64 = 0
        while (i < slots) {
            if (i != me && state[i] == Gated) {
                out.add(i)
            }
            i += 1
        }
        return out.toArray()
    }

    /** Any actor parked in a sync primitive or a mediated wait? (The
     * deadlock-recording condition when the token strands.) */
    internal func anyWaitingOrBlocked(): Bool {
        var i: Int64 = 0
        while (i < slots) {
            if (state[i] == Blocked || state[i] == Waiting) {
                return true
            }
            i++
        }
        return false
    }

    /** Every actor Finished? (The drain's completion condition.) */
    internal func allFinished(): Bool {
        var i: Int64 = 0
        while (i < slots) {
            if (state[i] != Finished) {
                return false
            }
            i++
        }
        return true
    }

    // ------------------------------------------------------------------
    // Protocol state: transitions (each is the full consistent mutation).
    // ------------------------------------------------------------------

    /** Park registration: the actor is gated, waiting on nothing. Also
     * the flip target of a notified waiter (whose registration the
     * transition clears). Stamps the gate-order sequence (the fair-mode
     * yield picks by it — see gateSeqOf). */
    internal func markGated(slot: Int64): Unit {
        state[slot] = Gated
        gateSeqCounter += 1u64
        gateSeq[slot] = gateSeqCounter
        waitKey[slot] = None
        waitEdge[slot] = NoEdge
    }

    /** A runtime-primitive park (its sync-wrap enter fired). */
    internal func markBlocked(slot: Int64): Unit {
        state[slot] = Blocked
    }

    /** Mediated wait: parked on its own gate, keyed by the waited
     * object, with the wait-for-graph edge semantics. */
    internal func markWaiting(slot: Int64, key: Object, edge: PctWaitEdgeKind): Unit {
        state[slot] = Waiting
        waitKey[slot] = Some(key)
        waitEdge[slot] = edge
    }

    /** Token grant / uncontended acquire: running again, the wait
     * registration (if any) consumed. */
    internal func markRunning(slot: Int64): Unit {
        state[slot] = Running
        waitKey[slot] = None
        waitEdge[slot] = NoEdge
    }

    /** Actor completion. */
    internal func markFinished(slot: Int64): Unit {
        state[slot] = Finished
    }

    /** The unique Running slot (the token holder), or -1 (quiescence /
     *  pre-release). The token protocol keeps at most one Running actor;
     *  the DPOR spawn-edge hook uses this to identify the spawner at a
     *  child's registration (the spawner really-parks on the registrar
     *  while holding the token, so its table state stays Running). */
    internal func runningSlot(): Int64 {
        var i: Int64 = 0
        while (i < slots) {
            if (state[i] == Running) {
                return i
            }
            i += 1
        }
        return -1
    }

    // ------------------------------------------------------------------
    // Mediated wait registration (queries for the wait-for graph).
    // ------------------------------------------------------------------

    internal func waitKeyOf(slot: Int64): ?Object {
        return waitKey[slot]
    }

    internal func waitEdgeOf(slot: Int64): PctWaitEdgeKind {
        return waitEdge[slot]
    }

    /**
     * Flip Waiting actors keyed on `key` (refEq) to Gated — up to `max`
     * (`notify` flips a single waiter; `unlock`/`release`/`notifyAll` flip
     * all): the key owner's completion (childExit, for futures) or release
     * (medRelease, for mutexes/semaphores/conditions) makes them eligible;
     * the very next pick sees them. Returns how many flipped.
     */
    internal func flipWaiting(key: Object, max!: Int64 = Int64.Max): Int64 {
        var flipped: Int64 = 0
        var i: Int64 = 0
        while (i < slots && flipped < max) {
            if (state[i] == Waiting) {
                if (let Some(k) <- waitKey[i] && refEq(k, key)) {
                    markGated(i)
                    flipped += 1
                }
            }
            i++
        }
        return flipped
    }

    // ------------------------------------------------------------------
    // Future ownership (recorded at child registration).
    // ------------------------------------------------------------------

    /** Record `slot`'s own future identity (its `ident` at registration). */
    internal func setMyFuture(slot: Int64, f: Object): Unit {
        myFuture[slot] = Some(f)
    }

    /**
     * The live registered child-owner slot of `f` (None = none). myFuture
     * is recorded at child registration and the child is running
     * (state != Finished) exactly while its future may still be
     * incomplete — an already-completed future's owner is Finished (or
     * mid-exit holding the token, which excludes a concurrent waiter), so
     * the scan is exact. Only children registered with a future identity
     * carry myFuture entries: runner-actor and external-thread owners
     * never mediate. Used by the mediated-join decision and as the
     * wait-for cycle abort's future edge target — a retained route with
     * no producer today (no future-identified child registers).
     */
    internal func liveChildOwner(f: Object): ?Int64 {
        var i: Int64 = 0
        while (i < slots) {
            if (state[i] != Finished) {
                if (let Some(mf) <- myFuture[i] && refEq(mf, f)) {
                    return Some(i)
                }
            }
            i++
        }
        return None
    }

    // ------------------------------------------------------------------
    // The virtual-timer fired marker (see the field comment; both sides
    // run under the engine lock).
    // ------------------------------------------------------------------
    internal func setTimerFired(slot: Int64, on: Bool): Unit {
        timerFired[slot] = on
    }

    internal func timerFiredOf(slot: Int64): Bool {
        return timerFired[slot]
    }

    // ------------------------------------------------------------------
    // Priorities (storage; the draw/promote policy stays with the
    // scheduler — these are the dense-rank primitives it drives).
    // ------------------------------------------------------------------

    internal func priorityOf(slot: Int64): Int64 {
        return priority[slot]
    }

    internal func setPriority(slot: Int64, p: Int64): Unit {
        priority[slot] = p
    }

    /** The highest priority rank among the other slots (0 when none). */
    internal func maxPriorityOtherThan(slot: Int64): Int64 {
        var maxPrio: Int64 = 0
        var i: Int64 = 0
        while (i < slots) {
            if (i != slot && priority[i] > maxPrio) {
                maxPrio = priority[i]
            }
            i++
        }
        return maxPrio
    }

    /** Assign `slot` the rank `rank`, shifting every priority >= rank up
     * by one (keeping the priority set dense, like promote does). */
    internal func insertPriorityAt(slot: Int64, rank: Int64): Unit {
        var i: Int64 = 0
        while (i < slots) {
            if (i != slot && priority[i] >= rank) {
                priority[i] = priority[i] + 1
            }
            i++
        }
        priority[slot] = rank
    }

    // ------------------------------------------------------------------
    // Decision counters (the replay key).
    // ------------------------------------------------------------------

    internal func bumpPoll(slot: Int64): Unit {
        pollCount[slot] += 1u64
    }

    internal func pollCountOf(slot: Int64): UInt64 {
        return pollCount[slot]
    }

    /** Reset at (re)registration: a fresh actor's decisions start at 0. */
    internal func resetPoll(slot: Int64): Unit {
        pollCount[slot] = 0u64
    }

    // ------------------------------------------------------------------
    // Gates: the actor-side half of every token hand-off.
    // ------------------------------------------------------------------

    /** Park the calling actor until a grant (see PctGate). */
    internal func park(slot: Int64): Unit {
        gates[slot].park()
    }

    /** Grant one park on `slot`'s gate (wake or arm). */
    internal func openGate(slot: Int64): Unit {
        gates[slot].openGate()
    }
}
