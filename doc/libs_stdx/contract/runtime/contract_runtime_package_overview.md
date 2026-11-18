# stdx.contract.runtime

## 功能介绍

contract.runtime 包提供契约检查的运行时支撑，包括：

- **检查开关**（`contractCheckEnabled`）：返回契约检查是否处于生效状态（编译期由条件编译变量 `contract_check` 决定基态，可被运行期一次性降级），仅供宏展开产物使用，用户不应直接调用；
- **运行期降级**（`disableContractChecks`）：关闭本进程内后续所有契约检查，单向、线程安全、幂等；
- **契约异常类**：公共基类 [ContractCheckException](./contract_runtime_package_api/contract_runtime_package_exceptions.md#abstract-class-contractcheckexception) 及 7 个契约检查失败时抛出的异常，基类继承自 `Exception`；
- **契约异常判定**（`isContractException`）：判断一个异常是否为契约异常；
- **运行时辅助函数**（`contractEvalEnter`、`contractEvalExit`、`contractInEvaluation`、`contractCaptureSnapshot`、`contractGhostGet`）：主要供宏展开后的代码使用，用户不应直接调用；
- **可见性枚举**（`ContractVisibility`）：用于比较契约检查所需的成员可见性。

契约的声明请使用 [stdx.contract.macros](../contract_package_api/contract_package_macros.md) 包中的宏。契约检查开关分两层：**编译期**由条件编译变量 `contract_check` 在编译 `stdx.contract.runtime` 包时决定并固化，默认开启（该包源码目录下的 `cfg.toml` 声明 `contract_check = "on"`；cjc 构建时读取当前工作目录下的 `cfg.toml`，cjpm 构建同样读取，`--cfg` 优先级更高），要编译出零检查开销的制品，需以 `cjc --cfg "contract_check=off" ...` 重新构建该包；**运行期**支持一次性降级，调用 [disableContractChecks](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-disablecontractchecks) 即关闭本进程内后续所有检查点，降级单向、不可重新开启。

## API 列表

### 函数

| 函数名 | 功能 |
| --- | --- |
| [contractCaptureSnapshot](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-contractcapturesnapshot) | 在检查开启时捕获入口快照，否则返回 `None`。 |
| [contractCheckEnabled](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-contractcheckenabled) | 返回契约检查是否处于生效状态（仅供宏展开产物使用）。 |
| [disableContractChecks](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-disablecontractchecks) | 单向关闭本进程内后续所有契约检查（线程安全、幂等）。 |
| [contractGhostGet](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-contractghostget) | 读取辅助变量，未初始化时抛出 `ContractCheckGhostStateException`。 |
| [contractEvalEnter](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-contractevalenter) | 进入契约表达式求值，增加当前线程的求值深度。 |
| [contractEvalExit](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-contractevalexit) | 退出契约表达式求值，减少当前线程的求值深度。 |
| [contractInEvaluation](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-contractinevaluation) | 判断当前线程是否处于契约表达式求值过程中。 |
| [_contract_gateEnabled](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-contract-gateenabled) | 每个检查点的门函数：检查生效且当前线程不在契约求值中时返回 `true`（内部 API，仅供宏展开产物使用；受编译期 `contract_check` 控制）。 |
| [isContractException](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-iscontractexception) | 判断异常是否为契约异常。 |

### 枚举

| 枚举名 | 功能 |
| --- | --- |
| [ContractVisibility](./contract_runtime_package_api/contract_runtime_package_enums.md#enum-contractvisibility) | 契约检查使用的成员可见性顺序。 |

### 异常类

| 异常类名 | 功能 |
| --- | --- |
| [ContractCheckException](./contract_runtime_package_api/contract_runtime_package_exceptions.md#abstract-class-contractcheckexception) | 全部契约异常的公共基类（抽象类），可统一捕获。 |
| [ContractCheckGhostStateException](./contract_runtime_package_api/contract_runtime_package_exceptions.md#class-contractcheckghoststateexception) | 辅助变量在初始化前被契约读取时抛出的异常。 |
| [ContractCheckAssertException](./contract_runtime_package_api/contract_runtime_package_exceptions.md#class-contractcheckassertexception) | 断言检查失败时抛出的异常。 |
| [ContractCheckEnsuresException](./contract_runtime_package_api/contract_runtime_package_exceptions.md#class-contractcheckensuresexception) | 后置条件检查失败时抛出的异常。 |
| [ContractCheckInvariantException](./contract_runtime_package_api/contract_runtime_package_exceptions.md#class-contractcheckinvariantexception) | 类型不变式检查失败时抛出的异常。 |
| [ContractCheckLoopInvariantException](./contract_runtime_package_api/contract_runtime_package_exceptions.md#class-contractcheckloopinvariantexception) | 循环不变式检查失败时抛出的异常。 |
| [ContractCheckRequiresException](./contract_runtime_package_api/contract_runtime_package_exceptions.md#class-contractcheckrequiresexception) | 前置条件检查失败时抛出的异常。 |
| [ContractCheckThrowsException](./contract_runtime_package_api/contract_runtime_package_exceptions.md#class-contractcheckthrowsexception) | 异常契约检查失败时抛出的异常。 |
