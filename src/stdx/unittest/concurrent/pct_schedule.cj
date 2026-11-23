/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

/**
 * Execution mode of a concurrent scenario.
 *
 * - `Stress`: the default Gaussian-backoff probabilistic stress mode. Actors
 *   are released simultaneously and perturbed with random busy-loop backoff;
 *   rare interleavings require many iterations to hit by chance.
 * - `PCT`: Probabilistic Concurrency Testing. The scheduler hands a
 *   single "token" to one actor at a time; switches happen at deterministic
 *   positions — actor operation boundaries, blocking sync operations and
 *   (with `--cj-pct`) right after every atomic operation, the fine-grained
 *   grid — guided by random priorities and a bounded budget of
 *   priority-change points (PCPs). Any bug requiring at most K scheduling
 *   switches is found with a polynomial number of runs, and every executed
 *   schedule is recorded and replayable. Requires the test binary to be
 *   compiled with `--cj-pct` (blocking inside actor operations is otherwise
 *   invisible to the scheduler; activate() rejects uninstrumented binaries).
 * - `DPOR`: Dynamic Partial Order Reduction with sleep sets (the
 *   deterministic model checker). The same token protocol and switch
 *   positions as PCT, but the schedule is driven by the dependency
 *   explorer instead of random priorities: every sync dependency between
 *   segments of different actors is explored in both orders (the race
 *   scan adds backtracking points), and sleep sets prune provably
 *   equivalent siblings. The exploration is deterministic — no seed. The
 *   scenario's `iterations` is the schedule budget. No mtrace runtime
 *   exists, so the per-schedule memory-trace analysis stays in its
 *   no-mtrace mode and reports no data races (see mtrace_ffi.cj).
 *   Requires `--cj-pct` like PCT.
 */
public enum TestMode {
    | Stress
    | PCT
    | DPOR
}

/**
 * How the current holders of a primitive relate to an acquire's progress
 * (the cycle abort's wait-for graph is built from this).
 *
 * - `Exclusive`: at most one holder blocks the acquire (mutex, monitor,
 *   reentrant mutex). A parked waiter carries a wait-edge to the tracked
 *   holder — its release is a necessary condition for progress.
 * - `AllHolders`: every current holder must act before the acquire can
 *   proceed (a ReadWriteLock's shared key: a writer needs every reader
 *   gone; a reader is blocked only while a writer holds or waits). Each
 *   tracked holder gets a wait-edge.
 * - `AnyReleaser`: any single release suffices (a semaphore's counted
 *   permits). No individual holder's release is necessary, so no sound
 *   wait-edge exists — semaphore waits never participate in cycle
 *   detection (a false-negative-only limitation).
 *
 * Reserved for the unittest infrastructure; not a general-purpose API.
 */
protected enum PctAcquireSemantics {
    | Exclusive
    | AllHolders
    | AnyReleaser
}

/**
 * Kind of a recorded PCT schedule event.
 *
 * - `Switch`: the token moved from `from` to `to` (`from == -1`: initial release).
 * - `Block`: `from` blocked in a sync primitive; the token moved to `to`.
 * - `Wait`: `from` entered a mediated wait (a contended mutex/semaphore
 *   acquire by an actor, or a condition wait — whose release of the inner
 *   lock is subsumed into this same decision — and the contended Mesa
 *   re-acquire after a notified wait; the mediated future join is a
 *   retained route with no producer today); it parked on its coordinator
 *   gate, keyed by the waited object, and the token moved to `to`.
 * - `Done`: `from` finished; the token moved to `to` (`to == -1`: nobody left).
 * - `Complete`: `from` finished and its completed future flipped waiting
 *   joiners to `Gated` in the same decision (the mediated-completion
 *   event; supersedes `Done` for that exit; reserved — never produced
 *   today); the token moved to `to`.
 * - `Unlock`: `from` unlocked a mutex with mediated waiters (the mediated
 *   acquire protocol): the waiters flipped to `Gated`, the releaser
 *   yielded, and the token
 *   moved to `to` (possibly `from` itself — the releaser competes for the
 *   very next grant; unlocks without waiters stay silent).
 * - `Release`: like `Unlock`, for a semaphore `release` with waiters.
 * - `Notify`: `from` notified a condition (the mediated condition-wait
 *   protocol) with a mediated waiter: a single waiter flipped to `Gated`,
 *   the notifier yielded, and
 *   the token moved to `to` (possibly `from` itself; notifies without
 *   waiters stay silent).
 * - `NotifyAll`: like `Notify`, but every waiter on the condition flipped
 *   (one yield decision covers the batch).
 * - `Spawn`: an actor registered as slot `to` with inserted priority rank
 *   `step` — produced by the window's initial-actor registration (initial
 *   actor `i` takes slot `i`); `from` is the registering side (`-1`: the
 *   runner's initial spawn).
 * - `Pcp`: a priority-change point promoted `to` to top priority.
 * - `FairYield`: `from` voluntarily yielded at a grid point (fair mode);
 *   the token moved to `to`.
 * - `Deadlock`: no gated actor remained while not all actors were done
 *   (recovery is possible — a timed-wait expiry or a non-actor release
 *   can still revive a waiter), OR the park closed a cycle in the
 *   wait-for graph (the cycle abort) — a proven deadlock; the iteration
 *   aborts and every actor unwinds.
 * - `Resume`: the token was claimed back after a deadlock (external wake —
 *   a timed-wait expiry, or a non-actor release flipping a mediated waiter
 *   while the token was stranded).
 * - `Timer`: a virtual-time timeout fired (the clock advanced to the
 *   waiter's deadline at a quiescence point — no gated actor remained —
 *   and the waiter was granted the token directly). `from` is the
 *   timed-out actor; `step` is the logical deadline in nanoseconds.
 *   Unlike `Resume`, a timer fire is a deterministic scheduling decision
 *   and replays: `sleep` and every finite wait of a PCT actor are
 *   simulated through the virtual clock, so their expiry never depends
 *   on wall time.
 */
protected enum PctEventKind <: Equatable<PctEventKind> & ToString {
    | Switch
    | Block
    | Wait
    | Done
    | Complete
    | Unlock
    | Release
    | Notify
    | NotifyAll
    | Spawn
    | Pcp
    | Deadlock
    | Resume
    | FairYield
    | Timer

    public override operator func ==(other: PctEventKind): Bool { // cjlint-ignore !G.OPR.01 parameterless enum: the language requires this manual == to satisfy Equatable<T>; match-based constructor comparison is the only possible implementation
        match ((this, other)) {
            case (Switch, Switch) => true
            case (Block, Block) => true
            case (Wait, Wait) => true
            case (Done, Done) => true
            case (Complete, Complete) => true
            case (Unlock, Unlock) => true
            case (Release, Release) => true
            case (Notify, Notify) => true
            case (NotifyAll, NotifyAll) => true
            case (Spawn, Spawn) => true
            case (Pcp, Pcp) => true
            case (FairYield, FairYield) => true
            case (Deadlock, Deadlock) => true
            case (Resume, Resume) => true
            case (Timer, Timer) => true
            case _ => false
        }
    }

    public func toString(): String {
        match (this) {
            case Switch => "Switch"
            case Block => "Block"
            case Wait => "Wait"
            case Done => "Done"
            case Complete => "Complete"
            case Unlock => "Unlock"
            case Release => "Release"
            case Notify => "Notify"
            case NotifyAll => "NotifyAll"
            case Spawn => "Spawn"
            case Pcp => "Pcp"
            case FairYield => "FairYield"
            case Deadlock => "Deadlock"
            case Resume => "Resume"
            case Timer => "Timer"
        }
    }
}

/**
 * One recorded PCT scheduling decision.
 *
 * `step` is the acting actor's decision counter at the event (incremented
 * at each operation boundary); replay keys on it so a recorded switch
 * reproduces at the exact same boundary.
 */
protected struct PctEvent {
    protected PctEvent(
        protected let kind!: PctEventKind,
        public let from!: Int32 = -1,
        public let to!: Int32 = -1,
        public let step!: UInt64 = 0
    ) {}
}

/**
 * Starvation accounting for one actor, derived from the event log.
 * `waits`/`blocks` count the actor's mediated parks / runtime parks;
 * each park's span is the number of subsequent decision events before the
 * actor was granted the token again (the next event picking it, or its
 * post-deadlock `Resume`) — a schedule-clock measure of how long the actor
 * waited while others decided. Parks never answered (a deadlocked or
 * aborted run) count in `openWaits` and contribute their truncated span.
 */
protected struct PctWaitStat {
    public PctWaitStat(
        public let actorId!: Int64,
        public let waits!: Int64 = 0,
        public let blocks!: Int64 = 0,
        public let totalWaitSpan!: Int64 = 0,
        public let maxWaitSpan!: Int64 = 0,
        public let openWaits!: Int64 = 0
    ) {}
}

/**
 * A recorded (or to-be-replayed) PCT schedule for one scenario iteration.
 *
 * Obtain one from `ScenarioResult.pctSchedule` after a PCT-mode run and feed
 * it back via `ScenarioBuilder.replaySchedule(...)` to reproduce the exact
 * same interleaving (same binary required).
 *
 * Actor slots: every actor is a dynamically registered child — the runner
 * spawns the initial actors in actor order (initial actor `i` takes slot
 * `i`, each with a `Spawn` event and a drawn priority rank). User-invoked
 * spawns are unmanaged and never register, so only the initial actors
 * take slots. `actorCount` reports the scenario's initial-actor count;
 * `spawnedActors` counts every registered actor.
 *
 * Schedules whose `deadlocked` or `diverged` flags are set, or that contain
 * `Resume` events, are not replayable (rejected at replay load).
 */
public class PCTSchedule {
    protected PCTSchedule(
        protected let seed!: UInt64,
        internal let actorCount!: Int64,
        protected let pcpBudget!: Int64,
        protected let events!: Array<PctEvent>,
        protected let diverged!: Bool = false,
        protected let deadlocked!: Bool = false,
        protected let pollCount!: UInt64 = 0, // cjlint-ignore !G.FUN.01 config-carrier signature: the named parameters are the structured configuration/context of this framework step; bundling them into a struct would only move the count
        protected let gridPoints!: UInt64 = 0, // cjlint-ignore !G.FUN.01 config-carrier signature: the named parameters are the structured configuration/context of this framework step; bundling them into a struct would only move the count
        internal let starvationSwitches!: UInt64 = 0, // cjlint-ignore !G.FUN.01 config-carrier signature: the named parameters are the structured configuration/context of this framework step; bundling them into a struct would only move the count
        /** Dynamically spawned actors that registered during the iteration. */
        internal let spawnedActors!: UInt64 = 0, // cjlint-ignore !G.FUN.01 config-carrier signature: the named parameters are the structured configuration/context of this framework step; bundling them into a struct would only move the count
        /**
         * The high-water mark of the virtual clock's armed-timer list in
         * this iteration (a diagnostic): bounded by the waiter count —
         * each armed wait purges the arming actor's stale entry — and
         * unbounded only if that purge regressed.
         */
        protected let timersHighWater!: Int64 = 0, // cjlint-ignore !G.FUN.01 config-carrier signature: the named parameters are the structured configuration/context of this framework step; bundling them into a struct would only move the count
        /**
         * The actor path of the wait-for cycle that aborted the
         * iteration (e.g. `[1, 0, 1]` — actor 1 waits on a key held by
         * actor 0, which waits on the future/key of actor 1). `None` when
         * no cycle was detected.
         */
        protected let deadlockCycle!: ?Array<Int64> = None // cjlint-ignore !G.FUN.01 config-carrier signature: the named parameters are the structured configuration/context of this framework step; bundling them into a struct would only move the count
    ) {}

    /** Single-line diagnostic summary. */
    public func report(): String { // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
        // cjlint-ignore -start !G.VAR.02 the variables below thread state across loop/algorithm iterations (accumulators or framework context); narrowing their scopes would change semantics
        var switches = 0
        var pcps = 0
        var blocks = 0
        var waits = 0
        var dones = 0
        var completes = 0
        var unlocks = 0
        var releases = 0
        var notifies = 0
        var notifyAlls = 0
        var spawns = 0
        var fairYields = 0
        var deadlocks = 0
        var timers = 0
        for (ev in events) {
        // cjlint-ignore -end
            match (ev.kind) {
                case Switch => switches++
                case Block => blocks++
                case Wait => waits++
                case Done => dones++
                case Complete => completes++
                case Unlock => unlocks++
                case Release => releases++
                case Notify => notifies++
                case NotifyAll => notifyAlls++
                case Spawn => spawns++
                case Pcp => pcps++
                case FairYield => fairYields++
                case Deadlock => deadlocks++
                case Timer => timers++
                case Resume => ()
            }
        }
        var maxWait = 0 // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
        for (st in waitStats()) {
            if (maxWait < st.maxWaitSpan) {
                maxWait = st.maxWaitSpan
            }
        }
        var status = if (deadlocked) { // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
            "DEADLOCKED"
        } else if (diverged) {
            "DIVERGED"
        } else {
            "ok"
        }
        if (let Some(cycle) <- deadlockCycle) {
            status += "(cycle="
            var first = true // cjlint-ignore !G.VAR.02 the variable threads state across loop/algorithm iterations (accumulator or framework context); narrowing its scope would change semantics
            for (a in cycle) {
                if (!first) {
                    status += "->"
                }
                status += "${a}"
                first = false
            }
            status += ")"
        }
        "PCT(seed=${seed}, actors=${actorCount}, pcpBudget=${pcpBudget}, " +
            "polls=${pollCount}, gridPoints=${gridPoints}, events=${events.size}: ${switches} switches, " +
            "${pcps} pcps, ${blocks} blocks, ${waits} waits, ${unlocks} unlocks, ${releases} releases, " +
            "${notifies} notifies, ${notifyAlls} notifyAlls, ${spawns} spawns, ${fairYields} fairYields, " +
            "${dones} dones, ${completes} completes, ${deadlocks} deadlocks, ${timers} timers, " +
            "${starvationSwitches} starvations, maxWait=${maxWait}, ${status})"
    }

    /**
     * Starvation accounting, one entry per referenced actor
     * slot: park counts and wait spans in decision events (see
     * `PctWaitStat`). Derived from the event log on demand — the hot path
     * records nothing extra.
     */
    protected func waitStats(): Array<PctWaitStat> { // cjlint-ignore !G.FUN.01 single cohesive algorithm block; splitting it would scatter the invariant across helpers without simplifying any step
        var slots = actorCount
        for (ev in events) {
            if (Int64(ev.from) + 1 > slots) {
                slots = Int64(ev.from) + 1
            }
            if (Int64(ev.to) + 1 > slots) {
                slots = Int64(ev.to) + 1
            }
        }
        if (slots <= 0) {
            return []
        }
        // cjlint-ignore -start !G.VAR.02 the variables below thread state across loop/algorithm iterations (accumulators or framework context); narrowing their scopes would change semantics
        let waits = Array<Int64>(slots, { _ => 0 })
        let blocks = Array<Int64>(slots, { _ => 0 })
        let totalSpan = Array<Int64>(slots, { _ => 0 })
        let maxSpan = Array<Int64>(slots, { _ => 0 })
        let open = Array<Int64>(slots, { _ => 0 })
        var i = 0
        // cjlint-ignore -end
        while (i < events.size) {
            let ev = events[i]
            if ((ev.kind == Wait || ev.kind == Block) && ev.from >= 0) {
                let a = Int64(ev.from)
                if (ev.kind == Wait) {
                    waits[a] += 1
                } else {
                    blocks[a] += 1
                }
                // The grant: the next event that picks `a` (any decision
                // whose target is `a`), or `a`'s post-deadlock Resume.
                var granted = -1
                var j = i + 1
                while (j < events.size) {
                    let g = events[j]
                    if (Int64(g.to) == a || (g.kind == Resume && Int64(g.from) == a)) {
                        granted = j
                        break
                    }
                    j++
                }
                let span = if (granted >= 0) {
                    granted - i
                } else {
                    events.size - i // never answered: the truncated span
                }
                totalSpan[a] += span
                if (span > maxSpan[a]) {
                    maxSpan[a] = span
                }
                if (granted < 0) {
                    open[a] += 1
                }
            }
            i++
        }
        let stats = Array<PctWaitStat>(slots, { i => PctWaitStat(
            actorId: Int64(i),
            waits: waits[i],
            blocks: blocks[i],
            totalWaitSpan: totalSpan[i],
            maxWaitSpan: maxSpan[i],
            openWaits: open[i]
        ) })
        return stats
    }

    /** Multi-line per-actor starvation report (see `waitStats`). */
    public func waitStatsReport(): String {
        let stats = waitStats()
        if (stats.size == 0) {
            return "wait stats: no actors"
        }
        var s = "wait stats (spans in decision events):\n"
        for (st in stats) {
            s += "  actor ${st.actorId}: waits=${st.waits} blocks=${st.blocks} " +
                "totalSpan=${st.totalWaitSpan} maxSpan=${st.maxWaitSpan} open=${st.openWaits}\n"
        }
        return s
    }
}

// ---------------------------------------------------------------------------
// The runtime contributes NO PCT surface: every scheduling decision point
// is a dispatch call made from --cj-pct-compiled user code (see the
// dispatch section of pct_coordinator.cj), and all protocol state lives in
// the Cangjie-side coordinator.
// ---------------------------------------------------------------------------
