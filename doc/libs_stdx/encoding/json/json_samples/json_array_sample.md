# JsonArray 使用示例

下面是 JsonArray 使用示例。该示例构造了一个 JsonArray 对象，并向其中添加了一些 JsonValue，最后以两种格式打印了该 JsonArray 对象。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

main() {
    // 创建不同类型的 JsonValue
    let nullValue: JsonValue = JsonNull()
    let boolValue: JsonValue = JsonBool(true)
    let intValue: JsonValue = JsonInt(7363)
    let floatValue: JsonValue = JsonFloat(736423.546)
    let stringValue: JsonValue = JsonString("ddddddd")

    // 创建嵌套的 JsonObject
    let nestedObject = JsonObject()
    nestedObject.put("a", JsonString("jjjjjj"))
    nestedObject.put("b", boolValue)
    nestedObject.put("c", JsonString("hhhhh"))

    // 创建嵌套的 JsonArray
    let nestedArray = ArrayList<JsonValue>()
    nestedArray.add(boolValue)
    nestedArray.add(JsonInt(3333333))
    nestedArray.add(nestedObject)
    nestedArray.add(JsonString("sdfghgfasd"))

    // 创建主 JsonArray
    let mainArray = ArrayList<JsonValue>()
    mainArray.add(boolValue)
    mainArray.add(nullValue)
    mainArray.add(JsonObject()) // 空对象
    mainArray.add(JsonBool(false))
    mainArray.add(JsonArray(nestedArray))
    mainArray.add(intValue)
    mainArray.add(stringValue)
    mainArray.add(floatValue)

    // 构建 JsonArray 并输出
    let result: JsonValue = JsonArray(mainArray)

    println("紧凑格式:")
    println(result.toString())

    println("\n格式化输出:")
    println(result.toJsonString())
}
```

运行结果：

```text
紧凑格式:
[true,null,{},false,[true,3333333,{"a":"jjjjjj","b":true,"c":"hhhhh"},"sdfghgfasd"],7363,"ddddddd",736423.546]

格式化输出:
[
  true,
  null,
  {},
  false,
  [
    true,
    3333333,
    {
      "a": "jjjjjj",
      "b": true,
      "c": "hhhhh"
    },
    "sdfghgfasd"
  ],
  7363,
  "ddddddd",
  736423.546
]
```
