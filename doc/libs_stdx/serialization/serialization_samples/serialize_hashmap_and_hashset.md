# HashSet 和 HashMap 序列化

示例：

<!-- verify -->
```cangjie
import std.collection.*
import stdx.serialization.serialization.*
import stdx.encoding.json.*

main(): Unit {
    // 序列化 HashSet
    let hashSet: HashSet<DataValue> = HashSet<DataValue>([DataValue(3), DataValue(5), DataValue(7)])
    let setDataModel: DataModel = hashSet.serialize()
    println(setDataModel.toJson().toJsonString())

    println("===========")

    // 序列化 HashMap
    let hashMap: HashMap<String, DataValue> = HashMap<String, DataValue>([
        ("key1", DataValue(3)),
        ("key2", DataValue(6)),
        ("key3", DataValue(9))
    ])
    let mapDataModel: DataModel = hashMap.serialize()
    print(mapDataModel.toJson().toJsonString())
}

// 自定义可序列化数据类型
class DataValue <: Hashable & Equatable<DataValue> & Serializable<DataValue> {
    var value: Int64

    init(value: Int64) {
        this.value = value
    }

    public func hashCode(): Int64 {
        return this.value
    }

    public operator func ==(right: DataValue): Bool {
        return this.value == right.value
    }

    public operator func !=(right: DataValue): Bool {
        return this.value != right.value
    }

    // 实现序列化方法
    public func serialize(): DataModel {
        return DataModelStruct().add(field<Int64>("value", value))
    }

    // 实现反序列化方法
    public static func deserialize(dm: DataModel): DataValue {
        let dataStruct = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("数据模型不是 DataModelStruct 类型")
        }
        let result = DataValue(0)
        result.value = Int64.deserialize(dataStruct.get("value"))
        return result
    }
}
```

运行结果：

```text
[
  {
    "value": 3
  },
  {
    "value": 5
  },
  {
    "value": 7
  }
]
===========
{
  "key1": {
    "value": 3
  },
  "key2": {
    "value": 6
  },
  "key3": {
    "value": 9
  }
}
```
