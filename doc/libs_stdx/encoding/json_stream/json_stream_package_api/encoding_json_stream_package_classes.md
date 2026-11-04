# 类

## class JsonReader

```cangjie
public class JsonReader {
    public init(inputStream: InputStream)
}
```

功能：此类提供 JSON 数据流转仓颉对象的反序列化能力。

使用示例见[使用 Json Stream 进行反序列化](../json_stream_samples/sample_json_reader.md)

### init(InputStream)

```cangjie
public init(inputStream: InputStream)
```

功能：根据输入流创建一个 [JsonReader](encoding_json_stream_package_classes.md#class-jsonreader)， [JsonReader](encoding_json_stream_package_classes.md#class-jsonreader) 从输入流中读取数据时，将跳过非 [JsonString](../../json/json_package_api/encoding_json_package_classes.md#class-jsonstring) 中的空字符（'\0', '\t', '\n', '\r'）。

参数：

- inputStream: InputStream - 输入的 JSON 数据流。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个包含JSON数据的输入流 
    let jsonStr = ##"{"name":"John","age":30}"##
    let buffer = ByteBuffer()
    buffer.write(jsonStr.toArray())

    // 使用构造函数创建JsonReader 
    let reader = JsonReader(buffer)

    // 读取数据验证构造函数 
    reader.startObject()
    let name = reader.readName()
    let nameValue = reader.readValue<String>()
    let age = reader.readName()
    let ageValue = reader.readValue<Int64>()
    reader.endObject()

    println("JsonReader构造函数示例: ${name}=${nameValue}, ${age}=${ageValue}")
}
```

运行结果：

```text
JsonReader构造函数示例: name=John, age=30
```

### func endArray()

```cangjie
public func endArray(): Unit
```

功能：从输入流的当前位置跳过空白字符后消耗一个 ']' 字符，[endArray](encoding_json_stream_package_classes.md#func-endarray) 必须有一个 [startArray](encoding_json_stream_package_classes.md#func-startarray) 与之对应。

异常：

- IllegalStateException - 如果输入流的 JSON 数据不符合格式，抛出异常。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个包含JSON数组的输入流 
    let jsonStr = ##"[1, "Two", 3.14, true]"##
    let buffer = ByteBuffer()
    buffer.write(jsonStr.toArray())

    // 创建JsonReader 
    let reader = JsonReader(buffer)

    // 开始数组 
    reader.startArray()

    // 读取数组元素 
    let first = reader.readValue<Int64>()
    let second = reader.readValue<String>()
    let third = reader.readValue<Float64>()
    let fourth = reader.readValue<Bool>()

    // 结束数组 
    reader.endArray()

    println("读取到的内容: ${first}, ${second}, ${third}, ${fourth}")
}
```

运行结果：

```text
读取到的内容: 1, Two, 3.140000, true
```

### func endObject()

```cangjie
public func endObject(): Unit
```

功能：从输入流的当前位置跳过空白字符后消耗一个 '}' 字符，[endObject](encoding_json_stream_package_classes.md#func-endobject) 必须有一个 [startObject](encoding_json_stream_package_classes.md#func-startobject) 与之对应。

异常：

- IllegalStateException - 如果输入流的 JSON 数据不符合格式，抛出异常。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个包含JSON对象的输入流 
    let jsonStr = ##"{"name":"zhangsan","age":25,"city":"Beijing"}"##
    let buffer = ByteBuffer()
    buffer.write(jsonStr.toArray())

    // 创建JsonReader 
    let reader = JsonReader(buffer)

    // 开始对象 
    reader.startObject()

    // 读取对象属性 
    let nameKey = reader.readName()
    let nameValue = reader.readValue<String>()
    let ageKey = reader.readName()
    let ageValue = reader.readValue<Int64>()
    let cityKey = reader.readName()
    let cityValue = reader.readValue<String>()

    // 结束对象 
    reader.endObject()

    println("读取到的内容: ${nameKey}=${nameValue}, ${ageKey}=${ageValue}, ${cityKey}=${cityValue}")
}
```

运行结果：

```text
读取到的内容: name=zhangsan, age=25, city=Beijing
```

### func peek()

```cangjie
public func peek(): Option<JsonToken>
```

功能：获取输入流的下一个 [JsonToken](encoding_json_stream_package_enums.md#enum-jsontoken) 的类型，不保证下一个 [JsonToken](encoding_json_stream_package_enums.md#enum-jsontoken) 的格式一定正确。

例：如果输入流中的下一个字符为 't'，获取的 [JsonToken](encoding_json_stream_package_enums.md#enum-jsontoken) 将为 [JsonToken](encoding_json_stream_package_enums.md#enum-jsontoken).Bool，但调用 readValue\<Bool>() 不一定成功。

返回值：

- Option\<[JsonToken](encoding_json_stream_package_enums.md#enum-jsontoken)> - 获取到的下一个 [JsonToken](encoding_json_stream_package_enums.md#enum-jsontoken) 的类型，如果到了输入流的结尾返回 None。

异常：

- IllegalStateException - 如果输入流的下一个字符不在以下范围内：(n, t, f, ", 0~9, -, {, }, [, ])。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个包含JSON数据的输入流 
    let jsonStr = ##""Hello, World!""##
    let buffer = ByteBuffer()
    buffer.write(jsonStr.toArray())

    // 创建JsonReader 
    let reader = JsonReader(buffer)

    // 使用peek查看下一个token类型 
    let tokenOption = reader.peek()

    // 检查token类型 
    if (let Some(token) <- tokenOption) {
        match (token) {
            case JsonToken.JsonString => println("下一个token是字符串类型")
            case _ => println("下一个token是其他类型")
        }
    } else {
        println("没有更多数据")
    }
}
```

运行结果：

```text
下一个token是字符串类型
```

### func readName()

```cangjie
public func readName(): String
```

功能：从输入流的当前位置读取一个 name。

返回值：

- String - 读取出的 name 值。

异常：

- IllegalStateException - 如果输入流的 JSON 数据不符合格式，抛出异常。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个包含JSON对象的输入流 
    let jsonStr = ##"{"key1":"value1","key2":5}"##
    let buffer = ByteBuffer()
    buffer.write(jsonStr.toArray())

    // 创建JsonReader 
    let reader = JsonReader(buffer)

    // 开始对象 
    reader.startObject()

    // 读取名称和值 
    let firstKey = reader.readName()
    let firstValue = reader.readValue<String>()
    let secondKey = reader.readName()
    let secondValue = reader.readValue<Int64>()

    // 结束对象 
    reader.endObject()

    println("读取到的内容: ${firstKey}=${firstValue}, ${secondKey}=${secondValue}")
}
```

运行结果：

```text
读取到的内容: key1=value1, key2=5
```

### func readValue\<T>() where T <: JsonDeserializable\<T>

```cangjie
public func readValue<T>(): T where T <: JsonDeserializable<T>
```

功能：从输入流的当前位置读取一个 value。

> **注意：**
>
> 当泛型 T 是 String 类型时，根据下一个 [JsonToken](encoding_json_stream_package_enums.md#enum-jsontoken) 的不同，该函数的返回值将会不同：
>
> - 当下一个 [JsonToken](encoding_json_stream_package_enums.md#enum-jsontoken) 是 [JsonString](../../json/json_package_api/encoding_json_package_classes.md#class-jsonstring) 时， 反序列化过程会按照标准 [ECMA-404 The JSON Data Interchange Standard](https://www.ecma-international.org/publications-and-standards/standards/ecma-404/) 对读到的 String 进行转义。
>
> - 当下一个 [JsonToken](encoding_json_stream_package_enums.md#enum-jsontoken) 是 [JsonInt](../../json/json_package_api/encoding_json_package_classes.md#class-jsonint) [JsonFloat](../../json/json_package_api/encoding_json_package_classes.md#class-jsonfloat) [JsonBool](../../json/json_package_api/encoding_json_package_classes.md#class-jsonbool) [JsonNull](../../json/json_package_api/encoding_json_package_classes.md#class-jsonnull) 其中一个时，将会读取下一个 `value` 字段的原始字符串并返回。
>
> - 当下一个 [JsonToken](encoding_json_stream_package_enums.md#enum-jsontoken) 是其它类型时，调用此接口会抛异常。

返回值：

- T - 读取出的 value 值。

异常：

- IllegalStateException - 如果输入流的 JSON 数据不符合格式，抛出异常。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个包含多种类型JSON值的输入流 
    let jsonStr = ##"["Hello", 123, true, null, 45.67, {"key":"value"}]"##
    let buffer = ByteBuffer()
    buffer.write(jsonStr.toArray())

    // 创建JsonReader 
    let reader = JsonReader(buffer)

    // 开始数组 
    reader.startArray()

    // 读取不同类型的值 
    let strValue = reader.readValue<String>()
    let intValue = reader.readValue<Int64>()
    let boolValue = reader.readValue<Bool>()
    let nullValue = reader.readValue<Option<String>>()
    let floatValue = reader.readValue<Float64>()

    // 数组内对象
    reader.startObject()
    let key = reader.readName()
    let value = reader.readValue<String>()
    reader.endObject()

    // 结束数组 
    reader.endArray()

    println(
        "读取到的内容: 字符串: ${strValue}, 整数: ${intValue}, 布尔: ${boolValue}, 空值: ${nullValue}, 浮点: ${floatValue}, 对象: ${key}=${value}")
}
```

运行结果：

```text
读取到的内容: 字符串: Hello, 整数: 123, 布尔: true, 空值: None, 浮点: 45.670000, 对象: key=value
```

### func readValueBytes()

```cangjie
public func readValueBytes(): Array<Byte>
```

功能：读取输入流的下一组原始数据(字节数组)，不进行转义等操作。

> **说明：**
>
> readValueBytes 的规则如下：
>
> - 如果 next token 是 value，则读取这个 value 的所有原始字节，直到读取到代表结束的符号，如 ',' '}' ']'。
>
> - 如果 next token 是 Name，读取 (name + value) 这一个组合的原始字节数组。
>
> - 如果 next token 是 BeginArray，读取 Array 内的内的所有原始字节。
>
> - 如果 next token 是 BeginObject，读取 Object 内的内的所有原始字节。
>
> - 如果 next token 是 EndArray 或者 EndObject 或者 None，不做任何操作，返回空的数组，再次执行 peek() 仍返回 EndArray 或者 EndObject 或者 None。

返回值：

- Array\<Byte> - 下一组数据对应的原始字节数据。

异常：

- IllegalStateException - 如果输入流的 JSON 数据不符合格式，抛出异常。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个包含JSON数据的输入流 
    let jsonStr = ##"{"key1":"value1","key2":"value2"}"##
    let buffer = ByteBuffer()
    buffer.write(jsonStr.toArray())

    // 创建JsonReader 
    let reader = JsonReader(buffer)

    // 开始对象 
    reader.startObject()

    // 读取原始字节数据，此处 next token 是 name，读取 (name + value) 这一个组合的原始字节数组 
    let valueBytes = reader.readValueBytes()

    // 跳过一个 name
    reader.readName()
    // 读取原始字节数据，此处 next token 是 value，读取 value 原始字节数组
    let valueBytes1 = reader.readValueBytes()

    // 结束对象 
    reader.endObject()

    println("第一个读取的字节数组(转字符串表示)=${String.fromUtf8(valueBytes)}")
    println("第二个读取的字节数组(转字符串表示)=${String.fromUtf8(valueBytes1)}")
}
```

运行结果：

```text
第一个读取的字节数组(转字符串表示)="key1":"value1"
第二个读取的字节数组(转字符串表示)="value2"
```

### func skip()

```cangjie
public func skip(): Unit
```

功能：从输入流的当前位置跳过一组数据。

> **说明：**
>
> Skip 的规则如下：
>
> - 如果 next token 是 value，跳过这个 value, 跳过 value 时不检查该 value 格式是否正确。
>
> - 如果 next token 是 Name，跳过 (name + value) 这一个组合。
>
> - 如果 next token 是 BeginArray，跳过这个 array。
>
> - 如果 next token 是 BeginObject，跳过这个 object。
>
> - 如果 next token 是 EndArray 或者 EndObject 或者 None，不做任何操作，peek 仍返回 EndArray 或者 EndObject 或者 None。

异常：

- IllegalStateException - 如果输入流的 JSON 数据不符合格式，抛出异常。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个包含JSON对象的输入流 
    let jsonStr = ##"[100, {"key1":"value1"}, {"key2":"value2"}, [1, "Two", 3.14, true]]"##
    let buffer = ByteBuffer()
    buffer.write(jsonStr.toArray())

    // 创建JsonReader 
    let reader = JsonReader(buffer)

    // 开始数组
    reader.startArray()

    // 读取第一个内容 
    let firstValue = reader.readValue<Int64>()

    // 跳过了一个对象
    reader.skip()

    // 读取第二个对象的name 
    reader.startObject()
    let secondValue = reader.readName()

    // 跳过了一个value
    reader.skip()

    // 结束了对象
    reader.endObject()

    // 跳过了一个数组
    reader.skip()

    // 可以正确执行，如果没有跳过一个数组，这里会报错
    reader.endArray()
    println("读取到的第一个内容: ${firstValue}")
    println("读取到的第二个内容: ${secondValue}")
}
```

运行结果：

```text
读取到的第一个内容: 100
读取到的第二个内容: key2
```

### func startArray()

```cangjie
public func startArray(): Unit
```

功能：从输入流的当前位置跳过空白字符后消耗一个 '[' 字符。

异常：

- IllegalStateException - 如果输入流的 JSON 数据不符合格式，抛出异常。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个包含JSON数组的输入流 
    let jsonStr = ##"[1, "Two", 3.14, true]"##
    let buffer = ByteBuffer()
    buffer.write(jsonStr.toArray())

    // 创建JsonReader 
    let reader = JsonReader(buffer)

    // 开始数组 
    reader.startArray()

    // 读取数组元素 
    let first = reader.readValue<Int64>()
    let second = reader.readValue<String>()
    let third = reader.readValue<Float64>()
    let fourth = reader.readValue<Bool>()

    // 结束数组 
    reader.endArray()

    println("读取到的内容: ${first}, ${second}, ${third}, ${fourth}")
}
```

运行结果：

```text
读取到的内容: 1, Two, 3.140000, true
```

### func startObject()

```cangjie
public func startObject(): Unit
```

功能：从输入流的当前位置跳过空白字符后消耗一个 '{' 字符。

异常：

- IllegalStateException - 如果输入流的 JSON 数据不符合格式，抛出异常。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个包含JSON对象的输入流 
    let jsonStr = ##"{"name":"zhangsan","age":25,"city":"Beijing"}"##
    let buffer = ByteBuffer()
    buffer.write(jsonStr.toArray())

    // 创建JsonReader 
    let reader = JsonReader(buffer)

    // 开始对象 
    reader.startObject()

    // 读取对象属性 
    let nameKey = reader.readName()
    let nameValue = reader.readValue<String>()
    let ageKey = reader.readName()
    let ageValue = reader.readValue<Int64>()
    let cityKey = reader.readName()
    let cityValue = reader.readValue<String>()

    // 结束对象 
    reader.endObject()

    println("读取到的内容: ${nameKey}=${nameValue}, ${ageKey}=${ageValue}, ${cityKey}=${cityValue}")
}
```

运行结果：

```text
读取到的内容: name=zhangsan, age=25, city=Beijing
```

## class JsonWriter

```cangjie
public class JsonWriter {
    public var writeConfig: WriteConfig = WriteConfig.compact
    public init(out: OutputStream)
}
```

功能：[JsonWriter](encoding_json_stream_package_classes.md#class-jsonwriter) 提供了将仓颉对象序列化到 OutputStream 的能力。

[JsonWriter](encoding_json_stream_package_classes.md#class-jsonwriter) 需要和 interface [JsonSerializable](encoding_json_stream_package_interfaces.md#interface-jsonserializable) 搭配使用，[JsonWriter](encoding_json_stream_package_classes.md#class-jsonwriter) 可以通过 writeValue 来将实现了 [JsonSerializable](encoding_json_stream_package_interfaces.md#interface-jsonserializable) 接口的类型写入到 Stream 中。

> **注意：**
>
> [JsonWriter](encoding_json_stream_package_classes.md#class-jsonwriter) 中使用缓冲区来减少写入 Stream 时的 IO 次数，在结束使用 [JsonWriter](encoding_json_stream_package_classes.md#class-jsonwriter) 之前需要调用 flush 函数来确保缓冲区中的数据全部写入 Stream。

示例：

使用示例见[使用 Json Stream 进行序列化](../json_stream_samples/sample_json_writer.md)

### var writeConfig

```cangjie
public var writeConfig: WriteConfig = WriteConfig.compact
```

功能：序列化格式配置。详见 [WriteConfig](./encoding_json_stream_package_structs.md#struct-writeconfig)。

类型：[WriteConfig](./encoding_json_stream_package_structs.md#struct-writeconfig)

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

### init(OutputStream)

```cangjie
public init(out: OutputStream)
```

功能：构造函数，构造一个将数据写入 out 的实例。

参数：

- out: OutputStream - 目标流

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个输出流 
    let outputStream = ByteBuffer()

    // 使用构造函数创建JsonWriter 
    let writer = JsonWriter(outputStream)

    // 使用writeValue写入一些数据 
    writer.writeValue("Hello, World!")
    writer.flush()

    println("JsonWriter构造函数示例: ${String.fromUtf8(outputStream.bytes())}")
}
```

运行结果：

```text
JsonWriter构造函数示例: "Hello, World!"
```

### func endArray()

```cangjie
public func endArray(): Unit
```

功能：结束序列化当前的 JSON 数组。

异常：

- IllegalStateException - 当前 writer 没有匹配的 startArray 时。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个输出流 
    let outputStream = ByteBuffer()

    // 创建JsonWriter 
    let writer = JsonWriter(outputStream)

    // 开始数组 
    writer.startArray()

    // 写入数组元素 
    writer.writeValue(1)
    writer.writeValue("hello world")
    writer.writeValue(3.14)

    // 结束数组 
    writer.endArray()
    writer.flush()

    println("转字符串表示: ${String.fromUtf8(outputStream.bytes())}")
}
```

运行结果：

```text
转字符串表示: [1,"hello world",3.14]
```

### func endObject()

```cangjie
public func endObject(): Unit
```

功能：结束序列化当前的 JSON object。

异常：

- IllegalStateException - 当前 writer 的状态不应该结束一个 JSON object 时。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个输出流 
    let outputStream = ByteBuffer()

    // 创建JsonWriter 
    let writer = JsonWriter(outputStream)

    // 开始对象 
    writer.startObject()

    // 写入对象属性 
    writer.writeName("property1").writeValue("value1")
    writer.writeName("property2").writeValue(42)

    // 结束对象 
    writer.endObject()
    writer.flush()

    println("转字符串表示: ${String.fromUtf8(outputStream.bytes())}")
}
```

运行结果：

```text
转字符串表示: {"property1":"value1","property2":42}
```

### func flush()

```cangjie
public func flush(): Unit
```

功能：将缓冲区中的数据写入 out，并且调用 out 的 flush 方法。

示例：

<!-- run -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个输出流 
    let outputStream = ByteBuffer()

    // 创建JsonWriter 
    let writer = JsonWriter(outputStream)

    // 写入一些数据 
    writer.writeValue("test data")

    // 调用flush方法确保数据写入流 
    writer.flush()
}
```

### func jsonValue(String)

```cangjie
public func jsonValue(value: String): JsonWriter
```

功能：将符合 JSON value 规范的原始字符串写入 stream。

> **注意：**
>
> 此函数不会对值 value 进行转义，也不会为入参添加双引号。如果使用者能够保证输入的值 value 符合数据转换标准[ECMA-404 The JSON Data Interchange Standard](https://www.ecma-international.org/publications-and-standards/standards/ecma-404/)， 建议使用该函数。

参数：

- value: String - 待写入的字符串。

返回值：

- [JsonWriter](encoding_json_stream_package_classes.md#class-jsonwriter) - 为方便链式调用，返回值为当前 [JsonWriter](encoding_json_stream_package_classes.md#class-jsonwriter) 的引用。

异常：

- IllegalStateException - 当前 writer 的状态不应该写入 value 时。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个输出流 
    let outputStream = ByteBuffer()

    // 创建JsonWriter 
    let writer = JsonWriter(outputStream)

    // 使用jsonValue写入原始JSON字符串 
    writer.jsonValue(##"{"property1":"value1","property2":42}"##)

    writer.flush()

    println("转字符串表示: ${String.fromUtf8(outputStream.bytes())}")
}
```

运行结果：

```text
转字符串表示: {"property1":"value1","property2":42}
```

### func startArray()

```cangjie
public func startArray(): Unit
```

功能：开始序列化一个新的 JSON 数组，每一个 [startArray](encoding_json_stream_package_classes.md#func-startarray-1) 都必须有一个 [endArray](encoding_json_stream_package_classes.md#func-endarray-1) 对应。

异常：

- IllegalStateException - 当前 writer 的状态不应该写入 JSON array 时。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个输出流 
    let outputStream = ByteBuffer()

    // 创建JsonWriter 
    let writer = JsonWriter(outputStream)

    // 开始数组 
    writer.startArray()

    // 写入数组元素 
    writer.writeValue(1)
    writer.writeValue("hello world")
    writer.writeValue(3.14)

    // 结束数组 
    writer.endArray()
    writer.flush()

    println("转字符串表示: ${String.fromUtf8(outputStream.bytes())}")
}
```

运行结果：

```text
转字符串表示: [1,"hello world",3.14]
```

### func startObject()

```cangjie
public func startObject(): Unit
```

功能：开始序列化一个新的 JSON object，每一个 [startObject](encoding_json_stream_package_classes.md#func-startobject-1) 都必须有一个 [endObject](encoding_json_stream_package_classes.md#func-endobject-1) 对应。

异常：

- IllegalStateException - 当前 writer 的状态不应该写入 JSON object 时。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个输出流 
    let outputStream = ByteBuffer()

    // 创建JsonWriter 
    let writer = JsonWriter(outputStream)

    // 开始对象 
    writer.startObject()

    // 写入对象属性 
    writer.writeName("name").writeValue("zhangsan")
    writer.writeName("age").writeValue(30)

    // 结束对象 
    writer.endObject()
    writer.flush()

    println("转字符串表示: ${String.fromUtf8(outputStream.bytes())}")
}
```

运行结果：

```text
转字符串表示: {"name":"zhangsan","age":30}
```

### func writeName(String)

```cangjie
public func writeName(name: String): JsonWriter
```

功能：在 object 结构中写入 name。

参数：

- name: String - 待写入的字符串。

返回值：

- [JsonWriter](encoding_json_stream_package_classes.md#class-jsonwriter) - 当前 [JsonWriter](encoding_json_stream_package_classes.md#class-jsonwriter) 引用。

异常：

- IllegalStateException - 当前 [JsonWriter](encoding_json_stream_package_classes.md#class-jsonwriter) 的状态不应写入参数 `name` 指定字符串时。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个输出流 
    let outputStream = ByteBuffer()

    // 创建JsonWriter 
    let writer = JsonWriter(outputStream)

    // 开始对象 
    writer.startObject()

    // 使用writeName写入名称 
    writer.writeName("key").writeValue("value")
    writer.writeName("count").writeValue(100)

    // 结束对象 
    writer.endObject()
    writer.flush()

    println("转字符串表示: ${String.fromUtf8(outputStream.bytes())}")
}
```

运行结果：

```text
转字符串表示: {"key":"value","count":100}
```

### func writeNullValue()

```cangjie
public func writeNullValue(): JsonWriter
```

功能：向流中写入 JSON value null。

返回值：

- [JsonWriter](encoding_json_stream_package_classes.md#class-jsonwriter) - 为方便链式调用，返回值为当前 [JsonWriter](encoding_json_stream_package_classes.md#class-jsonwriter) 的引用。

异常：

- IllegalStateException - 当前 writer 的状态不应该写入 value 时

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个输出流 
    let outputStream = ByteBuffer()

    // 创建JsonWriter 
    let writer = JsonWriter(outputStream)

    // 开始对象 
    writer.startObject()

    // 写入名称和null值 
    writer.writeName("nullField").writeNullValue()
    writer.writeName("anotherField").writeValue("someValue")

    // 结束对象 
    writer.endObject()
    writer.flush()

    println("转字符串表示: ${String.fromUtf8(outputStream.bytes())}")
}
```

运行结果：

```text
转字符串表示: {"nullField":null,"anotherField":"someValue"}
```

### func writeValue\<T>(T) where T <: JsonSerializable

```cangjie
public func writeValue<T>(v: T): JsonWriter where T <: JsonSerializable
```

功能：将实现了 [JsonSerializable](encoding_json_stream_package_interfaces.md#interface-jsonserializable) 接口的类型写入到 Stream 中。该接口会调用泛型 T 的 toJson 方法向输出流中写入数据。

json.stream 包已经为基础类型 Int64、UInt64、Float64、Bool、String 类型扩展实现了 [JsonSerializable](encoding_json_stream_package_interfaces.md#interface-jsonserializable)，并且为 Collection 类型 Array、ArrayList 和 HashMap 扩展实现了 [JsonSerializable](encoding_json_stream_package_interfaces.md#interface-jsonserializable)。

参数：

- v: T - 待写入的对象，类型为 T。

返回值：

- [JsonWriter](encoding_json_stream_package_classes.md#class-jsonwriter) - 返回当前 [JsonWriter](encoding_json_stream_package_classes.md#class-jsonwriter) 的引用。

异常：

- IllegalStateException - 当前 writer 的状态不应该写入 value 时。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.encoding.json.stream.*

main() {
    // 创建一个输出流 
    let outputStream = ByteBuffer()

    // 创建JsonWriter 
    let writer = JsonWriter(outputStream)

    // 使用writeValue写入各种类型的数据 
    writer.writeValue("Hello")
    writer.flush()

    println("转字符串表示(字符串): ${String.fromUtf8(outputStream.bytes())}")

    // 重新创建流和写入器以写入其他值 
    let outputStream2 = ByteBuffer()
    let writer2 = JsonWriter(outputStream2)

    // 写入对象
    writer2.startObject()
    writer2.writeName("key")
    writer2.writeValue("value")
    writer2.endObject()

    writer2.flush()

    println("转字符串表示(对象): ${String.fromUtf8(outputStream2.bytes())}")

    // 写入数组 
    let outputStream3 = ByteBuffer()
    let writer3 = JsonWriter(outputStream3)

    writer3.writeValue([1, 2, 3, 4])
    writer3.flush()

    println("转字符串表示(数组): ${String.fromUtf8(outputStream3.bytes())}")
}
```

运行结果：

```text
转字符串表示(字符串): "Hello"
转字符串表示(对象): {"key":"value"}
转字符串表示(数组): [1,2,3,4]
```
