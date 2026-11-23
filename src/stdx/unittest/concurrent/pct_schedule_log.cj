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
 * The PCT schedule log: the recorded event stream of one iteration and
 * its replay state (PctScheduler owns and drives it — the coordinator
 * requests decisions and never touches this class).
 *
 * Record mode appends every decision event (switches, blocks, waits,
 * unlocks/releases/notifies, spawns, exits, PCPs, deadlock/resume
 * markers, fair yields). Replay mode instead walks a loaded event array
 * with a cursor: the scheduler's decision methods peek the next expected
 * event, consume it on a match (kind + from, and the per-actor decision
 * step where the schedule depends on it), and set `diverged` on a
 * mismatch — a diverged replay stops consuming and continues in record
 * mode, and the divergence flag is reported on the schedule.
 *
 * LOCK CONTRACT: this class is NOT thread-safe on its own. Every method
 * is called by the scheduler under the coordinator's lock. `diverged`
 * is accessor-guarded for the same reason: the scheduler's decision
 * methods read and write it directly (divergence is detected at their
 * target checks).
 */
internal class PctScheduleLog {
    // The recorded event stream of the iteration.
    private let events = ArrayList<PctEvent>()
    // Replay state: the loaded events (rejections happen at load), the
    // cursor (advanced on each consumed match), and the divergence flag.
    private var diverged: Bool = false
    private var replayMode: Bool = false
    private var replayEvents: Array<PctEvent> = []
    private var replayCursor: Int64 = 0

    /** Has a replay decision mismatched the loaded schedule? */
    internal func isDiverged(): Bool {
        return diverged
    }

    /** Flag the replay as diverged (stops consuming; record mode from here on). */
    internal func markDiverged(): Unit {
        diverged = true
    }

    /** Append one decision event (record mode; re-record on replay). */
    internal func logEvent(kind: PctEventKind, from: Int64, to: Int64, step: UInt64): Unit {
        events.add(PctEvent(kind: kind, from: Int32(from), to: Int32(to), step: step))
    }

    /** Snapshot the recorded events (the reported schedule's payload). */
    internal func eventsSnapshot(): Array<PctEvent> {
        return events.toArray()
    }

    /**
     * Load a recorded schedule for replay. Returns 0 on success, -1 for
     * an empty schedule, -2 for schedules containing Resume events
     * (deadlock recovery depends on external wake timing and is not
     * replayable), -3 for schedules marked deadlocked (a Phase D cycle
     * abort unwound the actors mid-flight; the trailing decisions never
     * happened), -4 for schedules marked diverged (their tail is
     * record-mode output, no longer the schedule they describe), -5 when
     * the schedule was recorded for a different scenario (actor-count
     * mismatch — actor slots and the priority table are per-scenario),
     * -6 when an event references an actor slot outside
     * [0, expectedActorCount) (a foreign or hand-crafted event stream
     * must never reach the coordinator's slot indexing — a promoted
     * out-of-range victim would index the actor table out of bounds
     * under the engine lock and strand every later dispatch).
     * Call before spawning any thread.
     */
    internal func loadForReplay(schedule: PCTSchedule, expectedActorCount: Int64): Int32 {
        if (schedule.events.size == 0) {
            return -1
        }
        if (schedule.deadlocked) {
            return -3
        }
        if (schedule.diverged) {
            return -4
        }
        if (schedule.actorCount != expectedActorCount) {
            return -5
        }
        for (ev in schedule.events) {
            if (ev.kind == Resume) {
                return -2
            }
            // Actor references: -1 encodes "no actor" (the initial release,
            // a stranded token, a timer fire); anything else is a slot
            // index and must stay inside the replaying scenario's actor
            // table.
            if (ev.to >= 0 && Int64(ev.to) >= expectedActorCount) {
                return -6
            }
            if (ev.from >= 0 && Int64(ev.from) >= expectedActorCount) {
                return -6
            }
        }
        replayEvents = schedule.events
        replayCursor = 0
        replayMode = true
        diverged = false
        return 0
    }

    /** Is a schedule loaded and being replayed? */
    internal func isReplayMode(): Bool {
        return replayMode
    }

    /**
     * The next non-PCP replay event at the cursor, without consuming it
     * (PCPs are consumed by consumePcps; Resume is rejected at load and
     * never expected here).
     */
    internal func peek(): ?PctEvent {
        if (replayCursor >= Int64(replayEvents.size)) {
            return None
        }
        let ev = replayEvents[replayCursor]
        if (ev.kind == Resume) {
            return None
        }
        return Some(ev)
    }

    /** Advance the cursor past the just-matched event (a consumption). */
    internal func consume(): Unit {
        replayCursor++
    }

    /**
     * Is the cursor's next replay event a Timer (a recorded virtual-time
     * fire sitting immediately before the parking decision that triggered
     * it — the transfer decisions check this first so the fire's flip
     * happens before they consume their own event)?
     */
    internal func peekIsTimer(): Bool {
        if (let Some(ev) <- peek()) {
            return ev.kind == Timer
        }
        return false
    }
    /**
     * The decision methods' replay-matching primitive: try to consume the
     * peeked event as this decision's expected match. `kind` (and
     * `altKind`: the exit decisions accept Done/Complete, the park
     * decisions accept their own event or a Deadlock) selects the
     * acceptable event kinds; `from` must match when given (None = any —
     * the Spawn registration has no from); `step` must match when given
     * (the poll and fair-yield decisions key on the actor's decision
     * counter). Returns the consumed event on a match, None otherwise.
     *
     * Divergence is CALLER policy (the scheduler's decision methods): a
     * strict decision (whose schedule requires the event at this point —
     * block, park, unlock, exit, spawn, the initial switch) treats None
     * as divergence; a lenient one (an op-boundary or fair-yield switch —
     * a non-matching peeked event simply belongs to a later decision)
     * falls through to its fresh pick. The grant-target validation also
     * stays with the caller: -1 is a legitimate recorded outcome for
     * park/exit decisions and a divergence for the rest.
     */
    internal func tryConsume(kind: PctEventKind, altKind!: ?PctEventKind = None,
        from!: ?Int64 = None, step!: ?UInt64 = None): ?PctEvent {
        let ev = peek() ?? return None
        if (ev.kind != kind) {
            var altOk = false
            if (let Some(alt) <- altKind) {
                altOk = ev.kind == alt
            }
            if (!altOk) {
                return None
            }
        }
        if (let Some(f) <- from) {
            if (Int64(ev.from) != f) {
                return None
            }
        }
        if (let Some(s) <- step) {
            if (ev.step != s) {
                return None
            }
        }
        consume()
        return Some(ev)
    }

    /**
     * Consume the run of recorded PCP events at the cursor (replay
     * mode's firePcp): `apply` runs for each promoted victim (the
     * scheduler's promote), and each consumed event is re-recorded
     * verbatim so a faithful replay's own schedule equals the loaded
     * one. No RNG draws happen on this path, so the replay stream cannot
     * desync.
     */
    internal func consumePcps(apply: (Int64) -> Unit): Unit {
        while (replayCursor < Int64(replayEvents.size)) {
            let ev = replayEvents[replayCursor]
            if (ev.kind != Pcp) {
                break
            }
            apply(Int64(ev.to))
            replayCursor++
            logEvent(Pcp, Int64(ev.from), Int64(ev.to), ev.step)
        }
    }
}
