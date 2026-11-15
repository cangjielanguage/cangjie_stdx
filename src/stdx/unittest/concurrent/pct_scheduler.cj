/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.random.Random

/**
 * The outcome of a transfer decision (the scheduler's request API, see
 * PctBaseScheduler's transfer-decision section). The event recording — and
 * the replay-vs-record branching behind it — is the scheduler's business;
 * the coordinator only executes the token protocol on the result.
 */
internal enum PctTransfer {
    /** The token moves to the actor; the decision event is logged. */
    | Grant(Int64)
    /** The token strands; the `Deadlock` marker is logged iff the flag
     * (blocked/waiting actors remained). */
    | Strand(Bool)
    /** Nothing happened and nothing was logged; the caller keeps running. */
    | Silent
}

/**
 * A spawn registration decision (phase 1 of childEnter's two-phase
 * handshake): the slot the child binds, and — in a faithful replay — the
 * priority rank recorded in its Spawn event (`-1` = draw fresh at apply
 * time).
 */
internal struct PctSpawnDecision {
    internal PctSpawnDecision(
        internal let slot!: Int64,
        internal let rank!: Int64
    ) {}
}

/**
 * The PCT scheduling policy (pct_coordinator.cj owns and drives it): the
 * seeded decision stream, the priority-change-point machinery, and the
 * seeded spawn-rank draw. Everything else — the schedule log and its
 * replay machinery, the transfer templates, the starvation/fair-mode
 * recovery, the grant picks — is inherited from PctBaseScheduler, whose
 * default hook bodies ARE the PCT picks.
 *
 * The RNG (MT19937-64) is not thread-safe, but draws happen only under
 * the coordinator lock, so it is single-threaded by construction. Same
 * seed -> same schedule for deterministic programs, so schedule
 * reproducibility is coupled to std.random's algorithm.
 *
 * LOCK CONTRACT: this class is NOT thread-safe on its own. Every method
 * is called by the coordinator under its lock.
 */
internal class PctScheduler <: PctBaseScheduler {
    // Decision stream for record-mode schedules (priority permutation,
    // PCP draws). Replay mode never draws (onDecisionPoint consumes
    // recorded Pcp events through the schedule log).
    private let rng: Random
    // PCP.
    private var pcpsRemaining: Int64
    private let pcpFireProb: Float64

    internal init(seed!: UInt64, pcpBudget!: Int64, pcpFireProb!: Float64,
        starvationThreshold!: UInt64, switchBound!: Int64 = -1, table!: PctActorTable) {
        super(starvationThreshold: starvationThreshold, switchBound: switchBound, table: table)
        rng = Random(seed)
        pcpsRemaining = pcpBudget
        this.pcpFireProb = pcpFireProb
    }

    // ------------------------------------------------------------------
    // Priority-change points (the onDecisionPoint hook).
    // ------------------------------------------------------------------

    /**
     * Priority-change point, at every decision point (both modes). In
     * replay mode the recorded PCP events are consumed (no RNG draws, so
     * the replay stream cannot desync) and re-logged verbatim; in record
     * mode the RNG decides.
     */
    protected override func onDecisionPoint(holderId: Int64): Unit {
        if (log.isReplayMode()) {
            if (log.isDiverged()) {
                return
            }
            // Consume the run of recorded PCP events at the cursor,
            // promoting each victim; the log re-records them verbatim so a
            // faithful replay's own schedule equals the loaded one.
            log.consumePcps({ victim => promote(victim) })
            return
        }
        if (pcpsRemaining == 0 || pcpFireProb <= 0.0) {
            return
        }
        if (rng.nextFloat64() >= pcpFireProb) {
            return
        }
        pcpsRemaining--
        // Every actor is dynamic, so the victim range is the full live
        // slot range (the draw is a deterministic function of the
        // schedule — the slot count grows deterministically with the
        // Spawn order).
        let victim = Int64(rng.nextUInt64(UInt64(table.slotCount())))
        promote(victim)
        log.logEvent(Pcp, holderId, victim, table.pollCountOf(holderId))
    }

    /**
     * The newcomer's registration draw: r in [1, max+1] (the base's
     * applySpawnRank inserts it dense). Deterministic from the seeded
     * stream; the rank is recorded in the Spawn event and replay applies
     * it through insertPriorityAt (no replay-side draw).
     */
    protected override func drawSpawnRank(slot: Int64): Int64 {
        let maxPrio = table.maxPriorityOtherThan(slot)
        return 1 + Int64(rng.nextUInt64(UInt64(maxPrio + 1)))
    }

    /** Promote `victim` to top priority; everyone between shifts down one. */
    private func promote(victim: Int64): Unit {
        let oldPrio = table.priorityOf(victim)
        if (oldPrio == 1 || oldPrio == 0) {
            return // already top / unregistered slot
        }
        var i: Int64 = 0
        while (i < table.slotCount()) {
            let p = table.priorityOf(i)
            if (p < oldPrio && p != 0) {
                table.setPriority(i, p + 1)
            }
            i++
        }
        table.setPriority(victim, 1)
    }
}
