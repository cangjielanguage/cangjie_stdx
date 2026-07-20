# 使用 Json Stream 进行反序列化

示例：

<!-- verify -->
```cangjie
import stdx.encoding.json.stream.*
import std.io.*
import std.collection.*

// 定义一个类实现 JsonDeserializable 接口，支持从 JsonReader 反序列化
class DataModel <: JsonDeserializable<DataModel> {
    var name: Option<String> = None
    var isActive: Bool = false
    var score: Float64 = 0.0
    var description: String = ""
    var tags: Array<Int64> = Array<Int64>()
    var metadata: HashMap<String, String> = HashMap<String, String>()

    public static func fromJson(r: JsonReader): DataModel {
        let result = DataModel()
        while (let Some(v) <- r.peek()) {
            match (v) {
                case BeginObject =>
                    r.startObject()
                    while (r.peek() != EndObject) {
                        let fieldName = r.readName()
                        match (fieldName) {
                            case "name" => result.name = r.readValue<Option<String>>()
                            case "isActive" => result.isActive = r.readValue<Bool>()
                            case "score" => result.score = r.readValue<Float64>()
                            case "description" => result.description = r.readValue<String>()
                            case "tags" => result.tags = r.readValue<Array<Int64>>()
                            case "metadata" => result.metadata = r.readValue<HashMap<String, String>>()
                            case _ => ()
                        }
                    }
                    r.endObject()
                    break
                case _ => throw Exception("Expected BeginObject")
            }
        }
        return result
    }

    public func toString(): String {
        return "name: ${name}\nisActive: ${isActive}\nscore: ${score}\ndescription: ${description}\ntags: ${tags}\nmetadata: ${metadata}"
    }
}

main() {
    // 准备 JSON 字符串
    let jsonString = ##"{"name": null, "isActive": true, "score": 123.456, "description": "string", "tags": [123, 456], "metadata": {"key7": " ", "key8": "\\a"}}"##

    // 将 JSON 字符串写入 ByteBuffer
    let buffer = ByteBuffer()
    unsafe { buffer.write(jsonString.rawData()) }

    // 使用 JsonReader 反序列化
    let reader = JsonReader(buffer)
    let obj = DataModel.fromJson(reader)

    // 输出反序列化结果
    println(obj.toString())
}
```

运行结果：

```text
name: None
isActive: true
score: 123.456000
description: string
tags: [123, 456]
metadata: [(key7,  ), (key8, \a)]
```
