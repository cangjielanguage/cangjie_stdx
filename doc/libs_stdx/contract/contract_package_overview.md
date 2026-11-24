# stdx.contract

## 功能介绍

contract 包基于契约式设计（Design by Contract）思想，为仓颉语言提供运行期契约检查能力。开发者可以在函数、属性、类型和循环上声明契约子句，由运行时在检查开启时自动校验这些契约，从而在开发与测试阶段尽早发现违反约定的调用或实现。

contract 包由两个子包组成：

- [stdx.contract.macros](./contract_package_api/contract_package_macros.md)：提供 `@Contract`、`@ghost`、`@contractAssert`、`@loopInvariant` 等宏，是声明契约的入口；
- [stdx.contract.runtime](./runtime/contract_runtime_package_overview.md)：提供契约检查开关、契约异常类型及运行时辅助函数。

### 契约种类

| 契约 | 声明位置 | 关键字 | 说明 |
| --- | --- | --- | --- |
| 前置条件 | 函数、属性 | `requires` | 调用方必须满足的条件，在函数体执行前检查。 |
| 后置条件 | 函数、属性 | `ensures` | 函数返回时必须满足的条件，可用 `ensures r:` 绑定返回值。 |
| 异常契约 | 函数、属性 | `throws` | 声明在满足条件时必须抛出的异常类型。 |
| 类型不变式 | class、struct、interface | `invariant` | 类型实例在其公开接口被调用前后必须保持的条件。 |
| 抽象状态 | class、struct、interface、函数契约 | `variable` | 为类型（尤其是接口）声明可供契约引用的抽象状态；也可在函数契约中声明供其他子句引用的函数级辅助变量。 |
| 契约继承 | class、struct、interface | `inherits from` / `inherits <种类> <父类型>.<名称>` | 默认不继承父契约；`inherits from` 复用父类型声明的全部契约，`inherits requires/ensures/throws/variable/invariant` 选择性继承单个命名契约（可重命名）；类级 `variable` 总是自动继承。跨包场景见下文「跨包契约继承」。 |
| 函数体断言 | 函数体 | `@contractAssert` | 在函数体内部任意位置检查的断言。 |
| 循环不变式 | 函数体 | `@loopInvariant` | 在循环的检查点必须成立的条件。 |
| 幽灵代码 | 函数体 | `@ghost` | 仅用于维护抽象状态、不参与业务逻辑的辅助代码。 |

extend 类型上的 @Contract 仅用于承载成员级契约：其成员函数/属性可标注 @Contract 声明 `requires`/`ensures`/`throws` 等成员级子句（成员也可用 `inherits` 选择性继承成员契约）；extend 自身不支持任何类型级子句（`variable`、`invariant`、`inherits`），`@Contract` 的子句列表必须为空，否则宏展开报编译错误。

直接在类型成员上标注 `@Contract`（外层类型未声明类型级 `@Contract`）时，宏展开只能看到该成员自身，无法感知外层类型的成员列表：函数级 `variable` 声明的名称若与外层类型的成员同名，实现体内的裸名读取会按函数级辅助变量求值（类型级路径对同一情形会直接报编译 ERROR）。请避免这种同名，或将契约声明在外层类型的 `@Contract` 上。

宏在 token 层面分析 `match` 的 `case` 模式，用于识别会被契约改写波及的绑定名：`case Red =>` 这类无载荷枚举构造器与同名绑定在 token 层无法区分，会被按绑定名收集（宁可过报）。因此契约子句声明的辅助变量若与某个 `case` 构造器同名，该构造器名也会被改写。请避免同名，或为构造器路径加限定（如 `Color.Red`）。

上述子句的完整文法（如 `[名称]` 命名、`ensures r:` 返回值绑定、`$pre(...)` 入口快照引用、主构造函数上的契约等）见 [stdx.contract.macros](./contract_package_api/contract_package_macros.md) 中 `@Contract` 宏的说明。

`@ghost`、`@contractAssert`、`@loopInvariant` 均不要求宿主函数标注 `@Contract`：未标注时宏同样展开，执行仅受 `contract_check` 开关门控（检查开启时执行）。

### 启用与关闭

契约检查的开关分编译期和运行期两层。

**编译期**：由条件编译变量 `contract_check` 控制，默认开启。开关的取值在**编译 `stdx.contract.runtime` 包时**固化。`cfg.toml` 的读取位置与编译模式相关：**包模式**（`cjc -p <包目录>` 或 cjpm 构建）读取**包源码目录**下的 `cfg.toml`（`stdx.contract.runtime` 包内自带 `cfg.toml`，声明的默认值为 `contract_check = "on"`），不读取进程工作目录下的 `cfg.toml`；**单文件模式**（直接编译单个 `.cj` 文件）才读取进程工作目录下的 `cfg.toml`。`--cfg` 命令行选项优先级最高，可覆盖 `cfg.toml` 的取值。使用 CMake 构建本库时，构建脚本显式传入 `--cfg "contract_check=on"`，该选项会覆盖包内 `cfg.toml`——因此修改包内 `cfg.toml` 不会改变 CMake 构建产物的开关；若包源码目录下没有 `cfg.toml` 且未通过命令行或 `cjpm.toml` 的 `compile-option` 显式传入，使用 `contract_check` 条件编译的代码将直接报编译错误。消费预编译 stdx 制品的应用无需任何操作。若要自行编译出不含任何契约检查的 runtime 制品，可在 runtime 源码目录之外执行 `cjc -p <runtime源码目录> --cfg "contract_check=off" --output-type=dylib`（在应用侧编译时附加该选项不会改变预编译运行时中已固化的开关）；off 版制品中所有检查点的开销为编译期常量判断，契约子句不会被求值。

**运行期**：编译期开启的制品支持一次性降级——在进程内任意位置调用 [disableContractChecks](./runtime/contract_runtime_package_api/contract_runtime_package_funcs.md#func-disablecontractchecks) 后，本进程内后续所有检查点直接跳过。降级单向、线程安全且幂等，库不提供重新开启检查的 API；在 off 版制品中该函数为空操作。除此之外，库提供只读查询 [contractCheckEnabled](./runtime/contract_runtime_package_api/contract_runtime_package_funcs.md#func-contractcheckenabled)（仅供宏展开产物使用，返回当前检查是否生效）；开关基态仅由编译期 `contract_check` 决定。

检查开启时，每个契约子句在其检查点求值一次；类型不变式（`invariant`）会在该类型的成员被调用前后各求值一次，可用 `on_public`/`on_protected`/`on_private` 选择器限定检查范围，且每次契约求值伴随一次线程内求值状态的进入/退出标记。契约表达式应保持轻量，避免把使用本库的类型部署在性能敏感的热路径上。

### `@ghost` 的使用限制

`@ghost` 块展开为条件执行代码，其中 `let`/`var` 声明的变量在块外不可见，因此不能被同函数的 `requires`/`ensures`/`throws` 子句引用；需要被契约子句引用的抽象状态应改用 `variable` 子句声明。

此外，若某个契约表达式所调用的函数体内包含 `@ghost` 块，宏展开在求值该契约时（求值状态标记为真）会跳过该幽灵块，函数此刻读到的抽象状态可能与真实状态不一致，进而导致后续不变式误判。请避免在契约表达式会调用的函数中使用 `@ghost` 维护契约所依赖的状态。

### 并发与挂起限制

契约求值的进入/退出配对（`contractEvalEnter`/`contractEvalExit`）依赖线程本地的求值深度标记，其正确性以"进入与退出发生在同一线程"为前提。因此契约表达式中禁止调用可能挂起当前执行并引发线程迁移的函数（如有界并发、阻塞等待类操作）；若契约求值跨挂起点迁移到其他线程，原线程的深度标记可能残留（导致该线程后续契约检查被跳过），迁移目标线程的退出则会被安静忽略。请在纯同步、无挂起的表达式上编写契约。

### 保留标识符前缀

宏展开会生成以 `_contract_`、`_abs_` 为前缀的辅助标识符（如局部绑定 `_contract_r`、`_contract_pre_0`，成员辅助 `_contract_aux_*`、`_contract_body` 等）。在标注了 @Contract 的声明内，使用这两个前缀命名的类型成员、函数名、参数或函数体顶层局部变量会与生成代码冲突，宏展开将报告 ERROR 级编译诊断（保留成员名的检查仅覆盖生成代码实际占用的名称），请勿使用这两个前缀命名用户代码。

### 跨包契约继承

同包（同一编译单元）内的父契约通过内存中的元数据直接解析。跨包契约继承依赖两条环境变量在构建期传递父类型的契约元数据（`.cmeta` 记录）：

- `CANGJIE_STDX_CONTRACT_PKG_NAME`：当前编译包的完整包名。设置后，宏展开产出的 `.cmeta` 记录、继承来源标识（`ClauseOrigin`）和不变式检查方法名均使用带包名的限定名，避免不同包的同名类型互相覆盖或撞名；
- `CANGJIE_STDX_CONTRACT_META_DIR`：`.cmeta` 记录的读写目录，支持以 `:` 分隔的多个目录（第一个为写入目标，其余只读搜索）；单个 ASCII 字母的目录项会被视为 Windows 盘符前缀并与下一段重新拼接（如 `C:\cmeta`），因此 Windows 绝对路径可直接参与分隔。父库构建时把记录写入该目录，消费方包编译时把同一变量指向该目录即可发现父契约。未设置时默认使用当前目录下的 `target/contract_meta`，并把模块 `cjpm.toml` 中各 path 依赖的 `target/contract_meta` 目录追加为只读搜索位置（从工作目录逐级向上查找 `cjpm.toml` 定位模块根），因此经 cjpm 以 path 依赖组织的工程无需设置该变量即可完成跨包契约继承；git 依赖及不经 cjpm 的编译仍需按下述流程显式设置。

典型流程：以 `CANGJIE_STDX_CONTRACT_PKG_NAME=<父库包名>`、`CANGJIE_STDX_CONTRACT_META_DIR=<记录目录>` 构建父库，再以 `CANGJIE_STDX_CONTRACT_META_DIR=<同一记录目录>` 编译消费方包。随 stdx 一起构建的包由构建系统自动注入这两个变量；使用 cjpm 且父库为 path 依赖的应用只需省略 `CANGJIE_STDX_CONTRACT_META_DIR`（见上），但 **`CANGJIE_STDX_CONTRACT_PKG_NAME` 仍需自行设置**：cjpm 构建不会注入该变量，缺失时记录退化为简单名身份，两个包各自声明的同名 `@Contract` 类型会共用一条记录（冲突时仅有 WARNING，继承可能解析到错误声明，见下）。其余场景（如 git 依赖、直接以 cjc 编译）需要在构建命令环境中自行设置这两个变量。

若两个未设置 `CANGJIE_STDX_CONTRACT_PKG_NAME` 的包声明了同名 `@Contract` 类型，注册表中的后写者会替换先写者，编译器将发出 `conflicting contract metadata` 告警；此时应按上述约定设置包名后重新构建。

类级 `variable` 的自动继承（无需 `inherits from` 子句）要求父类型的契约元数据可发现：同包内父类型需先于当前类型展开，跨包则依赖上述记录目录。元数据不可发现时该路径会静默跳过继承；若依赖这一行为，建议同时书写显式 `inherits from <父类型>` 子句，该路径在元数据缺失时会直接报错。元数据**写入**失败不会中断编译，但整个进程只报一次 WARNING，提示该次构建的跨包继承不可用（通常为 `CANGJIE_STDX_CONTRACT_META_DIR` 配置不当或目录不可写）。

多个搜索目录中字节相同的 `.cmeta` 记录视为同一条记录——cjpm 以顶层模块为工作目录递归构建各依赖包，依赖库的记录会聚合进顶层 `target/contract_meta`，与依赖自身目录中的副本天然重复。仅当同名记录的内容真正分叉时才报 `ambiguous contract metadata` 告警并跳过继承，此时应使用带包名的限定引用或删除过期记录后重建。

继承展开没有深度或数量上限：父类型的全部契约子句（含其祖先继承而来的子句）都会在消费方包内重新生成。建议继承链保持在 5~8 层以内、单个类型的 `invariant` 数量控制在个位数，并避免在菱形继承的多个分支中重复声明同一子句；更深的组合会线性放大生成代码体积与宏展开耗时。

继承的成员契约按参数位置适配子类（**仅适用于成员函数**）：子类 override 重命名形参后，回放函数子句中的父形参名会按位置替换为子形参名（参数数量不一致时保持原文，此时子类需使用与父类一致的形参名才能编译）。子类回放的函数 `requires`/`ensures` 条件若引用父类 `private` 成员，会改写为对父类型展开时生成的公共条件检查方法（`_contract_member_cond_` 前缀，按声明类型与子句编号命名）的调用，在父作用域内求值。**属性（`prop`/getter/setter）的契约继承不适用上述机制**：属性子句按原文回放，不做形参 α-重命名，也不生成条件检查器——因此属性契约中引用父类 `private` 成员、或引用与子类 setter 形参不同的父形参名时，会在子类作用域下编译失败，请改用公共成员或在子类显式重写属性契约。此外，含 `$pre(...)` 快照引用、引用函数级 `variable` 槽位的条件以及接口默认成员的契约同样无法经检查器承载，仍按原文回放——此类条件不得引用子作用域不可见的父类成员。

**可信边界**：`CANGJIE_STDX_CONTRACT_META_DIR` 目录中的 `.cmeta` 记录会被宏展开重新解析并参与代码生成，其可信级别等同于源码。请只让受信任的构建过程写入该目录，不要将其指向共享可写位置或直接采信来路不明的记录。每条记录带有一个内容指纹：记录损坏或被其他构建的记录混用时，消费方编译会在 stderr 输出一行 WARNING（记录仍会被使用，编译不中断）；当父库源码不在当前编译范围内时，父类型被修改后留下的过期记录无法被检测到，此时应删除记录并重建父库。

### 契约失败

契约检查失败时，会抛出对应的契约异常。其中 `requires`/`ensures`/`throws` 的异常信息包含失败函数名及原始契约子句，`invariant` 的异常信息包含类型名及子句，而 `@contractAssert` 与 `@loopInvariant` 的异常信息仅包含对应的断言/不变式表达式。契约表达式求值过程中抛出的非契约异常（业务异常）不会被包装，按原类型向调用方传播。契约异常统一由 [stdx.contract.runtime 的异常类](./runtime/contract_runtime_package_api/contract_runtime_package_exceptions.md) 提供，且可以通过 [isContractException](./runtime/contract_runtime_package_api/contract_runtime_package_funcs.md#func-iscontractexceptionexception) 判断某个异常是否为契约异常。

### 示例

函数契约、属性契约、类型契约与契约继承的完整示例，参见 [stdx.contract.macros](./contract_package_api/contract_package_macros.md) 中 `@Contract` 宏的示例。

## API 列表

### 宏

| 宏名 | 功能 |
| --- | --- |
| [@Contract](./contract_package_api/contract_package_macros.md#contract-属性宏) | 为函数、属性或类型声明契约。 |
| [@ghost](./contract_package_api/contract_package_macros.md#ghost-宏) | 声明仅在维护抽象状态时执行的幽灵代码。 |
| [@contractAssert](./contract_package_api/contract_package_macros.md#contractassert-宏) | 在函数体中声明断言。 |
| [@loopInvariant](./contract_package_api/contract_package_macros.md#loopinvariant-属性宏) | 为循环声明循环不变式。 |

> 契约检查开关、契约异常类及运行时辅助函数请参见 [stdx.contract.runtime](./runtime/contract_runtime_package_overview.md)。
