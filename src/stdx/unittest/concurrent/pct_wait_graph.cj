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
 * The wait-for graph of one PCT iteration
 * (pct_coordinator.cj owns and drives it) — the deadlock DETECTION half
 * of the cycle abort only. The abort itself (waving the parked actors,
 * stranding the token, throwing the unwind) is the coordinator's
 * protocol action.
 *
 * The graph: an edge X -> Y means "Y must act (release the key / complete
 * the future) before X can proceed" — a necessary condition, which is
 * what makes a cycle a proof. Edges come from parked waiters (the actor
 * table's wait registration: key + edge kind, recorded at park time)
 * pointing at tracked holders (this component's holderKeys/holderEntries,
 * maintained by the acquire/release paths) or at a joined future's owner
 * child. The walk only continues through Waiting actors: a Gated/Running
 * target will act (no deadlock through it) and a runtime-parked (timed)
 * target returns on its own timeout. Every tracked holder genuinely
 * acquired through the coordinator and has not released since (acquire
 * tracking is a subset of reality: tryLock/timed successes are
 * invisible), so edges are never spurious — limitations (rogue non-actor
 * unlocks aside) are false negatives only.
 *
 * LOCK CONTRACT: this class is NOT thread-safe on its own. Every method
 * is called by the coordinator under its lock.
 */

/**
 * The edge semantics of a parked actor's wait, recorded at park time and
 * consulted by the cycle detector.
 *
 *  - `NoEdge`: the wait's progress is not tied to any tracked holder (a
 *    condition wait — the notifier is whoever runs next — or a semaphore
 *    acquire, whose any-releaser semantics admit no necessary-condition
 *    edge). The actor can still be the TARGET of other actors' edges (it
 *    may hold keys while parked).
 *  - `Exclusive`: one tracked holder blocks the wait (mutex/monitor
 *    acquire, the Mesa re-acquire).
 *  - `AllHolders`: every tracked holder must release (ReadWriteLock).
 *  - `Future`: the wait is a mediated join (a retained route with no
 *    producer today); the edge target is the future's owner child (its
 *    `childExit` is the flip).
 */
internal enum PctWaitEdgeKind <: Equatable<PctWaitEdgeKind> {
    | NoEdge
    | HoldExclusive
    | HoldAll
    | JoinFuture

    public override operator func ==(other: PctWaitEdgeKind): Bool { // cjlint-ignore !G.OPR.01 parameterless enum: the language requires this manual == to satisfy Equatable<T>; match-based constructor comparison is the only possible implementation

        match ((this, other)) {
            case (NoEdge, NoEdge) => true
            case (HoldExclusive, HoldExclusive) => true
            case (HoldAll, HoldAll) => true
            case (JoinFuture, JoinFuture) => true
            case _ => false
        }
    }
}

internal class PctWaitForGraph {
    // Tracked lock ownership, the wait-for graph's holder side. Parallel
    // lists: distinct keys (refEq) and, per key, flat [actor, holdCount]
    // pairs. Every actor acquire that the coordinator sees (medAcquire's
    // under-lock probe) adds a count; every release it sees (medRelease,
    // the condition wait's one-level drop) removes one; a non-actor
    // release forgets the key's holders entirely. The tracked set is
    // therefore a subset of the real holders (acquires through
    // tryLock/timed paths are invisible — false negatives only, never
    // false edges), which keeps every recorded edge a necessary condition
    // for the waiter's progress and every detected cycle a true deadlock.
    private let holderKeys = ArrayList<Object>()
    private let holderEntries = ArrayList<ArrayList<Int64>>()

    private let table: PctActorTable

    internal init(table!: PctActorTable) {
        this.table = table
    }

    /**
     * The acquire-semantics -> edge-kind mapping (the wrappers classify
     * how a key's holders block waiters; see PctAcquireSemantics in
     * pct_schedule.cj). Semaphore acquires admit no necessary-condition edge
     * (any releaser suffices).
     */
    internal func edgeKindFor(semantics: PctAcquireSemantics): PctWaitEdgeKind {
        match (semantics) {
            case Exclusive => HoldExclusive
            case AllHolders => HoldAll
            case AnyReleaser => NoEdge
        }
    }

    // ------------------------------------------------------------------
    // Tracked ownership (the holder side).
    // ------------------------------------------------------------------

    private func holderIndex(key: Object): Int64 {
        var i: Int64 = 0
        while (i < Int64(holderKeys.size)) {
            if (refEq(holderKeys[i], key)) {
                return i
            }
            i++
        }
        return -1
    }

    /** Record one (reentrant) hold of `key` by actor `me`. */
    internal func holderAdd(key: Object, me: Int64): Unit {
        var idx = holderIndex(key)
        if (idx < 0) {
            holderKeys.add(key)
            holderEntries.add(ArrayList<Int64>())
            idx = Int64(holderKeys.size) - 1
        }
        let entries = holderEntries[idx]
        var j: Int64 = 0
        while (j < Int64(entries.size)) {
            if (entries[j] == me) {
                entries[j + 1] += 1
                return
            }
            j += 2
        }
        entries.add(me)
        entries.add(1)
    }

    /**
     * Drop one (reentrant) hold of `key` by actor `me` (a release). Zero
     * counts stay in place — holderActors filters them — so the pair list
     * only ever grows, like every other per-iteration table.
     */
    internal func holderRemove(key: Object, me: Int64): Unit {
        let idx = holderIndex(key)
        if (idx < 0) {
            return
        }
        let entries = holderEntries[idx]
        var j: Int64 = 0
        while (j < Int64(entries.size)) {
            if (entries[j] == me) {
                if (entries[j + 1] > 0) {
                    entries[j + 1] -= 1
                }
                return
            }
            j += 2
        }
    }

    /** Forget every tracked holder of `key` (a non-actor release). */
    internal func holderClear(key: Object): Unit {
        let idx = holderIndex(key)
        if (idx < 0) {
            return
        }
        let entries = holderEntries[idx]
        var j: Int64 = 0
        while (j < Int64(entries.size)) {
            entries[j + 1] = 0
            j += 2
        }
    }

    /** The distinct actors currently tracked as holding `key`. */
    private func holderActors(key: Object): Array<Int64> {
        let res = ArrayList<Int64>()
        let idx = holderIndex(key)
        if (idx >= 0) {
            let entries = holderEntries[idx]
            var j: Int64 = 0
            while (j < Int64(entries.size)) {
                if (entries[j + 1] > 0) {
                    res.add(entries[j])
                }
                j += 2
            }
        }
        return res.toArray()
    }

    // ------------------------------------------------------------------
    // The waiter side + the cycle search.
    // ------------------------------------------------------------------

    // The wait-edge targets of a parked actor: who must act before it can
    // proceed. Empty for NoEdge waits and for untracked/non-attributeable
    // holders (the sound-under-approximation cases).
    private func edgeTargets(a: Int64): Array<Int64> {
        if (!table.isWaiting(a)) {
            return Array<Int64>(0, { _ => 0 })
        }
        let kind = table.waitEdgeOf(a)
        if (kind == NoEdge) {
            return Array<Int64>(0, { _ => 0 })
        }
        let keyOpt = table.waitKeyOf(a)
        if (keyOpt.isNone()) {
            return Array<Int64>(0, { _ => 0 })
        }
        let key = keyOpt.getOrThrow() // cjlint-ignore !G.ERR.03 invariant-guarded extraction: a preceding isNone()/contains() gate (or the ScenarioBuilder contract, see comment) guarantees Some here; None would be a framework bug where throwing is the intended behavior
        if (kind == JoinFuture) {
            // The mediated-join edge (a retained route; no producer today).
            if (let Some(owner) <- table.liveChildOwner(key)) {
                return [owner]
            }
            return Array<Int64>(0, { _ => 0 })
        }
        let holders = holderActors(key)
        if (kind == HoldExclusive) {
            if (holders.size == 1) {
                return holders
            }
            return Array<Int64>(0, { _ => 0 }) // 0 (untracked) or ambiguous: no sound edge
        }
        return holders // HoldAll: every tracked holder must release
    }

    /**
     * The cycle check at park time: does `me`'s fresh wait edge close a
     * wait-for cycle back to `me`? A cycle proves a deadlock — every
     * member waits on a necessary action of the next, so none can ever
     * act (the only legitimate breakers are the cycle members themselves,
     * all parked; timed parks elsewhere return on their own timeouts and
     * cannot release a key they do not hold; a rogue non-actor unlock is
     * the documented pathological exception). Returns the actor path of
     * the cycle (starting and ending at `me`).
     */
    internal func detectCycle(me: Int64): ?Array<Int64> { // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
        // Cheap gate: a cycle needs at least one OTHER Waiting actor
        // carrying a live edge kind.
        var anyCandidate = false
        var i: Int64 = 0
        while (i < table.slotCount()) {
            if (i != me && table.isWaiting(i) && table.waitEdgeOf(i) != NoEdge) {
                anyCandidate = true
                break
            }
            i++
        }
        if (!anyCandidate) {
            return None
        }
        // BFS from me's edge targets; parent[t] is the actor whose
        // wait-edge reached t (reconstruct the cycle through it).
        let parent = Array<Int64>(table.slotCount(), { _ => -1 })
        let seen = Array<Bool>(table.slotCount(), { _ => false }) // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        let queue = ArrayList<Int64>()
        for (t in edgeTargets(me)) {
            if (t == me) {
                return Some([me, me]) // self-edge: a reentrant self-deadlock
            }
            if (parent[t] == -1) {
                parent[t] = me
                queue.add(t)
            }
        }
        var head: Int64 = 0
        while (head < Int64(queue.size)) {
            let t = queue[head]
            head += 1
            if (seen[t]) {
                continue
            }
            seen[t] = true
            if (!table.isWaiting(t)) {
                continue // Gated/Running/Blocked: it can act, the path is live
            }
            for (s in edgeTargets(t)) {
                if (s == me) {
                    parent[me] = t
                    // Walk t back through the parents to me, then reverse:
                    // the cycle reads me -> ... -> t -> me.
                    let chain = ArrayList<Int64>()
                    var cur = t
                    while (cur != me) {
                        chain.add(cur)
                        cur = parent[cur]
                    }
                    let cycle = ArrayList<Int64>()
                    cycle.add(me)
                    var c: Int64 = Int64(chain.size) - 1
                    while (c >= 0) {
                        cycle.add(chain[c])
                        c -= 1
                    }
                    cycle.add(me)
                    return Some(cycle.toArray())
                }
                if (!seen[s] && parent[s] == -1) {
                    parent[s] = t
                    queue.add(s)
                }
            }
        }
        return None
    }
}
