# 使用 Json Stream 进行序列化

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.stream.*
import std.io.{ByteBuffer, readToEnd}

// 定义一个类实现 JsonSerializable 接口，支持序列化为 JSON
class Image <: JsonSerializable {
    var width: Int64
    var height: Int64
    var title: String
    var ids: Array<Int64>

    public init() {
        width = 0
        height = 0
        title = ""
        ids = Array<Int64>()
    }

    public func toJson(w: JsonWriter): Unit {
        w.startObject()
        w.writeName("Width").writeValue(width)
        w.writeName("Height").writeValue(height)
        w.writeName("Title").writeValue(title)
        w.writeName("Ids").writeValue<Array<Int64>>(ids)
        w.endObject()
    }
}

main() {
    // 创建 Image 对象并设置属性
    let image = Image()
    image.width = 800
    image.height = 600
    image.title = "View from 15th Floor"
    image.ids = [116, 943, 234, 38793]

    // 创建 JsonWriter
    let buffer = ByteBuffer()
    let writer = JsonWriter(buffer)

    // 序列化对象为 JSON
    writer.writeValue(image)
    writer.flush()

    // 输出 JSON 字符串
    println(String.fromUtf8(readToEnd(buffer)))
}
```

运行结果：

```text
{"Width":800,"Height":600,"Title":"View from 15th Floor","Ids":[116,943,234,38793]}
```
