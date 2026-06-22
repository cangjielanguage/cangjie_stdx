# Structs

## struct Position

```cangjie
public struct Position <: ToString {}
```

Function: Represents **a point** in source (line and column), used in `start` / `end` on [DebugLocation](chir_package_classes.md#class-debuglocation). When valid, line and column are **1-based**; `isValid()` requires both to be greater than `0`.

Parent Types:

- ToString

**Note:** There is no public constructor. You typically obtain a read-only `Position` from `start` / `end` on [DebugLocation](chir_package_classes.md#class-debuglocation), or from `location` on nodes such as [MemberVar](chir_package_classes.md#class-membervar), then use the properties and methods below.

### prop line

```cangjie
public prop line: Int64
```

Function: Source line number; `0` when invalid (consistent with `isValid()`).

Type: Int64

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    let p = mv.location.start
    println(p.line)
}
```

Output:

```text
0
```

### prop column

```cangjie
public prop column: Int64
```

Function: Source column number; `0` when invalid.

Type: Int64

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    let p = mv.location.start
    println(p.column)
}
```

Output:

```text
0
```

### func isValid()

```cangjie
public func isValid(): Bool
```

Function: Returns `true` when `line > 0` and `column > 0`.

Return Value:

- Bool - Whether this denotes a real source position.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    let p = mv.location.start
    println(p.isValid())
}
```

Output:

```text
false
```

### func toString()

```cangjie
public func toString(): String
```

Function: Compact debug form `-line-column` (see source `StringBuilder` concatenation).

Return Value:

- String - Position string.

Example:

<!-- verify -->
```cangjie
import stdx.chir.*

main() {
    let pkg = Package("p", AccessLevel.Public)
    let st = pkg.addStruct("S_m", "S")
    let mv = st.appendInstanceMemberVar("x", IntType.getInt32())
    let p = mv.location.start
    println(p.toString())
}
```

Output:

```text
-0-0
```
