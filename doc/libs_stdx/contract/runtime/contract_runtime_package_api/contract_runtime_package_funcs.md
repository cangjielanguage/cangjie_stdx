# 函数

## func contractCaptureSnapshot\<T>(Bool, () -> T)

```cangjie
public func contractCaptureSnapshot<T>(enabled: Bool, evaluate: () -> T): ?T
```

功能：在契约检查开启时捕获入口状态快照，否则返回 `None`。仅在构造函数契约的 `$pre` 表达式展开中使用（函数契约的 `$pre` 快照由普通局部绑定实现，不经过本函数）。

> **说明：**
>
> 该函数仅供宏展开产物使用，用户不应直接调用。

参数：

- enabled: Bool - 是否启用检查。
- evaluate: () -> T - 捕获快照时执行的求值函数。

返回值：

- ?T - `enabled` 为 `true` 时返回 `Some(evaluate())`，否则返回 `None`。

## func contractGhostGet\<T>(?T, String)

```cangjie
public func contractGhostGet<T>(holder: ?T, name: String): T
```

功能：读取辅助变量的值，`holder` 为 `None`（变量未初始化）时抛出 [ContractCheckGhostStateException](./contract_runtime_package_exceptions.md#class-contractcheckghoststateexception)。主要供宏展开后的代码使用，用户不应直接调用。

参数：

- holder: ?T - 辅助变量的存储槽。
- name: String - 辅助变量名，用于异常信息定位。

返回值：

- T - 辅助变量的当前值。

## func contractEvalEnter()

```cangjie
public func contractEvalEnter(): Unit
```

功能：进入契约表达式求值，将当前线程的求值深度加一。需要与 [contractEvalExit](#func-contractevalexit) 配对使用，通常放在 `finally` 中。

> **说明：**
>
> 该函数仅供宏展开产物使用，用户不应直接调用。

## func contractEvalExit()

```cangjie
public func contractEvalExit(): Unit
```

功能：退出契约表达式求值，将当前线程的求值深度减一。深度归零后，[contractInEvaluation](#func-contractinevaluation) 返回 `false`。若当前线程深度已为 `0`（无匹配的进入调用，例如契约求值跨挂起点发生线程迁移后），本函数安静地忽略并清除标记，不抛出异常，以免 `finally` 中的退出调用覆盖正在传播的业务异常。

> **说明：**
>
> 该函数仅供宏展开产物使用，用户不应直接调用。

## func contractInEvaluation()

```cangjie
public func contractInEvaluation(): Bool
```

功能：判断当前线程是否处于契约表达式求值过程中。

> **说明：**
>
> 该函数仅供宏展开产物使用，用户不应直接调用。

返回值：

- Bool - 当前线程的契约求值深度大于 `0` 时返回 `true`，否则返回 `false`。

## func contractCheckEnabled()

```cangjie
public func contractCheckEnabled(): Bool
```

功能：返回契约检查当前是否生效。编译期由条件编译变量 `contract_check` 决定开关基态（随 stdx 发布的运行时默认为开启）；编译期开启时返回 `true`，且可通过 [disableContractChecks](#func-disablecontractchecks) 运行期单向降级为 `false`；编译期关闭时恒返回 `false`，不涉及运行期降级状态。

> **说明：**
>
> 该函数仅供宏展开产物使用，用户不应直接调用。

返回值：

- Bool - 契约检查当前生效时返回 `true`（编译期开启且未被运行期降级），否则返回 `false`。

## func disableContractChecks()

```cangjie
public func disableContractChecks(): Unit
```

功能：单向关闭本进程内后续所有契约检查。调用后本进程内所有检查点直接跳过，且**不可重新开启**——库不提供任何恢复检查的 API，保证进程内行为单调弱化：要么全程检查、要么只检查到降级点，同一次调用不会因开关状态不同而时抛异常时不抛异常。

该函数线程安全（原子写）且幂等，可安全地多次调用。

> **说明：**
>
> 在以 `contract_check = "off"` 编译的运行时中，契约检查本就不存在，该函数为空操作。

## func \_contract_gateEnabled()

```cangjie
public func _contract_gateEnabled(): Bool
```

功能：每个契约检查点的门函数，检查生效（见 [contractCheckEnabled](#func-contractcheckenabled)）且当前线程不处于契约表达式求值过程中时返回 `true`。内部 API，仅供宏展开产物使用；受编译期 `contract_check` 控制。用户不应直接调用。

> **说明：**
>
> 该函数为内部 API，仅供宏展开产物使用；宏展开生成的检查点只调用该函数，用户定义的同名函数不会与宏识别冲突。

返回值：

- Bool - 检查生效且当前线程不在契约求值中时返回 `true`，否则返回 `false`。

## func isContractException(Exception)

```cangjie
public func isContractException(exception: Exception): Bool
```

功能：判断异常是否为契约异常。契约异常包括 [ContractCheckRequiresException](./contract_runtime_package_exceptions.md#class-contractcheckrequiresexception)、[ContractCheckEnsuresException](./contract_runtime_package_exceptions.md#class-contractcheckensuresexception)、[ContractCheckThrowsException](./contract_runtime_package_exceptions.md#class-contractcheckthrowsexception)、[ContractCheckAssertException](./contract_runtime_package_exceptions.md#class-contractcheckassertexception)、[ContractCheckLoopInvariantException](./contract_runtime_package_exceptions.md#class-contractcheckloopinvariantexception)、[ContractCheckInvariantException](./contract_runtime_package_exceptions.md#class-contractcheckinvariantexception) 和 [ContractCheckGhostStateException](./contract_runtime_package_exceptions.md#class-contractcheckghoststateexception)。

参数：

- exception: Exception - 待判断的异常。

返回值：

- Bool - 是契约异常时返回 `true`，否则返回 `false`。
