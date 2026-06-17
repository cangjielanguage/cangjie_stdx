# 结构体

## struct Position

```cangjie
public struct Position <: ToString {}
```

功能：表示源码中的**一个点**（行号与列号），在 [DebugLocation](chir_package_classes.md#class-debuglocation) 的 `start` / `end` 中使用。行、列在有效时为 **1 起计**；`isValid()` 要求二者均大于 0。

父类型：

- ToString

### prop line

```cangjie
public prop line: Int64
```

功能：源码行号；无效占位时为 `0`（与 `isValid()` 一致）。

类型：Int64

示例：

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

运行结果：

```text
0
```

### prop column

```cangjie
public prop column: Int64
```

功能：源码列号；无效占位时为 `0`。

类型：Int64

示例：

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

运行结果：

```text
0
```

### func isValid()

```cangjie
public func isValid(): Bool
```

功能：当 `line > 0` 且 `column > 0` 时返回 `true`。

返回值：

- Bool - 是否表示真实源码位置。

示例：

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

运行结果：

```text
false
```

### func toString()

```cangjie
public func toString(): String
```

功能：紧凑调试形式 `-行-列`（见源码 `StringBuilder` 拼接）。

返回值：

- String - 位置字符串。

示例：

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

运行结果：

```text
-0-0
```
