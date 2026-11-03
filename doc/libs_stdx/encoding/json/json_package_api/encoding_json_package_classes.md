# 类

## class JsonArray

```cangjie
public class JsonArray <: JsonValue {
    public init()
    public init(list: ArrayList<JsonValue>)
    public init(list: Array<JsonValue>)
}
```

功能：此类为 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 实现子类，主要用于封装数组类型的 JSON 数据。

父类型：

- [JsonValue](#class-jsonvalue)

示例：

使用示例见 [JsonArray 使用示例](../json_samples/json_array_sample.md)。

### init()

```cangjie
public init()
```

功能：创建空 [JsonArray](encoding_json_package_classes.md#class-jsonarray)。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jsonArray: JsonArray = JsonArray()
    println(jsonArray)
    println("JsonValue的数量: ${jsonArray.size()}")
}
```

运行结果：

```text
[]
JsonValue的数量: 0
```

<!--Del_sink-->
### init(this @local!)

```cangjie
public exclave init(this @local!)
```

功能：创建一个空的 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 实例。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 待构造的 `@local!` 实例。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    println("size=${ja.size()}")
}
```

运行结果：

```text
size=0
```
<!--DelEnd_sink-->
### init(Array\<JsonValue>)

```cangjie
public init(list: Array<JsonValue>)
```

功能：将指定的 Array 类型实例封装成 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 实例。

参数：

- list: Array\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> - 用于创建 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 的 Array。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

main() {
    let a: JsonValue = JsonNull()
    let b: JsonValue = JsonBool(true)
    let c: JsonValue = JsonInt(123)
    let d: JsonValue = JsonString("hello")
    let e: JsonValue = JsonObject(HashMap<String, JsonValue>([("hello", JsonString("world"))]))

    let array: Array<JsonValue> = [a, b, c, d, e]
    let jsonArray: JsonArray = JsonArray(array)

    println(jsonArray)
}
```

运行结果：

```text
[null,true,123,"hello",{"hello":"world"}]
```

<!--Del_sink-->
### init(this @local!, Array\<JsonValue> @local!)

```cangjie
public exclave init(this @local!, list: Array<JsonValue> @local!)
```

功能：根据 Array 构造一个 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 实例。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 待构造的 `@local!` 实例。
- list: Array\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local! - 用于创建 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 的 `@local!` Array。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    let arr: Array<JsonValue> @local! = [v1, v2]
    let ja: JsonArray @local! = JsonArray(arr) @local!
    let s: String @local! = ja.toString()
    println("ja=${String(s)}")
    println("size=${ja.size()}")
}
```

运行结果：

```text
ja=[1,2]
size=2
```
<!--DelEnd_sink-->
### init(ArrayList\<JsonValue>)

```cangjie
public init(list: ArrayList<JsonValue>)
```

功能：将指定的 ArrayList 类型实例封装成 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 实例。

参数：

- list: ArrayList\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> - 用于创建 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 的 ArrayList。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

main() {
    var a: JsonValue = JsonNull()
    var b: JsonValue = JsonBool(true)
    var c: JsonValue = JsonInt(123)
    var d: JsonValue = JsonString("hello")
    var e: JsonValue = JsonObject(HashMap<String, JsonValue>([("hello", JsonString("world"))]))

    var list: ArrayList<JsonValue> = ArrayList<JsonValue>()
    list.add(a)
    list.add(b)
    list.add(c)
    list.add(d)
    list.add(e)

    let jsonArray: JsonArray = JsonArray(list)
    println(jsonArray)
}
```

运行结果：

```text
[null,true,123,"hello",{"hello":"world"}]
```

<!--Del_sink-->
### init(this @local!, ArrayList\<JsonValue> @local!)

```cangjie
public exclave init(this @local!, list: ArrayList<JsonValue> @local!)
```

功能：根据 ArrayList 构造一个 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 实例。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 待构造的 `@local!` 实例。
- list: ArrayList\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local! - 用于创建 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 的 `@local!` ArrayList。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

main() {
    let list: ArrayList<JsonValue> @local! = ArrayList<JsonValue>() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    list.add(v1)
    list.add(v2)
    let ja: JsonArray @local! = JsonArray(list) @local!
    let s: String @local! = ja.toString()
    println("ja=${String(s)}")
    println("size=${ja.size()}")
}
```

运行结果：

```text
ja=[1,2]
size=2
```
<!--DelEnd_sink-->
### func add(JsonValue)

```cangjie
public func add(jv: JsonValue): JsonArray
```

功能：向 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中加入 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 数据。

参数：

- jv: [JsonValue](encoding_json_package_classes.md#class-jsonvalue) - 需要加入的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。

返回值：

- [JsonArray](encoding_json_package_classes.md#class-jsonarray) - 加入数据后的 [JsonArray](encoding_json_package_classes.md#class-jsonarray)。

示例：

<!-- verify -->
```cangjie
import std.collection.*
import stdx.encoding.json.*

main() {
    var jsonArray: JsonArray = JsonArray()
    println("初始 JsonArray: ${jsonArray}")
    println("初始数量: ${jsonArray.size()}")

    // 添加不同类型的 JsonValue
    jsonArray = jsonArray.add(JsonNull())
    println("添加 JsonNull 后: ${jsonArray}")
    println("数量: ${jsonArray.size()}")

    jsonArray = jsonArray.add(JsonBool(true))
    println("添加 JsonBool(true) 后: ${jsonArray}")
    println("数量: ${jsonArray.size()}")

    jsonArray = jsonArray.add(JsonString("hello"))
    println("添加 JsonString(\"hello\") 后: ${jsonArray}")
    println("数量: ${jsonArray.size()}")

    jsonArray = jsonArray.add(JsonObject(HashMap<String, JsonValue>([("hello", JsonString("world"))])))
    println("添加 JsonObject 后: ${jsonArray}")
    println("数量: ${jsonArray.size()}")
}
```

运行结果：

```text
初始 JsonArray: []
初始数量: 0
添加 JsonNull 后: [null]
数量: 1
添加 JsonBool(true) 后: [null,true]
数量: 2
添加 JsonString("hello") 后: [null,true,"hello"]
数量: 3
添加 JsonObject 后: [null,true,"hello",{"hello":"world"}]
数量: 4
```

<!--Del_sink-->
### func add(JsonValue)

```cangjie
public exclave func add(this @local!, jv: JsonValue @local!): JsonArray @local!
```

功能：向 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中加入 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 数据。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。
- jv: [JsonValue](encoding_json_package_classes.md#class-jsonvalue) @local! - 待加入的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 数据。

返回值：

- [JsonArray](encoding_json_package_classes.md#class-jsonarray) @local! - 加入数据后的 [JsonArray](encoding_json_package_classes.md#class-jsonarray)。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    let s: String @local! = ja.toString()
    println("ja=${String(s)}")
    println("size=${ja.size()}")
}
```

运行结果：

```text
ja=[1,2]
size=2
```
<!--DelEnd_sink-->
### func get(Int64)

```cangjie
public func get(index: Int64): Option<JsonValue>
```

功能：获取 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中指定索引的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)，并用 Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> 封装。

参数：

- index: Int64 - 指定的索引。

返回值：

- Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> - 对应索引的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 数据的封装形式。

示例：

<!-- verify -->
```cangjie
import std.collection.*
import stdx.encoding.json.*

main() {
    var jsonArray: JsonArray = JsonArray()
    jsonArray = jsonArray.add(JsonNull())
    jsonArray = jsonArray.add(JsonBool(true))
    jsonArray = jsonArray.add(JsonInt(100))
    jsonArray = jsonArray.add(JsonString("hello"))
    jsonArray = jsonArray.add(JsonObject(HashMap<String, JsonValue>([("hello", JsonString("world"))])))

    println("JsonArray 内容: ${jsonArray}")
    println("数量: ${jsonArray.size()}")

    // 测试获取不同索引的元素
    let opt1 = jsonArray.get(0)
    println("索引 0 的值: ${opt1.getOrThrow()}")

    let opt2 = jsonArray.get(2)
    println("索引 2 的值: ${opt2.getOrThrow()}")

    let opt3 = jsonArray.get(4)
    println("索引 4 的值: ${opt3.getOrThrow()}")

    // 测试超出范围的索引
    let opt4 = jsonArray.get(10)
    if (let Some(v) <- opt4) {
        println("索引 10 的值: ${v}")
    } else {
        println("索引 10 的值不存在")
    }
}
```

运行结果：

```text
JsonArray 内容: [null,true,100,"hello",{"hello":"world"}]
数量: 5
索引 0 的值: null
索引 2 的值: 100
索引 4 的值: {"hello":"world"}
索引 10 的值不存在
```

<!--Del_sink-->
### func get(Int64)

```cangjie
public exclave func get(this @local!, index: Int64): Option<JsonValue> @local!
```

功能：获取 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中指定索引的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)，并用 Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> 封装。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。
- index: Int64 - 指定的索引。

返回值：

- Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local! - 指定索引对应的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)，用 Option 封装。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    match (ja.get(0)) {
        case Some(v) =>
            let sv: String @local! = v.toString()
            println("first=${String(sv)}")
        case None => println("none")
    }
}
```

运行结果：

```text
first=1
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func get(Int64)

```cangjie
public exclave func get(this @local?, index: Int64): Option<JsonValue> @local?
```

功能：获取 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中指定索引的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)，并用 Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> 封装。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。
- index: Int64 - 指定的索引。

返回值：

- Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local? - 指定索引对应的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)，用 Option 封装。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    match (ja.get(1)) {
        case Some(v) =>
            let sv: String @local! = v.toString()
            println("second=${String(sv)}")
        case None => println("none")
    }
}
```

运行结果：

```text
second=2
```
<!--DelEnd_sink-->
### func getItems()

```cangjie
public func getItems(): ArrayList<JsonValue>
```

功能：获取 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中的 items 数据。

返回值：

- ArrayList\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> - [JsonArray](encoding_json_package_classes.md#class-jsonarray) 的 items 数据。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

main() {
    var jsonArray: JsonArray = JsonArray()
    jsonArray = jsonArray.add(JsonNull())
    jsonArray = jsonArray.add(JsonBool(true))
    jsonArray = jsonArray.add(JsonInt(100))
    jsonArray = jsonArray.add(JsonString("hello"))
    jsonArray = jsonArray.add(JsonObject(HashMap<String, JsonValue>([("hello", JsonString("world"))])))

    println("JsonArray 内容: ${jsonArray}")
    println("数量: ${jsonArray.size()}")

    // 获取 items 列表
    let items = jsonArray.getItems()
    let itemsSize = items.size
    println("获取的 items 列表数量: ${itemsSize}")

    // 遍历 items 列表
    for (i in items) {
        println("值: ${i}")
    }
}
```

运行结果：

```text
JsonArray 内容: [null,true,100,"hello",{"hello":"world"}]
数量: 5
获取的 items 列表数量: 5
值: null
值: true
值: 100
值: "hello"
值: {"hello":"world"}
```

<!--Del_sink-->
### func getItems()

```cangjie
public exclave func getItems(this @local!): ArrayList<JsonValue> @local!
```

功能：获取 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中的 items 数据。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- ArrayList\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local! - [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中的 items 数据。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    let items: ArrayList<JsonValue> @local! = ja.getItems()
    println("size=${items.size}")
}
```

运行结果：

```text
size=2
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func getItems()

```cangjie
public func getItems(this @local?): ArrayList<JsonValue> @local?
```

功能：获取 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中的 items 数据。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- ArrayList\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local? - [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中的 items 数据。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    let items: ArrayList<JsonValue> @local? = ja.getItems()
    println("size=${items.size}")
}
```

运行结果：

```text
size=2
```
<!--DelEnd_sink-->
### func kind()

```cangjie
public func kind(): JsonKind
```

功能：返回当前 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsArray）。

返回值：

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - 当前 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsArray）。

示例：

<!-- verify -->
```cangjie
import std.collection.*
import stdx.encoding.json.*

main() {
    var jsonArray: JsonArray = JsonArray()
    jsonArray = jsonArray.add(JsonNull())
    jsonArray = jsonArray.add(JsonBool(true))
    jsonArray = jsonArray.add(JsonInt(100))
    jsonArray = jsonArray.add(JsonObject(HashMap<String, JsonValue>([("hello", JsonString("world"))])))

    // 获取 JsonArray 的 kind
    let kind = jsonArray.kind()

    // 使用 match 语句来处理 JsonKind 枚举
    match (kind) {
        case JsonKind.JsArray => println("变量 jsonArray 的 kind 是 JsArray")
        case _ => println("变量 jsonArray 的 kind 不是 JsArray")
    }
}
```

运行结果：

```text
变量 jsonArray 的 kind 是 JsArray
```

<!--Del_sink-->
### func kind()

```cangjie
public func kind(this @local?): JsonKind
```

功能：返回当前 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsArray）。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - 当前 `@local?` [JsonArray](encoding_json_package_classes.md#class-jsonarray) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsArray）。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    match (ja.kind()) {
        case JsonKind.JsArray => println("kind is JsArray")
        case _ => println("kind is not JsArray")
    }
}
```

运行结果：

```text
kind is JsArray
```
<!--DelEnd_sink-->
### func size()

```cangjie
public func size(): Int64
```

功能：获取 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 的数量。

返回值：

- Int64 - [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 的数量。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonArray: JsonArray = JsonArray()

    println("初始 JsonArray 数量: ${jsonArray.size()}")

    // 添加元素并检查数量变化
    jsonArray = jsonArray.add(JsonNull())
    println("添加 JsonNull 后的数量: ${jsonArray.size()}")

    jsonArray = jsonArray.add(JsonBool(true))
    println("添加 JsonBool 后的数量: ${jsonArray.size()}")
    // 验证最终内容
    println("最终 JsonArray 内容: ${jsonArray}")
}
```

运行结果：

```text
初始 JsonArray 数量: 0
添加 JsonNull 后的数量: 1
添加 JsonBool 后的数量: 2
最终 JsonArray 内容: [null,true]
```

<!--Del_sink-->
### func size()

```cangjie
public func size(this @local?): Int64
```

功能：获取 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 的数量。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- Int64 - 当前 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 的数量。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    println("size=${ja.size()}")
}
```

运行结果：

```text
size=2
```
<!--DelEnd_sink-->
### func toJsonString()

```cangjie
public func toJsonString(): String
```

功能：将 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 转换为 JSON 格式的 (带有空格换行符) 的字符串。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

main() {
    var jsonArray: JsonArray = JsonArray()
    jsonArray = jsonArray.add(JsonNull())
    jsonArray = jsonArray.add(JsonBool(true))
    jsonArray = jsonArray.add(JsonInt(123))
    jsonArray = jsonArray.add(JsonString("hello"))
    jsonArray = jsonArray.add(JsonObject(HashMap<String, JsonValue>([("hello", JsonString("world"))])))

    println("JsonArray 内容: ${jsonArray}")
    println("数量: ${jsonArray.size()}")

    // 使用 toJsonString 方法
    let jsonString = jsonArray.toJsonString()
    println("toJsonString 结果:")
    println(jsonString)

    // 对比 toString 方法
    let toStringResult = jsonArray
    println("toString 结果: ${toStringResult}")
}
```

运行结果：

```text
JsonArray 内容: [null,true,123,"hello",{"hello":"world"}]
数量: 5
toJsonString 结果:
[
  null,
  true,
  123,
  "hello",
  {
    "hello": "world"
  }
]
toString 结果: [null,true,123,"hello",{"hello":"world"}]
```

<!--Del_sink-->
### func toJsonString()

```cangjie
public exclave func toJsonString(this @local!): String @local!
```

功能：将当前 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 转换为 JSON 格式的 (带有空格换行符) 的字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    let s: String @local! = ja.toJsonString()
    println(String(s))
}
```

运行结果：

```text
[
  1,
  2
]
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toJsonString()

```cangjie
public func toJsonString(this @local?): String
```

功能：将当前 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 转换为 JSON 格式的 (带有空格换行符) 的字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    let s: String = ja.toJsonString()
    println(s)
}
```

运行结果：

```text
[
  1,
  2
]
```
<!--DelEnd_sink-->
### func toJsonString(Int64, Bool, String)

```cangjie
public func toJsonString(depth: Int64, bracketInNewLine!: Bool = false, indent!: String = "  "): String
```

功能：将 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 转换为 JSON 格式的字符串。该函数将指定初始的缩进深度、首括号前是否缩进以及缩进字符串。

参数：

- depth: Int64 - 指定的缩进深度。
- bracketInNewLine!: Bool - 为 `true` 时，在首括号前添加 `depth` 份 `indent`；为 `false` 时不添加该缩进。此参数不插入换行符。
- indent!: String - 指定的缩进字符串，缩进字符串中只允许空格和制表符的组合，默认为两个空格。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- IllegalArgumentException - 如果 depth 为负数，或 indent 中存在 ' ' 和 '\t' 以外的字符，则抛出异常。
- JsonException - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import std.collection.*
import stdx.encoding.json.*

main() {
    var jsonArray: JsonArray = JsonArray()
    jsonArray = jsonArray.add(JsonNull())
    jsonArray = jsonArray.add(JsonBool(true))
    jsonArray = jsonArray.add(JsonInt(123))
    jsonArray = jsonArray.add(JsonString("hello"))
    jsonArray = jsonArray.add(JsonObject(HashMap<String, JsonValue>([("hello", JsonString("world"))])))

    println("=== 自定义参数toJsonString ===")
    let result = jsonArray.toJsonString(1, bracketInNewLine: true, indent: " ")
    println(result)
    println("=== 默认toJsonString ===")
    let result1 = jsonArray.toJsonString()
    println(result1)
}
```

运行结果：

```text
=== 自定义参数toJsonString ===
 [
  null,
  true,
  123,
  "hello",
  {
   "hello": "world"
  }
 ]
=== 默认toJsonString ===
[
  null,
  true,
  123,
  "hello",
  {
    "hello": "world"
  }
]
```

<!--Del_sink-->
### func toJsonString(Int64, Bool, String)

```cangjie
public exclave func toJsonString(this @local!, depth: Int64, bracketInNewLine!: Bool = false, indent!: String @~local = "  "): String @local!
```

功能：将当前 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 转换为 JSON 格式的字符串。该函数将指定初始的缩进深度、首括号前是否缩进以及缩进字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。
- depth: Int64 - 初始缩进深度，也是 JSON 写入深度的起始值；嵌套值会继续增加写入深度。
- bracketInNewLine!: Bool - 为 `true` 时，在首括号前添加 `depth` 份 `indent`；为 `false` 时不添加该缩进。此参数不插入换行符。
- indent!: String @~local - 指定的缩进字符串，缩进字符串中只允许空格和制表符的组合，默认为两个空格。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

异常：

- IllegalArgumentException - 如果 depth 为负数，或 indent 中存在 ' ' 和 '\t' 以外的字符，则抛出异常。
- JsonException - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    let s: String @local! = ja.toJsonString(1, bracketInNewLine: true, indent: " ")
    println(String(s))
}
```

运行结果：

```text
 [
  1,
  2
 ]
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toJsonString(Int64, Bool, String)

```cangjie
public func toJsonString(this @local?, depth: Int64, bracketInNewLine!: Bool = false, indent!: String @local? = "  "): String
```

功能：将当前 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 转换为 JSON 格式的字符串。该函数将指定初始的缩进深度、首括号前是否缩进以及缩进字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。
- depth: Int64 - 初始缩进深度，也是 JSON 写入深度的起始值；嵌套值会继续增加写入深度。
- bracketInNewLine!: Bool - 为 `true` 时，在首括号前添加 `depth` 份 `indent`；为 `false` 时不添加该缩进。此参数不插入换行符。
- indent!: String @local? - 指定的缩进字符串，缩进字符串中只允许空格和制表符的组合，默认为两个空格。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- IllegalArgumentException - 如果 depth 为负数，或 indent 中存在 ' ' 和 '\t' 以外的字符，则抛出异常。
- JsonException - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    let s: String = ja.toJsonString(1, bracketInNewLine: true, indent: " ")
    println(s)
}
```

运行结果：

```text
 [
  1,
  2
 ]
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(): String
```

功能：将 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 转换为 JSON 格式的 (带有空格换行符) 的字符串，不对字符串值中的 html 特殊字符 `&` 转义；对象键中的 `&` 仍转义为 `\u0026`。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonArray: JsonArray = JsonArray()
    jsonArray = jsonArray.add(JsonString("~!@#$%^&*();':\"/.,<>?\\|"))

    // 使用 toJsonString 方法
    let jsonString = jsonArray.toJsonString()
    println("toJsonString 结果（仅&符号转义）:")
    println(jsonString)

    // 使用 toJsonStringWithoutEscaping 方法
    let jsonStringWithoutEscaping = jsonArray.toJsonStringWithoutEscaping()
    println("toJsonStringWithoutEscaping 结果（无转义）:")
    println(jsonStringWithoutEscaping)
}
```

运行结果：

```text
toJsonString 结果（仅&符号转义）:
[
  "~!@#$%^\u0026*();':\"/.,<>?\\|"
]
toJsonStringWithoutEscaping 结果（无转义）:
[
  "~!@#$%^&*();':\"/.,<>?\\|"
]
```

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public exclave func toJsonStringWithoutEscaping(this @local!): String @local!
```

功能：将当前 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 转换为 JSON 格式的 (带有空格换行符) 的字符串，不对 html 特殊字符 `&` 转义。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    let s: String @local! = ja.toJsonStringWithoutEscaping()
    println(String(s))
}
```

运行结果：

```text
[
  1,
  2
]
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(this @local?): String
```

功能：将当前 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 转换为 JSON 格式的 (带有空格换行符) 的字符串，不对 html 特殊字符 `&` 转义。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    let s: String = ja.toJsonStringWithoutEscaping()
    println(s)
}
```

运行结果：

```text
[
  1,
  2
]
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping(Int64, Bool, String)

```cangjie
public func toJsonStringWithoutEscaping(depth: Int64, bracketInNewLine!: Bool = false, indent!: String = "  "): String
```

功能：将 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 转换为 JSON 格式的字符串。该函数将指定初始的缩进深度、首括号前是否缩进以及缩进字符串，不对字符串值中的 html 特殊字符 `&` 转义；对象键中的 `&` 仍转义为 `\u0026`。

参数：

- depth: Int64 - 指定的缩进深度。
- bracketInNewLine!: Bool - 为 `true` 时，在首括号前添加 `depth` 份 `indent`；为 `false` 时不添加该缩进。此参数不插入换行符。
- indent!: String - 指定的缩进字符串，缩进字符串中只允许空格和制表符的组合，默认为两个空格。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- IllegalArgumentException - 如果 depth 为负数，或 indent 中存在 ' ' 和 '\t' 以外的字符，则抛出异常。
- JsonException - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonArray: JsonArray = JsonArray()
    jsonArray = jsonArray.add(JsonString("~!@#$%^&*();':\"/.,<>?\\|"))

    // 使用 toJsonString 方法
    let jsonString = jsonArray.toJsonString(2, bracketInNewLine: true, indent: " ")
    println("toJsonString （带参数） 结果（仅&符号转义）:")
    println(jsonString)

    // 使用 toJsonStringWithoutEscaping 方法
    let jsonStringWithoutEscaping = jsonArray.toJsonStringWithoutEscaping(2, bracketInNewLine: true, indent: " ")
    println("toJsonStringWithoutEscaping （带参数） 结果（无转义）:")
    println(jsonStringWithoutEscaping)
}
```

运行结果：

```text
toJsonString （带参数） 结果（仅&符号转义）:
  [
   "~!@#$%^\u0026*();':\"/.,<>?\\|"
  ]
toJsonStringWithoutEscaping （带参数） 结果（无转义）:
  [
   "~!@#$%^&*();':\"/.,<>?\\|"
  ]
```

<!--Del_sink-->
### func toJsonStringWithoutEscaping(Int64, Bool, String)

```cangjie
public exclave func toJsonStringWithoutEscaping(this @local!, depth: Int64, bracketInNewLine!: Bool = false, indent!: String @~local = "  "): String @local!
```

功能：将当前 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 转换为 JSON 格式的字符串。该函数将指定初始的缩进深度、首括号前是否缩进以及缩进字符串，不对 html 特殊字符 `&` 转义。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。
- depth: Int64 - 初始缩进深度，也是 JSON 写入深度的起始值；嵌套值会继续增加写入深度。
- bracketInNewLine!: Bool - 为 `true` 时，在首括号前添加 `depth` 份 `indent`；为 `false` 时不添加该缩进。此参数不插入换行符。
- indent!: String @~local - 指定的缩进字符串，缩进字符串中只允许空格和制表符的组合，默认为两个空格。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

异常：

- IllegalArgumentException - 如果 depth 为负数，或 indent 中存在 ' ' 和 '\t' 以外的字符，则抛出异常。
- JsonException - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    let s: String @local! = ja.toJsonStringWithoutEscaping(1, bracketInNewLine: true, indent: " ")
    println(String(s))
}
```

运行结果：

```text
 [
  1,
  2
 ]
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toJsonStringWithoutEscaping(Int64, Bool, String)

```cangjie
public func toJsonStringWithoutEscaping(this @local?, depth: Int64, bracketInNewLine!: Bool = false, indent!: String @local? = "  "): String
```

功能：将当前 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 转换为 JSON 格式的字符串。该函数将指定初始的缩进深度、首括号前是否缩进以及缩进字符串，不对 html 特殊字符 `&` 转义。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。
- depth: Int64 - 初始缩进深度，也是 JSON 写入深度的起始值；嵌套值会继续增加写入深度。
- bracketInNewLine!: Bool - 为 `true` 时，在首括号前添加 `depth` 份 `indent`；为 `false` 时不添加该缩进。此参数不插入换行符。
- indent!: String @local? - 指定的缩进字符串，缩进字符串中只允许空格和制表符的组合，默认为两个空格。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- IllegalArgumentException - 如果 depth 为负数，或 indent 中存在 ' ' 和 '\t' 以外的字符，则抛出异常。
- JsonException - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    let s: String = ja.toJsonStringWithoutEscaping(1, bracketInNewLine: true, indent: " ")
    println(s)
}
```

运行结果：

```text
 [
  1,
  2
 ]
```
<!--DelEnd_sink-->
### func toString()

```cangjie
public func toString(): String
```

功能：将 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 转换为字符串。

返回值：

- String - 转换后的字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import std.collection.*
import stdx.encoding.json.*

main() {
    var jsonArray: JsonArray = JsonArray()
    jsonArray = jsonArray.add(JsonNull())
    jsonArray = jsonArray.add(JsonBool(true))
    jsonArray = jsonArray.add(JsonInt(123))
    jsonArray = jsonArray.add(JsonString("hello&world"))
    jsonArray = jsonArray.add(JsonObject(HashMap<String, JsonValue>([("hello", JsonString("world"))])))

    // 使用 toString 方法
    let stringResult = jsonArray
    println("toString 结果: ${stringResult}")
}
```

运行结果：

```text
toString 结果: [null,true,123,"hello\u0026world",{"hello":"world"}]
```

<!--Del_sink-->
### func toString()

```cangjie
public exclave func toString(this @local?): String @local!
```

功能：将当前 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 转换为字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- String @local! - 转换后的 `@local!` 字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    let s: String @local! = ja.toString()
    println("ja=${String(s)}")
}
```

运行结果：

```text
ja=[1,2]
```
<!--DelEnd_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(): String
```

功能：将 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 转换为字符串，不对字符串值中的 html 特殊字符 `&` 转义；对象键中的 `&` 仍转义为 `\u0026`。

返回值：

- String - 转换后的字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import std.collection.*
import stdx.encoding.json.*

main() {
    var jsonArray: JsonArray = JsonArray()
    jsonArray = jsonArray.add(JsonNull())
    jsonArray = jsonArray.add(JsonBool(true))
    jsonArray = jsonArray.add(JsonInt(123))
    jsonArray = jsonArray.add(JsonString("hello&world"))
    jsonArray = jsonArray.add(JsonObject(HashMap<String, JsonValue>([("hello", JsonString("world"))])))

    // 使用 toStringWithoutEscaping 方法
    let stringResult = jsonArray
    println("toString 结果: ${stringResult.toStringWithoutEscaping()}")
}
```

运行结果：

```text
toString 结果: [null,true,123,"hello&world",{"hello":"world"}]
```

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public exclave func toStringWithoutEscaping(this @local!): String @local!
```

功能：将当前 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 转换为字符串，不对 html 特殊字符 `&` 转义。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    let s: String @local! = ja.toStringWithoutEscaping()
    println("ja=${String(s)}")
}
```

运行结果：

```text
ja=[1,2]
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(this @local?): String
```

功能：将当前 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 转换为字符串，不对 html 特殊字符 `&` 转义。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- String - 转换后的字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    let s: String = ja.toStringWithoutEscaping()
    println("ja=${s}")
}
```

运行结果：

```text
ja=[1,2]
```
<!--DelEnd_sink-->
### operator func \[](Int64)

```cangjie
public operator func [](index: Int64): JsonValue
```

功能：获取 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中指定索引的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。

参数：

- index: Int64 - 指定的索引。

返回值：

- [JsonValue](encoding_json_package_classes.md#class-jsonvalue) - 对应索引的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果 index 不是 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 的有效索引，抛出异常。

示例：

<!-- verify -->
```cangjie
import std.collection.*
import stdx.encoding.json.*

main() {
    var jsonArray: JsonArray = JsonArray()
    jsonArray = jsonArray.add(JsonNull())
    jsonArray = jsonArray.add(JsonBool(true))
    jsonArray = jsonArray.add(JsonInt(123))
    jsonArray = jsonArray.add(JsonString("hello&world"))
    jsonArray = jsonArray.add(JsonObject(HashMap<String, JsonValue>([("hello", JsonString("world"))])))

    println("JsonArray 内容: ${jsonArray}")

    // 使用下标操作符访问元素
    println("使用下标操作符访问元素:")
    let element0 = jsonArray[0]
    println("索引 0 的值: ${element0}")

    let element1 = jsonArray[1]
    println("索引 1 的值: ${element1}")

    let element3 = jsonArray[3]
    println("索引 3 的值: ${element3}")

    // 测试越界访问（应该会抛出异常）
    println("测试越界访问:")
    try {
        let elementOut = jsonArray[10]
        println("索引 10 的值: ${elementOut}")
    } catch (e: Exception) {
        println("捕获到异常: ${e.message}")
    }
}
```

运行结果：

```text
JsonArray 内容: [null,true,123,"hello\u0026world",{"hello":"world"}]
使用下标操作符访问元素:
索引 0 的值: null
索引 1 的值: true
索引 3 的值: "hello\u0026world"
测试越界访问:
捕获到异常: Index '10' does not exist in JsonArray.
```

<!--Del_sink-->
### operator func \[](Int64)

```cangjie
public exclave operator func [](this @local!, index: Int64): JsonValue @local!
```

功能：获取 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中指定索引的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。
- index: Int64 - 指定的索引。

返回值：

- [JsonValue](encoding_json_package_classes.md#class-jsonvalue) @local! - 指定索引对应的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果索引在 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中不存在，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(10) @local!
    let v2: JsonValue @local! = JsonInt(20) @local!
    ja.add(v1)
    ja.add(v2)
    let v: JsonValue @local! = ja[0]
    let ji: JsonInt @local! = v.asInt()
    println("first=${ji.getValue()}")
}
```

运行结果：

```text
first=10
```
<!--DelEnd_sink-->

<!--Del_sink-->
### operator func \[](Int64)

```cangjie
public exclave operator func [](this @local?, index: Int64): JsonValue @local?
```

功能：获取 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中指定索引的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。
- index: Int64 - 指定的索引。

返回值：

- [JsonValue](encoding_json_package_classes.md#class-jsonvalue) @local? - 指定索引对应的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果索引在 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 中不存在，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    let v: JsonValue @local? = ja[1]
    let s: String @local! = v.toString()
    println("second=${String(s)}")
}
```

运行结果：

```text
second=2
```
<!--DelEnd_sink-->
## class JsonBool

```cangjie
public class JsonBool <: JsonValue {
    public init(bv: Bool)
}
```

功能：此类为 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 实现子类，主要用于封装 true 或者 false 的 JSON 数据。

父类型：

- [JsonValue](#class-jsonvalue)

### init(Bool)

```cangjie
public init(bv: Bool)
```

功能：将指定的 Bool 类型实例封装成 [JsonBool](encoding_json_package_classes.md#class-jsonbool) 实例。

参数：

- bv: Bool - Bool 类型。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonTrue: JsonBool = JsonBool(true)

    println("JsonBool(true) 创建的对象: ${jsonTrue}")
}
```

运行结果：

```text
JsonBool(true) 创建的对象: true
```

<!--Del_sink-->
### init(this @local!, Bool)

```cangjie
public exclave init(this @local!, bv: Bool)
```

功能：将指定的 Bool 类型实例封装成 [JsonBool](encoding_json_package_classes.md#class-jsonbool) 实例。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 待构造的 `@local!` 实例。
- bv: Bool - 用于创建 [JsonBool](encoding_json_package_classes.md#class-jsonbool) 的 Bool 值。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jb: JsonBool @local! = JsonBool(true) @local!
    println("value=${jb.getValue()}")
}
```

运行结果：

```text
value=true
```
<!--DelEnd_sink-->
### func getValue()

```cangjie
public func getValue(): Bool
```

功能：获取 [JsonBool](encoding_json_package_classes.md#class-jsonbool) 中 value 的实际值。

返回值：

- Bool - value 的实际值。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonTrue: JsonBool = JsonBool(true)

    var trueValue = jsonTrue.getValue()

    println("JsonBool(true) 的值: ${trueValue}")
}
```

运行结果：

```text
JsonBool(true) 的值: true
```

<!--Del_sink-->
### func getValue()

```cangjie
public func getValue(this @local?): Bool
```

功能：获取 [JsonBool](encoding_json_package_classes.md#class-jsonbool) 中 value 的实际值。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- Bool - value 的实际值。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeBool(): JsonBool @local? {
    let b: JsonBool @local! = JsonBool(true) @local!
    b
}

main() {
    let jb: JsonBool @local? = makeBool()
    println("value=${jb.getValue()}")
}
```

运行结果：

```text
value=true
```
<!--DelEnd_sink-->
### func kind()

```cangjie
public func kind(): JsonKind
```

功能：返回当前 [JsonBool](encoding_json_package_classes.md#class-jsonbool) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsBool）。

返回值：

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - 当前 [JsonBool](encoding_json_package_classes.md#class-jsonbool) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsBool）。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonTrue: JsonBool = JsonBool(true)

    var trueKind = jsonTrue.kind()

    // 使用 match 语句处理类型
    match (trueKind) {
        case JsonKind.JsBool => println("变量jsonTrue的类型是JsBool")
        case _ => println("变量jsonTrue的类型不是JsBool")
    }
}
```

运行结果：

```text
变量jsonTrue的类型是JsBool
```

<!--Del_sink-->
### func kind()

```cangjie
public func kind(this @local?): JsonKind
```

功能：返回当前 [JsonBool](encoding_json_package_classes.md#class-jsonbool) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsBool）。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - 当前 `@local?` [JsonBool](encoding_json_package_classes.md#class-jsonbool) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsBool）。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeBool(): JsonBool @local? {
    let b: JsonBool @local! = JsonBool(true) @local!
    b
}

main() {
    let jb: JsonBool @local? = makeBool()
    match (jb.kind()) {
        case JsonKind.JsBool => println("kind is JsBool")
        case _ => println("kind is not JsBool")
    }
}
```

运行结果：

```text
kind is JsBool
```
<!--DelEnd_sink-->
### func toJsonString()

```cangjie
public func toJsonString(): String
```

功能：将 [JsonBool](encoding_json_package_classes.md#class-jsonbool) 转换为 JSON 格式的 (带有空格换行符) 字符串。

返回值：

- String - 转换后的 JSON 格式字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonTrue: JsonBool = JsonBool(true)

    var trueJsonStr = jsonTrue.toJsonString()

    println("JsonBool(true) 的 JSON 字符串: ${trueJsonStr}")
}
```

运行结果：

```text
JsonBool(true) 的 JSON 字符串: true
```

<!--Del_sink-->
### func toJsonString()

```cangjie
public exclave func toJsonString(this @local!): String @local!
```

功能：将当前 [JsonBool](encoding_json_package_classes.md#class-jsonbool) 转换为 JSON 格式的 (带有空格换行符) 字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jb: JsonBool @local! = JsonBool(true) @local!
    let s: String @local! = jb.toJsonString()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=true
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(): String
```

功能：等同 toJsonString()。

返回值：

- String - 转换后的 JSON 格式字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonTrue: JsonBool = JsonBool(true)

    var trueJsonStr = jsonTrue.toJsonStringWithoutEscaping()

    println("等同 toJsonString(): ${trueJsonStr}")
}
```

运行结果：

```text
等同 toJsonString(): true
```

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public exclave func toJsonStringWithoutEscaping(this @local!): String @local!
```

功能：将当前 [JsonBool](encoding_json_package_classes.md#class-jsonbool) 转换为 JSON 格式的 (带有空格换行符) 字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jb: JsonBool @local! = JsonBool(true) @local!
    let s: String @local! = jb.toJsonStringWithoutEscaping()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=true
```
<!--DelEnd_sink-->
### func toString()

```cangjie
public func toString(): String
```

功能：将 [JsonBool](encoding_json_package_classes.md#class-jsonbool) 转换为字符串。

返回值：

- String - 转换后的字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonTrue: JsonBool = JsonBool(true)

    var trueStr = jsonTrue.toString()

    println("JsonBool(true) 的字符串表示: ${trueStr}")
}
```

运行结果：

```text
JsonBool(true) 的字符串表示: true
```

<!--Del_sink-->
### func toString()

```cangjie
public exclave func toString(this @local?): String @local!
```

功能：将当前 [JsonBool](encoding_json_package_classes.md#class-jsonbool) 转换为字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- String @local! - 转换后的 `@local!` 字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeBool(): JsonBool @local? {
    let b: JsonBool @local! = JsonBool(true) @local!
    b
}

main() {
    let jb: JsonBool @local? = makeBool()
    let s: String @local! = jb.toString()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=true
```
<!--DelEnd_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(): String
```

功能：等同 toString()。

返回值：

- String - 转换后的字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonTrue: JsonBool = JsonBool(true)

    var trueStr = jsonTrue.toStringWithoutEscaping()

    println("等同toString(): ${trueStr}")
}
```

运行结果：

```text
等同toString(): true
```

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public exclave func toStringWithoutEscaping(this @local!): String @local!
```

功能：将当前 [JsonBool](encoding_json_package_classes.md#class-jsonbool) 转换为字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jb: JsonBool @local! = JsonBool(true) @local!
    let s: String @local! = jb.toStringWithoutEscaping()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=true
```
<!--DelEnd_sink-->
## class JsonFloat

```cangjie
public class JsonFloat <: JsonValue {
    public init(fv: Float64)
    public init(v: Int64)
}
```

功能：此类为 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 实现子类，主要用于封装浮点类型的 JSON 数据。

父类型：

- [JsonValue](#class-jsonvalue)

### init(Float64)

```cangjie
public init(fv: Float64)
```

功能：将指定的 Float64 类型实例封装成 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 实例。

参数：

- fv: Float64 - Float64 类型。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jsonFloat: JsonFloat = JsonFloat(3.14159)

    println("JsonFloat(3.14159) 创建的对象: ${jsonFloat}")
}
```

运行结果：

```text
JsonFloat(3.14159) 创建的对象: 3.141590
```

<!--Del_sink-->
### init(this @local!, Float64)

```cangjie
public exclave init(this @local!, fv: Float64)
```

功能：将指定的 Float64 类型实例封装成 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 实例。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 待构造的 `@local!` 实例。
- fv: Float64 - 用于创建 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 的 Float64 值。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jf: JsonFloat @local! = JsonFloat(1.5) @local!
    println("value=${jf.getValue()}")
}
```

运行结果：

```text
value=1.500000
```
<!--DelEnd_sink-->
### init(Int64)

```cangjie
public init(v: Int64)
```

功能：将指定的 Int64 类型实例封装成 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 实例。

参数：

- v: Int64 - Int64 类型。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jsonFloat: JsonFloat = JsonFloat(42)

    println("JsonFloat(42) 创建的对象: ${jsonFloat}")
}
```

运行结果：

```text
JsonFloat(42) 创建的对象: 42.000000
```

<!--Del_sink-->
### init(this @local!, Int64)

```cangjie
public exclave init(this @local!, v: Int64)
```

功能：将指定的 Int64 类型实例封装成 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 实例。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 待构造的 `@local!` 实例。
- v: Int64 - 用于创建 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 的 Int64 值。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jf: JsonFloat @local! = JsonFloat(42) @local!
    println("value=${jf.getValue()}")
}
```

运行结果：

```text
value=42.000000
```
<!--DelEnd_sink-->
### func getValue()

```cangjie
public func getValue(): Float64
```

功能：获取 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 中 value 的实际值。

返回值：

- Float64 - value 的实际值。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jsonFloat: JsonFloat = JsonFloat(3.14159)

    let value = jsonFloat.getValue()

    println("JsonFloat(3.14159) 的值: ${value}")
}
```

运行结果：

```text
JsonFloat(3.14159) 的值: 3.141590
```

<!--Del_sink-->
### func getValue()

```cangjie
public func getValue(this @local?): Float64
```

功能：获取 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 中 value 的实际值。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- Float64 - value 的实际值。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeFloat(): JsonFloat @local? {
    let f: JsonFloat @local! = JsonFloat(3.5) @local!
    f
}

main() {
    let jf: JsonFloat @local? = makeFloat()
    println("value=${jf.getValue()}")
}
```

运行结果：

```text
value=3.500000
```
<!--DelEnd_sink-->
### func kind()

```cangjie
public func kind(): JsonKind
```

功能：返回当前 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsFloat）。

返回值：

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - 当前 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsFloat）。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jsonFloat: JsonFloat = JsonFloat(3.14159)

    let kind = jsonFloat.kind()

    // 使用 match 语句处理类型
    match (kind) {
        case JsonKind.JsFloat => println("变量jsonFloat的类型是JsFloat")
        case _ => println("变量jsonFloat的类型不是JsFloat")
    }
}
```

运行结果：

```text
变量jsonFloat的类型是JsFloat
```

<!--Del_sink-->
### func kind()

```cangjie
public func kind(this @local?): JsonKind
```

功能：返回当前 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsFloat）。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - 当前 `@local?` [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsFloat）。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeFloat(): JsonFloat @local? {
    let f: JsonFloat @local! = JsonFloat(3.5) @local!
    f
}

main() {
    let jf: JsonFloat @local? = makeFloat()
    match (jf.kind()) {
        case JsonKind.JsFloat => println("kind is JsFloat")
        case _ => println("kind is not JsFloat")
    }
}
```

运行结果：

```text
kind is JsFloat
```
<!--DelEnd_sink-->
### func toJsonString()

```cangjie
public func toJsonString(): String
```

功能：将 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 转换为 JSON 格式的 (带有空格换行符) 字符串。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当封装的 Float64 值为 NaN 或正负无穷时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jsonFloat: JsonFloat = JsonFloat(3.14159)

    let jsonStr = jsonFloat.toJsonString()

    println("JsonFloat(3.14159) 的 JSON 字符串: ${jsonStr}")
}
```

运行结果：

```text
JsonFloat(3.14159) 的 JSON 字符串: 3.141590
```

<!--Del_sink-->
### func toJsonString()

```cangjie
public exclave func toJsonString(this @local!): String @local!
```

功能：将当前 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 转换为 JSON 格式的 (带有空格换行符) 字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当封装的 Float64 值为 NaN 或正负无穷时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jf: JsonFloat @local! = JsonFloat(3.5) @local!
    let s: String @local! = jf.toJsonString()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=3.500000
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(): String
```

功能：等同 toJsonString()。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当封装的 Float64 值为 NaN 或正负无穷时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jsonFloat: JsonFloat = JsonFloat(3.14159)

    let jsonStr = jsonFloat.toJsonStringWithoutEscaping()

    println("等同 toJsonString(): ${jsonStr}")
}
```

运行结果：

```text
等同 toJsonString(): 3.141590
```

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public exclave func toJsonStringWithoutEscaping(this @local!): String @local!
```

功能：将当前 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 转换为 JSON 格式的 (带有空格换行符) 字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当封装的 Float64 值为 NaN 或正负无穷时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jf: JsonFloat @local! = JsonFloat(3.5) @local!
    let s: String @local! = jf.toJsonStringWithoutEscaping()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=3.500000
```
<!--DelEnd_sink-->
### func toString()

```cangjie
public func toString(): String
```

功能：将 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 转换为字符串。

返回值：

- String - 转换后的字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当封装的 Float64 值为 NaN 或正负无穷时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jsonFloat: JsonFloat = JsonFloat(3.14159)

    let str = jsonFloat.toString()

    println("JsonFloat(3.14159) 的字符串表示: ${str}")
}
```

运行结果：

```text
JsonFloat(3.14159) 的字符串表示: 3.141590
```

<!--Del_sink-->
### func toString()

```cangjie
public exclave func toString(this @local?): String @local!
```

功能：将当前 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 转换为字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- String @local! - 转换后的 `@local!` 字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当封装的 Float64 值为 NaN 或正负无穷时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeFloat(): JsonFloat @local? {
    let f: JsonFloat @local! = JsonFloat(3.5) @local!
    f
}

main() {
    let jf: JsonFloat @local? = makeFloat()
    let s: String @local! = jf.toString()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=3.500000
```
<!--DelEnd_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(): String
```

功能：等同 toString()。

返回值：

- String - 转换后的字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当封装的 Float64 值为 NaN 或正负无穷时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jsonFloat: JsonFloat = JsonFloat(3.14159)

    let str = jsonFloat.toStringWithoutEscaping()

    println("等同toString(): ${str}")
}
```

运行结果：

```text
等同toString(): 3.141590
```

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public exclave func toStringWithoutEscaping(this @local!): String @local!
```

功能：将当前 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 转换为字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当封装的 Float64 值为 NaN 或正负无穷时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jf: JsonFloat @local! = JsonFloat(3.5) @local!
    let s: String @local! = jf.toStringWithoutEscaping()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=3.500000
```
<!--DelEnd_sink-->
## class JsonInt

```cangjie
public class JsonInt <: JsonValue {
    public init(iv: Int64)
}
```

功能：此类为 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 实现子类，主要用于封装整数类型的 JSON 数据。

父类型：

- [JsonValue](#class-jsonvalue)

### init(Int64)

```cangjie
public init(iv: Int64)
```

功能：将指定的 Int64 类型实例封装成 [JsonInt](encoding_json_package_classes.md#class-jsonint) 实例。

参数：

- iv: Int64 - 用于创建 [JsonInt](encoding_json_package_classes.md#class-jsonint) 的 Int64。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonInt: JsonInt = JsonInt(42)

    println("JsonInt(42) 创建的对象: ${jsonInt}")
}
```

运行结果：

```text
JsonInt(42) 创建的对象: 42
```

<!--Del_sink-->
### init(this @local!, Int64)

```cangjie
public exclave init(this @local!, iv: Int64)
```

功能：将指定的 Int64 类型实例封装成 [JsonInt](encoding_json_package_classes.md#class-jsonint) 实例。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 待构造的 `@local!` 实例。
- iv: Int64 - 用于创建 [JsonInt](encoding_json_package_classes.md#class-jsonint) 的 Int64 值。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ji: JsonInt @local! = JsonInt(123) @local!
    println("value=${ji.getValue()}")
}
```

运行结果：

```text
value=123
```
<!--DelEnd_sink-->
### func getValue()

```cangjie
public func getValue(): Int64
```

功能：获取 [JsonInt](encoding_json_package_classes.md#class-jsonint) 中 value 的实际值。

返回值：

- Int64 - value 的实际值。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonInt: JsonInt = JsonInt(42)

    var value = jsonInt.getValue()

    println("JsonInt(42) 的值: ${value}")
}
```

运行结果：

```text
JsonInt(42) 的值: 42
```

<!--Del_sink-->
### func getValue()

```cangjie
public func getValue(this @local?): Int64
```

功能：获取 [JsonInt](encoding_json_package_classes.md#class-jsonint) 中 value 的实际值。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- Int64 - value 的实际值。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeInt(): JsonInt @local? {
    let i: JsonInt @local! = JsonInt(123) @local!
    i
}

main() {
    let ji: JsonInt @local? = makeInt()
    println("value=${ji.getValue()}")
}
```

运行结果：

```text
value=123
```
<!--DelEnd_sink-->
### func kind()

```cangjie
public func kind(): JsonKind
```

功能：返回当前 [JsonInt](encoding_json_package_classes.md#class-jsonint) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsInt）。

返回值：

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - 当前 [JsonInt](encoding_json_package_classes.md#class-jsonint) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsInt）。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonInt: JsonInt = JsonInt(42)

    var kind = jsonInt.kind()

    // 使用 match 语句处理类型
    match (kind) {
        case JsonKind.JsInt => println("变量jsonInt的类型是JsInt")
        case _ => println("变量jsonInt的类型不是JsInt")
    }
}
```

运行结果：

```text
变量jsonInt的类型是JsInt
```

<!--Del_sink-->
### func kind()

```cangjie
public func kind(this @local?): JsonKind
```

功能：返回当前 [JsonInt](encoding_json_package_classes.md#class-jsonint) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsInt）。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - 当前 `@local?` [JsonInt](encoding_json_package_classes.md#class-jsonint) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsInt）。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeInt(): JsonInt @local? {
    let i: JsonInt @local! = JsonInt(123) @local!
    i
}

main() {
    let ji: JsonInt @local? = makeInt()
    match (ji.kind()) {
        case JsonKind.JsInt => println("kind is JsInt")
        case _ => println("kind is not JsInt")
    }
}
```

运行结果：

```text
kind is JsInt
```
<!--DelEnd_sink-->
### func toJsonString()

```cangjie
public func toJsonString(): String
```

功能：将 [JsonInt](encoding_json_package_classes.md#class-jsonint) 转换为 JSON 格式的 (带有空格换行符) 字符串。

返回值：

- String - 转换后的 JSON 格式字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonInt: JsonInt = JsonInt(42)

    var jsonStr = jsonInt.toJsonString()

    println("JsonInt(42) 的 JSON 字符串: ${jsonStr}")
}
```

运行结果：

```text
JsonInt(42) 的 JSON 字符串: 42
```

<!--Del_sink-->
### func toJsonString()

```cangjie
public exclave func toJsonString(this @local!): String @local!
```

功能：将当前 [JsonInt](encoding_json_package_classes.md#class-jsonint) 转换为 JSON 格式的 (带有空格换行符) 字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ji: JsonInt @local! = JsonInt(123) @local!
    let s: String @local! = ji.toJsonString()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=123
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(): String
```

功能：等同 toJsonString()。

返回值：

- String - 转换后的 JSON 格式字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonInt: JsonInt = JsonInt(42)

    var jsonStr = jsonInt.toJsonStringWithoutEscaping()

    println("等同 toJsonString(): ${jsonStr}")
}
```

运行结果：

```text
等同 toJsonString(): 42
```

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public exclave func toJsonStringWithoutEscaping(this @local!): String @local!
```

功能：将当前 [JsonInt](encoding_json_package_classes.md#class-jsonint) 转换为 JSON 格式的 (带有空格换行符) 字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ji: JsonInt @local! = JsonInt(123) @local!
    let s: String @local! = ji.toJsonStringWithoutEscaping()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=123
```
<!--DelEnd_sink-->
### func toString()

```cangjie
public func toString(): String
```

功能：将 [JsonInt](encoding_json_package_classes.md#class-jsonint) 转换为字符串。

返回值：

- String - 转换后的字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonInt: JsonInt = JsonInt(42)

    var str = jsonInt.toString()

    println("JsonInt(42) 的字符串表示: ${str}")
}
```

运行结果：

```text
JsonInt(42) 的字符串表示: 42
```

<!--Del_sink-->
### func toString()

```cangjie
public exclave func toString(this @local?): String @local!
```

功能：将当前 [JsonInt](encoding_json_package_classes.md#class-jsonint) 转换为字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- String @local! - 转换后的 `@local!` 字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeInt(): JsonInt @local? {
    let i: JsonInt @local! = JsonInt(123) @local!
    i
}

main() {
    let ji: JsonInt @local? = makeInt()
    let s: String @local! = ji.toString()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=123
```
<!--DelEnd_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(): String
```

功能：等同 toString()。

返回值：

- String - 转换后的字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonInt: JsonInt = JsonInt(42)

    var str = jsonInt.toStringWithoutEscaping()

    println("等同toString(): ${str}")
}
```

运行结果：

```text
等同toString(): 42
```

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public exclave func toStringWithoutEscaping(this @local!): String @local!
```

功能：将当前 [JsonInt](encoding_json_package_classes.md#class-jsonint) 转换为字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ji: JsonInt @local! = JsonInt(123) @local!
    let s: String @local! = ji.toStringWithoutEscaping()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=123
```
<!--DelEnd_sink-->
## class JsonNull

```cangjie
public class JsonNull <: JsonValue
```

功能：此类为 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 实现子类，主要用于封装 null 的 JSON 数据。

父类型：

- [JsonValue](#class-jsonvalue)

### func kind()

```cangjie
public func kind(): JsonKind
```

功能：返回当前 [JsonNull](encoding_json_package_classes.md#class-jsonnull) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsNull）。

返回值：

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - 当前 [JsonNull](encoding_json_package_classes.md#class-jsonnull) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsNull）。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonNull: JsonNull = JsonNull()

    let kind = jsonNull.kind()
    // 使用 match 语句处理类型
    match (kind) {
        case JsonKind.JsNull => println("变量jsonNull的类型是JsNull")
        case _ => println("变量jsonNull的类型不是JsNull")
    }
}
```

运行结果：

```text
变量jsonNull的类型是JsNull
```

<!--Del_sink-->
### func kind()

```cangjie
public func kind(this @local?): JsonKind
```

功能：返回当前 [JsonNull](encoding_json_package_classes.md#class-jsonnull) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsNull）。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - 当前 `@local?` [JsonNull](encoding_json_package_classes.md#class-jsonnull) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsNull）。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeNull(): JsonNull @local? {
    let n: JsonNull @local! = JsonNull() @local!
    n
}

main() {
    let n: JsonNull @local? = makeNull()
    match (n.kind()) {
        case JsonKind.JsNull => println("kind is JsNull")
        case _ => println("kind is not JsNull")
    }
}
```

运行结果：

```text
kind is JsNull
```
<!--DelEnd_sink-->
### func toJsonString()

```cangjie
public func toJsonString(): String
```

功能：将 [JsonNull](encoding_json_package_classes.md#class-jsonnull) 转换为 JSON 格式的 (带有空格换行符) 字符串。

返回值：

- String - 转换后的 JSON 格式字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonNull: JsonNull = JsonNull()

    var jsonStr = jsonNull.toJsonString()
    println("JsonNull 的 JSON 字符串: ${jsonStr}")
}
```

运行结果：

```text
JsonNull 的 JSON 字符串: null
```

<!--Del_sink-->
### func toJsonString()

```cangjie
public exclave func toJsonString(this @local!): String @local!
```

功能：将当前 [JsonNull](encoding_json_package_classes.md#class-jsonnull) 转换为 JSON 格式的 (带有空格换行符) 字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let n: JsonNull @local! = JsonNull() @local!
    let s: String @local! = n.toJsonString()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=null
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(): String
```

功能：等同 toJsonString()。

返回值：

- String - 转换后的 JSON 格式字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonNull: JsonNull = JsonNull()

    var jsonStr = jsonNull.toJsonStringWithoutEscaping()

    println("等同 toJsonString(): ${jsonStr}")
}
```

运行结果：

```text
等同 toJsonString(): null
```

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public exclave func toJsonStringWithoutEscaping(this @local!): String @local!
```

功能：将当前 [JsonNull](encoding_json_package_classes.md#class-jsonnull) 转换为 JSON 格式的 (带有空格换行符) 字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let n: JsonNull @local! = JsonNull() @local!
    let s: String @local! = n.toJsonStringWithoutEscaping()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=null
```
<!--DelEnd_sink-->
### func toString()

```cangjie
public func toString(): String
```

功能：将 [JsonNull](encoding_json_package_classes.md#class-jsonnull) 转换为字符串。

返回值：

- String - 转换后的字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonNull: JsonNull = JsonNull()

    var str = jsonNull.toString()
    println("JsonNull 的字符串表示: ${str}")
}
```

运行结果：

```text
JsonNull 的字符串表示: null
```

<!--Del_sink-->
### func toString()

```cangjie
public exclave func toString(this @local?): String @local!
```

功能：将当前 [JsonNull](encoding_json_package_classes.md#class-jsonnull) 转换为字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- String @local! - 转换后的 `@local!` 字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeNull(): JsonNull @local? {
    let n: JsonNull @local! = JsonNull() @local!
    n
}

main() {
    let n: JsonNull @local? = makeNull()
    let s: String @local! = n.toString()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=null
```
<!--DelEnd_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(): String
```

功能：等同 toString()。

返回值：

- String - 转换后的字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonNull: JsonNull = JsonNull()

    var str = jsonNull.toStringWithoutEscaping()

    println("等同 toJsonString(): ${str}")
}
```

运行结果：

```text
等同 toJsonString(): null
```

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public exclave func toStringWithoutEscaping(this @local!): String @local!
```

功能：将当前 [JsonNull](encoding_json_package_classes.md#class-jsonnull) 转换为字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let n: JsonNull @local! = JsonNull() @local!
    let s: String @local! = n.toStringWithoutEscaping()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=null
```
<!--DelEnd_sink-->
## class JsonObject

```cangjie
public class JsonObject <: JsonValue {
    public init()
    public init(map: HashMap<String, JsonValue>)
}
```

功能：此类为 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 实现子类，主要用于封装 object 类型的 JSON 数据。

父类型：

- [JsonValue](#class-jsonvalue)

### init()

```cangjie
public init()
```

功能：创建空 [JsonObject](encoding_json_package_classes.md#class-jsonobject)。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonObject: JsonObject = JsonObject()

    println("创建空JsonObject: ${jsonObject}")
}
```

运行结果：

```text
创建空JsonObject: {}
```

<!--Del_sink-->
### init(this @local!)

```cangjie
public exclave init(this @local!)
```

功能：创建一个空的 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 实例。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 待构造的 `@local!` 实例。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    println("size=${jo.size()}")
}
```

运行结果：

```text
size=0
```
<!--DelEnd_sink-->
### init(HashMap\<String, JsonValue>)

```cangjie
public init(map: HashMap<String, JsonValue>)
```

功能：将指定的 HashMap 类型实例封装成 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 实例。

参数：

- map: HashMap\<String, [JsonValue](encoding_json_package_classes.md#class-jsonvalue)> - data 数据。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

main() {
    var fields = HashMap<String, JsonValue>()
    fields.add("name", JsonString("张三"))
    fields.add("age", JsonInt(25))
    fields.add("student", JsonBool(true))

    // 使用HashMap创建新的JsonObject
    var jsonObject2: JsonObject = JsonObject(fields)

    println("使用HashMap创建JsonObject: ${jsonObject2}")
}
```

运行结果：

```text
使用HashMap创建JsonObject: {"name":"张三","age":25,"student":true}
```

<!--Del_sink-->
### init(this @local!, HashMap\<String, JsonValue> @local!)

```cangjie
public exclave init(this @local!, map: HashMap<String, JsonValue> @local!)
```

功能：根据 HashMap 构造一个 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 实例。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 待构造的 `@local!` 实例。
- map: HashMap\<String, [JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local! - 用于创建 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 的 `@local!` HashMap。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

main() {
    let map: HashMap<String, JsonValue> @local! = HashMap<String, JsonValue>() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    map.add(k, v)
    let jo: JsonObject @local! = JsonObject(map) @local!
    let s: String @local! = jo.toString()
    println("jo=${String(s)}")
    println("size=${jo.size()}")
}
```

运行结果：

```text
jo={"hello":"world"}
size=1
```
<!--DelEnd_sink-->
### func containsKey(String)

```cangjie
public func containsKey(key: String): Bool
```

功能：判断 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中是否存在 key。

参数：

- key: String - 指定的 key。

返回值：

- Bool - 存在返回 true，不存在返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonObject: JsonObject = JsonObject()
    jsonObject.put("name", JsonString("张三"))
    jsonObject.put("age", JsonInt(25))

    var hasName = jsonObject.containsKey("name")
    var hasAddress = jsonObject.containsKey("address")

    println("JsonObject是否包含name键: ${hasName}")
    println("JsonObject是否包含address键: ${hasAddress}")
}
```

运行结果：

```text
JsonObject是否包含name键: true
JsonObject是否包含address键: false
```

<!--Del_sink-->
### func containsKey(String)

```cangjie
public func containsKey(this @local?, key: String @local?): Bool
```

功能：判断 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中是否存在 key。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。
- key: String @local? - 指定的键。

返回值：

- Bool - 如果存在该 key，返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let k: String @local? = "hello"
    println("contains=${jo.containsKey(k)}")
    let missing: String @local? = "foo"
    println("missing=${jo.containsKey(missing)}")
}
```

运行结果：

```text
contains=true
missing=false
```
<!--DelEnd_sink-->
### func get(String)

```cangjie
public func get(key: String): Option<JsonValue>
```

功能：获取 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中 key 对应的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)，并用 Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> 封装。

参数：

- key: String - 指定的 key。

返回值：

- Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> - key 对应的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 的封装形式。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonObject: JsonObject = JsonObject()
    jsonObject.put("name", JsonString("张三"))
    jsonObject.put("age", JsonInt(25))

    var nameValue = jsonObject.get("name")
    var ageValue = jsonObject.get("age")
    var addressValue = jsonObject.get("address") // 不存在的键

    // 使用match处理Option类型
    var nameStr = match (nameValue) {
        case Some(value) => value
        case None => "键不存在"
    }

    var ageStr = match (ageValue) {
        case Some(value) => value
        case None => "键不存在"
    }

    var addressStr = match (addressValue) {
        case Some(value) => value
        case None => "键不存在"
    }

    println("name的值: ${nameStr}")
    println("age的值: ${ageStr}")
    println("address的值: ${addressStr}")
}
```

运行结果：

```text
name的值: "张三"
age的值: 25
address的值: 键不存在
```

<!--Del_sink-->
### func get(String)

```cangjie
public exclave func get(this @local!, key: String @local!): Option<JsonValue> @local!
```

功能：获取 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中 key 对应的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)，并用 Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> 封装。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。
- key: String @local! - 指定的键。

返回值：

- Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local! - 键对应的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)，用 Option 封装。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    match (jo.get("hello")) {
        case Some(found) =>
            let sv: String @local! = found.toString()
            println("found=${String(sv)}")
        case None => println("none")
    }
}
```

运行结果：

```text
found="world"
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func get(String)

```cangjie
public exclave func get(this @local?, key: String @local?): Option<JsonValue> @local?
```

功能：获取 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中 key 对应的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)，并用 Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> 封装。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。
- key: String @local? - 指定的键。

返回值：

- Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local? - 键对应的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)，用 Option 封装。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let k: String @local? = "hello"
    match (jo.get(k)) {
        case Some(found) =>
            let sv: String @local! = found.toString()
            println("found=${String(sv)}")
        case None => println("none")
    }
}
```

运行结果：

```text
found="world"
```
<!--DelEnd_sink-->
### func getFields()

```cangjie
public func getFields(): HashMap<String, JsonValue>
```

功能：获取 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中的 fields 数据。

返回值：

- HashMap\<String, [JsonValue](encoding_json_package_classes.md#class-jsonvalue)> - [JsonObject](encoding_json_package_classes.md#class-jsonobject) 的 fields 数据。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

main() {
    var jsonObject: JsonObject = JsonObject()
    jsonObject.put("name", JsonString("张三"))
    jsonObject.put("age", JsonInt(25))
    jsonObject.put("student", JsonBool(true))

    var fields: HashMap<String, JsonValue> = jsonObject.getFields()

    println("JsonObject的字段数据: ${jsonObject}")
    println("获取到的字段HashMap: ${fields}")
}
```

运行结果：

```text
JsonObject的字段数据: {"name":"张三","age":25,"student":true}
获取到的字段HashMap: [(name, "张三"), (age, 25), (student, true)]
```

<!--Del_sink-->
### func getFields()

```cangjie
public exclave func getFields(this @local!): HashMap<String, JsonValue> @local!
```

功能：获取 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中的 fields 数据。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- HashMap\<String, [JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local! - [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中的 fields 数据。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let fields: HashMap<String, JsonValue> @local! = jo.getFields()
    println("size=${jo.size()}")
    println("empty=${fields.isEmpty()}")
}
```

运行结果：

```text
size=1
empty=false
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func getFields()

```cangjie
public func getFields(this @local?): HashMap<String, JsonValue> @local?
```

功能：获取 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中的 fields 数据。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- HashMap\<String, [JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local? - [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中的 fields 数据。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let fields: HashMap<String, JsonValue> @local? = jo.getFields()
    println("size=${jo.size()}")
    println("empty=${fields.isEmpty()}")
}
```

运行结果：

```text
size=1
empty=false
```
<!--DelEnd_sink-->
### func kind()

```cangjie
public func kind(): JsonKind
```

功能：返回当前 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsObject）。

返回值：

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - 当前 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsObject）。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonObject: JsonObject = JsonObject()
    jsonObject.put("name", JsonString("张三"))

    var kind = jsonObject.kind()

    // 使用 match 语句处理类型
    match (kind) {
        case JsonKind.JsObject => println("变量jsonObject的类型是JsObject")
        case _ => println("变量jsonObject的类型不是JsObject")
    }
}
```

运行结果：

```text
变量jsonObject的类型是JsObject
```

<!--Del_sink-->
### func kind()

```cangjie
public func kind(this @local?): JsonKind
```

功能：返回当前 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsObject）。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - 当前 `@local?` [JsonObject](encoding_json_package_classes.md#class-jsonobject) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsObject）。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    match (jo.kind()) {
        case JsonKind.JsObject => println("kind is JsObject")
        case _ => println("kind is not JsObject")
    }
}
```

运行结果：

```text
kind is JsObject
```
<!--DelEnd_sink-->
### func put(String, JsonValue)

```cangjie
public func put(key: String, v: JsonValue): Unit
```

功能：向 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中加入 key-[JsonValue](encoding_json_package_classes.md#class-jsonvalue) 数据。

参数：

- key: String - 需要加入的 key。
- v: [JsonValue](encoding_json_package_classes.md#class-jsonvalue) - 对应 key 的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonObject: JsonObject = JsonObject()

    jsonObject.put("name", JsonString("张三"))
    jsonObject.put("age", JsonInt(25))
    jsonObject.put("student", JsonBool(true))

    println("添加键值对后的JsonObject: ${jsonObject}")
}
```

运行结果：

```text
添加键值对后的JsonObject: {"name":"张三","age":25,"student":true}
```

<!--Del_sink-->
### func put(String, JsonValue)

```cangjie
public exclave func put(this @local!, key: String @local!, v: JsonValue @local!): Unit
```

功能：向 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中加入 key-[JsonValue](encoding_json_package_classes.md#class-jsonvalue) 数据。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。
- key: String @local! - 指定的键。
- v: [JsonValue](encoding_json_package_classes.md#class-jsonvalue) @local! - 键对应的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 数据。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let s: String @local! = jo.toString()
    println("jo=${String(s)}")
}
```

运行结果：

```text
jo={"hello":"world"}
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func put(String, JsonValue)

```cangjie
public exclave func put(this @local!, key: String @local?, v: JsonValue @local!): Unit
```

功能：向 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中加入 key-[JsonValue](encoding_json_package_classes.md#class-jsonvalue) 数据，加入时将键深拷贝为本地持有的 `String @local!` 字符串存储。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。
- key: String @local? - 指定的键。
- v: [JsonValue](encoding_json_package_classes.md#class-jsonvalue) @local! - 键对应的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 数据。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local? = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let s: String @local! = jo.toString()
    println("jo=${String(s)}")
}
```

运行结果：

```text
jo={"hello":"world"}
```
<!--DelEnd_sink-->
### func size()

```cangjie
public func size(): Int64
```

功能：获取 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中 fields 存入 string-[JsonValue](encoding_json_package_classes.md#class-jsonvalue) 的数量。

返回值：

- Int64 - [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中 fields 的大小。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonObject: JsonObject = JsonObject()

    var initialSize = jsonObject.size()
    println("初始JsonObject的大小: ${initialSize}")

    jsonObject.put("name", JsonString("张三"))
    var sizeAfterAdd1 = jsonObject.size()
    println("添加一个键值对后的大小: ${sizeAfterAdd1}")

    jsonObject.put("age", JsonInt(25))
    jsonObject.put("student", JsonBool(true))
    var finalSize = jsonObject.size()
    println("添加多个键值对后的最终大小: ${finalSize}")
}
```

运行结果：

```text
初始JsonObject的大小: 0
添加一个键值对后的大小: 1
添加多个键值对后的最终大小: 3
```

<!--Del_sink-->
### func size()

```cangjie
public func size(this @local?): Int64
```

功能：获取 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中 fields 存入 string-[JsonValue](encoding_json_package_classes.md#class-jsonvalue) 的数量。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- Int64 - [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中 fields 的数量。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    println("size=${jo.size()}")
}
```

运行结果：

```text
size=1
```
<!--DelEnd_sink-->
### func toJsonString()

```cangjie
public func toJsonString(): String
```

功能：将 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 转换为 JSON 格式的 (带有空格换行符) 字符串。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonObject: JsonObject = JsonObject()
    jsonObject.put("name", JsonString("张三"))
    jsonObject.put("age", JsonInt(25))
    jsonObject.put("student", JsonBool(true))

    var jsonStr = jsonObject.toJsonString()

    println("JsonObject转换为JSON字符串:\n${jsonStr}")
}
```

运行结果：

```text
JsonObject转换为JSON字符串:
{
  "name": "张三",
  "age": 25,
  "student": true
}
```

<!--Del_sink-->
### func toJsonString()

```cangjie
public exclave func toJsonString(this @local!): String @local!
```

功能：将当前 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 转换为 JSON 格式的 (带有空格换行符) 字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let s: String @local! = jo.toJsonString()
    println(String(s))
}
```

运行结果：

```text
{
  "hello": "world"
}
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toJsonString()

```cangjie
public func toJsonString(this @local?): String
```

功能：将当前 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 转换为 JSON 格式的 (带有空格换行符) 字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let s: String = jo.toJsonString()
    println(s)
}
```

运行结果：

```text
{
  "hello": "world"
}
```
<!--DelEnd_sink-->
### func toJsonString(Int64, Bool, String)

```cangjie
public func toJsonString(depth: Int64, bracketInNewLine!: Bool = false, indent!: String = "  "): String
```

功能：将 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 转换为 JSON 格式的字符串。该函数将指定初始的缩进深度、首括号前是否缩进以及缩进字符串。

参数：

- depth: Int64 - 缩进深度。
- bracketInNewLine!: Bool - 为 `true` 时，在首括号前添加 `depth` 份 `indent`；为 `false` 时不添加该缩进。此参数不插入换行符。
- indent!: String - 指定的缩进字符串，缩进字符串中只允许空格和制表符的组合，默认为两个空格。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- IllegalArgumentException - 如果 depth 为负数，或 indent 中存在 ' ' 和 '\t' 以外的字符，则抛出异常。
- JsonException - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonObject: JsonObject = JsonObject()
    jsonObject.put("name", JsonString("张三"))
    jsonObject.put("age", JsonInt(25))
    jsonObject.put("student", JsonBool(true))

    // 使用参数的toJsonString方法，使用命名参数
    var jsonStr1 = jsonObject.toJsonString(0, bracketInNewLine: false, indent: "  ") // 默认缩进
    var jsonStr2 = jsonObject.toJsonString(1, bracketInNewLine: true, indent: "    ") // 深度1，第一个括号换行，4个空格缩进

    println("默认格式的JSON字符串:\n${jsonStr1}")
    println("指定参数的JSON字符串:\n${jsonStr2}")
}
```

运行结果：

```text
默认格式的JSON字符串:
{
  "name": "张三",
  "age": 25,
  "student": true
}
指定参数的JSON字符串:
    {
        "name": "张三",
        "age": 25,
        "student": true
    }
```

<!--Del_sink-->
### func toJsonString(Int64, Bool, String)

```cangjie
public exclave func toJsonString(this @local!, depth: Int64, bracketInNewLine!: Bool = false, indent!: String @~local = "  "): String @local!
```

功能：将当前 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 转换为 JSON 格式的字符串。该函数将指定初始的缩进深度、首括号前是否缩进以及缩进字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。
- depth: Int64 - 初始缩进深度，也是 JSON 写入深度的起始值；嵌套值会继续增加写入深度。
- bracketInNewLine!: Bool - 为 `true` 时，在首括号前添加 `depth` 份 `indent`；为 `false` 时不添加该缩进。此参数不插入换行符。
- indent!: String @~local - 指定的缩进字符串，缩进字符串中只允许空格和制表符的组合，默认为两个空格。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

异常：

- IllegalArgumentException - 如果 depth 为负数，或 indent 中存在 ' ' 和 '\t' 以外的字符，则抛出异常。
- JsonException - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let s: String @local! = jo.toJsonString(1, bracketInNewLine: true, indent: " ")
    println(String(s))
}
```

运行结果：

```text
 {
  "hello": "world"
 }
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toJsonString(Int64, Bool, String)

```cangjie
public func toJsonString(this @local?, depth: Int64, bracketInNewLine!: Bool = false, indent!: String @local? = "  "): String
```

功能：将当前 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 转换为 JSON 格式的字符串。该函数将指定初始的缩进深度、首括号前是否缩进以及缩进字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。
- depth: Int64 - 初始缩进深度，也是 JSON 写入深度的起始值；嵌套值会继续增加写入深度。
- bracketInNewLine!: Bool - 为 `true` 时，在首括号前添加 `depth` 份 `indent`；为 `false` 时不添加该缩进。此参数不插入换行符。
- indent!: String @local? - 指定的缩进字符串，缩进字符串中只允许空格和制表符的组合，默认为两个空格。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- IllegalArgumentException - 如果 depth 为负数，或 indent 中存在 ' ' 和 '\t' 以外的字符，则抛出异常。
- JsonException - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let s: String = jo.toJsonString(1, bracketInNewLine: true, indent: " ")
    println(s)
}
```

运行结果：

```text
 {
  "hello": "world"
 }
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(): String
```

功能：将 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 转换为 JSON 格式的 (带有空格换行符) 字符串，不对字符串值中的 html 特殊字符 `&` 转义；对象键中的 `&` 仍转义为 `\u0026`。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonObject: JsonObject = JsonObject()
    jsonObject.put("name", JsonString("张三&李四")) // 包含&符号
    jsonObject.put("description", JsonString("学生<25岁"))

    var jsonStr = jsonObject.toJsonStringWithoutEscaping()
    var normalJsonStr = jsonObject.toJsonString() // 对比正常方法

    println("不转义HTML特殊字符的JSON字符串:\n${jsonStr}")
    println("正常转义的JSON字符串:\n${normalJsonStr}")
}
```

运行结果：

```text
不转义HTML特殊字符的JSON字符串:
{
  "name": "张三&李四",
  "description": "学生<25岁"
}
正常转义的JSON字符串:
{
  "name": "张三\u0026李四",
  "description": "学生<25岁"
}
```

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public exclave func toJsonStringWithoutEscaping(this @local!): String @local!
```

功能：将当前 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 转换为 JSON 格式的 (带有空格换行符) 字符串，不对 html 特殊字符 `&` 转义。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let s: String @local! = jo.toJsonStringWithoutEscaping()
    println(String(s))
}
```

运行结果：

```text
{
  "hello": "world"
}
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(this @local?): String
```

功能：将当前 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 转换为 JSON 格式的 (带有空格换行符) 字符串，不对 html 特殊字符 `&` 转义。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let s: String = jo.toJsonStringWithoutEscaping()
    println(s)
}
```

运行结果：

```text
{
  "hello": "world"
}
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping(Int64, Bool, String)

```cangjie
public func toJsonStringWithoutEscaping(depth: Int64, bracketInNewLine!: Bool = false, indent!: String = "  "): String
```

功能：将 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 转换为 JSON 格式的字符串。该函数将指定初始的缩进深度、首括号前是否缩进以及缩进字符串，不对字符串值中的 html 特殊字符 `&` 转义；对象键中的 `&` 仍转义为 `\u0026`。

参数：

- depth: Int64 - 缩进深度。
- bracketInNewLine!: Bool - 为 `true` 时，在首括号前添加 `depth` 份 `indent`；为 `false` 时不添加该缩进。此参数不插入换行符。
- indent!: String - 指定的缩进字符串，缩进字符串中只允许空格和制表符的组合，默认为两个空格。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- IllegalArgumentException - 如果 depth 为负数，或 indent 中存在 ' ' 和 '\t' 以外的字符，则抛出异常。
- JsonException - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonObject: JsonObject = JsonObject()
    jsonObject.put("name", JsonString("张三&李四")) // 包含&符号
    jsonObject.put("description", JsonString("学生<25岁"))

    // 使用参数的toJsonStringWithoutEscaping方法
    var jsonStr1 = jsonObject.toJsonStringWithoutEscaping(0, bracketInNewLine: false, indent: "  ") // 默认缩进
    var jsonStr2 = jsonObject.toJsonStringWithoutEscaping(1, bracketInNewLine: true, indent: "    ") // 深度1，第一个括号换行，4个空格缩进

    println("不转义的默认格式JSON字符串:\n${jsonStr1}")
    println("不转义的指定参数JSON字符串:\n${jsonStr2}")
}
```

运行结果：

```text
不转义的默认格式JSON字符串:
{
  "name": "张三&李四",
  "description": "学生<25岁"
}
不转义的指定参数JSON字符串:
    {
        "name": "张三&李四",
        "description": "学生<25岁"
    }
```

<!--Del_sink-->
### func toJsonStringWithoutEscaping(Int64, Bool, String)

```cangjie
public exclave func toJsonStringWithoutEscaping(this @local!, depth: Int64, bracketInNewLine!: Bool = false, indent!: String @~local = "  "): String @local!
```

功能：将当前 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 转换为 JSON 格式的字符串。该函数将指定初始的缩进深度、首括号前是否缩进以及缩进字符串，不对 html 特殊字符 `&` 转义。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。
- depth: Int64 - 初始缩进深度，也是 JSON 写入深度的起始值；嵌套值会继续增加写入深度。
- bracketInNewLine!: Bool - 为 `true` 时，在首括号前添加 `depth` 份 `indent`；为 `false` 时不添加该缩进。此参数不插入换行符。
- indent!: String @~local - 指定的缩进字符串，缩进字符串中只允许空格和制表符的组合，默认为两个空格。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

异常：

- IllegalArgumentException - 如果 depth 为负数，或 indent 中存在 ' ' 和 '\t' 以外的字符，则抛出异常。
- JsonException - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let s: String @local! = jo.toJsonStringWithoutEscaping(1, bracketInNewLine: true, indent: " ")
    println(String(s))
}
```

运行结果：

```text
 {
  "hello": "world"
 }
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toJsonStringWithoutEscaping(Int64, Bool, String)

```cangjie
public func toJsonStringWithoutEscaping(this @local?, depth: Int64, bracketInNewLine!: Bool = false, indent!: String @local? = "  "): String
```

功能：将当前 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 转换为 JSON 格式的字符串。该函数将指定初始的缩进深度、首括号前是否缩进以及缩进字符串，不对 html 特殊字符 `&` 转义。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。
- depth: Int64 - 初始缩进深度，也是 JSON 写入深度的起始值；嵌套值会继续增加写入深度。
- bracketInNewLine!: Bool - 为 `true` 时，在首括号前添加 `depth` 份 `indent`；为 `false` 时不添加该缩进。此参数不插入换行符。
- indent!: String @local? - 指定的缩进字符串，缩进字符串中只允许空格和制表符的组合，默认为两个空格。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- IllegalArgumentException - 如果 depth 为负数，或 indent 中存在 ' ' 和 '\t' 以外的字符，则抛出异常。
- JsonException - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let s: String = jo.toJsonStringWithoutEscaping(1, bracketInNewLine: true, indent: " ")
    println(s)
}
```

运行结果：

```text
 {
  "hello": "world"
 }
```
<!--DelEnd_sink-->
### func toString()

```cangjie
public func toString(): String
```

功能：将 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 转换为字符串。

返回值：

- String - 转换后的字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonObject: JsonObject = JsonObject()
    jsonObject.put("name", JsonString("张三"))
    jsonObject.put("age", JsonInt(25))
    jsonObject.put("student", JsonBool(true))

    var str = jsonObject.toString()

    println("JsonObject的字符串表示: ${str}")
}
```

运行结果：

```text
JsonObject的字符串表示: {"name":"张三","age":25,"student":true}
```

<!--Del_sink-->
### func toString()

```cangjie
public exclave func toString(this @local?): String @local!
```

功能：将当前 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 转换为字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- String @local! - 转换后的 `@local!` 字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let s: String @local! = jo.toString()
    println("jo=${String(s)}")
}
```

运行结果：

```text
jo={"hello":"world"}
```
<!--DelEnd_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(): String
```

功能：将 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 转换为字符串，不对字符串值中的 html 特殊字符 `&` 转义；对象键中的 `&` 仍转义为 `\u0026`。

返回值：

- String - 转换后的字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当 JSON 写入深度超过 100，或待序列化的内容中存在值为 NaN 或正负无穷的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonObject: JsonObject = JsonObject()
    jsonObject.put("name", JsonString("张三&李四")) // 包含&符号
    jsonObject.put("description", JsonString("学生<25岁"))

    var str = jsonObject.toStringWithoutEscaping()
    var normalStr = jsonObject.toString() // 对比正常方法

    println("不转义HTML特殊字符的字符串: ${str}")
    println("正常转义的字符串: ${normalStr}")
}
```

运行结果：

```text
不转义HTML特殊字符的字符串: {"name":"张三&李四","description":"学生<25岁"}
正常转义的字符串: {"name":"张三\u0026李四","description":"学生<25岁"}
```

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public exclave func toStringWithoutEscaping(this @local!): String @local!
```

功能：将当前 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 转换为字符串，不对 html 特殊字符 `&` 转义。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let s: String @local! = jo.toStringWithoutEscaping()
    println("jo=${String(s)}")
}
```

运行结果：

```text
jo={"hello":"world"}
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(this @local?): String
```

功能：将当前 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 转换为字符串，不对 html 特殊字符 `&` 转义。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- String - 转换后的字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let s: String = jo.toStringWithoutEscaping()
    println("jo=${s}")
}
```

运行结果：

```text
jo={"hello":"world"}
```
<!--DelEnd_sink-->
### operator func \[](String)

```cangjie
public operator func [](key: String): JsonValue
```

功能：获取 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中 key 对应的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。

参数：

- key: String - 指定的 key。

返回值：

- [JsonValue](encoding_json_package_classes.md#class-jsonvalue) - key 对应的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果 key 不是 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 的有效键，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonObject: JsonObject = JsonObject()
    jsonObject.put("name", JsonString("张三"))
    jsonObject.put("age", JsonInt(25))

    // 使用索引操作符获取值
    var nameValue = jsonObject["name"]

    var ageValue = jsonObject["age"]

    println("通过索引操作符获取name: ${nameValue}")
    println("通过索引操作符获取age: ${ageValue}")
}
```

运行结果：

```text
通过索引操作符获取name: "张三"
通过索引操作符获取age: 25
```

<!--Del_sink-->
### operator func \[](String)

```cangjie
public exclave operator func [](this @local!, key: String @local!): JsonValue @local!
```

功能：获取 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中 key 对应的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。
- key: String @local! - 指定的键。

返回值：

- [JsonValue](encoding_json_package_classes.md#class-jsonvalue) @local! - 键对应的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果 key 在 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中不存在，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let v2: JsonValue @local! = jo[k]
    let js: JsonString @local! = v2.asString()
    let sv: String @local! = js.getValue()
    println("value=${String(sv)}")
}
```

运行结果：

```text
value=world
```
<!--DelEnd_sink-->

<!--Del_sink-->
### operator func \[](String)

```cangjie
public exclave operator func [](this @local?, key: String @local?): JsonValue @local?
```

功能：获取 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中 key 对应的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。
- key: String @local? - 指定的键。

返回值：

- [JsonValue](encoding_json_package_classes.md#class-jsonvalue) @local? - 键对应的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果 key 在 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 中不存在，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let k: String @local? = "hello"
    let v: JsonValue @local? = jo[k]
    let s: String @local! = v.toString()
    println("value=${String(s)}")
}
```

运行结果：

```text
value="world"
```
<!--DelEnd_sink-->
## class JsonString

```cangjie
public class JsonString <: JsonValue {
    public init(sv: String)
}
```

功能：此类为 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 实现子类，主要用于封装字符串类型的 JSON 数据。

父类型：

- [JsonValue](#class-jsonvalue)

### init(String)

```cangjie
public init(sv: String)
```

功能：将指定的 String 类型实例封装成 [JsonString](encoding_json_package_classes.md#class-jsonstring) 实例。

参数：

- sv: String - String 类型。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString: JsonString = JsonString("Hello, 世界")

    println("JsonString(\"Hello, 世界\") 创建的对象: ${jsonString}")
}
```

运行结果：

```text
JsonString("Hello, 世界") 创建的对象: "Hello, 世界"
```

<!--Del_sink-->
### init(this @local!, String @local!)

```cangjie
public exclave init(this @local!, sv: String @local!)
```

功能：根据 字符串构造一个 [JsonString](encoding_json_package_classes.md#class-jsonstring) 实例。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 待构造的 `@local!` 实例。
- sv: String @local! - 用于创建 [JsonString](encoding_json_package_classes.md#class-jsonstring) 的 `@local!` 字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let s: String @local! = "hello"
    let js: JsonString @local! = JsonString(s) @local!
    let v: String @local! = js.getValue()
    println("value=${String(v)}")
}
```

运行结果：

```text
value=hello
```
<!--DelEnd_sink-->
### func getValue()

```cangjie
public func getValue(): String
```

功能：获取 [JsonString](encoding_json_package_classes.md#class-jsonstring) 中 value 的实际值。

返回值：

- String - value 的实际值。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString: JsonString = JsonString("Hello, 世界")

    var value = jsonString.getValue()

    println("JsonString(\"Hello, 世界\") 的值: ${value}")
}
```

运行结果：

```text
JsonString("Hello, 世界") 的值: Hello, 世界
```

<!--Del_sink-->
### func getValue()

```cangjie
public exclave func getValue(this @local!): String @local!
```

功能：获取 [JsonString](encoding_json_package_classes.md#class-jsonstring) 中 value 的实际值。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - value 的实际值。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let s: String @local! = "hello"
    let js: JsonString @local! = JsonString(s) @local!
    let v: String @local! = js.getValue()
    println("value=${String(v)}")
}
```

运行结果：

```text
value=hello
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func getValue()

```cangjie
public exclave func getValue(this @local?): String @local?
```

功能：获取 [JsonString](encoding_json_package_classes.md#class-jsonstring) 中 value 的实际值。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- String @local? - value 的实际值。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeStr(): JsonString @local? {
    let s: String @local! = "hello"
    let js: JsonString @local! = JsonString(s) @local!
    js
}

main() {
    let js: JsonString @local? = makeStr()
    let v: String @local? = js.getValue()
    println("value=${String(v)}")
}
```

运行结果：

```text
value=hello
```
<!--DelEnd_sink-->
### func kind()

```cangjie
public func kind(): JsonKind
```

功能：返回当前 [JsonString](encoding_json_package_classes.md#class-jsonstring) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsString）。

返回值：

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - 当前 [JsonString](encoding_json_package_classes.md#class-jsonstring) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsString）。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString: JsonString = JsonString("Hello, 世界")

    var kind = jsonString.kind()

    // 使用 match 语句处理类型
    match (kind) {
        case JsonKind.JsString => println("变量jsonString的类型是JsString")
        case _ => println("变量jsonString的类型不是JsString")
    }
}
```

运行结果：

```text
变量jsonString的类型是JsString
```

<!--Del_sink-->
### func kind()

```cangjie
public func kind(this @local?): JsonKind
```

功能：返回当前 [JsonString](encoding_json_package_classes.md#class-jsonstring) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsString）。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - 当前 `@local?` [JsonString](encoding_json_package_classes.md#class-jsonstring) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型（JsString）。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeStr(): JsonString @local? {
    let s: String @local! = "hello"
    let js: JsonString @local! = JsonString(s) @local!
    js
}

main() {
    let js: JsonString @local? = makeStr()
    match (js.kind()) {
        case JsonKind.JsString => println("kind is JsString")
        case _ => println("kind is not JsString")
    }
}
```

运行结果：

```text
kind is JsString
```
<!--DelEnd_sink-->
### func toJsonString()

```cangjie
public func toJsonString(): String
```

功能：将 [JsonString](encoding_json_package_classes.md#class-jsonstring) 转换为 JSON 格式的 (带有空格换行符) 字符串。

返回值：

- String - 转换后的 JSON 格式字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString: JsonString = JsonString("Hello, 世界")

    var jsonStr = jsonString.toJsonString()

    println("JsonString(\"Hello, 世界\") 的 JSON 字符串: ${jsonStr}")
}
```

运行结果：

```text
JsonString("Hello, 世界") 的 JSON 字符串: "Hello, 世界"
```

<!--Del_sink-->
### func toJsonString()

```cangjie
public exclave func toJsonString(this @local!): String @local!
```

功能：将当前 [JsonString](encoding_json_package_classes.md#class-jsonstring) 转换为 JSON 格式的 (带有空格换行符) 字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let s: String @local! = "hello"
    let js: JsonString @local! = JsonString(s) @local!
    let r: String @local! = js.toJsonString()
    println("s=${String(r)}")
}
```

运行结果：

```text
s="hello"
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(): String
```

功能：将 [JsonString](encoding_json_package_classes.md#class-jsonstring) 转换为 JSON 格式的 (带有空格换行符) 字符串，不对 html 特殊字符 `&` 转义。

返回值：

- String - 转换后的 JSON 格式字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString: JsonString = JsonString("Hello & World <测试>")

    var jsonStr = jsonString.toJsonStringWithoutEscaping()
    var normalJsonStr = jsonString.toJsonString() // 对比正常方法

    println("不转义HTML特殊字符的JSON字符串: ${jsonStr}")
    println("正常转义的JSON字符串: ${normalJsonStr}")
}
```

运行结果：

```text
不转义HTML特殊字符的JSON字符串: "Hello & World <测试>"
正常转义的JSON字符串: "Hello \u0026 World <测试>"
```

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public exclave func toJsonStringWithoutEscaping(this @local!): String @local!
```

功能：将当前 [JsonString](encoding_json_package_classes.md#class-jsonstring) 转换为 JSON 格式的 (带有空格换行符) 字符串，不对 html 特殊字符 `&` 转义。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let s: String @local! = "hello"
    let js: JsonString @local! = JsonString(s) @local!
    let r: String @local! = js.toJsonStringWithoutEscaping()
    println("s=${String(r)}")
}
```

运行结果：

```text
s="hello"
```
<!--DelEnd_sink-->
### func toString()

```cangjie
public func toString(): String
```

功能：将 [JsonString](encoding_json_package_classes.md#class-jsonstring) 转换为字符串。

返回值：

- String - 转换后的字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString: JsonString = JsonString("Hello, 世界")

    var str = jsonString.toString()

    println("JsonString(\"Hello, 世界\") 的字符串表示: ${str}")
}
```

运行结果：

```text
JsonString("Hello, 世界") 的字符串表示: "Hello, 世界"
```

<!--Del_sink-->
### func toString()

```cangjie
public exclave func toString(this @local?): String @local!
```

功能：将当前 [JsonString](encoding_json_package_classes.md#class-jsonstring) 转换为字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- String @local! - 转换后的 `@local!` 字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeStr(): JsonString @local? {
    let s: String @local! = "hello"
    let js: JsonString @local! = JsonString(s) @local!
    js
}

main() {
    let js: JsonString @local? = makeStr()
    let s: String @local! = js.toString()
    println("s=${String(s)}")
}
```

运行结果：

```text
s="hello"
```
<!--DelEnd_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(): String
```

功能：将 [JsonString](encoding_json_package_classes.md#class-jsonstring) 转换为字符串，不对 html 特殊字符 `&` 转义。

返回值：

- String - 转换后的字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString: JsonString = JsonString("Hello & World <测试>")

    var str = jsonString.toStringWithoutEscaping()
    var normalStr = jsonString.toString() // 对比正常方法

    println("不转义HTML特殊字符的字符串: ${str}")
    println("正常转义的字符串: ${normalStr}")
}
```

运行结果：

```text
不转义HTML特殊字符的字符串: "Hello & World <测试>"
正常转义的字符串: "Hello \u0026 World <测试>"
```

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public exclave func toStringWithoutEscaping(this @local!): String @local!
```

功能：将当前 [JsonString](encoding_json_package_classes.md#class-jsonstring) 转换为字符串，不对 html 特殊字符 `&` 转义。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的字符串。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let s: String @local! = "hello"
    let js: JsonString @local! = JsonString(s) @local!
    let r: String @local! = js.toStringWithoutEscaping()
    println("s=${String(r)}")
}
```

运行结果：

```text
s="hello"
```
<!--DelEnd_sink-->
## class JsonValue

```cangjie
sealed abstract class JsonValue <: ToString
```

功能：此类为 JSON 数据层，主要用于 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 和 String 数据之间的互相转换。

抽象类 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 提供了 String 类型和具体的 JSON 类型相互转换的接口，以及具体的 JSON 类型判断功能。

父类型：

- ToString

示例：

使用示例见[JsonValue 和 String 互相转换](../json_samples/json_value_sample.md)。

### static func fromStr(String)

```cangjie
public static func fromStr(s: String): JsonValue
```

功能：将字符串数据解析为 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。对于整数，支持前导 '0b'，'0o'，'0x'（不区分大小写），分别表示二进制，八进制和十六进制。非空字符串解析失败时，抛出的 [JsonException](encoding_json_package_exceptions.md#class-jsonexception) 消息包含错误字符及其行数和列数。列号不计行首的 ASCII 空格，但会计入制表符。

JSON 在解析 String 转换为 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 时，转义字符 \\ 之后只能对应 JSON 支持的转义字符（b、f、n、r、t、u、\\、\"、\/），其中 \\u 的格式为：\\uXXXX，X 为十六进制数，例：\\u0041 代表字符 'A'。

参数：

- s: String - 传入字符串，须符合 JSON 语法。

返回值：

- [JsonValue](encoding_json_package_classes.md#class-jsonvalue) - 转换后的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果解析字符串出错，或解析数字时原生缓冲区分配失败，抛出异常；分配器抛出的 Error 不会在此转换为 JsonException。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString = ##"{"name": "张三", "age": 25, "student": true}"##
    // JSON解析JsonObject
    var jsonValue: JsonValue = JsonValue.fromStr(jsonString)

    println("JsonValue 是 JsonString?: ${jsonValue is JsonString}")
    println("JsonValue 是 JsonObject?: ${jsonValue is JsonObject}")
    println("解析后的JsonValue: ${jsonValue}")

    // JSON解析JsonString合法的转义字符
    let str1 = ##""\n""##
    let jsonValue1 = JsonValue.fromStr(str1)
    println("解析JsonString: ${jsonValue1}")

    // JSON解析JsonString合法的转义字符
    let str2 = ##""\u0041""##
    let jsonValue2 = JsonValue.fromStr(str2)
    println("解析JsonString: ${jsonValue2}")

    // JSON解析JsonString不合法的转义字符
    try {
        let str3 = ##""\x1""##
        let jsonValue3 = JsonValue.fromStr(str3)
        println("解析JsonString: ${jsonValue3}")
    } catch (e: JsonException) {
        println("异常信息: ${e.message}")
    }
}
```

运行结果：

```text
JsonValue 是 JsonString?: false
JsonValue 是 JsonObject?: true
解析后的JsonValue: {"name":"张三","age":25,"student":true}
解析JsonString: "\n"
解析JsonString: "A"
异常信息: Invalid JSON data: Parse Error: [Line]: 1, [Pos]: 3, [Error]: Unexpected character: 'x'.
```

<!--Del_sink-->
### static func fromStr(String)

```cangjie
public exclave static func fromStr(s: String @local!): JsonValue @local!
```

功能：将 字符串数据解析为 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- s: String @local! - 传入字符串。

返回值：

- [JsonValue](encoding_json_package_classes.md#class-jsonvalue) @local! - 解析得到的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果解析字符串出错，或解析数字时原生缓冲区分配失败，抛出异常；分配器抛出的 Error 不会在此转换为 JsonException。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let s: String @local! = ##"[1, 2, 3]"##
    let v: JsonValue @local! = JsonValue.fromStr(s)
    let a: JsonArray @local! = v.asArray()
    println("size=${a.size()}")
}
```

运行结果：

```text
size=3
```
<!--DelEnd_sink-->

<!--Del_sink-->
### static func fromStr(String)

```cangjie
public exclave static func fromStr(s: String @local?): JsonValue @local!
```

功能：将字符串数据解析为 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)，解析前先将该字符串深拷贝为 `@local!` 字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- s: String @local? - 传入字符串。

返回值：

- [JsonValue](encoding_json_package_classes.md#class-jsonvalue) @local! - 解析得到的 [JsonValue](encoding_json_package_classes.md#class-jsonvalue)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果解析字符串出错，或解析数字时原生缓冲区分配失败，抛出异常；分配器抛出的 Error 不会在此转换为 JsonException。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeStr(): String @local? {
    let s: String @local! = ##"123"##
    s
}

main() {
    let s: String @local? = makeStr()
    let v: JsonValue @local! = JsonValue.fromStr(s)
    let ji: JsonInt @local! = v.asInt()
    println("value=${ji.getValue()}")
}
```

运行结果：

```text
value=123
```
<!--DelEnd_sink-->
### func asArray()

```cangjie
public func asArray(): JsonArray
```

功能：将 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 格式。

返回值：

- [JsonArray](encoding_json_package_classes.md#class-jsonarray) - 转换后的 [JsonArray](encoding_json_package_classes.md#class-jsonarray)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString = ##"[1, 2, 3, "hello"]"##
    var jsonValue: JsonValue = JsonValue.fromStr(jsonString)

    var jsonArray = jsonValue.asArray()

    println("JsonValue转换为JsonArray: ${jsonArray}")
    println("数组大小: ${jsonArray.size()}")

    // 转换异常示例
    jsonString = ##"123"##
    jsonValue = JsonValue.fromStr(jsonString)
    try {
        jsonArray = jsonValue.asArray()
    } catch (e: JsonException) {
        println("转换异常: ${e.message}")
    }
}
```

运行结果：

```text
JsonValue转换为JsonArray: [1,2,3,"hello"]
数组大小: 4
转换异常: Failed to convert JsonValue to JsonArray.
```

<!--Del_sink-->
### func asArray()

```cangjie
public exclave func asArray(this @local!): JsonArray @local!
```

功能：将当前 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为 [JsonArray](encoding_json_package_classes.md#class-jsonarray) 格式。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- [JsonArray](encoding_json_package_classes.md#class-jsonarray) @local! - 转换后的 [JsonArray](encoding_json_package_classes.md#class-jsonarray)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    let v: JsonValue @local! = ja
    let a: JsonArray @local! = v.asArray()
    println("size=${a.size()}")
}
```

运行结果：

```text
size=2
```
<!--DelEnd_sink-->
### func asBool()

```cangjie
public func asBool(): JsonBool
```

功能：将 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为 [JsonBool](encoding_json_package_classes.md#class-jsonbool) 格式。

返回值：

- [JsonBool](encoding_json_package_classes.md#class-jsonbool) - 转换后的 [JsonBool](encoding_json_package_classes.md#class-jsonbool)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString = ##"true"##
    var jsonValue: JsonValue = JsonValue.fromStr(jsonString)

    var jsonBool = jsonValue.asBool()

    println("JsonValue转换为JsonBool: ${jsonBool}")
    println("JsonBool的值: ${jsonBool.getValue()}")

    // 转换异常示例
    jsonString = ##"123"##
    jsonValue = JsonValue.fromStr(jsonString)
    try {
        jsonBool = jsonValue.asBool()
    } catch (e: Exception) {
        println("转换异常: ${e.message}")
    }
}
```

运行结果：

```text
JsonValue转换为JsonBool: true
JsonBool的值: true
转换异常: Failed to convert JsonValue to JsonBool.
```

<!--Del_sink-->
### func asBool()

```cangjie
public exclave func asBool(this @local!): JsonBool @local!
```

功能：将当前 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为 [JsonBool](encoding_json_package_classes.md#class-jsonbool) 格式。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- [JsonBool](encoding_json_package_classes.md#class-jsonbool) @local! - 转换后的 [JsonBool](encoding_json_package_classes.md#class-jsonbool)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let v: JsonValue @local! = JsonBool(true) @local!
    let jb: JsonBool @local! = v.asBool()
    println("value=${jb.getValue()}")
}
```

运行结果：

```text
value=true
```
<!--DelEnd_sink-->
### func asFloat()

```cangjie
public func asFloat(): JsonFloat
```

功能：将 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 格式。

返回值：

- [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) - 转换后的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString = ##"3.14159"##
    var jsonValue: JsonValue = JsonValue.fromStr(jsonString)

    var jsonFloat = jsonValue.asFloat()

    println("JsonValue转换为JsonFloat: ${jsonFloat}")
    println("JsonFloat的值: ${jsonFloat.getValue()}")

    // 转换异常示例
    jsonString = ##"null"##
    jsonValue = JsonValue.fromStr(jsonString)
    try {
        jsonFloat = jsonValue.asFloat()
    } catch (e: Exception) {
        println("转换异常: ${e.message}")
    }
}
```

运行结果：

```text
JsonValue转换为JsonFloat: 3.141590
JsonFloat的值: 3.141590
转换异常: Failed to convert JsonValue to JsonFloat.
```

<!--Del_sink-->
### func asFloat()

```cangjie
public exclave func asFloat(this @local!): JsonFloat @local!
```

功能：将当前 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 格式。如果当前对象是 [JsonInt](encoding_json_package_classes.md#class-jsonint)，将按其整数值构造 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat)。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) @local! - 转换后的 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let v: JsonValue @local! = JsonInt(42) @local!
    let jf: JsonFloat @local! = v.asFloat()
    println("value=${jf.getValue()}")
}
```

运行结果：

```text
value=42.000000
```
<!--DelEnd_sink-->
### func asInt()

```cangjie
public func asInt(): JsonInt
```

功能：将 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为 [JsonInt](encoding_json_package_classes.md#class-jsonint) 格式。

返回值：

- [JsonInt](encoding_json_package_classes.md#class-jsonint) - 转换后的 [JsonInt](encoding_json_package_classes.md#class-jsonint)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString = ##"42"##
    var jsonValue: JsonValue = JsonValue.fromStr(jsonString)

    var jsonInt = jsonValue.asInt()

    println("JsonValue转换为JsonInt: ${jsonInt}")
    println("JsonInt的值: ${jsonInt.getValue()}")

    // 转换异常示例
    jsonString = ##"123.12"##
    jsonValue = JsonValue.fromStr(jsonString)
    try {
        jsonInt = jsonValue.asInt()
    } catch (e: Exception) {
        println("转换异常: ${e.message}")
    }
}
```

运行结果：

```text
JsonValue转换为JsonInt: 42
JsonInt的值: 42
转换异常: Failed to convert JsonValue to JsonInt.
```

<!--Del_sink-->
### func asInt()

```cangjie
public exclave func asInt(this @local!): JsonInt @local!
```

功能：将当前 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为 [JsonInt](encoding_json_package_classes.md#class-jsonint) 格式。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- [JsonInt](encoding_json_package_classes.md#class-jsonint) @local! - 转换后的 [JsonInt](encoding_json_package_classes.md#class-jsonint)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let v: JsonValue @local! = JsonInt(123) @local!
    let ji: JsonInt @local! = v.asInt()
    println("value=${ji.getValue()}")
}
```

运行结果：

```text
value=123
```
<!--DelEnd_sink-->
### func asNull()

```cangjie
public func asNull(): JsonNull
```

功能：将 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为 [JsonNull](encoding_json_package_classes.md#class-jsonnull) 格式。

返回值：

- [JsonNull](encoding_json_package_classes.md#class-jsonnull) - 转换后的 [JsonNull](encoding_json_package_classes.md#class-jsonnull)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString = ##"null"##
    var jsonValue: JsonValue = JsonValue.fromStr(jsonString)

    var jsonNull = jsonValue.asNull()

    println("JsonValue转换为JsonNull: ${jsonNull}")
}
```

运行结果：

```text
JsonValue转换为JsonNull: null
```

<!--Del_sink-->
### func asNull()

```cangjie
public exclave func asNull(this @local!): JsonNull @local!
```

功能：将当前 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为 [JsonNull](encoding_json_package_classes.md#class-jsonnull) 格式。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- [JsonNull](encoding_json_package_classes.md#class-jsonnull) @local! - 转换后的 [JsonNull](encoding_json_package_classes.md#class-jsonnull)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let v: JsonValue @local! = JsonNull() @local!
    let n: JsonNull @local! = v.asNull()
    let s: String @local! = n.toString()
    println("n=${String(s)}")
}
```

运行结果：

```text
n=null
```
<!--DelEnd_sink-->
### func asObject()

```cangjie
public func asObject(): JsonObject
```

功能：将 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 格式。

返回值：

- [JsonObject](encoding_json_package_classes.md#class-jsonobject) - 转换后的 [JsonObject](encoding_json_package_classes.md#class-jsonobject)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString = ##"{"name": "张三", "age": 25, "student": true}"##
    var jsonValue: JsonValue = JsonValue.fromStr(jsonString)

    var jsonObject = jsonValue.asObject()

    println("JsonValue转换为JsonObject: ${jsonObject}")
    println("JsonObject的大小: ${jsonObject.size()}")

    // 转换异常示例
    jsonString = ##"[1, 2, 3, "hello"]"##
    jsonValue = JsonValue.fromStr(jsonString)
    try {
        jsonObject = jsonValue.asObject()
    } catch (e: Exception) {
        println("转换异常: ${e.message}")
    }
}
```

运行结果：

```text
JsonValue转换为JsonObject: {"name":"张三","age":25,"student":true}
JsonObject的大小: 3
转换异常: Failed to convert JsonValue to JsonObject.
```

<!--Del_sink-->
### func asObject()

```cangjie
public exclave func asObject(this @local!): JsonObject @local!
```

功能：将当前 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为 [JsonObject](encoding_json_package_classes.md#class-jsonobject) 格式。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- [JsonObject](encoding_json_package_classes.md#class-jsonobject) @local! - 转换后的 [JsonObject](encoding_json_package_classes.md#class-jsonobject)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let v2: JsonValue @local! = jo
    let o: JsonObject @local! = v2.asObject()
    println("size=${o.size()}")
}
```

运行结果：

```text
size=1
```
<!--DelEnd_sink-->
### func asString()

```cangjie
public func asString(): JsonString
```

功能：将 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为 [JsonString](encoding_json_package_classes.md#class-jsonstring) 格式。

返回值：

- [JsonString](encoding_json_package_classes.md#class-jsonstring) - 转换后的 [JsonString](encoding_json_package_classes.md#class-jsonstring)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString = ##""Hello, 世界""##
    var jsonValue: JsonValue = JsonValue.fromStr(jsonString)

    var jsonStr = jsonValue.asString()

    println("JsonValue转换为JsonString: ${jsonStr}")
    println("JsonString的值: ${jsonStr.getValue()}")

    // 转换异常示例
    jsonString = ##"{"name": "张三", "age": 25, "student": true}"##
    jsonValue = JsonValue.fromStr(jsonString)
    try {
        jsonStr = jsonValue.asString()
    } catch (e: Exception) {
        println("转换异常: ${e.message}")
    }
}
```

运行结果：

```text
JsonValue转换为JsonString: "Hello, 世界"
JsonString的值: Hello, 世界
转换异常: Failed to convert JsonValue to JsonString.
```

<!--Del_sink-->
### func asString()

```cangjie
public exclave func asString(this @local!): JsonString @local!
```

功能：将当前 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为 [JsonString](encoding_json_package_classes.md#class-jsonstring) 格式。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- [JsonString](encoding_json_package_classes.md#class-jsonstring) @local! - 转换后的 [JsonString](encoding_json_package_classes.md#class-jsonstring)。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 如果转换失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let s: String @local! = "hello"
    let v: JsonValue @local! = JsonString(s) @local!
    let js: JsonString @local! = v.asString()
    let sv: String @local! = js.getValue()
    println("value=${String(sv)}")
}
```

运行结果：

```text
value=hello
```
<!--DelEnd_sink-->
### func kind()

```cangjie
public func kind(): JsonKind
```

功能：返回当前 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型。

返回值：

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - 当前 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString = ##"{"name": "张三", "age": 25}"##
    var jsonValue: JsonValue = JsonValue.fromStr(jsonString)

    var kind = jsonValue.kind()

    // 使用 match 语句处理类型
    match (kind) {
        case JsonKind.JsArray => println("JsonValue的类型是JsArray")
        case JsonKind.JsString => println("JsonValue的类型是JsString")
        case JsonKind.JsInt => println("JsonValue的类型是JsInt")
        case JsonKind.JsObject => println("JsonValue的类型是JsObject")
        case JsonKind.JsFloat => println("JsonValue的类型是JsFloat")
        case JsonKind.JsBool => println("JsonValue的类型是JsBool")
        case JsonKind.JsNull => println("JsonValue的类型是JsNull")
    }
}
```

运行结果：

```text
JsonValue的类型是JsObject
```

<!--Del_sink-->
### func kind()

```cangjie
public open func kind(this @local?): JsonKind
```

功能：返回当前 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - 当前 `@local?` [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 所属的 [JsonKind](encoding_json_package_enums.md#enum-jsonkind) 类型。

异常：

- UnimplementedException - 如果调用绑定到 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 的默认实现（当前对象的具体子类未覆写该 local 版本方法），抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeValue(): JsonValue @local? {
    let v: JsonValue @local! = JsonInt(123) @local!
    v
}

main() {
    let v: JsonValue @local? = makeValue()
    match (v.kind()) {
        case JsonKind.JsInt => println("kind is JsInt")
        case _ => println("kind is not JsInt")
    }
}
```

运行结果：

```text
kind is JsInt
```
<!--DelEnd_sink-->
### func toJsonString()

```cangjie
public func toJsonString(): String
```

功能：将 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为 JSON 格式的 (带有空格换行符) 字符串。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当具体子类的序列化实现失败时抛出异常，例如 JSON 写入深度超过 100，或 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 的值为 NaN 或正负无穷。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString = ##"{"name": "张三", "age": 25, "hobbies": ["读书", "游泳"]}"##
    var jsonValue: JsonValue = JsonValue.fromStr(jsonString)

    var jsonStr = jsonValue.toJsonString()

    println("JsonValue转换为JSON字符串:\n${jsonStr}")
}
```

运行结果：

```text
JsonValue转换为JSON字符串:
{
  "name": "张三",
  "age": 25,
  "hobbies": [
    "读书",
    "游泳"
  ]
}
```

<!--Del_sink-->
### func toJsonString()

```cangjie
public open func toJsonString(this @local!): String @local!
```

功能：将当前 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为 JSON 格式的 (带有空格换行符) 字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

异常：

- JsonException - 当具体子类的序列化实现失败时抛出异常，例如 JSON 写入深度超过 100，或 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 的值为 NaN 或正负无穷。
- UnimplementedException - 如果调用绑定到 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 的默认实现（当前对象的具体子类未覆写该 local 版本方法），抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let v: JsonValue @local! = JsonInt(123) @local!
    let s: String @local! = v.toJsonString()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=123
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(): String
```

功能：将 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为 JSON 格式的 (带有空格换行符) 字符串，不对字符串值中的 html 特殊字符 `&` 转义；对象键中的 `&` 仍转义为 `\u0026`。

返回值：

- String - 转换后的 JSON 格式字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当具体子类的序列化实现失败时抛出异常，例如 JSON 写入深度超过 100，或 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 的值为 NaN 或正负无穷。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString = ##"{"description": "Hello & World <测试>"}"##
    var jsonValue: JsonValue = JsonValue.fromStr(jsonString)

    var jsonStr = jsonValue.toJsonStringWithoutEscaping()
    var normalJsonStr = jsonValue.toJsonString() // 对比正常方法

    println("不转义HTML特殊字符的JSON字符串:\n${jsonStr}")
    println("正常转义的JSON字符串:\n${normalJsonStr}")
}
```

运行结果：

```text
不转义HTML特殊字符的JSON字符串:
{
  "description": "Hello & World <测试>"
}
正常转义的JSON字符串:
{
  "description": "Hello \u0026 World <测试>"
}
```

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public open func toJsonStringWithoutEscaping(this @local!): String @local!
```

功能：将当前 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为 JSON 格式的 (带有空格换行符) 字符串，不对 html 特殊字符 `&` 转义。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的 JSON 格式字符串。

异常：

- JsonException - 当具体子类的序列化实现失败时抛出异常，例如 JSON 写入深度超过 100，或 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 的值为 NaN 或正负无穷。
- UnimplementedException - 如果调用绑定到 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 的默认实现（当前对象的具体子类未覆写该 local 版本方法），抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let v: JsonValue @local! = JsonInt(123) @local!
    let s: String @local! = v.toJsonStringWithoutEscaping()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=123
```
<!--DelEnd_sink-->
### func toString()

```cangjie
public func toString(): String
```

功能：将 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为字符串。

返回值：

- String - 转换后的字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当具体子类的序列化实现失败时抛出异常，例如 JSON 写入深度超过 100，或 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 的值为 NaN 或正负无穷。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString = ##"{"name": "张三", "age": 25}"##
    var jsonValue: JsonValue = JsonValue.fromStr(jsonString)

    var str = jsonValue.toString()

    println("JsonValue转换为字符串: ${str}")
}
```

运行结果：

```text
JsonValue转换为字符串: {"name":"张三","age":25}
```

<!--Del_sink-->
### func toString()

```cangjie
public open func toString(this @local?): String @local!
```

功能：将当前 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为字符串。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local? - 调用该方法的当前 `@local?` 实例。

返回值：

- String @local! - 转换后的 `@local!` 字符串。

异常：

- JsonException - 当具体子类的序列化实现失败时抛出异常，例如 JSON 写入深度超过 100，或 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 的值为 NaN 或正负无穷。
- UnimplementedException - 如果调用绑定到 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 的默认实现（当前对象的具体子类未覆写该 local 版本方法），抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeValue(): JsonValue @local? {
    let v: JsonValue @local! = JsonInt(123) @local!
    v
}

main() {
    let v: JsonValue @local? = makeValue()
    let s: String @local! = v.toString()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=123
```
<!--DelEnd_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(): String
```

功能：将 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为字符串，不对字符串值中的 html 特殊字符 `&` 转义；对象键中的 `&` 仍转义为 `\u0026`。

返回值：

- String - 转换后的字符串。

异常：

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - 当具体子类的序列化实现失败时抛出异常，例如 JSON 写入深度超过 100，或 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 的值为 NaN 或正负无穷。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    var jsonString = ##"{"description": "Hello & World <测试>"}"##
    var jsonValue: JsonValue = JsonValue.fromStr(jsonString)

    var str = jsonValue.toStringWithoutEscaping()
    var normalStr = jsonValue.toString() // 对比正常方法

    println("不转义HTML特殊字符的字符串: ${str}")
    println("正常转义的字符串: ${normalStr}")
}
```

运行结果：

```text
不转义HTML特殊字符的字符串: {"description":"Hello & World <测试>"}
正常转义的字符串: {"description":"Hello \u0026 World <测试>"}
```

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public open func toStringWithoutEscaping(this @local!): String @local!
```

功能：将当前 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 转换为字符串，不对 html 特殊字符 `&` 转义。

> **注意：**
>
> - 实验性 API，仅用于测试验证，规范和实现仍可能发生变化，请谨慎使用。
> - 不支持平台：OpenHarmony。

参数：

- this @local! - 调用该方法的当前 `@local!` 实例。

返回值：

- String @local! - 转换后的字符串。

异常：

- JsonException - 当具体子类的序列化实现失败时抛出异常，例如 JSON 写入深度超过 100，或 [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) 的值为 NaN 或正负无穷。
- UnimplementedException - 如果调用绑定到 [JsonValue](encoding_json_package_classes.md#class-jsonvalue) 的默认实现（当前对象的具体子类未覆写该 local 版本方法），抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let v: JsonValue @local! = JsonInt(123) @local!
    let s: String @local! = v.toStringWithoutEscaping()
    println("s=${String(s)}")
}
```

运行结果：

```text
s=123
```
<!--DelEnd_sink-->
