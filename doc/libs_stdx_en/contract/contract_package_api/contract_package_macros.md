# Macros

## `@Contract` Attribute Macro

Function: Declares contract clauses for functions, properties, or types. 

> **Note:**
>
> Contract checking is enabled by default and is controlled by the compile-time conditional compilation variable `contract_check`, with support for a one-shot one-way runtime demotion through [disableContractChecks](../runtime/contract_runtime_package_api/contract_runtime_package_funcs.md#func-disablecontractchecks) (for details, see [Enabling and Disabling](../contract_package_overview.md#enabling-and-disabling) in stdx.contract); the outputs of the following examples all assume that contract checking is enabled at compile time. Note that when checking is disabled (at compile time or by runtime demotion), macro expansion still generates the auxiliary variable holders (`_contract_aux_*`), which may trigger compiler "unused variable" warnings; this is expected behavior.

> **Note:**
>
> The @Contract macro has the following restrictions:
>
> - It can be applied to ordinary functions, constructors (including primary constructors), properties, and class, struct, interface, and extend type declarations; enum is not supported; on an extend, @Contract only carries member-level contracts and its type-level clause list must be empty (`variable`/`invariant`/`inherits` are not supported and report a compile error);
> - Function contracts require the annotated function to be an ordinary function, not a `const` function;
> - Property contracts can be declared standalone and do not need to be located inside a type contract;
> - Member functions or member properties that use contract inheritance (`inherits`) must be located inside a type contract; otherwise, the macro expansion reports a compile error: member functions report `inherited function contracts require an enclosing type contract`, and member properties report `inherited property contracts require an enclosing type contract`;
> - The `set` clause of a property contract can only be used on `mut prop`;
> - The function-level `variable` clause is not supported in a `mut` method of a struct (a `mut` method cannot host a local helper function); declaring one reports the compile error `function-level variable is not supported in a mut method`;
> - Constructor contracts do not support the `ensures r: <expr>` return-value binding (constructors have no return value); the macro expansion reports a compile error;
> - An abstract property without accessor bodies (an interface member or an abstract class member) cannot be annotated with @Contract directly; its contracts must be declared in the enclosing type's type contract. Properties with accessor bodies can be annotated with @Contract standalone, and the macro reports a compile error for bodiless properties;
> - If the return value identifier `r` in `ensures r: <expr>` has the same name as a parameter or the enclosing function, a compile error is reported during macro expansion; in type member functions or property contracts, a compile error is also reported if `r` has the same name as a member of the enclosing type (member functions, properties, member variables, and class-level auxiliary variables);
> - `r` having the same name as a global variable does not cause an error, but in the postcondition expression `r` is bound to the return value rather than to the same-named global variable;
> - Binding identifiers in `match` case patterns are collected lexically: every identifier in an or-pattern (`case a | b =>`, `case (a | b) =>`) and the constructor name of a payload-less enum constructor (`case Red =>`) are treated as bindings; an auxiliary contract variable sharing such a name may produce a spurious conflict report, so rename it to avoid the conflict;
> - Violating the above restrictions makes the macro expansion report a compile error (except for the case where the return value identifier has the same name as a global variable, see the previous item); when `@Contract` is applied to an unsupported declaration kind (such as enum), the macro expansion reports a compile error as well.

Macro attributes:

- `attr`: the contract clauses carried in `[]`. The supported contract clauses are as follows:

- Functions (and the `get` / `set` of properties) support the following clauses:
    - `requires [<name>] <expr>`: precondition, checked before the function body executes;
    - `ensures [<name>] <expr>`: postcondition, checked before the function returns; with `ensures [<name>] r: <expr>`, the return value can be referenced via `r` in the expression;
    - `throws [<name>] <exception type> if <expr>`: when the condition holds, the function must throw an exception of the specified type; all clauses whose conditions hold must be satisfied simultaneously;
    - `variable <name>: <type> [= <expression>]`: declares a function-level auxiliary variable that can be referenced by other clauses; if not explicitly initialized, the variable starts uninitialized, and reading it before any assignment throws `ContractCheckGhostStateException`;
    - `inherits requires|ensures|throws <parent type>.<name>`: selectively inherits a single contract from the parent type; `inherits requires|ensures|throws <new name> = <parent type>.<name>` renames the contract during inheritance;
    - `inherits variable <parent type>.<name>`: selectively inherits an auxiliary variable of a member function from the parent type (renaming is not supported);
    - `$pre(<expr>)`: references the value of `<expr>` evaluated at function entry; it can only be used in `ensures` clauses (unavailable in `invariant`, `requires`, `throws`, and body macros, and `$pre` expressions cannot be nested).
- Types (class, struct, interface; extend excluded, see the restrictions above) support the following clauses:
    - `[static] variable <name>: <type> [= <expression>]`: declares abstract state that can be referenced by contracts;
    - `[on_public|on_protected|on_private] [static] invariant [<label>] <expression>`: declares a type invariant; without a selector, members at internal visibility and broader (public, protected, and package-internal members) are checked by default, and the selector restricts the member visibility that triggers invariant checking;
    - `inherits from <parent type>`: reuses the contracts declared on the parent type; can be augmented with `[conforming]` to force implementations to conform to the parent contracts. `inherits from` requires the parent type to carry a type-level @Contract annotation (its clause list may be empty); otherwise the parent's contract metadata is unavailable and the macro expansion reports a compile error;
    - `inherits invariant <parent type>.<name>`: selectively inherits a single invariant from the parent type; `inherits invariant <new name> = <parent type>.<name>` renames the invariant during inheritance.
- Contract inheritance does not happen by default; parent type contracts are inherited only when an `inherits` clause is explicitly written. The type-level `variable` is an exception and is always inherited automatically from the direct parent type carrying contracts.
- Names of the same kind of contract on the same function declaration must be distinct from each other; contracts of different kinds may share names. Contract names newly declared on an overriding function must not coincide with the names of the same kind of contract in the parent type (unless that name is explicitly inherited).
- Properties declare the clauses for reading and writing via `get` / `set` respectively. In the `set` clause, `value` refers to the actual argument of the setter.
- Names in contract expressions follow the ordinary scoping rules of the language; the macro never promotes a bare name to a field access. When a function or constructor argument shares its name with a field, a bare reference denotes the argument, not the field — the condition may then hold vacuously. Qualify field reads with `this.<field>` in that case.

Macro parameters:

- `input`: the annotated function, property, or type declaration.

Example:

Example 1 (function contract):

<!-- verify -->
```cangjie
import stdx.contract.macros.*

class BankAccount {
    private var balance: Float64

    init(balance: Float64) {
        this.balance = balance
    }

    @Contract[
        requires amount > 0.0
        requires amount <= this.balance
        ensures this.balance == $pre(this.balance) - amount
        throws IllegalArgumentException if amount <= 0.0
    ]
    public func withdraw(amount: Float64): Unit {
        if (amount <= 0.0) {
            throw IllegalArgumentException("amount must be positive")
        }
        this.balance -= amount
    }

    public func getBalance(): Float64 {
        this.balance
    }
}

main() {
    let account = BankAccount(100.0)
    account.withdraw(30.0)
    println(account.getBalance())
    try {
        account.withdraw(200.0)
    } catch (e: ContractCheckRequiresException) {
        println(e.message)
    }
}
```

Execution result:

```text
70.000000
requires failed in withdraw: requires amount <= this.balance
```

Example 2 (property contract):

<!-- verify -->
```cangjie
import stdx.contract.macros.*

@Contract[
    variable stored: Int64 = 0
    on_public invariant stored >= 0
]
class Box {
    @Contract[
        get ensures r: r == stored
        set requires value >= 0
    ]
    public mut prop value: Int64 {
        get() {
            stored
        }
        set(v) {
            stored = v
        }
    }
}

main() {
    let box = Box()
    box.value = 5
    println(box.value)
    try {
        box.value = -1
    } catch (e: ContractCheckRequiresException) {
        println(e.message)
    }
}
```

Execution result:

```text
5
requires failed in value: requires v >= 0
```

> **Note:**
>
> The `value` in the contract clause refers to the actual argument of the setter, so the exception message shows the actual argument name `v`.
>
> In this example, the accessor bodies of `get`/`set` directly read and write the auxiliary variable `stored`, so the compiler emits the WARNING that auxiliary variables are only accessible inside `@ghost`, `@contractAssert`, or `@loopInvariant` blocks; this is expected behavior (the accessors' access to the abstract state relies on checking being enabled). If you do not want this warning, move the maintenance of the abstract state into `@ghost(...)`.

Example 3 (type contract and invariant):

<!-- verify -->
```cangjie
import stdx.contract.macros.*

@Contract[
    variable total: Int64 = 0
    on_public invariant total >= 0
]
class Counter {
    public func current(): Int64 {
        total
    }

    @Contract[
        requires total < 10
        ensures total == $pre(total) + 1
    ]
    public func inc(): Unit {
        @ghost(total = total + 1)
    }
}

main() {
    let counter = Counter()
    counter.inc()
    println(counter.current())
    try {
        for (_ in 0..10) {
            counter.inc()
        }
    } catch (e: ContractCheckRequiresException) {
        println(e.message)
    }
}
```

Execution result:

```text
1
requires failed in inc: requires total < 10
```

> **Note:**
>
> The body of `current()` directly reads the auxiliary variable `total`, so the compiler emits the WARNING that auxiliary variables are only accessible inside `@ghost`, `@contractAssert`, or `@loopInvariant` blocks; this is expected behavior. The update of the abstract state in `inc()` is already written inside `@ghost(...)` and does not trigger this warning.

Example 4 (contract inheritance):

<!-- verify -->
```cangjie
import stdx.contract.macros.*
import std.collection.*

@Contract[
    variable values: ArrayList<Int64> = ArrayList<Int64>()
]
public interface Stack {
    @Contract[
        requires values.size < 3
        ensures values.size == $pre(values.size) + 1
    ]
    func push(x: Int64): Unit

    @Contract[
        requires !values.isEmpty()
        ensures r: r == values.size + 1
    ]
    func pop(): Int64

    func size(): Int64
}

@Contract[
    inherits from Stack
]
public class ArrayStack <: Stack {
    private let items = ArrayList<Int64>()

    public func push(x: Int64): Unit {
        items.add(x)
        @ghost(values.add(x))
    }

    public func pop(): Int64 {
        let value = items.remove(at: items.size - 1)
        @ghost(values.remove(at: values.size - 1))
        value
    }

    public func size(): Int64 {
        values.size
    }
}

main() {
    let stack: Stack = ArrayStack()
    stack.push(1)
    stack.push(2)
    println(stack.pop())
    println(stack.size())
    try {
        stack.push(3)
        stack.push(4)
        stack.push(5)
    } catch (e: ContractCheckRequiresException) {
        println(e.message)
    }
}
```

Execution result:

```text
2
1
requires failed in push: requires values.size < 3
```

## `@ghost` Macro

Function: Declares ghost code. Ghost code executes only when contract checking is enabled and the current execution is not inside contract expression evaluation. It is used to maintain auxiliary logic such as the abstract state declared in [type contracts](#contract-attribute-macro), without affecting business behavior.

> **Note:**
>
> The macro does not require the host function to be annotated with [@Contract](#contract-attribute-macro): when unannotated, the macro still expands, and execution is gated only by the `contract_check` switch (it executes when checking is enabled).

Macro parameters:

- `input`: the ghost code.

Example:

<!-- verify -->
```cangjie
import stdx.contract.macros.*

@Contract[
    variable stored: Int64 = 1
    on_public invariant stored >= 0
]
class Counter {
    @Contract
    public func dec(): Unit {
        @ghost(stored = stored - 1)
    }
}

main() {
    let counter = Counter()
    counter.dec()
    println("first dec ok")
    try {
        counter.dec()
    } catch (e: ContractCheckInvariantException) {
        println(e.message)
    }
}
```

Execution result:

```text
first dec ok
invariant failed in Counter: on_public invariant stored >= 0
```

## `@contractAssert` Macro

Function: Declares an assertion in a function body. When checking is enabled and the assertion expression evaluates to `false`, [ContractCheckAssertException](../runtime/contract_runtime_package_api/contract_runtime_package_exceptions.md#class-contractcheckassertexception) is thrown with the message `assertion failed: <assertion expression>`.

> **Note:**
>
> The macro does not require the host function to be annotated with [@Contract](#contract-attribute-macro): when unannotated, the macro still expands, and execution is gated only by the `contract_check` switch (it executes when checking is enabled).

Macro parameters:

- `input`: the assertion expression.

Example:

<!-- verify -->
```cangjie
import stdx.contract.macros.*

@Contract
func checkPositive(x: Int64): Unit {
    @contractAssert(x > 0)
}

main() {
    try {
        checkPositive(-1)
    } catch (e: ContractCheckAssertException) {
        println(e.message)
    }
}
```

Execution result:

```text
assertion failed: x > 0
```

## `@loopInvariant` Attribute Macro

Function: Declares a loop invariant for a loop. When checking is enabled and an invariant evaluates to `false`, [ContractCheckLoopInvariantException](../runtime/contract_runtime_package_api/contract_runtime_package_exceptions.md#class-contractcheckloopinvariantexception) is thrown with the message `loop invariant failed: <invariant expression>`.

> **Note:**
>
> - The macro does not require the host function to be annotated with [@Contract](#contract-attribute-macro): when unannotated, the macro still expands, and execution is gated only by the `contract_check` switch (it executes when checking is enabled);
> - The property-style form `@loopInvariant[...] <loop>` is not supported;
> - A `while` loop is checked once at the start of each iteration and once after the loop exits (it is also checked when the loop body never executes); a `for-in` loop is checked only at the start of each iteration; a `do-while` loop is checked after each execution of the loop body, before the condition is evaluated (a `continue` in the loop body runs the invariant check first before entering the next iteration).

Macro attributes:

- `definitions`: the list of invariant expressions, carried in `[]`, at least one.

Macro parameters:

- `input`: the loop expression to be checked (`for-in`, `while`, or `do-while`), passed as the second argument in `()`.

Example:

<!-- verify -->
```cangjie
import stdx.contract.macros.*

@Contract[
    requires n >= 0
    ensures r: r == n
]
func accumulate(n: Int64): Int64 {
    var i = 0
    var sum = 0
    @loopInvariant[i >= 0 && i <= n](while (i < n) {
        i += 1
        sum += i
        @contractAssert(sum > 0)
    })
    i
}

main() {
    println(accumulate(5))
}
```

Execution result:

```text
5
```
