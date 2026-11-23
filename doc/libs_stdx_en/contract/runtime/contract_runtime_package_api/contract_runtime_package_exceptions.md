# Exceptions

## abstract class ContractCheckException

```cangjie
public abstract class ContractCheckException <: Exception {
    public init()
    public init(message: String)
}
```

Function: The common base class of all contract-check exceptions. Being abstract only prevents direct instantiation; it does not prevent forging through subclassing. Use [isContractException](./contract_runtime_package_funcs.md#func-iscontractexception) to check whether an exception is a contract exception, or catch all contract failures uniformly with this type in a `try/catch`.

> **Note:** Contract exceptions are exempt from the business-exception `throws` verification. Contracts are not a security boundary: the abstract base class only prevents direct instantiation, not forging through subclassing — this class can be inherited, and the constructors of this class and all its subclasses are `public`, so any code can construct these exceptions (or derived types) to make the `throws` verification in macro-expanded code treat the check as a contract failure; this library does not defend against such deliberate bypasses.

### init()

```cangjie
public init()
```

Function: Constructs a base contract exception with an empty message.

### init(String)

```cangjie
public init(message: String)
```

Function: Constructs a base contract exception.

Parameters:

- message: String - The exception message.

Parent Type:

- Exception

## class ContractCheckAssertException

```cangjie
public class ContractCheckAssertException <: ContractCheckException {
    public init(message!: String = "ContractCheckAssertException")
}
```

Function: The exception thrown when an assertion declared by [@contractAssert](../../contract_package_api/contract_package_macros.md#contractassert-macro) fails its check; the exception message has the format `assertion failed: <assertion expression>`.

Parent Type:

- ContractCheckException

### init(String)

```cangjie
public init(message!: String = "ContractCheckAssertException")
```

Function: Constructs an assertion check exception with the default message `"ContractCheckAssertException"`.

Parameters:

- message!: String - The exception message.

## class ContractCheckEnsuresException

```cangjie
public class ContractCheckEnsuresException <: ContractCheckException {
    public init(message!: String = "ContractCheckEnsuresException")
}
```

Function: The exception thrown when a postcondition (`ensures`) check fails; the exception message has the format `ensures failed in <function name>: <clause>`.

Parent Type:

- ContractCheckException

### init(String)

```cangjie
public init(message!: String = "ContractCheckEnsuresException")
```

Function: Constructs a postcondition check exception with the default message `"ContractCheckEnsuresException"`.

Parameters:

- message!: String - The exception message.

## class ContractCheckGhostStateException

```cangjie
public class ContractCheckGhostStateException <: ContractCheckException {
    public init(message!: String = "ContractCheckGhostStateException")
}
```

Function: The exception thrown when an auxiliary variable (ghost variable/abstract state) is read by a contract before being initialized. Sources include:

- A function-level or type-level auxiliary variable read by another contract expression before being assigned;
- The stored value of a property (ghost property/abstract property) read before being initialized.

Parent Type:

- ContractCheckException

### init(String)

```cangjie
public init(message!: String = "ContractCheckGhostStateException")
```

Function: Constructs an auxiliary variable state exception with the default message `"ContractCheckGhostStateException"`; in the function-level auxiliary variable scenario, the exception message has the format `contract variable `<variable name>` is used before it is initialized`.

Parameters:

- message!: String - The exception message.

## class ContractCheckInvariantException

```cangjie
public class ContractCheckInvariantException <: ContractCheckException {
    public init(message!: String = "ContractCheckInvariantException")
}
```

Function: The exception thrown when a type invariant check fails; the exception message has the format `invariant failed in <type name>: <clause>`.

Parent Type:

- ContractCheckException

### init(String)

```cangjie
public init(message!: String = "ContractCheckInvariantException")
```

Function: Constructs a type invariant check exception with the default message `"ContractCheckInvariantException"`.

Parameters:

- message!: String - The exception message.

## class ContractCheckLoopInvariantException

```cangjie
public class ContractCheckLoopInvariantException <: ContractCheckException {
    public init(message!: String = "ContractCheckLoopInvariantException")
}
```

Function: The exception thrown when a loop invariant declared by [@loopInvariant](../../contract_package_api/contract_package_macros.md#loopinvariant-attribute-macro) fails its check; the exception message has the format `loop invariant failed: <invariant expression>`.

Parent Type:

- ContractCheckException

### init(String)

```cangjie
public init(message!: String = "ContractCheckLoopInvariantException")
```

Function: Constructs a loop invariant check exception with the default message `"ContractCheckLoopInvariantException"`.

Parameters:

- message!: String - The exception message.

## class ContractCheckRequiresException

```cangjie
public class ContractCheckRequiresException <: ContractCheckException {
    public init(message!: String = "ContractCheckRequiresException")
}
```

Function: The exception thrown when a precondition (`requires`) check fails; the exception message has the format `requires failed in <function name>: <clause>`.

Parent Type:

- ContractCheckException

### init(String)

```cangjie
public init(message!: String = "ContractCheckRequiresException")
```

Function: Constructs a precondition check exception with the default message `"ContractCheckRequiresException"`.

Parameters:

- message!: String - The exception message.

## class ContractCheckThrowsException

```cangjie
public class ContractCheckThrowsException <: ContractCheckException {
    public let cause: ?Exception
    public init(message!: String = "ContractCheckThrowsException", cause!: ?Exception = None)
}
```

Function: The exception thrown when an exception contract (`throws`) check fails.

- When the condition holds but the required exception is not thrown, `cause` is `None`, and the exception message has the format `throws failed in <function name>: required exception was not thrown; clauses:\n<clause>`;
- When a mismatched exception is thrown, `cause` is the original exception, and the exception message has the format `throws failed in <function name>: unexpected exception; clauses:\n<clause>cause: `.

Parent Type:

- ContractCheckException

### cause

```cangjie
public let cause: ?Exception
```

Function: Records the original exception wrapped when the type does not match; it is `None` when the function returns normally and causes the contract to fail.

### init(String, ?Exception)

```cangjie
public init(message!: String = "ContractCheckThrowsException", cause!: ?Exception = None)
```

Function: Constructs an exception contract check exception with the default message `"ContractCheckThrowsException"`.

Parameters:

- message!: String - The exception message.
- cause!: ?Exception - The original exception wrapped when the type does not match; defaults to `None`.
