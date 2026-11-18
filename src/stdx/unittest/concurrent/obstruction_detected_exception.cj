/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

/**
 * Thrown by the scheduler (DPOR windows with
 * `ObstructionPolicy.ThrowObstruction`) when an operation is detected to be
 * obstructed: its actor accumulated `threshold` consecutive scheduling
 * checks waiting for a gated peer the scheduler never grants — the guided
 * ordering makes this operation a dead end.
 *
 * This is the throw-instead-of-fair-yield semantics for the starvation
 * recovery point (`PctBaseScheduler.noteGridContinue`): instead of
 * abandoning the guide and fair-yielding (a schedule event the guide never
 * decided — one that corrupts the POP sleep-set characterization's
 * already-explored bookkeeping), the operation ends here and
 * the exception unwinds through the user's operation frame to the per-op
 * capture (`execResultOf` at the scenario level), where it becomes the
 * operation's recorded result and the actor proceeds to its next
 * operation — a per-operation bounded wait:
 * - no token is transferred and no schedule event is added, so the
 *   schedule stays a pure function of the guide (replay re-derives the
 *   throw from the streak counter deterministically);
 * - the information is preserved as an outcome ("this ordering obstructs
 *   the operation") instead of being silently resolved by a forced
 *   interleaving.
 *
 * PCT windows never throw this: the PCT scheduler is always built with
 * `ObstructionPolicy.YieldFairly` (the fair-mode yield — PCT's liveness
 * mechanism). The package-internal `runDporWindowStepped` driver with
 * raw op closures performs no per-op capture, so an obstruction
 * exception aborts the actor there; only the scenario API turns it
 * into a per-op result.
 *
 * Catchable by user code (e.g. to distinguish obstruction from a SUT's own
 * exceptions when decoding outcomes); the message is deterministic
 * (a function of the actor id and the streak counter, both
 * schedule-stable), so equal obstruction outcomes compare equal through
 * `execResultOf`.
 */
public class ObstructionDetectedException <: Exception {
    /** The actor (slot index) whose operation was obstructed. */
    public let actorId: Int64
    /** The consecutive scheduling checks the operation accumulated. */
    public let polls: UInt64
    /** The configured starvation threshold — the bounded-wait budget per operation. */
    public let threshold: UInt64

    public init(actorId!: Int64, polls!: UInt64, threshold!: UInt64) {
        super("obstruction detected: actor ${actorId} made ${polls} consecutive " +
            "scheduling checks (threshold ${threshold}) waiting for a gated peer; " +
            "the scheduled ordering obstructs this operation")
        this.actorId = actorId
        this.polls = polls
        this.threshold = threshold
    }
}

/**
 * What the scheduler does at the starvation recovery point — an unbroken
 * grid-poll run means the running operation waits for a peer the scheduler
 * never grants (non-obstruction-freedom under the current ordering):
 * - `YieldFairly` — switch the iteration to fair scheduling and
 *   voluntary-yield at the grid point (a guide-foreign token transfer
 *   that explores past the wall). The PCT scheduler is always built
 *   with this policy (its liveness mechanism); DPOR windows can select
 *   it to use the fair-yield recovery instead.
 * - `ThrowObstruction` — throw `ObstructionDetectedException` instead
 *   (see the class doc: the operation ends as a bounded wait, the guide
 *   stays pure). The default for DPOR windows
 *   (`DporWindowConfig.obstructionPolicy`).
 */
public enum ObstructionPolicy <: Equatable<ObstructionPolicy> & ToString {
    | YieldFairly
    | ThrowObstruction

    public override operator func ==(other: ObstructionPolicy): Bool { // cjlint-ignore !G.OPR.01 parameterless enum: the language requires this manual == to satisfy Equatable<T>; match-based constructor comparison is the only possible implementation
        match ((this, other)) {
            case (YieldFairly, YieldFairly) => true
            case (ThrowObstruction, ThrowObstruction) => true
            case _ => false
        }
    }

    public func toString(): String {
        match (this) {
            case YieldFairly => "fair-yield"
            case ThrowObstruction => "throw-obstruction"
        }
    }
}
