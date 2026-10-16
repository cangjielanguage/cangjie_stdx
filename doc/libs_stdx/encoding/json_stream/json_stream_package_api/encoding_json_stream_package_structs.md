# 结构体

## struct WriteConfig

```cangjie
public struct WriteConfig {
    public static let compact: WriteConfig
    public static let pretty: WriteConfig
}
```

功能：用于表示 [JsonWriter](./encoding_json_stream_package_classes.md#class-jsonwriter) 的序列化格式配置。

示例：

使用示例见 [WriteConfig 使用示例](../json_stream_samples/sample_json_writeconfig.md)。

### static let compact

```cangjie
public static let compact: WriteConfig
```

功能：提供紧凑的序列化格式。

> **说明：**
>
> compact 的各属性值为：
>
> - newline: ""，空字符串。
> - indent: ""，空字符串。
> - useSpaceAfterSeparators: false。
> - htmlSafe: false。
> - dateTimeFormat: DateTimeFormat.RFC3339。

类型：[WriteConfig](#struct-writeconfig)

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建使用compact配置的JsonWriter 
    let buffer = ByteBuffer()
    let writer = JsonWriter(buffer)
    var config = WriteConfig.compact // 使用紧凑格式

    writer.writeConfig = config

    // 写入简单对象 
    writer.startObject()
    writer.writeName("Name").writeValue("zhangsan")
    writer.writeName("Age").writeValue(18)
    writer.endObject()

    writer.flush()

    // 打印结果 
    println("使用compact配置的JSON输出: ${String.fromUtf8(buffer.bytes())}")
}
```

运行结果：

```text
使用compact配置的JSON输出: {"Name":"zhangsan","Age":18}
```

### static let pretty

```cangjie
public static let pretty: WriteConfig
```

功能：提供整洁的序列化格式。

> **说明：**
>
> pretty 的各属性值为：
>
> - newline: "\n"。
> - indent: "&emsp;&emsp;&emsp;&emsp;"，包含 4 个空格的字符串。
> - useSpaceAfterSeparators: true。
> - htmlSafe: false。
> - dateTimeFormat: DateTimeFormat.RFC3339。

类型：[WriteConfig](#struct-writeconfig)

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建使用pretty配置的JsonWriter 
    let buffer = ByteBuffer()
    let writer = JsonWriter(buffer)
    var config = WriteConfig.pretty // 使用美化格式

    writer.writeConfig = config

    // 写入简单对象 
    writer.startObject()
    writer.writeName("Name").writeValue("zhangsan")
    writer.writeName("Age").writeValue(18)
    writer.endObject()

    writer.flush()

    // 打印结果 
    println("使用pretty配置的JSON输出:\n${String.fromUtf8(buffer.bytes())}")
}
```

运行结果：

```text
使用pretty配置的JSON输出:
{
    "Name": "zhangsan",
    "Age": 18
}
```

### prop dateTimeFormat

```cangjie
public mut prop dateTimeFormat: String
```

功能：用于序列化 DateTime 类型时的格式控制，功能与 DateTime 的 func toString(DateTimeFormat) 一致。

类型：String

示例：

<!-- verify -->
```cangjie
import std.io.*
import std.time.*
import stdx.encoding.json.stream.*

main() {
    // 创建使用pretty配置的JsonWriter 
    let buffer = ByteBuffer()
    let writer = JsonWriter(buffer)
    var config = WriteConfig.pretty // 使用美化格式

    config.dateTimeFormat = "yyyy-MM-dd"
    writer.writeConfig = config

    // 写入简单对象 
    writer.startObject()
    writer.writeName("Name").writeValue("zhangsan")
    writer.writeName("DOB").writeValue(DateTime.of(year: 2026, month: 1, dayOfMonth: 7))
    writer.endObject()

    writer.flush()

    // 打印结果 
    println("修改DateTime格式的JSON输出:\n${String.fromUtf8(buffer.bytes())}")
}
```

运行结果：

```text
修改DateTime格式的JSON输出:
{
    "Name": "zhangsan",
    "DOB": "2026-01-07"
}
```

### prop htmlSafe

```cangjie
public mut prop htmlSafe: Bool
```

功能：用于表示是否转义 HTML 字符 `<`、`>`、`&`、`=` 和 `'`。

该值为 true 时，会将 HTML 字符转义为对应的 Unicode 编码的字符串。

该选项只对 json value 中的字符串字面量有效。

类型：Bool

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建使用pretty配置的JsonWriter 
    let buffer = ByteBuffer()
    let writer = JsonWriter(buffer)
    var config = WriteConfig.pretty // 使用美化格式

    config.htmlSafe = true
    writer.writeConfig = config

    // 写入包含HTML字符的对象 
    writer.startObject()
    writer.writeName("Content").writeValue("<script>alert('XSS')</script>")
    writer.writeName("Title").writeValue("Hello & Welcome")
    writer.endObject()

    writer.flush()

    // 打印结果 
    println("启用htmlSafe的JSON输出:\n${String.fromUtf8(buffer.bytes())}")
}
```

运行结果：

```text
启用htmlSafe的JSON输出:
{
    "Content": "\u003cscript\u003ealert(\u0027XSS\u0027)\u003c/script\u003e",
    "Title": "Hello \u0026 Welcome"
}
```

### prop indent

```cangjie
public mut prop indent: String
```

功能：序列化过程中，为每个缩进级别填充的缩进字符串，用于定义序列化输出内容的缩进格式。

取值必须匹配正则表达式：^[ \t]*$，即字符串仅可包含空格、制表符，或为空字符串。

无换行行为时，该属性不生效。

类型：String

异常：

- IllegalArgumentException - 设置的字符串包含 ' ' 或者 '\t' 以外的字符。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建使用compact配置的JsonWriter 
    let buffer = ByteBuffer()
    let writer = JsonWriter(buffer)
    var config = WriteConfig.pretty

    config.indent = " " // 1个空格对应的输出1个缩进
    writer.writeConfig = config

    // 写入简单对象 
    writer.startObject()
    writer.writeName("Name").writeValue("zhangsan")
    writer.writeName("Age").writeValue(18)
    writer.endObject()

    writer.flush()

    // 打印结果 
    println("使用indent格式的JSON输出:\n${String.fromUtf8(buffer.bytes())}")
}
```

运行结果：

```text
使用indent格式的JSON输出:
{
 "Name": "zhangsan",
 "Age": 18
}
```

### prop newline

```cangjie
public mut prop newline: String
```

功能：用于表示序列化时填入的换行符。取值应匹配正则 `^[\r\n]*$` 。

当该值不为空字符串且合法时，JsonWriter 调用 startObject 和 startArray 操作、插入元素、以及它们的结束操作会产生新的换行。

当该值为空字符串时，不会触发换行。

类型：String

异常：

- IllegalArgumentException - 设置的字符串包含 '\r' 或者 '\n' 以外的字符。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建使用compact配置的JsonWriter 
    let buffer = ByteBuffer()
    let writer = JsonWriter(buffer)
    var config = WriteConfig.pretty // 使用美化格式

    config.newline = "\n\n" // 换行符
    writer.writeConfig = config

    // 写入简单对象 
    writer.startObject()
    writer.writeName("Name").writeValue("zhangsan")
    writer.writeName("Age").writeValue(18)
    writer.endObject()

    writer.flush()

    // 打印结果 
    println("使用newline格式的JSON输出:\n${String.fromUtf8(buffer.bytes())}")
}
```

运行结果：

```text
使用newline格式的JSON输出:
{

    "Name": "zhangsan",

    "Age": 18

}
```

### prop useSpaceAfterSeparators

```cangjie
public mut prop useSpaceAfterSeparators: Bool
```

功能：用于表示序列化时在 ':' 和 ',' 后是否加一个空格。

该值为 true 时，每插入一个 field name 或者 array 元素后会自动写入一个空格。

该选项只对 json Object 中的 field 以及 json Array 中的元素有效。

类型：Bool

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建使用compact配置的JsonWriter 
    let buffer = ByteBuffer()
    let writer = JsonWriter(buffer)
    var config = WriteConfig.compact // 使用紧凑格式

    config.useSpaceAfterSeparators = true // 启用在分隔符后添加空格
    writer.writeConfig = config

    // 写入简单对象 
    writer.startObject()
    writer.writeName("Name").writeValue("zhangsan")
    writer.writeName("Age").writeValue(18)
    writer.endObject()

    writer.flush()

    // 打印结果 
    println("启用useSpaceAfterSeparators的JSON输出: ${String.fromUtf8(buffer.bytes())}")
}
```

运行结果：

```text
启用useSpaceAfterSeparators的JSON输出: {"Name": "zhangsan","Age": 18}
```
