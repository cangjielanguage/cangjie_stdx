# JsonValue 与 DataModel 的转换

下面是 JSON 字符串与自定义类型间的转换的示例。该用例为 Person 类型实现了 Serializable 接口，随后进行了从 JSON 字符串到自定义类型的转换和从自定义类型到 JSON 字符串的转换。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*
import stdx.encoding.json.*

// 定义 Person 类，实现 Serializable 接口
class Person <: Serializable<Person> {
    var name: String = ""
    var age: Int64 = 0
    var loc: Option<Location> = Option<Location>.None

    public func serialize(): DataModel {
        return DataModelStruct()
            .add(field<String>("name", name))
            .add(field<Int64>("age", age))
            .add(field<Option<Location>>("loc", loc))
    }

    public static func deserialize(dm: DataModel): Person {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = Person()
        result.name = String.deserialize(dms.get("name"))
        result.age = Int64.deserialize(dms.get("age"))
        result.loc = Option<Location>.deserialize(dms.get("loc"))
        return result
    }
}

// 定义 Location 类，实现 Serializable 接口
class Location <: Serializable<Location> {
    var country: String = ""
    var province: String = ""

    public func serialize(): DataModel {
        return DataModelStruct().add(field<String>("country", country)).add(field<String>("province", province))
    }

    public static func deserialize(dm: DataModel): Location {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let result = Location()
        result.country = String.deserialize(dms.get("country"))
        result.province = String.deserialize(dms.get("province"))
        return result
    }
}

main() {
    // 准备 JSON 字符串
    let jsonString = ##"{
    "name": "A",
    "age": 30,
    "loc": {
        "country": "China",
        "province": "Beijing"
    }
}"##

    // 从 JSON 字符串转换为自定义类型（反序列化）
    let jsonValue = JsonValue.fromStr(jsonString)
    let dataModel = DataModel.fromJson(jsonValue)
    let person = Person.deserialize(dataModel)

    println("反序列化结果:")
    println("姓名: ${person.name}")
    println("年龄: ${person.age}")
    println("国家: ${person.loc.getOrThrow().country}")
    println("省份: ${person.loc.getOrThrow().province}")

    // 从自定义类型转换为 JSON 字符串（序列化）
    println("\n序列化结果:")
    let serializedDataModel = person.serialize()
    let jsonObject = serializedDataModel.toJson().asObject()
    println(jsonObject.toJsonString())
}
```

运行结果：

```text
反序列化结果:
姓名: A
年龄: 30
国家: China
省份: Beijing

序列化结果:
{
  "name": "A",
  "age": 30,
  "loc": {
    "country": "China",
    "province": "Beijing"
  }
}
```
