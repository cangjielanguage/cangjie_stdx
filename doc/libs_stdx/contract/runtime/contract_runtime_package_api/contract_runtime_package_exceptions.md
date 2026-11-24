# 异常类

## class ContractCheckException

```cangjie
public abstract class ContractCheckException <: Exception {
    public init()
    public init(message: String)
}
```

功能：所有契约检查异常的公共基类。可通过 [isContractException](./contract_runtime_package_funcs.md#func-iscontractexceptionexception) 判断某个异常是否为契约异常，也可在 `try/catch` 中以该类型统一捕获全部契约失败。

契约异常不受业务异常 `throws` 校验约束。契约不是安全边界：抽象基类仅阻止直接实例化，不阻止子类化伪造——本类可被继承，且本类与全部子类的构造函数均为 `public`，任何代码都可以构造这些异常（或其派生类型）使宏展开产物中的 `throws` 校验按契约失败处理，本库不防御这种主动绕过。

### init()

```cangjie
public init()
```

功能：构造一个契约异常基类实例，异常信息为空。

### init(String)

```cangjie
public init(message: String)
```

功能：构造一个契约异常基类实例。

参数：

- message: String - 异常信息。

父类型：

- Exception

## class ContractCheckAssertException

```cangjie
public class ContractCheckAssertException <: ContractCheckException {
    public init(message!: String = "ContractCheckAssertException")
}
```

功能：[@contractAssert](../../contract_package_api/contract_package_macros.md#contractassert-宏) 声明的断言检查失败时抛出的异常，异常信息格式为 `assertion failed: <断言表达式>`。

父类型：

- ContractCheckException

### init(String)

```cangjie
public init(message!: String = "ContractCheckAssertException")
```

功能：构造一个断言检查异常，默认异常信息为 `"ContractCheckAssertException"`。

参数：

- message!: String - 异常信息。

## class ContractCheckEnsuresException

```cangjie
public class ContractCheckEnsuresException <: ContractCheckException {
    public init(message!: String = "ContractCheckEnsuresException")
}
```

功能：后置条件（`ensures`）检查失败时抛出的异常，异常信息格式为 `ensures failed in <函数名>: <子句>`。

父类型：

- ContractCheckException

### init(String)

```cangjie
public init(message!: String = "ContractCheckEnsuresException")
```

功能：构造一个后置条件检查异常，默认异常信息为 `"ContractCheckEnsuresException"`。

参数：

- message!: String - 异常信息。

## class ContractCheckGhostStateException

```cangjie
public class ContractCheckGhostStateException <: ContractCheckException {
    public init(message!: String = "ContractCheckGhostStateException")
}
```

功能：辅助变量（ghost 变量/抽象状态）在初始化前被契约读取时抛出的异常。来源包括：

- 函数级或类型级辅助变量在赋值前被其他契约表达式读取；
- 属性（ghost 属性/抽象属性）的存储值在初始化前被读取。

父类型：

- ContractCheckException

### init(String)

```cangjie
public init(message!: String = "ContractCheckGhostStateException")
```

功能：构造一个辅助变量状态异常，默认异常信息为 `"ContractCheckGhostStateException"`；函数级辅助变量场景下异常信息格式为 `contract variable `<变量名>` is used before it is initialized`。

参数：

- message!: String - 异常信息。

## class ContractCheckInvariantException

```cangjie
public class ContractCheckInvariantException <: ContractCheckException {
    public init(message!: String = "ContractCheckInvariantException")
}
```

功能：类型不变式检查失败时抛出的异常，异常信息格式为 `invariant failed in <类型名>: <子句>`。

父类型：

- ContractCheckException

### init(String)

```cangjie
public init(message!: String = "ContractCheckInvariantException")
```

功能：构造一个类型不变式检查异常，默认异常信息为 `"ContractCheckInvariantException"`。

参数：

- message!: String - 异常信息。

## class ContractCheckLoopInvariantException

```cangjie
public class ContractCheckLoopInvariantException <: ContractCheckException {
    public init(message!: String = "ContractCheckLoopInvariantException")
}
```

功能：[@loopInvariant](../../contract_package_api/contract_package_macros.md#loopinvariant-属性宏) 声明的循环不变式检查失败时抛出的异常，异常信息格式为 `loop invariant failed: <不变式表达式>`。

父类型：

- ContractCheckException

### init(String)

```cangjie
public init(message!: String = "ContractCheckLoopInvariantException")
```

功能：构造一个循环不变式检查异常，默认异常信息为 `"ContractCheckLoopInvariantException"`。

参数：

- message!: String - 异常信息。

## class ContractCheckRequiresException

```cangjie
public class ContractCheckRequiresException <: ContractCheckException {
    public init(message!: String = "ContractCheckRequiresException")
}
```

功能：前置条件（`requires`）检查失败时抛出的异常，异常信息格式为 `requires failed in <函数名>: <子句>`。

父类型：

- ContractCheckException

### init(String)

```cangjie
public init(message!: String = "ContractCheckRequiresException")
```

功能：构造一个前置条件检查异常，默认异常信息为 `"ContractCheckRequiresException"`。

参数：

- message!: String - 异常信息。

## class ContractCheckThrowsException

```cangjie
public class ContractCheckThrowsException <: ContractCheckException {
    public let cause: ?Exception
    public init(message!: String = "ContractCheckThrowsException", cause!: ?Exception = None)
}
```

功能：异常契约（`throws`）检查失败时抛出的异常。

- 条件成立但未抛出要求的异常时，`cause` 为 `None`，异常信息格式为 `throws failed in <函数名>: required exception was not thrown; clauses:\n<子句>`；
- 抛出了不匹配的异常时，`cause` 为原始异常，异常信息格式为 `throws failed in <函数名>: unexpected exception; clauses:\n<子句>cause: `。

父类型：

- ContractCheckException

### cause

```cangjie
public let cause: ?Exception
```

功能：记录类型不匹配时被包装的原始异常；正常返回导致契约失败时为 `None`。

### init(String, ?Exception)

```cangjie
public init(message!: String = "ContractCheckThrowsException", cause!: ?Exception = None)
```

功能：构造一个异常契约检查异常，默认异常信息为 `"ContractCheckThrowsException"`。

参数：

- message!: String - 异常信息。
- cause!: ?Exception - 类型不匹配时被包装的原始异常，默认为 `None`。
