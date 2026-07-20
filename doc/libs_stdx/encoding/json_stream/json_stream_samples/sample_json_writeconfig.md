# WriteConfig 使用示例

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.stream.{JsonWriter, WriteConfig, JsonSerializable}
import std.io.ByteBuffer

main() {
    // 创建 JsonWriter
    let buffer = ByteBuffer()
    let writer = JsonWriter(buffer)

    // 设置 JSON 格式化配置（使用 pretty 格式）
    let formatConfig = WriteConfig.pretty
    writer.writeConfig = formatConfig

    // 写入 JSON 数据
    writer.writeValue(Student())

    // 输出格式化的 JSON 字符串
    println(String.fromUtf8(buffer.bytes()))
}

// 定义一个类实现 JsonSerializable 接口
class Student <: JsonSerializable {
    public func toJson(w: JsonWriter): Unit {
        w.startObject()
        w.writeName("Name").writeValue("zhangsan")
        w.writeName("Age").writeValue(18)
        w.writeName("Scores").writeValue([88.8, 99.9])
        w.writeName("Class")
        w.startObject()
        w.writeName("Name").writeValue("Class A")
        w.writeName("Students Number").writeValue(33)
        w.endObject()
        w.endObject()
        w.flush()
    }
}
```

运行结果：

```text
{
    "Name": "zhangsan",
    "Age": 18,
    "Scores": [
        88.8,
        99.9
    ],
    "Class": {
        "Name": "Class A",
        "Students Number": 33
    }
}
```
