# 枚举

## enum AccessLevel

```cangjie
public enum AccessLevel <: ToString & Equatable<AccessLevel> {
    | Internal
    | Protected
    | Public
}
```

功能：表示**包的访问级别**，用于控制跨包边界的可见性。

父类型：

- ToString
- Equatable\<[AccessLevel](#enum-accesslevel)>

### Internal

```cangjie
Internal
```

功能：本包及子包可见。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Internal)
    println(pkg.accessLevel.toString())
}
```

运行结果：

```text
internal
```

### Protected

```cangjie
Protected
```

功能：同 Module 下的包可见。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Protected)
    println(pkg.accessLevel.toString())
}
```

运行结果：

```text
protected
```

### Public

```cangjie
Public
```

功能：所有包可见。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    println(pkg.accessLevel.toString())
}
```

运行结果：

```text
public
```

### func toString()

```cangjie
public func toString(): String
```

功能：将访问级别转为小写字符串：`"internal"`、`"protected"` 或 `"public"`。

返回值：

- String - 上述三种之一。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(AccessLevel.Public.toString())
}
```

运行结果：

```text
public
```

### operator func ==(AccessLevel)

```cangjie
public operator func ==(other: AccessLevel): Bool
```

功能：比较两个访问级别是否为同一变体（`Internal`、`Protected`、`Public` 各自与自身相等，彼此不等）。

参数：

- other: AccessLevel - 另一访问级别。

返回值：

- Bool - 相等则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_eq_AccessLevel same: ${AccessLevel.Public == AccessLevel.Public}")
    println("op_eq_AccessLevel diff: ${AccessLevel.Public == AccessLevel.Internal}")
}
```

运行结果：

```text
op_eq_AccessLevel same: true
op_eq_AccessLevel diff: false
```

### operator func !=(AccessLevel)

```cangjie
public operator func !=(other: AccessLevel): Bool
```

功能：与上一节的 `==` 相反，两个访问级别不同时为 `true`，相同时为 `false`（等价于 `!(this == other)`）。

参数：

- other: AccessLevel - 另一访问级别。

返回值：

- Bool - 不相等则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_ne_AccessLevel diff: ${AccessLevel.Public != AccessLevel.Internal}")
    println("op_ne_AccessLevel same: ${AccessLevel.Public != AccessLevel.Public}")
}
```

运行结果：

```text
op_ne_AccessLevel diff: true
op_ne_AccessLevel same: false
```

## enum OverflowStrategy

```cangjie
public enum OverflowStrategy <: ToString & Equatable<OverflowStrategy> {
    | NA
    | Wrapping
    | Throwing
    | Saturating
    | ...
}
```

功能：**溢出处理策略**，用于算术表达式，决定运算溢出时的行为方式。

父类型：

- ToString
- Equatable\<[OverflowStrategy](#enum-overflowstrategy)>

### NA

```cangjie
NA
```

功能：不适用，默认溢出策略，表示运算无需特殊溢出处理。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let expr = BinaryExpression.create(BinaryExprKind.Add, IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2))
    println(expr.overflow.toString())
}
```

运行结果：

```text
NA
```

### Wrapping

```cangjie
Wrapping
```

功能：回绕溢出策略，溢出时数值回绕（wrap around）到类型范围的另一端。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let expr = BinaryExpression.create(BinaryExprKind.Add, IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2))
    expr.overflow = OverflowStrategy.Wrapping
    println(expr.overflow.toString())
}
```

运行结果：

```text
Wrapping
```

### Throwing

```cangjie
Throwing
```

功能：抛出异常溢出策略，溢出时抛出异常终止运算。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let expr = BinaryExpression.create(BinaryExprKind.Sub, IntLiteral.get(IntType.getInt64(), 100), IntLiteral.get(IntType.getInt64(), 1))
    expr.overflow = OverflowStrategy.Throwing
    println(expr.overflow.toString())
}
```

运行结果：

```text
Throwing
```

### Saturating

```cangjie
Saturating
```

功能：饱和溢出策略，溢出时数值钳位到类型极值（不超出范围）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let expr = BinaryExpression.create(BinaryExprKind.Mul, IntLiteral.get(IntType.getInt64(), 10), IntLiteral.get(IntType.getInt64(), 3))
    expr.overflow = OverflowStrategy.Saturating
    println(expr.overflow.toString())
}
```

运行结果：

```text
Saturating
```

### func toString()

```cangjie
public func toString(): String
```

功能：将溢出策略转为字符串：`"NA"`、`"Wrapping"`、`"Throwing"` 或 `"Saturating"`。

返回值：

- String - 上述四种之一。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(OverflowStrategy.NA.toString())
    println(OverflowStrategy.Wrapping.toString())
    println(OverflowStrategy.Throwing.toString())
    println(OverflowStrategy.Saturating.toString())
}
```

运行结果：

```text
NA
Wrapping
Throwing
Saturating
```

### operator func ==(OverflowStrategy)

```cangjie
public operator func ==(other: OverflowStrategy): Bool
```

功能：比较两个溢出策略是否为同一变体（`NA`、`Wrapping`、`Throwing`、`Saturating` 各自与自身相等，彼此不等）。

参数：

- other: OverflowStrategy - 另一溢出策略。

返回值：

- Bool - 相等则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_eq_OverflowStrategy same: ${OverflowStrategy.Wrapping == OverflowStrategy.Wrapping}")
    println("op_eq_OverflowStrategy diff: ${OverflowStrategy.Wrapping == OverflowStrategy.Throwing}")
}
```

运行结果：

```text
op_eq_OverflowStrategy same: true
op_eq_OverflowStrategy diff: false
```

### operator func !=(OverflowStrategy)

```cangjie
public operator func !=(other: OverflowStrategy): Bool
```

功能：与上一节的 `==` 相反，两个溢出策略不同时为 `true`，相同时为 `false`（等价于 `!(this == other)`）。

参数：

- other: OverflowStrategy - 另一溢出策略。

返回值：

- Bool - 不相等则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_ne_OverflowStrategy diff: ${OverflowStrategy.Wrapping != OverflowStrategy.Throwing}")
    println("op_ne_OverflowStrategy same: ${OverflowStrategy.Wrapping != OverflowStrategy.Wrapping}")
}
```

运行结果：

```text
op_ne_OverflowStrategy diff: true
op_ne_OverflowStrategy same: false
```

## enum UnaryExprKind

```cangjie
public enum UnaryExprKind <: ToString & Equatable<UnaryExprKind> {
    | Neg
    | Not
    | BitNot
    | ...
}
```

功能：CHIR 中的**一元运算符类别**，表示取负、逻辑非、按位取反等运算。

父类型：

- ToString
- Equatable\<[UnaryExprKind](#enum-unaryexprkind)>

### Neg

```cangjie
Neg
```

功能：一元取负运算符，对数值取负（如 `-x`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(UnaryExprKind.Neg.toString())
}
```

运行结果：

```text
Neg
```

### Not

```cangjie
Not
```

功能：一元逻辑非运算符，对布尔值取反（如 `!b`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let expr = UnaryExpression.create(UnaryExprKind.Not, BoolLiteral.get(false))
    println(UnaryExprKind.Not.toString())
}
```

运行结果：

```text
Not
```

### BitNot

```cangjie
BitNot
```

功能：一元按位取反运算符，对整数按位取反（如 `~x`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let expr = UnaryExpression.create(UnaryExprKind.BitNot, IntLiteral.get(IntType.getInt64(), 7))
    println(UnaryExprKind.BitNot.toString())
}
```

运行结果：

```text
BitNot
```

### func toString()

```cangjie
public func toString(): String
```

功能：将一元运算符类别转为字符串：`"Neg"`、`"Not"` 或 `"BitNot"`。

返回值：

- String - 上述三种之一。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(UnaryExprKind.Neg.toString())
    println(UnaryExprKind.Not.toString())
    println(UnaryExprKind.BitNot.toString())
}
```

运行结果：

```text
Neg
Not
BitNot
```

### operator func ==(UnaryExprKind)

```cangjie
public operator func ==(other: UnaryExprKind): Bool
```

功能：比较两个一元运算符类别是否为同一变体（`Neg`、`Not`、`BitNot` 各自与自身相等，彼此不等）。

参数：

- other: UnaryExprKind - 另一一元运算符类别。

返回值：

- Bool - 相等则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_eq_UnaryExprKind same: ${UnaryExprKind.Neg == UnaryExprKind.Neg}")
    println("op_eq_UnaryExprKind diff: ${UnaryExprKind.Neg == UnaryExprKind.Not}")
}
```

运行结果：

```text
op_eq_UnaryExprKind same: true
op_eq_UnaryExprKind diff: false
```

### operator func !=(UnaryExprKind)

```cangjie
public operator func !=(other: UnaryExprKind): Bool
```

功能：与上一节的 `==` 相反，两个一元运算符类别不同时为 `true`，相同时为 `false`（等价于 `!(this == other)`）。

参数：

- other: UnaryExprKind - 另一一元运算符类别。

返回值：

- Bool - 不相等则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_ne_UnaryExprKind diff: ${UnaryExprKind.Neg != UnaryExprKind.Not}")
    println("op_ne_UnaryExprKind same: ${UnaryExprKind.Neg != UnaryExprKind.Neg}")
}
```

运行结果：

```text
op_ne_UnaryExprKind diff: true
op_ne_UnaryExprKind same: false
```

## enum BinaryExprKind

```cangjie
public enum BinaryExprKind <: ToString & Equatable<BinaryExprKind> {
    | Add
    | Sub
    | Mul
    | Div
    | Mod
    | Exp
    | LShift
    | RShift
    | BitAnd
    | BitOr
    | BitXor
    | LT
    | GT
    | LE
    | GE
    | Equal
    | NotEqual
    | And
    | Or
    | ...
}
```

功能：CHIR 中的**二元运算符类别**，涵盖算术、位运算、比较和逻辑运算。

父类型：

- ToString
- Equatable\<[BinaryExprKind](#enum-binaryexprkind)>

### Add

```cangjie
Add
```

功能：二元加法运算符（`x + y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let expr = BinaryExpression.create(BinaryExprKind.Add, IntLiteral.get(IntType.getInt64(), 3), IntLiteral.get(IntType.getInt64(), 4))
    println(BinaryExprKind.Add.toString())
}
```

运行结果：

```text
Add
```

### Sub

```cangjie
Sub
```

功能：二元减法运算符（`x - y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.Sub.toString())
}
```

运行结果：

```text
Sub
```

### Mul

```cangjie
Mul
```

功能：二元乘法运算符（`x * y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.Mul.toString())
}
```

运行结果：

```text
Mul
```

### Div

```cangjie
Div
```

功能：二元除法运算符（`x / y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.Div.toString())
}
```

运行结果：

```text
Div
```

### Mod

```cangjie
Mod
```

功能：二元取模运算符（`x % y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.Mod.toString())
}
```

运行结果：

```text
Mod
```

### Exp

```cangjie
Exp
```

功能：二元指数运算符（`x ** y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.Exp.toString())
}
```

运行结果：

```text
Exp
```

### LShift

```cangjie
LShift
```

功能：二元左移运算符（`x << y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.LShift.toString())
}
```

运行结果：

```text
LShift
```

### RShift

```cangjie
RShift
```

功能：二元右移运算符（`x >> y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.RShift.toString())
}
```

运行结果：

```text
RShift
```

### BitAnd

```cangjie
BitAnd
```

功能：二元按位与运算符（`x & y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.BitAnd.toString())
}
```

运行结果：

```text
BitAnd
```

### BitOr

```cangjie
BitOr
```

功能：二元按位或运算符（`x | y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.BitOr.toString())
}
```

运行结果：

```text
BitOr
```

### BitXor

```cangjie
BitXor
```

功能：二元按位异或运算符（`x ^ y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.BitXor.toString())
}
```

运行结果：

```text
BitXor
```

### LT

```cangjie
LT
```

功能：二元小于比较运算符（`x < y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.LT.toString())
}
```

运行结果：

```text
LT
```

### GT

```cangjie
GT
```

功能：二元大于比较运算符（`x > y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.GT.toString())
}
```

运行结果：

```text
GT
```

### LE

```cangjie
LE
```

功能：二元小于等于比较运算符（`x <= y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.LE.toString())
}
```

运行结果：

```text
LE
```

### GE

```cangjie
GE
```

功能：二元大于等于比较运算符（`x >= y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.GE.toString())
}
```

运行结果：

```text
GE
```

### Equal

```cangjie
Equal
```

功能：二元相等比较运算符（`x == y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.Equal.toString())
}
```

运行结果：

```text
Equal
```

### NotEqual

```cangjie
NotEqual
```

功能：二元不等比较运算符（`x != y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.NotEqual.toString())
}
```

运行结果：

```text
NotEqual
```

### And

```cangjie
And
```

功能：二元逻辑与运算符（`x && y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.And.toString())
}
```

运行结果：

```text
And
```

### Or

```cangjie
Or
```

功能：二元逻辑或运算符（`x || y`）。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.Or.toString())
}
```

运行结果：

```text
Or
```

### func toString()

```cangjie
public func toString(): String
```

功能：将二元运算符类别转为字符串，按类别分组如下：

- 算术类：`"Add"`、`"Sub"`、`"Mul"`、`"Div"`、`"Mod"`、`"Exp"`；
- 位运算类：`"LShift"`、`"RShift"`、`"BitAnd"`、`"BitOr"`、`"BitXor"`；
- 比较类：`"LT"`、`"GT"`、`"LE"`、`"GE"`、`"Equal"`、`"NotEqual"`；
- 逻辑类：`"And"`、`"Or"`。

返回值：

- String - 上述十九种之一。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.Add.toString())
    println(BinaryExprKind.LShift.toString())
    println(BinaryExprKind.LT.toString())
    println(BinaryExprKind.And.toString())
}
```

运行结果：

```text
Add
LShift
LT
And
```

### operator func ==(BinaryExprKind)

```cangjie
public operator func ==(other: BinaryExprKind): Bool
```

功能：比较两个二元运算符类别是否为同一变体（各变体与自身相等，彼此不等）。

参数：

- other: BinaryExprKind - 另一二元运算符类别。

返回值：

- Bool - 相等则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_eq_BinaryExprKind same: ${BinaryExprKind.Add == BinaryExprKind.Add}")
    println("op_eq_BinaryExprKind diff: ${BinaryExprKind.Add == BinaryExprKind.Sub}")
}
```

运行结果：

```text
op_eq_BinaryExprKind same: true
op_eq_BinaryExprKind diff: false
```

### operator func !=(BinaryExprKind)

```cangjie
public operator func !=(other: BinaryExprKind): Bool
```

功能：与上一节的 `==` 相反，两个二元运算符类别不同时为 `true`，相同时为 `false`（等价于 `!(this == other)`）。

参数：

- other: BinaryExprKind - 另一二元运算符类别。

返回值：

- Bool - 不相等则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_ne_BinaryExprKind diff: ${BinaryExprKind.Add != BinaryExprKind.Sub}")
    println("op_ne_BinaryExprKind same: ${BinaryExprKind.Add != BinaryExprKind.Add}")
}
```

运行结果：

```text
op_ne_BinaryExprKind diff: true
op_ne_BinaryExprKind same: false
```

## enum InsertPosition

```cangjie
public enum InsertPosition {
    | AtEnd(Block)
    | AtStart(Block)
    | Before(Expression)
    | After(Expression)
    | ...
}
```

功能：CHIRBuilder 构建表达式时的**插入位置**，指定新表达式在基本块中的插入方式。

### AtEnd(Block)

```cangjie
AtEnd(Block)
```

功能：在基本块末尾插入，新表达式追加到 Block 的表达式列表末尾。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let fType = FuncType.get(Array<Type>(), UnitType.get())
    let funcDef = pkg.addFunction(fType, "f", "f", "demo")
    funcDef.initBody()
    if (let Some(bg) <- funcDef.body) {
        let block = bg.entryBlock
        let pos = InsertPosition.AtEnd(block)
        let builder = CHIRBuilder(pos)
        builder.createBinaryAdd(IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2), OverflowStrategy.NA)
        println("exprs count: ${block.exprs.size}")
    }
}
```

运行结果：

```text
exprs count: 1
```

### AtStart(Block)

```cangjie
AtStart(Block)
```

功能：在基本块开头插入，新表达式插入到 Block 的表达式列表起始位置。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let fType = FuncType.get(Array<Type>(), UnitType.get())
    let funcDef = pkg.addFunction(fType, "f", "f", "demo")
    funcDef.initBody()
    if (let Some(bg) <- funcDef.body) {
        let block = bg.entryBlock
        let pos = InsertPosition.AtStart(block)
        let builder = CHIRBuilder(pos)
        builder.createBinaryAdd(IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2), OverflowStrategy.NA)
        println("exprs count: ${block.exprs.size}")
    }
}
```

运行结果：

```text
exprs count: 1
```

### Before(Expression)

```cangjie
Before(Expression)
```

功能：在指定表达式之前插入，新表达式插入到目标 Expression 的前方。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let fType = FuncType.get(Array<Type>(), UnitType.get())
    let funcDef = pkg.addFunction(fType, "f", "f", "demo")
    funcDef.initBody()
    if (let Some(bg) <- funcDef.body) {
        let block = bg.entryBlock
        let builder1 = CHIRBuilder(InsertPosition.AtEnd(block))
        let expr1 = builder1.createBinaryAdd(IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2), OverflowStrategy.NA)
        let pos = InsertPosition.Before(expr1)
        let builder2 = CHIRBuilder(pos)
        builder2.createBinarySub(IntLiteral.get(IntType.getInt64(), 5), IntLiteral.get(IntType.getInt64(), 3), OverflowStrategy.NA)
        println("exprs count: ${block.exprs.size}")
    }
}
```

运行结果：

```text
exprs count: 2
```

### After(Expression)

```cangjie
After(Expression)
```

功能：在指定表达式之后插入，新表达式插入到目标 Expression 的后方。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let fType = FuncType.get(Array<Type>(), UnitType.get())
    let funcDef = pkg.addFunction(fType, "f", "f", "demo")
    funcDef.initBody()
    if (let Some(bg) <- funcDef.body) {
        let block = bg.entryBlock
        let builder1 = CHIRBuilder(InsertPosition.AtEnd(block))
        let expr1 = builder1.createBinaryAdd(IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2), OverflowStrategy.NA)
        let pos = InsertPosition.After(expr1)
        let builder2 = CHIRBuilder(pos)
        builder2.createBinarySub(IntLiteral.get(IntType.getInt64(), 5), IntLiteral.get(IntType.getInt64(), 3), OverflowStrategy.NA)
        println("exprs count: ${block.exprs.size}")
    }
}
```

运行结果：

```text
exprs count: 2
```

## enum IRActionMode

```cangjie
public enum IRActionMode <: Equatable<IRActionMode> {
    | Continue
    | Stop
    | Skip
    | ...
}
```

功能：控制 CHIRVisitor 遍历表达式时的**行为模式**，决定是否继续遍历后续表达式。

父类型：

- Equatable\<IRActionMode>

### Continue

```cangjie
Continue
```

功能：继续遍历，CHIRVisitor 将继续访问后续表达式和嵌套 BlockGroup。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let mode = IRActionMode.Continue
    match (mode) {
        case Continue => println("continue")
        case Stop => println("stop")
        case Skip => println("skip")
        case _ => println("other")
    }
}
```

运行结果：

```text
continue
```

### Stop

```cangjie
Stop
```

功能：停止遍历，CHIRVisitor 将终止当前遍历流程，不再访问后续表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let mode = IRActionMode.Stop
    match (mode) {
        case Continue => println("continue")
        case Stop => println("stop")
        case Skip => println("skip")
        case _ => println("other")
    }
}
```

运行结果：

```text
stop
```

### Skip

```cangjie
Skip
```

功能：跳过当前表达式的嵌套 BlockGroup，但继续遍历后续表达式。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let mode = IRActionMode.Skip
    match (mode) {
        case Continue => println("continue")
        case Stop => println("stop")
        case Skip => println("skip")
        case _ => println("other")
    }
}
```

运行结果：

```text
skip
```

### operator func ==(IRActionMode)

```cangjie
public operator func ==(rhs: IRActionMode): Bool
```

功能：判断两个 IRActionMode 是否相等。

参数：

- rhs: IRActionMode - 另一 IRActionMode。

返回值：

- Bool - 相等则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_eq_IRActionMode same: ${IRActionMode.Continue == IRActionMode.Continue}")
    println("op_eq_IRActionMode diff: ${IRActionMode.Continue == IRActionMode.Stop}")
}
```

运行结果：

```text
op_eq_IRActionMode same: true
op_eq_IRActionMode diff: false
```

### operator func !=(IRActionMode)

```cangjie
public operator func !=(rhs: IRActionMode): Bool
```

功能：与上一节的 `==` 相反，两个 IRActionMode 不同时为 `true`，相同时为 `false`（等价于 `!(this == rhs)`）。

参数：

- rhs: IRActionMode - 另一 IRActionMode。

返回值：

- Bool - 不相等则为 `true`，否则为 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_ne_IRActionMode diff: ${IRActionMode.Continue != IRActionMode.Stop}")
    println("op_ne_IRActionMode same: ${IRActionMode.Continue != IRActionMode.Continue}")
}
```

运行结果：

```text
op_ne_IRActionMode diff: true
op_ne_IRActionMode same: false
```

## enum TypeActionMode

```cangjie
public enum TypeActionMode {
    | CONTINUE
    | SKIP
    | STOP
}
```

功能：控制 TypeVisitor 遍历类型时的**行为模式**，决定是否继续遍历后续类型。

### CONTINUE

```cangjie
CONTINUE
```

功能：继续遍历，TypeVisitor 将继续访问后续类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let mode = TypeActionMode.CONTINUE
    match (mode) {
        case CONTINUE => println("continue")
        case SKIP => println("skip")
        case STOP => println("stop")
    }
}
```

运行结果：

```text
continue
```

### SKIP

```cangjie
SKIP
```

功能：跳过当前类型，TypeVisitor 将跳过此类型继续遍历后续类型。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let mode = TypeActionMode.SKIP
    match (mode) {
        case CONTINUE => println("continue")
        case SKIP => println("skip")
        case STOP => println("stop")
    }
}
```

运行结果：

```text
skip
```

### STOP

```cangjie
STOP
```

功能：停止遍历，TypeVisitor 将终止当前遍历流程。

示例：

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let mode = TypeActionMode.STOP
    match (mode) {
        case CONTINUE => println("continue")
        case SKIP => println("skip")
        case STOP => println("stop")
    }
}
```

运行结果：

```text
stop
```
