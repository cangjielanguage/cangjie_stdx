# Enums

## enum AccessLevel

```cangjie
public enum AccessLevel <: ToString & Equatable<AccessLevel> {
    | Internal
    | Protected
    | Public
}
```

Function: Represents the **package access level** used to control visibility across package boundaries.

Parent Types:

- ToString
- Equatable\<[AccessLevel](#enum-accesslevel)>

### Internal

```cangjie
Internal
```

Function: Visible in this package and subpackages.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Internal)
    println(pkg.accessLevel.toString())
}
```

Output:

```text
internal
```

### Protected

```cangjie
Protected
```

Function: Visible to packages under the same module.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Protected)
    println(pkg.accessLevel.toString())
}
```

Output:

```text
protected
```

### Public

```cangjie
Public
```

Function: Visible to all packages.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    println(pkg.accessLevel.toString())
}
```

Output:

```text
public
```

### func toString()

```cangjie
public func toString(): String
```

Function: Converts the access level to a lowercase string: `"internal"`, `"protected"`, or `"public"`.

Return Value:

- String - One of the three values above.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(AccessLevel.Public.toString())
}
```

Output:

```text
public
```

### operator func ==(AccessLevel)

```cangjie
public operator func ==(other: AccessLevel): Bool
```

Function: Compares whether two access levels are the same variant (`Internal`, `Protected`, and `Public` are each equal to themselves and unequal to each other).

Parameters:

- other: AccessLevel - The other access level.

Return Value:

- Bool - `true` if equal, otherwise `false`.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_eq_AccessLevel same: ${AccessLevel.Public == AccessLevel.Public}")
    println("op_eq_AccessLevel diff: ${AccessLevel.Public == AccessLevel.Internal}")
}
```

Output:

```text
op_eq_AccessLevel same: true
op_eq_AccessLevel diff: false
```

### operator func !=(AccessLevel)

```cangjie
public operator func !=(other: AccessLevel): Bool
```

Function: Opposite of `==` in the previous section: `true` when the two access levels differ, `false` when they are equal (equivalent to `!(this == other)`).

Parameters:

- other: AccessLevel - The other access level.

Return Value:

- Bool - `true` if not equal, otherwise `false`.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_ne_AccessLevel diff: ${AccessLevel.Public != AccessLevel.Internal}")
    println("op_ne_AccessLevel same: ${AccessLevel.Public != AccessLevel.Public}")
}
```

Output:

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

Function: **Overflow handling strategy** for arithmetic expressions, determining behavior when an operation overflows.

Parent Types:

- ToString
- Equatable\<[OverflowStrategy](#enum-overflowstrategy)>

### NA

```cangjie
NA
```

Function: Not applicable; default overflow strategy indicating no special overflow handling is needed.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let expr = BinaryExpression.create(BinaryExprKind.Add, IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2))
    println(expr.overflow.toString())
}
```

Output:

```text
NA
```

### Wrapping

```cangjie
Wrapping
```

Function: Wrapping overflow strategy; values wrap around to the other end of the type's range on overflow.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let expr = BinaryExpression.create(BinaryExprKind.Add, IntLiteral.get(IntType.getInt64(), 1), IntLiteral.get(IntType.getInt64(), 2))
    expr.overflow = OverflowStrategy.Wrapping
    println(expr.overflow.toString())
}
```

Output:

```text
Wrapping
```

### Throwing

```cangjie
Throwing
```

Function: Throwing overflow strategy; throws an exception to abort the operation on overflow.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let expr = BinaryExpression.create(BinaryExprKind.Sub, IntLiteral.get(IntType.getInt64(), 100), IntLiteral.get(IntType.getInt64(), 1))
    expr.overflow = OverflowStrategy.Throwing
    println(expr.overflow.toString())
}
```

Output:

```text
Throwing
```

### Saturating

```cangjie
Saturating
```

Function: Saturating overflow strategy; values are clamped to the type's extreme values on overflow (never exceed the range).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let expr = BinaryExpression.create(BinaryExprKind.Mul, IntLiteral.get(IntType.getInt64(), 10), IntLiteral.get(IntType.getInt64(), 3))
    expr.overflow = OverflowStrategy.Saturating
    println(expr.overflow.toString())
}
```

Output:

```text
Saturating
```

### func toString()

```cangjie
public func toString(): String
```

Function: Converts the overflow strategy to a string: `"NA"`, `"Wrapping"`, `"Throwing"` or `"Saturating"`.

Return Value:

- String - One of the four values above.

Example:

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

Output:

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

Function: Compares whether two overflow strategies are the same variant (`NA`, `Wrapping`, `Throwing`, `Saturating` are each equal to themselves and unequal to each other).

Parameters:

- other: OverflowStrategy - The other overflow strategy.

Return Value:

- Bool - `true` if equal, otherwise `false`.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_eq_OverflowStrategy same: ${OverflowStrategy.Wrapping == OverflowStrategy.Wrapping}")
    println("op_eq_OverflowStrategy diff: ${OverflowStrategy.Wrapping == OverflowStrategy.Throwing}")
}
```

Output:

```text
op_eq_OverflowStrategy same: true
op_eq_OverflowStrategy diff: false
```

### operator func !=(OverflowStrategy)

```cangjie
public operator func !=(other: OverflowStrategy): Bool
```

Function: Opposite of `==` in the previous section: `true` when the two overflow strategies differ, `false` when they are equal (equivalent to `!(this == other)`).

Parameters:

- other: OverflowStrategy - The other overflow strategy.

Return Value:

- Bool - `true` if not equal, otherwise `false`.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_ne_OverflowStrategy diff: ${OverflowStrategy.Wrapping != OverflowStrategy.Throwing}")
    println("op_ne_OverflowStrategy same: ${OverflowStrategy.Wrapping != OverflowStrategy.Wrapping}")
}
```

Output:

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

Function: **Unary operator category** in CHIR, representing negation, logical not, bitwise not, etc.

Parent Types:

- ToString
- Equatable\<[UnaryExprKind](#enum-unaryexprkind)>

### Neg

```cangjie
Neg
```

Function: Unary negation operator; negates a numeric value (i.e., `-x`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(UnaryExprKind.Neg.toString())
}
```

Output:

```text
Neg
```

### Not

```cangjie
Not
```

Function: Unary logical not operator; negates a boolean value (i.e., `!b`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let expr = UnaryExpression.create(UnaryExprKind.Not, BoolLiteral.get(false))
    println(UnaryExprKind.Not.toString())
}
```

Output:

```text
Not
```

### BitNot

```cangjie
BitNot
```

Function: Unary bitwise not operator; inverts all bits of an integer (i.e., `~x`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let expr = UnaryExpression.create(UnaryExprKind.BitNot, IntLiteral.get(IntType.getInt64(), 7))
    println(UnaryExprKind.BitNot.toString())
}
```

Output:

```text
BitNot
```

### func toString()

```cangjie
public func toString(): String
```

Function: Converts the unary operator category to a string: `"Neg"`, `"Not"` or `"BitNot"`.

Return Value:

- String - One of the three values above.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(UnaryExprKind.Neg.toString())
    println(UnaryExprKind.Not.toString())
    println(UnaryExprKind.BitNot.toString())
}
```

Output:

```text
Neg
Not
BitNot
```

### operator func ==(UnaryExprKind)

```cangjie
public operator func ==(other: UnaryExprKind): Bool
```

Function: Compares whether two unary operator categories are the same variant (`Neg`, `Not`, `BitNot` are each equal to themselves and unequal to each other).

Parameters:

- other: UnaryExprKind - The other unary operator category.

Return Value:

- Bool - `true` if equal, otherwise `false`.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_eq_UnaryExprKind same: ${UnaryExprKind.Neg == UnaryExprKind.Neg}")
    println("op_eq_UnaryExprKind diff: ${UnaryExprKind.Neg == UnaryExprKind.Not}")
}
```

Output:

```text
op_eq_UnaryExprKind same: true
op_eq_UnaryExprKind diff: false
```

### operator func !=(UnaryExprKind)

```cangjie
public operator func !=(other: UnaryExprKind): Bool
```

Function: Opposite of `==` in the previous section: `true` when the two unary operator categories differ, `false` when they are equal (equivalent to `!(this == other)`).

Parameters:

- other: UnaryExprKind - The other unary operator category.

Return Value:

- Bool - `true` if not equal, otherwise `false`.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_ne_UnaryExprKind diff: ${UnaryExprKind.Neg != UnaryExprKind.Not}")
    println("op_ne_UnaryExprKind same: ${UnaryExprKind.Neg != UnaryExprKind.Neg}")
}
```

Output:

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

Function: **Binary operator category** in CHIR, covering arithmetic, bitwise, comparison, and logical operations.

Parent Types:

- ToString
- Equatable\<[BinaryExprKind](#enum-binaryexprkind)>

### Add

```cangjie
Add
```

Function: Binary addition operator (`x + y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let expr = BinaryExpression.create(BinaryExprKind.Add, IntLiteral.get(IntType.getInt64(), 3), IntLiteral.get(IntType.getInt64(), 4))
    println(BinaryExprKind.Add.toString())
}
```

Output:

```text
Add
```

### Sub

```cangjie
Sub
```

Function: Binary subtraction operator (`x - y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.Sub.toString())
}
```

Output:

```text
Sub
```

### Mul

```cangjie
Mul
```

Function: Binary multiplication operator (`x * y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.Mul.toString())
}
```

Output:

```text
Mul
```

### Div

```cangjie
Div
```

Function: Binary division operator (`x / y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.Div.toString())
}
```

Output:

```text
Div
```

### Mod

```cangjie
Mod
```

Function: Binary modulo operator (`x % y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.Mod.toString())
}
```

Output:

```text
Mod
```

### Exp

```cangjie
Exp
```

Function: Binary exponentiation operator (`x ** y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.Exp.toString())
}
```

Output:

```text
Exp
```

### LShift

```cangjie
LShift
```

Function: Binary left shift operator (`x << y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.LShift.toString())
}
```

Output:

```text
LShift
```

### RShift

```cangjie
RShift
```

Function: Binary right shift operator (`x >> y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.RShift.toString())
}
```

Output:

```text
RShift
```

### BitAnd

```cangjie
BitAnd
```

Function: Binary bitwise AND operator (`x & y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.BitAnd.toString())
}
```

Output:

```text
BitAnd
```

### BitOr

```cangjie
BitOr
```

Function: Binary bitwise OR operator (`x | y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.BitOr.toString())
}
```

Output:

```text
BitOr
```

### BitXor

```cangjie
BitXor
```

Function: Binary bitwise XOR operator (`x ^ y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.BitXor.toString())
}
```

Output:

```text
BitXor
```

### LT

```cangjie
LT
```

Function: Binary less-than comparison operator (`x < y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.LT.toString())
}
```

Output:

```text
LT
```

### GT

```cangjie
GT
```

Function: Binary greater-than comparison operator (`x > y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.GT.toString())
}
```

Output:

```text
GT
```

### LE

```cangjie
LE
```

Function: Binary less-than-or-equal comparison operator (`x <= y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.LE.toString())
}
```

Output:

```text
LE
```

### GE

```cangjie
GE
```

Function: Binary greater-than-or-equal comparison operator (`x >= y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.GE.toString())
}
```

Output:

```text
GE
```

### Equal

```cangjie
Equal
```

Function: Binary equality comparison operator (`x == y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.Equal.toString())
}
```

Output:

```text
Equal
```

### NotEqual

```cangjie
NotEqual
```

Function: Binary inequality comparison operator (`x != y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.NotEqual.toString())
}
```

Output:

```text
NotEqual
```

### And

```cangjie
And
```

Function: Binary logical AND operator (`x && y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.And.toString())
}
```

Output:

```text
And
```

### Or

```cangjie
Or
```

Function: Binary logical OR operator (`x || y`).

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println(BinaryExprKind.Or.toString())
}
```

Output:

```text
Or
```

### func toString()

```cangjie
public func toString(): String
```

Function: Converts the binary operator category to a string, grouped as follows:
- Arithmetic: `"Add"`, `"Sub"`, `"Mul"`, `"Div"`, `"Mod"`, `"Exp"`;
- Bitwise: `"LShift"`, `"RShift"`, `"BitAnd"`, `"BitOr"`, `"BitXor"`;
- Comparison: `"LT"`, `"GT"`, `"LE"`, `"GE"`, `"Equal"`, `"NotEqual"`;
- Logical: `"And"`, `"Or"`.

Return Value:

- String - One of the nineteen values above.

Example:

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

Output:

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

Function: Compares whether two binary operator categories are the same variant (each variant is equal to itself and unequal to others).

Parameters:

- other: BinaryExprKind - The other binary operator category.

Return Value:

- Bool - `true` if equal, otherwise `false`.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_eq_BinaryExprKind same: ${BinaryExprKind.Add == BinaryExprKind.Add}")
    println("op_eq_BinaryExprKind diff: ${BinaryExprKind.Add == BinaryExprKind.Sub}")
}
```

Output:

```text
op_eq_BinaryExprKind same: true
op_eq_BinaryExprKind diff: false
```

### operator func !=(BinaryExprKind)

```cangjie
public operator func !=(other: BinaryExprKind): Bool
```

Function: Opposite of `==` in the previous section: `true` when the two binary operator categories differ, `false` when they are equal (equivalent to `!(this == other)`).

Parameters:

- other: BinaryExprKind - The other binary operator category.

Return Value:

- Bool - `true` if not equal, otherwise `false`.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_ne_BinaryExprKind diff: ${BinaryExprKind.Add != BinaryExprKind.Sub}")
    println("op_ne_BinaryExprKind same: ${BinaryExprKind.Add != BinaryExprKind.Add}")
}
```

Output:

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

Function: **Insertion position** when building expressions with CHIRBuilder, specifying how new expressions are inserted into a basic block.

### AtEnd(Block)

```cangjie
AtEnd(Block)
```

Function: Insert at the end of a basic block; new expressions are appended to the Block's expression list tail.

Example:

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

Output:

```text
exprs count: 1
```

### AtStart(Block)

```cangjie
AtStart(Block)
```

Function: Insert at the start of a basic block; new expressions are inserted at the beginning of the Block's expression list.

Example:

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

Output:

```text
exprs count: 1
```

### Before(Expression)

```cangjie
Before(Expression)
```

Function: Insert before the specified expression; new expressions are inserted ahead of the target Expression.

Example:

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

Output:

```text
exprs count: 2
```

### After(Expression)

```cangjie
After(Expression)
```

Function: Insert after the specified expression; new expressions are inserted behind the target Expression.

Example:

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

Output:

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

Function: Controls the **behavior mode** of CHIRVisitor when traversing expressions, determining whether to continue traversing subsequent expressions.

Parent Types:

- Equatable\<IRActionMode>

### Continue

```cangjie
Continue
```

Function: Continue traversal; CHIRVisitor will keep visiting subsequent expressions and nested BlockGroups.

Example:

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

Output:

```text
continue
```

### Stop

```cangjie
Stop
```

Function: Stop traversal; CHIRVisitor will terminate the current traversal and will not visit subsequent expressions.

Example:

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

Output:

```text
stop
```

### Skip

```cangjie
Skip
```

Function: Skip nested BlockGroups of the current expression, but continue traversing subsequent expressions.

Example:

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

Output:

```text
skip
```

### operator func ==(IRActionMode)

```cangjie
public operator func ==(rhs: IRActionMode): Bool
```

Function: Determines whether two IRActionMode values are equal.

Parameters:

- rhs: IRActionMode - The other IRActionMode.

Return Value:

- Bool - true if the two IRActionMode values are equal, false otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_eq_IRActionMode same: ${IRActionMode.Continue == IRActionMode.Continue}")
    println("op_eq_IRActionMode diff: ${IRActionMode.Continue == IRActionMode.Stop}")
}
```

Output:

```text
op_eq_IRActionMode same: true
op_eq_IRActionMode diff: false
```

### operator func !=(IRActionMode)

```cangjie
public operator func !=(rhs: IRActionMode): Bool
```

Function: Opposite of `==` in the previous section: `true` when the two IRActionMode values differ, `false` when they are equal (equivalent to `!(this == rhs)`).

Parameters:

- rhs: IRActionMode - The other IRActionMode.

Return Value:

- Bool - `true` if not equal, otherwise `false`.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    println("op_ne_IRActionMode diff: ${IRActionMode.Continue != IRActionMode.Stop}")
    println("op_ne_IRActionMode same: ${IRActionMode.Continue != IRActionMode.Continue}")
}
```

Output:

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

Function: Controls the **behavior mode** of TypeVisitor when traversing types, determining whether to continue traversing subsequent types.

### CONTINUE

```cangjie
CONTINUE
```

Function: Continue traversal; TypeVisitor will keep visiting subsequent types.

Example:

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

Output:

```text
continue
```

### SKIP

```cangjie
SKIP
```

Function: Skip the current type; TypeVisitor will skip this type and continue traversing subsequent types.

Example:

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

Output:

```text
skip
```

### STOP

```cangjie
STOP
```

Function: Stop traversal; TypeVisitor will terminate the current traversal process.

Example:

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

Output:

```text
stop
```
