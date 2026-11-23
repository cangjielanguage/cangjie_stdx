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
 * One armed virtual timer: the absolute (logical) deadline, the waiting
 * actor it belongs to, and the wait key the actor was parked under at
 * arm time. The key is part of the entry so a fired-or-refired timer can
 * be validated lazily: an entry is LIVE exactly while its actor is still
 * `Waiting` on that key — any other state (woken by a notify/completion
 * flip, running, finished) makes the entry stale, and stale entries are
 * purged at fire time instead of being book-kept on every wake path.
 */
internal class PctTimerEntry {
    internal let deadline: Int64
    internal let actor: Int64
    internal let key: Object

    internal init(deadline!: Int64, actor!: Int64, key!: Object) {
        this.deadline = deadline
        this.actor = actor
        this.key = key
    }
}

/**
 * The PCT virtual clock of one iteration (PctScheduler owns and drives
 * it): a logical nanosecond counter that never relates to wall time, plus
 * the armed virtual timers. It is what turns timeouts into scheduling
 * decisions — `sleep` and every finite wait of a PCT actor arm a timer
 * and park on the coordinator gate; the clock advances ONLY at scheduled
 * quiescence (a strand point of a transfer decision: the token stranded,
 * nobody gated), where the single earliest valid timer fires and its
 * waiter is granted the token directly (the `Timer` event — replayable,
 * unlike the `Resume` of a genuinely external wake). Time therefore can
 * never overtake a runnable actor: notify-vs-timeout races resolve
 * schedule-driven instead of wall-clock-driven, which is the whole
 * determinism win.
 *
 * LOCK CONTRACT: not thread-safe on its own — every method runs under
 * the engine lock (like the scheduler's other state). No RNG draws
 * anywhere: the earliest-valid pick (deadline, ties by lowest slot) is
 * deterministic, so replays cannot desync.
 */
internal class PctClock {
    // Armed timers. A linear scan suffices (actor counts are small) and
    // makes the deterministic tie-break (earliest deadline, then lowest
    // slot) explicit.
    private let timers = ArrayList<PctTimerEntry>()
    // The largest the armed list ever grew (a diagnostic counter, exposed
    // through the schedule — see the purge rationale in arm()).
    private var highWater: Int64 = 0 // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
    // The logical now, in nanoseconds; only `advanceTo` moves it forward.
    private var now: Int64 = 0

    /** Arm a timer for `me` (parked Waiting on `key`): the deadline is
     * fixed NOW (at the wait's entry), saturating at Int64.Max; a
     * barging re-wait never re-arms, so the deadline cannot extend. */
    internal func arm(me: Int64, key: Object, nanos: Int64): Unit {
        // An actor parks on one wait at a time, and a barging re-wait
        // never re-arms, so any entry already present for `me` is stale
        // by construction (its wait ended by a notify — a timer fire
        // consumes its entry via `take` instead). Drop it here: the
        // alternative purge (earliestValid) runs only on the
        // quiescence/strand path, so a wait/notify hot loop that never
        // strands would otherwise net one stale entry per cycle and grow
        // the list without bound for the whole window. After the purge
        // the list holds at most one entry per parked waiter.
        var i: Int64 = Int64(timers.size) - 1
        while (i >= 0) {
            if (timers[i].actor == me) {
                timers.remove(at: i)
            }
            i -= 1
        }
        var deadline = Int64.Max // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        if (nanos < Int64.Max - now) {
            deadline = now + nanos
        }
        timers.add(PctTimerEntry(deadline: deadline, actor: me, key: key))
        let size = Int64(timers.size)
        if (size > highWater) {
            highWater = size
        }
    }

    /** The largest armed-list size seen in this window (a diagnostic:
     *  bounded by the waiter count after arm()'s purge, unbounded
     *  without it). */
    internal func armedHighWater(): Int64 {
        return highWater
    }

    /**
     * The earliest LIVE timer, after purging stale entries (entries whose
     * actor is no longer Waiting on the entry's key — woken by another
     * path, or re-registered on a different wait). The returned entry is
     * NOT removed; the fire decision validates it against the replay
     * cursor first and consumes it via `take` only when it actually
     * fires (a diverged replay still fires — record mode from there on).
     */
    internal func earliestValid(table: PctActorTable): ?PctTimerEntry {
        var best: ?PctTimerEntry = None
        var i: Int64 = Int64(timers.size) - 1
        while (i >= 0) {
            let e = timers[i]
            var live = false
            if (table.stateOf(e.actor) == Waiting) {
                if (let Some(k) <- table.waitKeyOf(e.actor)) {
                    live = refEq(k, e.key)
                }
            }
            if (!live) {
                timers.remove(at: i)
            } else if (best.isNone()) {
                best = Some(e)
            } else {
                let b = best.getOrThrow() // cjlint-ignore !G.ERR.03 invariant-guarded extraction: a preceding isNone()/contains() gate (or the ScenarioBuilder contract, see comment) guarantees Some here; None would be a framework bug where throwing is the intended behavior
                if (e.deadline < b.deadline || (e.deadline == b.deadline && e.actor < b.actor)) {
                    best = Some(e)
                }
            }
            i--
        }
        return best
    }

    /** Consume a fired entry (by identity — everything runs under one
     * lock, and the list is small). */
    internal func take(entry: PctTimerEntry): Unit {
        var i: Int64 = 0
        while (i < Int64(timers.size)) {
            if (refEq(timers[i], entry)) {
                timers.remove(at: i)
                return
            }
            i++
        }
    }

    /** Advance the logical clock to a fired deadline (monotone). */
    internal func advanceTo(deadline: Int64): Unit {
        if (deadline > now) {
            now = deadline
        }
    }
}
