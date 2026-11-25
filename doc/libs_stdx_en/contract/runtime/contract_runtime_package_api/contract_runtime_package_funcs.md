# Functions

## func contractCaptureSnapshot\<T>(Bool, () -> T)

```cangjie
public func contractCaptureSnapshot<T>(enabled: Bool, evaluate: () -> T): ?T
```

Function: Captures a snapshot of the entry state when contract checking is enabled; otherwise returns `None`. It is used only in the expansion of `$pre` expressions in constructor contracts (the `$pre` snapshots of function contracts are plain local bindings and do not go through this function).

> **Note:**
>
> This function is intended only for use by macro expansion output; users should not call it directly.

Parameters:

- enabled: Bool - Whether checking is enabled.
- evaluate: () -> T - The evaluation function executed when the snapshot is captured.

Return Value:

- ?T - Returns `Some(evaluate())` when `enabled` is `true`; otherwise returns `None`.

## func contractGhostGet\<T>(?T, String)

```cangjie
public func contractGhostGet<T>(holder: ?T, name: String): T
```

Function: Reads the value of an auxiliary variable, throwing [ContractCheckGhostStateException](./contract_runtime_package_exceptions.md#class-contractcheckghoststateexception) when `holder` is `None` (the variable is uninitialized). It is mainly intended for use by macro-expanded code; users should not call it directly.

Parameters:

- holder: ?T - The storage slot of the auxiliary variable.
- name: String - The name of the auxiliary variable, used for locating it in exception messages.

Return Value:

- T - The current value of the auxiliary variable.

## func contractEvalEnter()

```cangjie
public func contractEvalEnter(): Unit
```

Function: Enters contract expression evaluation, incrementing the evaluation depth of the current thread. It must be used in pairs with [contractEvalExit](#func-contractevalexit), usually placed in a `finally` block.

> **Note:**
>
> This function is intended only for use by macro expansion output; users should not call it directly.

## func contractEvalExit()

```cangjie
public func contractEvalExit(): Unit
```

Function: Exits contract expression evaluation, decrementing the evaluation depth of the current thread. Once the depth reaches zero, [contractInEvaluation](#func-contractinevaluation) returns `false`. If the depth of the current thread is already `0` (no matching enter call, for example after a thread migration moved the evaluation across a suspension point), the call is quietly ignored and the flag is cleared instead of throwing, so that the exit emitted in a `finally` block cannot replace a business exception being propagated.

> **Note:**
>
> This function is intended only for use by macro expansion output; users should not call it directly.

## func contractInEvaluation()

```cangjie
public func contractInEvaluation(): Bool
```

Function: Determines whether the current thread is inside contract expression evaluation.

> **Note:**
>
> This function is intended only for use by macro expansion output; users should not call it directly.

Return Value:

- Bool - Returns `true` when the contract evaluation depth of the current thread is greater than `0`; otherwise returns `false`.

## func contractCheckEnabled()

```cangjie
public func contractCheckEnabled(): Bool
```

Function: Returns whether contract checking is currently active. The compile-time base state is determined by the conditional compilation variable `contract_check` (enabled by default in the runtime shipped with stdx); it returns `true` when checking was compiled in, and can be demoted one-way to `false` at runtime through [disableContractChecks](#func-disablecontractchecks). When checking was compiled out, it always returns `false` and no runtime demotion state is involved.

> **Note:**
>
> This function is intended only for use by macro expansion output; users should not call it directly.

Return Value:

- Bool - Returns `true` when contract checking is currently active (compiled in and not demoted at runtime); otherwise returns `false`.

## func disableContractChecks()

```cangjie
public func disableContractChecks(): Unit
```

Function: One-way disabling of all subsequent contract checks in the process. After the call, every check point in the process is skipped, and checking **cannot be re-enabled** — the library provides no API to restore checking, guaranteeing that in-process behavior is monotonically weakened: either fully checked, or checked only up to the demotion point, and the same call can never flip between throwing and not throwing depending on the switch state.

The function is thread-safe (atomic store) and idempotent; calling it multiple times is safe.

> **Note:**
>
> In a runtime compiled with `contract_check = "off"`, contract checking does not exist in the first place, and this function is a no-op.

## func \_contract_gateEnabled()

```cangjie
public func _contract_gateEnabled(): Bool
```

Function: The gate function of every contract check point; returns `true` when checking is active (see [contractCheckEnabled](#func-contractcheckenabled)) and the current thread is not inside contract expression evaluation. Internal API, intended only for use by macro expansion output, controlled by the compile-time `contract_check`, and users should not call it directly; the check points generated by macro expansion call only this function, so a user-defined function of the same name cannot collide with macro recognition.

Return Value:

- Bool - Returns `true` when checking is active and the current thread is not inside contract evaluation; otherwise returns `false`.

## func isContractException(Exception)

```cangjie
public func isContractException(exception: Exception): Bool
```

Function: Determines whether an exception is a contract exception. Contract exceptions include [ContractCheckRequiresException](./contract_runtime_package_exceptions.md#class-contractcheckrequiresexception), [ContractCheckEnsuresException](./contract_runtime_package_exceptions.md#class-contractcheckensuresexception), [ContractCheckThrowsException](./contract_runtime_package_exceptions.md#class-contractcheckthrowsexception), [ContractCheckAssertException](./contract_runtime_package_exceptions.md#class-contractcheckassertexception), [ContractCheckLoopInvariantException](./contract_runtime_package_exceptions.md#class-contractcheckloopinvariantexception), [ContractCheckInvariantException](./contract_runtime_package_exceptions.md#class-contractcheckinvariantexception), and [ContractCheckGhostStateException](./contract_runtime_package_exceptions.md#class-contractcheckghoststateexception).

Parameters:

- exception: Exception - The exception to check.

Return Value:

- Bool - Returns `true` if the exception is a contract exception; otherwise returns `false`.
