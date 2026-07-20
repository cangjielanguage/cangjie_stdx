# class 序列化和反序列化

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*
import stdx.encoding.json.*

// 自定义可序列化类，包含姓名、年龄和位置信息
class Person <: Serializable<Person> {
    var name: String = "Abcde"
    var age: Int64 = 555
    var location: Option<Location> = Option<Location>.None

    // 实现序列化方法
    public func serialize(): DataModel {
        return DataModelStruct()
            .add(field<String>("name", name))
            .add(field<Int64>("age", age))
            .add(field<Option<Location>>("location", location))
    }

    // 实现反序列化方法
    public static func deserialize(dm: DataModel): Person {
        let dataStruct = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("数据模型不是 DataModelStruct 类型")
        }
        let result = Person()
        result.name = String.deserialize(dataStruct.get("name"))
        result.age = Int64.deserialize(dataStruct.get("age"))
        result.location = Option<Location>.deserialize(dataStruct.get("location"))
        return result
    }
}

// 位置信息类
class Location <: Serializable<Location> {
    var timestamp: Int64 = 666
    var tag: Rune = 'T'

    // 实现序列化方法
    public func serialize(): DataModel {
        return DataModelStruct()
            .add(field<Int64>("timestamp", timestamp))
            .add(field<Rune>("tag", tag))
    }

    // 实现反序列化方法
    public static func deserialize(dm: DataModel): Location {
        let dataStruct = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("数据模型不是 DataModelStruct 类型")
        }
        let result = Location()
        result.timestamp = Int64.deserialize(dataStruct.get("timestamp"))
        result.tag = Rune.deserialize(dataStruct.get("tag"))
        return result
    }
}

main(): Unit {
    // 序列化对象并转换为 JSON
    let person = Person()
    let jsonValue: JsonValue = person.serialize().toJson()
    let jsonObject = (jsonValue as JsonObject).getOrThrow()

    // 提取并打印序列化后的字段值
    let nameValue = (jsonObject.get("name").getOrThrow() as JsonString).getOrThrow()
    let ageValue = (jsonObject.get("age").getOrThrow() as JsonInt).getOrThrow()
    let locationValue = jsonObject.get("location").getOrThrow()

    println(nameValue.getValue())
    println(ageValue.getValue())
    println(locationValue.toString())

    println("===========")

    // 从 JSON 字符串反序列化对象
    let jsonString = ##"{"age": 123, "location": { "tag": "H", "timestamp": 45 }, "name": "zhangsan"}"##
    let parsedJson = JsonValue.fromStr(jsonString)
    let parsedObject = (parsedJson as JsonObject).getOrThrow()

    // 提取并打印反序列化后的字段值
    let parsedName = (parsedObject.get("name").getOrThrow() as JsonString).getOrThrow()
    let parsedAge = (parsedObject.get("age").getOrThrow() as JsonInt).getOrThrow()
    let parsedLocation = (parsedObject.get("location").getOrThrow() as JsonObject).getOrThrow()
    let parsedTimestamp = (parsedLocation.get("timestamp").getOrThrow() as JsonInt).getOrThrow()
    let parsedTag = (parsedLocation.get("tag").getOrThrow() as JsonString).getOrThrow()

    println(parsedName.getValue())
    println(parsedAge.getValue())
    println(parsedTimestamp.getValue())
    println(parsedTag.getValue())
}
```

运行结果：

```text
Abcde
555
null
===========
zhangsan
123
45
H
```
