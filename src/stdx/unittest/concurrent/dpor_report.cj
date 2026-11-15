/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

import std.collection.ArrayList
import std.collection.HashMap

/**
 * The POP sleep-set characterization mode:
 *  - `Char` (default): the schedule-expression characterization is
 *    active — optimal up to the duplicate classes the post-hoc
 *    block-detection windows still explore (each costs one window;
 *    their subtrees are cut at the block).
 *  - `Off`: the characterization disabled — complete and sound,
 *    exploring the duplicate classes of compatible read schedules
 *    from one write (the kill switch).
 */
public enum DporSleepCharMode <: Equatable<DporSleepCharMode> & ToString {
    | Char
    | Off

    public override operator func ==(other: DporSleepCharMode): Bool { // cjlint-ignore !G.OPR.01 parameterless enum: the language requires this manual == to satisfy Equatable<T>; match-based constructor comparison is the only possible implementation
        match ((this, other)) {
            case (Char, Char) => true
            case (Off, Off) => true
            case _ => false
        }
    }

    public func toString(): String {
        match (this) {
            case Char => "char"
            case Off => "off"
        }
    }
}

/**
 * Configuration of one DPOR exploration: the schedule budget and the
 * starvation threshold (the shared livelock recovery — see
 * PctBaseScheduler). The scenario layer builds this from the builder's
 * knobs and adds state management and verification around each explored
 * schedule.
 */
internal struct DporWindowConfig {
    internal DporWindowConfig(
        /** Maximum explored schedules (the exploration budget). */
        internal let maxSchedules!: Int64 = 100,
        /** Grid-poll run that triggers fair scheduling (shared with PCT). */
        internal let starvationThreshold!: UInt64 = 10_000u64,
        /** Per-schedule guided-switch bound: the driver never plans a
         *  schedule with more voluntary (guided) token switches than
         *  this; backtrack points beyond it are pruned, and the report
         *  marks the exploration `depthPruned` (not `exhausted`). -1
         *  (default) is unbounded — the depth-bound analogue of
         *  `maxSchedules`, which bounds the width. */
        internal let switchBound!: Int64 = -1,
        /** The POP sleep-set characterization mode (see
         *  DporSleepCharMode; the default is on). */
        internal let sleepCharMode!: DporSleepCharMode = Char,
        /** What the starvation recovery point does (see ObstructionPolicy
         *  and ObstructionDetectedException): `ThrowObstruction` (the
         *  default) ends the obstructed operation with a per-op bounded
         *  wait — no guide-foreign fair yield, so the schedule stays a
         *  pure function of the guide (replay re-derives the throw from
         *  the streak counter); `YieldFairly` uses the fair-mode
         *  voluntary yield (the recovery PCT always uses). Note: a
         *  throw-window schedule replays faithfully only under a
         *  matching policy — under YieldFairly the replay would
         *  fair-yield where the recording threw. */
        internal let obstructionPolicy!: ObstructionPolicy = ThrowObstruction
    ) {}
}

/**
 * The outcome of one DPOR exploration: the exploration statistics and
 * the last executed schedule (the reproduction artifact of the final
 * explored interleaving; every DPOR schedule is an ordinary
 * `PCTSchedule` and replays through the scenario builder's
 * `.replaySchedule(...)`).
 */
public struct DporReport {
    internal DporReport(
        /** Schedules actually executed. */
        public let schedulesExplored!: Int64,
        /** The exploration completed (budget not exhausted). */
        public let exhausted!: Bool,
        /** Any explored schedule hit a wait-for deadlock (the wait-for
         *  cycle abort — the diagnosis, reported like PCT's; see
         *  "Deadlock detection" in the README). */
        public let deadlocked!: Bool,
        /** The last explored schedule (replayable). */
        public let lastSchedule!: PCTSchedule,
        /** Data races found in the first racing schedule (the
         *  exploration stops there — first-failure semantics extend to
         *  races); empty without an mtrace runtime. */
        protected let racePairs!: Array<DporRacePair>,
        /** The exploration stopped because a schedule exhibited a data
         *  race (the racing schedule is the reproduction artifact). */
        public let stoppedOnRace!: Bool,
        /** mtrace events dropped across the exploration (buffer overflow
         *  or memory cap): every drop is a potential missed race — a
         *  non-zero value means the race report is incomplete. Zero
         *  without an mtrace runtime. */
        internal let droppedEvents!: UInt64,
        /** Backtrack points were pruned by the configured switch bound
         *  (DporWindowConfig.switchBound): the exploration is incomplete
         *  for that reason — distinct from an unbounded run's
         *  `exhausted`, and from budget/first-failure stops. */
        public let depthPruned!: Bool = false, // cjlint-ignore !G.FUN.01 config-carrier signature: the named parameters are the structured configuration/context of this framework step; bundling them into a struct would only move the count
        /** A human-readable exploration statistics line. */
        public let stats!: String
    ) {}
}

/** Holds the scheduler reference across the factory closure. */
internal class DporSchedHolder {
    internal var sched: ?DporScheduler = None
}

/**
 * Run one DPOR window with a fully-formed guide (the driver's internal
 * window): constructs the coordinator with a DporScheduler (captured
 * for the run data), runs the shared window lifecycle, and returns
 * the window report plus the collected decision/segment data.
 *
 * `keyBase`/`keyBoundary` bracket the schedule's setup on the sync-key
 * ID counter (see PctSyncKey): sync objects constructed in between are
 * the schedule's STATE phase and carry window-relative offsets for
 * cross-window logical identity in the snapshot layer.
 */
internal func runDporWindowSingle( // cjlint-ignore !G.FUN.01 config-carrier signature: the named parameters are the structured configuration/context of this framework step; bundling them into a struct would only move the count
    entries!: Array<DporGuideEntry>,
    collector!: DporTraceCollector,
    starvationThreshold!: UInt64,
    obstructionPolicy!: ObstructionPolicy,
    keyBase!: Int64,
    keyBoundary!: Int64,
    actors!: Array<Array<() -> Unit>>
): (PctWindowReport, DporRunData) {
    let holder = DporSchedHolder()
    let coord = PctCoordinator(
        seed: 0u64, // the DPOR policy draws no randomness
        actorCount: actors.size,
        pcpBudget: 0,
        pcpFireProb: 0.0,
        starvationThreshold: starvationThreshold,
        schedulerFactory: Some({ table =>
            let s = DporScheduler(
                guide: entries,
                collector: collector,
                starvationThreshold: starvationThreshold,
                obstructionPolicy: obstructionPolicy,
                keyBase: keyBase,
                keyBoundary: keyBoundary,
                table: table)
            holder.sched = Some(s)
            return s
        })
    )
    let report = runWindowInternal(coord, actors)
    let sched = holder.sched.getOrThrow() // cjlint-ignore !G.ERR.03 intended failure mode: a DPOR window must explore at least one schedule; None means a framework bug and throwing is correct
    return (report, sched.runData())
}

/**
 * One explored schedule's outcome, delivered to the stepped driver's
 * `afterSchedule` hook (runDporWindowStepped): the window report of the
 * schedule that just ran plus its 0-based index in the exploration.
 */
internal struct DporScheduleOutcome {
    internal DporScheduleOutcome(
        /** The schedule's 0-based exploration index. */
        internal let scheduleIndex!: Int64,
        /** The window report of the schedule that just ran. */
        internal let windowReport!: PctWindowReport
    ) {}
}

/**
 * The stepped DPOR exploration: the package-internal DPOR driver the
 * scenario layer builds `TestMode.DPOR` on. Each schedule is bracketed
 * by caller hooks so the scenario runner can reset its state around it:
 *
 * - `beforeSchedule` runs before each window (reset + fresh state via
 *   the state factory).
 * - `opsFactory` runs right after (compose the actor operation closures
 *   against the fresh state — they are invoked between the window's
 *   scheduling points exactly like `runPctWindow`'s actors).
 * - `afterSchedule` runs after each window (verify the fresh state,
 *   consult the window report); returning false stops the exploration
 *   early — the report then carries the schedules explored so far.
 *
 * The exploration also stops by itself on the first schedule that
 * exhibits a data race (the mtrace race scan; no-op without an mtrace
 * runtime) — races are findings, first-failure semantics.
 *
 * The hooks run on the driver thread, serialized, outside the window's
 * actor protocol.
 *
 * Throws on framework misuse only (uninstrumented binary, a leaked
 * previous window, protocol violations) — actor failures travel in the
 * per-schedule window reports.
 */
internal func runDporWindowStepped( // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
    config!: DporWindowConfig,
    beforeSchedule!: () -> Unit,
    opsFactory!: () -> Array<Array<() -> Unit>>,
    afterSchedule!: (DporScheduleOutcome) -> Bool
): DporReport {
    let popDriver = DporPopDriver(switchBound: config.switchBound,
        sleepChar: config.sleepCharMode == Char)
    // One collector for the whole exploration: the GC-move translation
    // map must persist across windows (see DporTraceCollector).
        // cjlint-ignore -start !G.VAR.02 the variables below thread state across loop/algorithm iterations (accumulators or framework context); narrowing their scopes would change semantics
    let collector = DporTraceCollector()
    var deadlocked = false
    var lastSchedule: ?PCTSchedule = None
    var exhausted = false
    var stoppedOnRace = false
    var droppedEvents: UInt64 = 0u64
    let racePairs = ArrayList<DporRacePair>()
    // Race-key dedup: the same (actor, pc, addr) pair recurs within one
    // window's scan (loop iterations re-touch the same sites), so only
    // the first pair per key is reported. The exploration stops at the
    // first racing schedule, so keys never accumulate across schedules.
    let raceSeen = HashMap<String, Bool>()
    var run: Int64 = 0
    var stopped = false
    var depthPruned = false
    var stats = ""
    var popTask: ?DporPopTask = None
    // The driver thread's own traffic (window lifecycle, futures drain,
        // cjlint-ignore -end
    // driver bookkeeping) is framework noise — suppressed for the whole
    // exploration (no-op without an mtrace runtime). The try/finally
    // keeps the depth balanced and recording off even on a framework
    // misuse throw.
    suppressBegin()
    try {
        while (run < config.maxSchedules && !stopped) {
            // The driver's next task: a whole pinned node E1·σ (an
            // empty guide for the root window).
            let entries: Array<DporGuideEntry> // cjlint-ignore !G.VAR.02 the declaration must span the enclosing branch/loop: the value is assigned (or produced) in one arm and consumed after it, so the live range is already minimal
            popTask = None
            match (popDriver.nextTask()) {
                case Some(t) =>
                    popTask = Some(t)
                    entries = t.guide
                case None =>
                    // The stack is empty: genuine exhaustion when no
                    // child was switch-bound pruned; stranded
                    // pruned children mean the exploration was
                    // depth-pruned instead.
                    exhausted = popDriver.prunedCount() == 0
                    break
            }
            // mtrace lifecycle per window: clean buffers, record during
            // the window only, account for drops (each drop is a
            // potential missed race).
            resetAll()
            setEnabled(true)
            // The sync-key ID bracket of this schedule's setup: sync
            // objects constructed by beforeSchedule + opsFactory (the
            // fresh state and the op closures' captured keys) are the
            // STATE phase — they carry window-relative offsets so the
            // snapshot layer matches them across schedules by logical
            // identity (see PctSyncKey). Objects predating the window
            // (reused state) and mid-window creations keep identity
            // semantics.
            let keyBase = pctSyncKeyCounterNow()
            beforeSchedule()
            let actors = opsFactory()
            let keyBoundary = pctSyncKeyCounterNow()
            let (report, data) = runDporWindowSingle(
                entries: entries,
                collector: collector,
                starvationThreshold: config.starvationThreshold,
                obstructionPolicy: config.obstructionPolicy,
                keyBase: keyBase,
                keyBoundary: keyBoundary,
                actors: actors)
            setEnabled(false)
            droppedEvents += droppedCount()
            lastSchedule = Some(report.schedule)
            if (report.deadlocked) {
                deadlocked = true
                // A deadlocked schedule is a terminal finding for this
                // branch: record it (the race scan below still runs on the
                // partial data) and continue the exploration — other
                // branches may avoid the cycle.
            }
            // The race scan runs on every window's own segment data
            // (races are per-execution findings). The first racing
            // schedule is a terminal finding — like a failing verify, it
            // stops the exploration (below, after the afterSchedule
            // hook, so the racing schedule's own verification outcome is
            // still recorded); its pairs are the report.
            let windowRaces = dporScanRaces(data)
            for (pair in windowRaces) {
                let lo = DporRacePair(actorA: pair.actorA, pcA: pair.pcA, // cjlint-ignore !G.VAR.02 the declaration must span the enclosing branch/loop: the value is assigned (or produced) in one arm and consumed after it, so the live range is already minimal
                    actorB: pair.actorB, pcB: pair.pcB, addr: pair.addr, size: pair.size,
                    locA: pair.locA, locB: pair.locB)
                let key = "${lo.actorA}|${lo.pcA}|${lo.actorB}|${lo.pcB}|${lo.addr}|${lo.size}" // cjlint-ignore !G.VAR.02 the declaration must span the enclosing branch/loop: the value is assigned (or produced) in one arm and consumed after it, so the live range is already minimal
                if (!raceSeen.contains(key)) {
                    raceSeen.add(key, true)
                    racePairs.add(lo)
                }
            }
            popDriver.recordWindow(popTask.getOrThrow(), data) // cjlint-ignore !G.ERR.03 invariant-guarded extraction: a preceding isNone()/contains() gate (or the ScenarioBuilder contract, see comment) guarantees Some here; None would be a framework bug where throwing is the intended behavior
            run += 1
            if (!afterSchedule(DporScheduleOutcome(scheduleIndex: run - 1, windowReport: report))) {
                stopped = true
            }
            if (windowRaces.size > 0) {
                stoppedOnRace = true
                stopped = true // first race stops the exploration
            }
        }
    } finally {
        setEnabled(false)
        suppressEnd()
    }
    let schedule = match (lastSchedule) {
        case Some(s) => s
        case None =>
            // maxSchedules == 0: nothing ran; an empty report schedule.
            PCTSchedule(seed: 0u64, actorCount: 0, pcpBudget: 0,
                events: Array<PctEvent>(0, { _ => PctEvent(kind: Switch) }),
                diverged: false, deadlocked: false, pollCount: 0u64, gridPoints: 0u64,
                starvationSwitches: 0u64, spawnedActors: 0u64, deadlockCycle: None)
    }
    depthPruned = popDriver.prunedCount() > 0
    stats = popDriver.statsLine()
    return DporReport(
        schedulesExplored: run,
        exhausted: exhausted,
        deadlocked: deadlocked,
        lastSchedule: schedule,
        racePairs: racePairs.toArray(),
        stoppedOnRace: stoppedOnRace,
        droppedEvents: droppedEvents,
        depthPruned: depthPruned,
        stats: stats)
}
