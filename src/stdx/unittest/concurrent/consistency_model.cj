/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

/**
 * Consistency model used to validate the recorded concurrent history of a scenario.
 *
 * The chosen model determines how the partial order over operation invocations is
 * derived: it constrains which permutations the consistency validator must search
 * when looking for a sequential re-execution that reproduces every observed
 * result. Stronger models admit fewer linearizations (faster validation, can
 * detect more bugs) but reject more concurrent executions (may flag valid
 * non-sequentially-consistent designs as violations).
 *
 * The three supported models, from strongest to weakest:
 * - `Linearizability` — preserves per-actor program order *and* cross-thread
 *   real-time happens-before edges (captured via vector clocks at each
 *   operation's invocation and response).
 * - `SequentialConsistency` — preserves per-actor program order only.
 * - `Serializability` — preserves nothing; the validator searches *every*
 *   permutation of the operations. Useful for data structures whose methods are
 *   intentionally not sequentially consistent (e.g. a stale `size` on a
 *   concurrent queue).
 * - `NoValidation` — validation disabled: no consistency validator is built
 *   at all (not the auto validator that `.reset`/`.withState` would trigger,
 *   and not one registered via `sequentialSpec`). The scenario still runs its
 *   per-iteration reset/state/after/verify cycle; only the recorded-history
 *   validation is skipped. Use this for coverage-style harnesses on
 *   deliberately buggy SUTs (every violating window is a finding to record,
 *   not a reason to stop the exploration), or when the per-window
 *   re-execution cost is unwanted.
 *
 * Hierarchy: a history that is linearizable is also sequentially consistent and
 * serializable; a history that is sequentially consistent is also serializable.
 * Therefore `lin.passed ⇒ sc.passed ⇒ ser.passed`.
 */
public enum ConsistencyModel {
    /// Preserve per-actor program order only. Cross-thread real-time ordering is
    /// not enforced, so two operations that overlap in real time may be reordered
    /// relative to each other in the linearization.
    | SequentialConsistency
    /// Strongest model: preserve per-actor program order *and* cross-thread
    /// real-time happens-before (captured via per-operation vector clocks).
    /// Required to detect store-buffer effects and other real-time-ordering bugs.
    | Linearizability
    /// Weakest model: derive an empty partial order so the validator searches
    /// every permutation of the operations. Use this when the SUT's methods are
    /// intentionally not sequentially consistent (e.g. a `size` method that may
    /// return a stale or future value under concurrent modification).
    | Serializability
    /// Validation disabled: no consistency validator is built (see the enum
    /// kdoc). The scenario-level reset/state machinery still runs — this only
    /// opts out of the per-window recorded-history validation.
    | NoValidation
}

protected func modelCapitalizedName(model: ConsistencyModel): String {
    match (model) {
        case SequentialConsistency => "Sequentially consistent"
        case Linearizability => "Linearizable"
        case Serializability => "Serializable"
        case NoValidation => "Not validated"
    }
}

protected func modelNotName(model: ConsistencyModel): String {
    match (model) {
        case SequentialConsistency => "NOT sequentially consistent"
        case Linearizability => "NOT linearizable"
        case Serializability => "NOT serializable"
        case NoValidation => "not validated"
    }
}