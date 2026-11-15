/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

/**
 * A named, state-aware operation to be executed by a scenario actor against the
 * shared per-iteration state of type `S`.
 *
 * Each `Operation` carries a user-supplied `body` lambda `(S) -> EquatableObj`
 * that is invoked when the operation runs. The body is wrapped via
 * `execResultOf` so that both its return value and any exception it throws are
 * captured as a type-erased `EquatableObj` for later comparison against the
 * sequentially re-executed result.
 *
 * Instances are constructed via the `operation<T>(name, body)` factory
 * functions rather than directly, so that the user can write `body` in terms of
 * its natural return type `T <: Equatable<T>` instead of `EquatableObj`.
 *
 * Used by `ScenarioBuilder.actorWithOps` (multi-op actor — operations
 * run in listed order within one thread).
 */
public class Operation<S> {
    Operation(
        let name!: String,
        let body!: (S) -> EquatableObj,
    ) {}

    func executeWrapped(state: S): EquatableObj {
        body(state)
    }
}

/**
 * Construct a stateless `Operation<Unit>` for use in capture-based scenarios.
 *
 * The `body` lambda ignores the `Unit` state placeholder and typically closes
 * over shared mutable state externally (e.g. an `AtomicInt64` declared in the
 * test scope). The returned `Operation<Unit>` is suitable for passing to
 * `ScenarioBuilder.actorWithOps` on a `ScenarioBuilder<Unit>`.
 *
 * The body's result is captured via `execResultOf`, so both its return value and
 * any thrown exception become the operation's recorded result.
 *
 * @param T result type of the body; must satisfy `T <: Equatable<T>` so that
 *          observed and sequentially re-executed results can be compared
 * @param name human-readable name shown in mismatch tables and reports
 * @param body closure that performs the operation, ignoring the `Unit` state
 * @return a named `Operation<Unit>` ready to be added to a scenario actor
 */
public func operation<T>(name: String, body: () -> T): Operation<Unit> where T <: Equatable<T> {
    Operation<Unit>(name: name) { _: Unit => execResultOf(body) }
}

/**
 * Construct a state-aware `Operation<S>` for typed per-iteration-state scenarios.
 *
 * The `body` lambda receives the per-iteration state instance of type `S`
 * (produced fresh on each iteration by `ScenarioBuilder.withState`). The
 * returned `Operation<S>` is suitable for passing to
 * `ScenarioBuilder.actorWithOps` on a `ScenarioBuilder<S>`.
 *
 * The body's result is captured via `execResultOf`, so both its return value and
 * any thrown exception become the operation's recorded result.
 *
 * @param T result type of the body; must satisfy `T <: Equatable<T>` so that
 *          observed and sequentially re-executed results can be compared
 * @param S per-iteration state type
 * @param name human-readable name shown in mismatch tables and reports
 * @param body closure that performs the operation, receiving the state `S`
 * @return a named `Operation<S>` ready to be added to a scenario actor
 */
public func operation<T, S>(name: String, body: (S) -> T): Operation<S> where T <: Equatable<T> {
    Operation<S>(name: name) { state: S => execResultOf({ => body(state) }) }
}


/**
 * Recorded form of a single operation execution, captured by the framework as
 * actors run their operation lists.
 *
 * An `OperationInvocation` records *what* ran (which actor, which operation
 * index, the operation's name), *what it returned* (as a type-erased
 * `EquatableObj` so exceptions and arbitrary equatable values are comparable),
 * and — for `Linearizability` — the vector-clock snapshots taken at the
 * operation's invocation and response, used to derive cross-thread real-time
 * happens-before edges.
 *
 * Instances are normally constructed by the framework's `ScenarioRunner` as
 * actors execute. Test code that wants to validate a manually-constructed
 * history (without running a scenario) can use the `newOperationInvocation`
 * helper from the separate test-helper package `stdx.concurrent_test_util`
 * in the cangjie_test repo (same stdx module, accessible via the test
 * suite's helpers).
 */
public class OperationInvocation {
    protected OperationInvocation(
        /**
         * Id of the actor that executed this operation (zero-based, in the order
         * actors were added to the scenario).
         */
        public let actorId!: Int64,
        /**
         * Index of this operation within its actor's operation list
         * (zero-based).
         */
        public let operationIndex!: Int64,
        /** Human-readable name of the operation, taken from `Operation.name`. */
        public let operationName!: String,
        /** Type-erased result of the operation (value or captured exception). */
        public let result!: EquatableObj,
        let invocationVC!: ?Array<Int64> = None,
        let responseVC!: ?Array<Int64> = None
    ) {}

    prop operationId: Int64 {
        get() { actorId * 1000 + operationIndex }
    }
}
