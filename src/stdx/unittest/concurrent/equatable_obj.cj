/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2026. All rights reserved.
 * This source file is part of the Cangjie project, licensed under Apache-2.0
 * with Runtime Library Exception.
 *
 * See https://cangjie-lang.cn/pages/LICENSE for license information.
 */

package stdx.unittest.concurrent

/**
 * Type-erased bridge for comparing the results of concurrent operations.
 *
 * Operations in a scenario produce values of different types (`Int64`, `Bool`,
 * `?Int64`, ...) that must be compared against the result of the sequentially
 * re-executed operation to detect consistency violations. Because the validator
 * works with type-erased state (`Any`), it cannot directly compare two values of
 * compile-time-unknown type. `EquatableObj` provides a single `eq(other: Any): Bool`
 * entry point that each concrete carrier type implements to perform the actual
 * comparison.
 *
 * Declared as an `abstract class` (rather than an `interface`) so that it
 * satisfies the `T <: Object` constraint of `AtomicOptionReference`, which is
 * used for the lock-free memoisation cache in `PermutationNode`. Cangjie does
 * not allow interfaces to inherit classes (interfaces can only inherit
 * interfaces), so an interface cannot be made `<: Object` directly.
 */
public abstract class EquatableObj <: ToString {

    /**
     * Return `true` if `other` carries a value equal to this instance's value.
     *
     * Implementations should return `false` (rather than throw) when `other`
     * is of an incompatible carrier type. Exceptions thrown by the underlying
     * value are compared by message, so a thrown exception is one valid
     * sequential outcome.
     *
     * @param other the right-hand operand, passed as `Any`
     * @return `true` if the two carried values are considered equal
     */
    public func eq(other: Any): Bool // cjlint-ignore !G.ITF.04 type-erased equality by design: outcomes of unrelated types are compared through an Any-typed parameter
}

/**
 * Wrap a closure into an `EquatableObj` for type-erased comparison.
 *
 * The closure `f` is invoked exactly once. If it returns normally, the result
 * (which must satisfy `T <: Equatable<T>`) is wrapped in an `EqProxy<T>` whose
 * `eq` compares values with `==`. If `f` throws an `Exception`, the exception
 * is captured and wrapped in an `EqProxy<Exception>` whose `eq` compares
 * exceptions by `message`. Therefore a thrown exception is treated as one
 * possible sequential outcome rather than as a harness crash.
 *
 * Used both by the `actor` / `operation` factory helpers (to capture the
 * result of each operation lambda) and by user-supplied `sequentialSpec`
 * reference implementations (to produce the sequentially re-executed result
 * that the validator compares against the observed one).
 *
 * @param f closure whose result is `Equatable<T>` or which throws
 * @return a type-erased `EquatableObj` carrying either the result or the
 *         captured exception
 */
public func execResultOf<T>(f: () -> T): EquatableObj where T <: Equatable<T> {
    try {
        let result = f()
        EqProxy(result)
    } catch (e: Exception) {
        EqProxy(e)
    }
}


class EqProxy<T> <: EquatableObj {

    EqProxy(let value: T) {}

    public func eq(other: Any): Bool { // cjlint-ignore !G.ITF.04 type-erased equality by design: outcomes of unrelated types are compared through an Any-typed parameter
        if (let Some(other) <- (other as EqProxy<T>)) {
            return match ((value, other.value)) {
                case (e1: Exception, e2: Exception) => e1.message == e2.message
                case (_, o: Equatable<T>) => o == value
                case _ => false
            }
        }
        return false
    }

    public func toString(): String {
        match (value) {
            case v: ToString => v.toString()
            case _ => "<non-stringifiable>"
        }
    }

}