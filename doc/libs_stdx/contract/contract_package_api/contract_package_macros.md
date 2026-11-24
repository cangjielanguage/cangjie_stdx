# 宏

## `@Contract` 属性宏

功能：为函数、属性或类型声明契约子句。

契约检查默认开启，由编译期条件编译变量 `contract_check` 控制，并支持通过 [disableContractChecks](../runtime/contract_runtime_package_api/contract_runtime_package_funcs.md#func-disablecontractchecks) 在运行期一次性单向降级（详见 [契约检查的启用与关闭](../contract_package_overview.md#启用与关闭)）。下文示例的运行结果均以编译期开启契约检查为前提。检查关闭时（无论编译期关闭还是运行期降级），宏展开仍会生成辅助变量持有者（`_contract_aux_*`），此时可能触发编译器「未使用变量」类告警，属预期行为。

@Contract 宏的使用有以下限制：

- 可用于普通函数、构造函数（含主构造函数）、属性，以及 class、struct、interface、extend 类型声明，不支持 enum；extend 上的 @Contract 仅用于承载成员级契约，其类型级子句列表必须为空（不支持 `variable`/`invariant`/`inherits`，书写时报编译错误）；
- 不支持在 `@C` 互操作类型和 `foreign` 函数上声明契约，宏展开报编译错误；且 `@C` 检测仅在 `@Contract` 写在 `@C` 之前时生效；
- 函数契约要求被标注的函数是普通函数，不能是 `const` 函数；
- 函数契约不支持 `async` / `reaasync` 函数，声明时宏展开报编译错误：`contract is not supported on async/reasync functions; annotate a synchronous helper instead.`；
- 属性契约可以独立声明，不要求位于类型契约内部；
- 需要使用契约继承（`inherits`）的成员函数或成员属性必须位于类型契约内部，否则宏展开时报编译错误：成员函数报 `inherited function contracts require an enclosing type contract`，成员属性报 `inherited property contracts require an enclosing type contract`；
- 属性契约的 `set` 子句只能用于 `mut prop`；
- 构造函数契约不支持 `ensures r: <expr>` 返回值绑定（构造函数没有返回值），宏展开报编译错误；
- 无访问器体的抽象属性（接口成员、抽象类成员）不能直接标注 @Contract，须把契约声明在所在类型的类型契约内；带访问器体的属性可独立标注 @Contract，宏对无体属性报编译错误；
- `ensures r: <expr>` 中的返回值标识符 `r` 与参数名或所在函数名同名时，宏展开时报编译错误；在类型成员函数或属性契约中，`r` 与所在类型的成员名（成员函数、属性、成员变量及类级辅助变量）同名时，同样报编译错误；
- `r` 与全局变量同名时不报错，但后置条件表达式中 `r` 会绑定到返回值，而非同名的全局变量；
- `match` 的 `case` 模式按词法收集绑定标识符：or-pattern（`case a | b =>`、`case (a | b) =>`）中的所有标识符，以及无载荷枚举构造器（`case Red =>`）的构造器名，都会被视为绑定；契约辅助变量与这些名字同名时可能产生多余的冲突报告，建议重命名规避；
- 不满足上述限制时，宏展开会报告编译错误（返回值标识符与全局变量同名的情况除外，见上一条）。

宏属性：

`attr` 以 `[]` 携带契约子句，按标注对象分为以下两类。

**函数与属性子句**（适用于函数及属性的 `get` / `set`）：

- `requires [<名称>] <expr>`：前置条件，在函数体执行前检查；
- `ensures [<名称>] <expr>`：后置条件，在函数返回前检查；使用 `ensures [<名称>] r: <expr>` 可在表达式中通过 `r` 引用返回值；
- `throws [<名称>] <异常类型> if <expr>`：当条件成立时，函数必须抛出指定类型的异常；所有条件成立的子句必须同时满足；
- `variable <名称>: <类型> [= <表达式>]`：声明函数级辅助变量，供其他子句引用；未显式初始化时，变量以未初始化状态开始，在任何赋值之前读取会抛出 `ContractCheckGhostStateException`；
- `inherits requires|ensures|throws <父类型>.<名称>`：选择性继承父类型上的单个契约；`inherits requires|ensures|throws <新名称> = <父类型>.<名称>` 可在继承时重命名；
- `inherits variable <父类型>.<名称>`：选择性继承父类型上成员函数的辅助变量（不支持重命名）；
- `$pre(<expr>)`：引用函数入口时 `<expr>` 的求值结果；只能在 `ensures` 子句中使用（`invariant`、`requires`、`throws` 及函数体宏中不可用，`$pre` 表达式不可嵌套）。

**类型子句**（适用于 class、struct、interface；extend 除外，见上方使用限制）：

- `[static] variable <名称>: <类型> [= <表达式>]`：声明可供契约引用的抽象状态；
- `[on_public|on_protected|on_private] [static] invariant [<标签>] <表达式>`：声明类型不变式；未写选择器时，默认对 internal 及更宽的成员（公开、受保护与包级内部成员）检查，选择器用于限定触发不变式检查的成员可见性；
- `inherits from <父类型>`：复用父类型声明的契约，可附加 `[conforming]` 修饰，强制实现与父契约一致；`inherits from` 要求父类型带有类型级 @Contract 标注（子句列表可以为空），否则无法获取父类型的契约元数据，宏展开报编译错误；
- `inherits invariant <父类型>.<名称>`：选择性继承父类型上的单个不变式；`inherits invariant <新名称> = <父类型>.<名称>` 可在继承时重命名。

**通用规则**：

- 契约继承默认不发生，只有显式书写 `inherits` 子句才继承父类型契约；类型级 `variable` 例外，总是从带契约的直接父类型自动继承。
- 同一函数声明上同一种契约的名称必须互不相同，不同种类可以同名；重写函数新声明的契约名称不得与父类型中同种契约的名称相同（显式继承该名称时除外）。
- 属性通过 `get` / `set` 分别声明读取与写入时的契约子句。`set` 子句中的 `value` 指代 setter 的实际参数。
- 契约表达式中的名字按仓颉语言作用域规则解析，宏不会把裸名自动提升为字段访问：当函数或构造函数的参数与字段同名时，裸名引用指参数而非同名字段，此时条件可能恒真；需要引用字段时使用 `this.<字段名>` 限定。

宏参数：

- `input`：被标注的函数、属性或类型声明。

示例：

示例 1（函数契约）：

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

运行结果：

```text
70.000000
requires failed in withdraw: requires amount <= this.balance
```

示例 2（属性契约）：

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

运行结果：

```text
5
requires failed in value: requires v >= 0
```

契约子句中的 `value` 指代 setter 的实际参数，因此异常信息中显示的是实际参数名 `v`。示例中 `get`/`set` 访问器实现体直接读写辅助变量 `stored`，编译时会产生「辅助变量仅可在 `@ghost`、`@contractAssert` 或 `@loopInvariant` 块内访问」的 WARNING，属预期行为（实现体对抽象状态的访问依赖检查开启）；若不希望出现该警告，应将抽象状态的维护移入 `@ghost(...)`。

示例 3（类型契约与不变式）：

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

运行结果：

```text
1
requires failed in inc: requires total < 10
```

`current()` 实现体直接读取辅助变量 `total`，会触发与示例 2 相同的「辅助变量仅可在 `@ghost`、`@contractAssert` 或 `@loopInvariant` 块内访问」WARNING，属预期行为；`inc()` 中抽象状态的更新已写在 `@ghost(...)` 内，不会触发该警告。

示例 4（契约继承）：

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

运行结果：

```text
2
1
requires failed in push: requires values.size < 3
```

## `@ghost` 宏

功能：声明幽灵代码。幽灵代码只在契约检查开启且当前不处于契约表达式求值过程中时执行，用于维护 [@Contract](#contract-属性宏) 声明的类型契约中的抽象状态等辅助逻辑，不影响业务行为。

宏参数：

- `input`：幽灵代码。

示例：

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

运行结果：

```text
first dec ok
invariant failed in Counter: on_public invariant stored >= 0
```

## `@contractAssert` 宏

功能：在函数体中声明断言。检查开启时，若断言表达式为 `false`，抛出 [ContractCheckAssertException](../runtime/contract_runtime_package_api/contract_runtime_package_exceptions.md#class-contractcheckassertexception)，异常信息为 `assertion failed: <断言表达式>`。

宏参数：

- `input`：断言表达式。

示例：

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

运行结果：

```text
assertion failed: x > 0
```

## `@loopInvariant` 属性宏

功能：为循环声明循环不变式。检查开启时，若不变式为 `false`，抛出 [ContractCheckLoopInvariantException](../runtime/contract_runtime_package_api/contract_runtime_package_exceptions.md#class-contractcheckloopinvariantexception)，异常信息为 `loop invariant failed: <不变式表达式>`。

该宏不能写成属性式的 `@loopInvariant[...] <循环>`。`while` 循环每次迭代开始时以及循环退出后各检查一次（循环体一次都不执行时也会检查）；`for-in` 循环仅在每次迭代开始时检查；`do-while` 循环在每次循环体执行后、条件求值前检查（循环体中的 `continue` 在离开其所在 `try` 的 `finally` 执行之后、条件求值之前执行检查）。

宏属性：

- `definitions`：不变式表达式列表，以 `[]` 携带，至少一个。

宏参数：

- `input`：需要检查的循环表达式（`for-in`、`while` 或 `do-while`），作为第二个参数放在 `()` 中。

示例：

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

运行结果：

```text
5
```
