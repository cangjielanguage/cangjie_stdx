/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.contract.runtime

import std.sync.{AtomicBool}

/**
 * @brief The common base class of all contract-check failures.
 *
 * Contract violations raised by `@Contract`-generated checks are reported through
 * subclasses of this type. Being abstract only prevents direct instantiation; contract
 * failures bypass business-exception `throws` verification, so the class does not
 * prevent forging through subclassing either. Use `isContractException` to check
 * whether an exception is a contract exception, or catch all contract failures
 * uniformly with this type in a `try/catch`.
 */
public abstract class ContractCheckException <: Exception {
    public init() { super() }
    public init(message: String) { super(message) }
}

/**
 * @brief Thrown when a precondition (`requires`) check fails; the exception message
 * has the format `requires failed in <function name>: <clause>`.
 */
public class ContractCheckRequiresException <: ContractCheckException {
    public init(message!: String = "ContractCheckRequiresException") {
        super(message)
    }
}

/**
 * @brief Thrown when a postcondition (`ensures`) check fails; the exception message
 * has the format `ensures failed in <function name>: <clause>`.
 */
public class ContractCheckEnsuresException <: ContractCheckException {
    public init(message!: String = "ContractCheckEnsuresException") {
        super(message)
    }
}

/**
 * @brief Thrown when an exception contract (`throws`) check fails.
 *
 * When the clause condition holds but the required exception is not thrown, `cause`
 * is `None` and the message has the format `throws failed in <function name>:
 * required exception was not thrown; clauses:\n<clause>`. When a mismatched exception
 * is thrown, `cause` is the original exception and the message ends with
 * `unexpected exception; clauses:\n<clause>cause: `.
 */
public class ContractCheckThrowsException <: ContractCheckException {
    /// The original exception wrapped on a type mismatch; None when the function
    /// returns normally and causes the contract to fail.
    public let cause: ?Exception

    public init(message!: String = "ContractCheckThrowsException", cause!: ?Exception = None) {
        super(message)
        this.cause = cause
    }
}

/**
 * @brief Thrown when an assertion declared by `@contractAssert` fails its check; the
 * exception message has the format `assertion failed: <assertion expression>`.
 */
public class ContractCheckAssertException <: ContractCheckException {
    public init(message!: String = "ContractCheckAssertException") {
        super(message)
    }
}

/**
 * @brief Thrown when a loop invariant declared by `@loopInvariant` fails its check;
 * the exception message has the format `loop invariant failed: <invariant expression>`.
 */
public class ContractCheckLoopInvariantException <: ContractCheckException {
    public init(message!: String = "ContractCheckLoopInvariantException") {
        super(message)
    }
}

/**
 * @brief Thrown when a type invariant check fails; the exception message has the
 * format `invariant failed in <type name>: <clause>`.
 */
public class ContractCheckInvariantException <: ContractCheckException {
    public init(message!: String = "ContractCheckInvariantException") {
        super(message)
    }
}

/**
 * @brief Thrown when a contract check reads an auxiliary variable (ghost variable /
 * abstract state) before it was initialized.
 *
 * Sources include: a function-level or type-level auxiliary variable read by another
 * contract expression before being assigned, and the stored value of a property
 * (ghost property/abstract property) read before being initialized. In the
 * function-level scenario the message has the format ``contract variable
 * `<variable name>` is used before it is initialized``.
 */
public class ContractCheckGhostStateException <: ContractCheckException {
    public init(message!: String = "ContractCheckGhostStateException") {
        super(message)
    }
}

/**
 * @brief Determines whether an exception is a contract exception, i.e. any subclass of
 * `ContractCheckException`.
 *
 * Contract exceptions are exempt from business-exception `throws` verification, so
 * callers can use this predicate to recognize them reliably.
 *
 * @param exception The exception to check.
 * @return true if the exception is a contract exception, false otherwise.
 */
public func isContractException(exception: Exception): Bool {
    exception is ContractCheckException
}

// Global switch base state: selected at compile time through the `contract_check` conditional
// compilation variable (see the two `contractCheckEnabled` variants below). Runtime demotion
// is available only when checking is compiled in; a compiled-out binary can never check
// (or un-check) at runtime.

// Per-thread nesting depth for contract expressions.
private let _CONTRACT_EVALUATION_DEPTH = ThreadLocal<Int64>()

// One-time diagnostic latch for the underflow in `contractEvalExit`; an atomic bit makes the
// latch fire exactly once even when several threads observe the underflow concurrently.
private let _EVAL_UNDERFLOW_WARNED = AtomicBool(false)

// Runtime demotion latch for contract checking. One-way by design: once stored, checks stay
// off for the rest of the process, so in-process behavior is monotonically weakened — a run
// is either fully checked or checked only up to the demotion point, never flapping between
// the two. The latch is read on every gate call when checking is compiled in; compiled-out
// builds short-circuit on the `_checkContractEnabled` constant before touching it.
private let _RUNTIME_DISABLED = AtomicBool(false)

/**
 * @brief Disables all contract checks for the rest of the process.
 *
 * One-way demotion: no API re-enables checking, so the same call never flips between
 * throwing and not throwing within a run, and a state corrupted while checks were off
 * can never be re-armed by turning checking back on — in-process behavior is
 * monotonically weakened. Thread-safe (atomic store) and idempotent; calling it
 * multiple times is safe.
 *
 * Available only when the runtime was built with checking compiled in
 * (`contract_check = "on"`, the shipped default); in a compiled-out build this function
 * is a no-op because checking can never be active there anyway.
 */
public func disableContractChecks(): Unit {
    _RUNTIME_DISABLED.store(true)
}

/**
 * @brief Enters one contract-expression evaluation.
 *
 * Raises the per-thread re-entrancy depth so nested contract checks (from callables
 * the expression invokes) are skipped. Must be paired with `contractEvalExit` in
 * `finally`, which the generated code always emits. For macro expansion products only;
 * users should not call it directly.
 */
public func contractEvalEnter(): Unit {
    let depth = _CONTRACT_EVALUATION_DEPTH.get() ?? 0
    _CONTRACT_EVALUATION_DEPTH.set(Some(depth + 1))
}

/**
 * @brief Leaves one contract-expression evaluation; see `contractEvalEnter`.
 *
 * Generated code emits the exit inside `finally`, so a depth underflow (e.g. after a
 * thread migration moved the evaluation to another thread) must not raise here: an
 * exception thrown from `finally` would replace the business exception that is being
 * propagated. An underflow is therefore absorbed: the flag is cleared and a one-time
 * warning is printed to stderr so that silently skipped contract checks stay
 * diagnosable. For macro expansion products only; users should not call it directly.
 */
public func contractEvalExit(): Unit {
    let depth = _CONTRACT_EVALUATION_DEPTH.get() ?? 0
    if (depth == 0) {
        if (_EVAL_UNDERFLOW_WARNED.compareAndSwap(false, true)) {
            // Best-effort diagnostic; never let it escape into `finally`.
            // Plain `println` (stdout): `Console` is not available in every toolchain's `std.env`.
            try {
                println(
                    "[stdx.contract] WARNING: contractEvalExit underflow; contract checks on " +
                    "this thread may be silently skipped (hint: a contract expression may " +
                    "have migrated across threads)")
            } catch (e: Exception) {
                ()
            }
        }
        _CONTRACT_EVALUATION_DEPTH.set(None)
    } else if (depth > 1) {
        _CONTRACT_EVALUATION_DEPTH.set(Some(depth - 1))
    } else {
        _CONTRACT_EVALUATION_DEPTH.set(None)
    }
}

/**
 * @brief Whether the current thread is inside a contract-expression evaluation.
 *
 * For macro expansion products only; users should not call it directly.
 *
 * @return true when the contract evaluation depth of the current thread is greater
 * than zero, false otherwise.
 */
public func contractInEvaluation(): Bool {
    (_CONTRACT_EVALUATION_DEPTH.get() ?? 0) > 0
}

/**
 * @brief Captures a snapshot of the entry state when contract checking is enabled;
 * otherwise returns `None`, so the caller does not need to provide a default value.
 *
 * Used only in the expansion of `$pre` expressions in constructor contracts (the
 * `$pre` snapshots of function contracts are plain local bindings and do not go
 * through this function). For macro expansion products only; users should not call it
 * directly.
 *
 * @param enabled Whether the check point that needs the snapshot is active.
 * @param evaluate The evaluation executed when the snapshot is captured.
 * @return Some(evaluate()) when enabled is true, None otherwise.
 */
public func contractCaptureSnapshot<T>(enabled: Bool, evaluate: () -> T): ?T {
    if (enabled) {
        Some(evaluate())
    } else {
        None
    }
}

/**
 * @brief Reads a function- or constructor-level auxiliary (ghost) variable.
 *
 * For macro expansion products only; users should not call it directly.
 *
 * @param holder The storage slot of the auxiliary variable.
 * @param name The name of the auxiliary variable, used for locating it in the
 * exception message.
 * @return The current value of the auxiliary variable.
 * @throws ContractCheckGhostStateException if the variable was never initialized,
 * which is a ghost-state violation.
 */
public func contractGhostGet<T>(holder: ?T, name: String): T {
    match (holder) {
        case Some(value) => value
        case None => throw ContractCheckGhostStateException(
            message: "contract variable `${name}` is used before it is initialized")
    }
}

/**
 * @brief Whether contract checking is currently active: compiled in by the
 * `contract_check` conditional compilation variable AND not demoted at runtime through
 * `disableContractChecks`. For macro expansion products only; users should not call it
 * directly.
 *
 * @return true when contract checking is currently active (compiled in and not demoted
 * at runtime), false otherwise.
 */
@When[contract_check == "on"]
public func contractCheckEnabled(): Bool {
    !_RUNTIME_DISABLED.load()
}

/**
 * @brief Compiled-out variant of `contractCheckEnabled`: with checking compiled out it
 * degenerates into the compile-time constant `false` with no runtime cost. For macro
 * expansion products only; users should not call it directly.
 *
 * @return false, always.
 */
@When[contract_check != "on"]
public func contractCheckEnabled(): Bool {
    false
}

/**
 * @brief Combined eligibility gate emitted by macro expansion at every check point:
 * checks apply only when contract checking is active (see `contractCheckEnabled`) AND
 * the current thread is not already inside another contract-expression evaluation.
 *
 * Generated code calls only this wrapper (never `contractCheckEnabled`/
 * `contractInEvaluation` directly), and macro-side recognition matches this unique
 * `_contract_`-reserved-prefix name alone, so user-defined functions cannot collide
 * with the recognition. When checking is compiled out, the compile-time `false`
 * short-circuits before the evaluation-depth lookup. Internal API, for macro expansion
 * products only; users should not call it directly.
 *
 * @return true when checking is active and the current thread is not inside contract
 * evaluation, false otherwise.
 */
public func _contract_gateEnabled(): Bool { // cjlint-ignore !G.NAM.04
    contractCheckEnabled() && !contractInEvaluation()
}
