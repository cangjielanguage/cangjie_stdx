# 接口

## interface Internable

```cangjie
public interface Internable {
    static func configInternPool(capacity!: Int64, strMaxLength!: Int64): Unit
    static func intern(array: Array<Byte>): String
    static func intern(str: String): String
}
```

功能：用来为 String 类型提供池化缓存扩展。

### static func configInternPool(Int64, Int64)

```cangjie
static func configInternPool(capacity!: Int64, strMaxLength!: Int64): Unit
```

功能：配置字符串缓存池的容量和所缓存的字符串的最大长度，如果不配置，调用 intern 方法时仅返回常量池的字符串对象，而不会缓存新的字符串对象。

参数：

- capacity!: Int64 - 动态缓存池的容量。
- strMaxLength!: Int64 - 动态缓存池中，每个字符串对象的最大长度，超出后不会缓存。

异常：

- IllegalArgumentException - 当 `capacity` 或 `strMaxLength` 参数的值小于等于 0 时，抛出异常。

### static func intern(Array\<Byte>)

```cangjie
static func intern(array: Array<Byte>): String
```

功能：获取与输入数组内容一致的已经被缓存起来的字符串对象。

参数：

- array: Array\<Byte> - 运行时创建的 Byte 数组，该数组计划用于创建一个字符串。

返回值：

- String - 在缓存池中的字符串对象，该字符串对象的 Byte 数组表示与入参一致。

### static func intern(String)

```cangjie
static func intern(str: String): String
```

功能：获取与输入字符串内容一致的已经被缓存起来的字符串对象。

参数：

- str: String - 运行时创建的字符串。

返回值：

- String - 在缓存池中的字符串对象。

### extend String <: Internable

```cangjie
extend String <: Internable
```

功能：为 String 扩展 [Internable](#interface-internable) 接口，以实现将 String 池化缓存。

父类型：

- [Internable](#interface-internable)

#### static func configInternPool(Int64, Int64)

```cangjie
public static func configInternPool(capacity!: Int64 = 8192, strMaxLength!: Int64 = 512): Unit
```

功能：配置字符串缓存池的容量和所缓存的字符串的最大长度，如果不配置，调用 intern 方法时仅返回常量池的字符串对象，而不会缓存新的字符串对象。

参数：

- capacity!: Int64 - 动态缓存池的容量。默认值为 8192。
- strMaxLength!: Int64 - 动态缓存池中，每个字符串对象的最大长度，超出后不会缓存。默认值为 512。

异常：

- IllegalArgumentException - 当 `capacity` 或 `strMaxLength` 参数的值小于等于 0 时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.string_intern.*

main(): Unit {
    // 配置字符串缓存池
    String.configInternPool(capacity: 10000, strMaxLength: 1000)
}
```

#### static func intern(Array\<Byte>)

```cangjie
public static func intern(array: Array<Byte>): String
```

功能：获取与输入数组内容一致的已经被缓存起来的字符串对象。

参数：

- array: Array\<Byte> - 运行时创建的 Byte 数组，该数组计划用于创建一个字符串。

返回值：

- String - 在缓存池中的字符串对象，该字符串对象的 Byte 数组表示与入参一致。

示例：

<!-- verify -->
```cangjie
import stdx.string_intern.*

main(): Unit {
    // 配置字符串缓存池
    String.configInternPool(capacity: 10000, strMaxLength: 1000)

    // 创建一个字节数组
    let byteArray: Array<Byte> = [104, 101, 108, 108, 111] // "hello"的ASCII码

    // 使用intern方法获取缓存的字符串
    let internedStr = String.intern(byteArray)

    println("字节数组池化缓存成功: ${internedStr}")
}
```

运行结果：

```text
字节数组池化缓存成功: hello
```

#### static func intern(String)

```cangjie
public static func intern(str: String): String
```

功能：获取与输入字符串内容一致的已经被缓存起来的字符串对象。

参数：

- str: String - 运行时创建的字符串。

返回值：

- String - 在缓存池中的字符串对象。

示例：

<!-- verify -->
```cangjie
import stdx.string_intern.*

main(): Unit {
    String.configInternPool(capacity: 10000, strMaxLength: 1000)

    // 使用intern方法获取缓存的字符串
    let internedStr = String.intern("hello, 仓颉")

    println("字符串池化缓存成功: ${internedStr}")
}
```

运行结果：

```text
字符串池化缓存成功: hello, 仓颉
```
