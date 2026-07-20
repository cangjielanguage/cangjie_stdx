# 接口

## interface Serializable\<T>

```cangjie
public interface Serializable<T> {
    func serialize(): DataModel
    static func deserialize(dm: DataModel): T
}
```

功能：用于规范序列化。

### static func deserialize(DataModel)

```cangjie
static func deserialize(dm: DataModel): T
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为对象。

> **说明：**
>
> 支持实现 [Serializable](serialization_package_interfaces.md#interface-serializablet) 的类型包括:
>
> - 基本数据类型：整数类型、浮点类型、布尔类型、字符类型、字符串类型。
> - Collection 类型：Array、ArrayList、HashSet、HashMap、Option。
> - 用户自定义的实现了 [Serializable](serialization_package_interfaces.md#interface-serializablet)\<T> 的类型。

参数：

- dm: [DataModel](./serialization_package_classes.md#class-datamodel) - 待反序列化的数据。

返回值：

- T - 反序列化的对象。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不支持反序列化到 T 类型时，抛出异常。

### func serialize()

```cangjie
func serialize(): DataModel
```

功能：将自身序列化为 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

### extend Bool <: Serializable

```cangjie
extend Bool <: Serializable<Bool>
```

功能：为 Bool 类型实现 [Serializable](#interface-serializablet) 接口。

父类型：

- [Serializable](#interface-serializablet)\<Bool>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Bool
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 Bool。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- Bool - 反序列化后的 Bool。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不是 [DataModelBool](serialization_package_classes.md#class-datamodelbool) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*

main() {
    // 先获得一个序列化后的DataModel
    let dataModel = true.serialize()

    // 使用Bool的deserialize方法反序列化
    let result = Bool.deserialize(dataModel)

    println("Bool反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
Bool反序列化成功: true
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 Bool 序列化为 [DataModelBool](serialization_package_classes.md#class-datamodelbool)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModelBool](serialization_package_classes.md#class-datamodelbool)。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*

main() {
    let boolValue: Bool = true
    let dataModel = boolValue.serialize()
    return 0
}
```

### extend Float16 <: Serializable

```cangjie
extend Float16 <: Serializable<Float16>
```

功能：为 Float16 类型实现 [Serializable](#interface-serializablet) 接口。

父类型：

- [Serializable](#interface-serializablet)\<Float16>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Float16
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 Float16。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- Float16 - 反序列化后的 Float16。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不是 [DataModelFloat](serialization_package_classes.md#class-datamodelfloat) 或者 [DataModelInt](serialization_package_classes.md#class-datamodelint) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*

main() {
    // 先获得一个序列化后的DataModel
    let dataModel = 3.14f16.serialize()

    // 使用Float16的deserialize方法反序列化
    let result = Float16.deserialize(dataModel)

    println("Float16反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
Float16反序列化成功: 3.140625
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 Float16 序列化为 [DataModelFloat](serialization_package_classes.md#class-datamodelfloat)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModelFloat](serialization_package_classes.md#class-datamodelfloat)。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*

main() {
    let floatValue: Float16 = 3.14f16
    let dataModel = floatValue.serialize()
    return 0
}
```

### extend Float32 <: Serializable

```cangjie
extend Float32 <: Serializable<Float32>
```

功能：为 Float32 类型实现 [Serializable](#interface-serializablet) 接口。

父类型：

- [Serializable](#interface-serializablet)\<Float32>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Float32
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 Float32。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- Float32 - 反序列化后的 Float32。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不是 [DataModelFloat](serialization_package_classes.md#class-datamodelfloat) 或者 [DataModelInt](serialization_package_classes.md#class-datamodelint) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*

main() {
    // 先获得一个序列化后的DataModel
    let dataModel = 3.14f32.serialize()

    // 使用Float32的deserialize方法反序列化
    let result = Float32.deserialize(dataModel)

    println("Float32反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
Float32反序列化成功: 3.140000
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 Float32 序列化为 [DataModelFloat](serialization_package_classes.md#class-datamodelfloat)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModelFloat](serialization_package_classes.md#class-datamodelfloat)。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*

main() {
    let floatValue: Float32 = 3.14f32
    let dataModel = floatValue.serialize()
    return 0
}
```

### extend Float64 <: Serializable

```cangjie
extend Float64 <: Serializable<Float64>
```

功能：为 Float64 类型实现 [Serializable](#interface-serializablet) 接口。

父类型：

- [Serializable](#interface-serializablet)\<Float64>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Float64
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 Float64。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- Float64 - 反序列化后的 Float64。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不是 [DataModelFloat](serialization_package_classes.md#class-datamodelfloat) 或者 [DataModelInt](serialization_package_classes.md#class-datamodelint) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*

main() {
    // 先获得一个序列化后的DataModel
    let dataModel = 3.14.serialize()

    // 使用Float64的deserialize方法反序列化
    let result = Float64.deserialize(dataModel)

    println("Float64反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
Float64反序列化成功: 3.140000
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 Float64 序列化为 [DataModelFloat](serialization_package_classes.md#class-datamodelfloat)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModelFloat](serialization_package_classes.md#class-datamodelfloat)。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*

main() {
    let floatValue: Float64 = 3.14159f64
    let dataModel = floatValue.serialize()
    return 0
}
```

### extend Int16 <: Serializable

```cangjie
extend Int16 <: Serializable<Int16>
```

功能：为 Int16 类型实现 [Serializable](#interface-serializablet) 接口。

父类型：

- [Serializable](#interface-serializablet)\<Int16>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Int16
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 Int16。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- Int16 - 反序列化后的 Int16。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不是 [DataModelInt](serialization_package_classes.md#class-datamodelint) 时，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*

main() {
    // 先获得一个序列化后的DataModel
    let dataModel = 123i16.serialize()

    // 使用Int16的deserialize方法反序列化
    let result = Int16.deserialize(dataModel)

    println("Int16反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
Int16反序列化成功: 123
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 Int16 序列化为 [DataModelInt](serialization_package_classes.md#class-datamodelint)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModelInt](serialization_package_classes.md#class-datamodelint)。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*

main() {
    let intValue: Int16 = 123
    let dataModel = intValue.serialize()
    return 0
}
```

### extend Int32 <: Serializable

```cangjie
extend Int32 <: Serializable<Int32>
```

功能：为 Int32 类型实现 [Serializable](#interface-serializablet) 接口。

父类型：

- [Serializable](#interface-serializablet)\<Int32>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Int32
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 Int32。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- Int32 - 反序列化后的 Int32。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不是 [DataModelInt](serialization_package_classes.md#class-datamodelint) 时，抛出异常

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*

main() {
    // 先获得一个序列化后的DataModel
    let dataModel = 123i32.serialize()

    // 使用Int32的deserialize方法反序列化
    let result = Int32.deserialize(dataModel)

    println("Int32反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
Int32反序列化成功: 123
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 Int32 序列化为 [DataModelInt](serialization_package_classes.md#class-datamodelint)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModelInt](serialization_package_classes.md#class-datamodelint)。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*

main() {
    let intValue: Int32 = 123
    let dataModel = intValue.serialize()
    return 0
}
```

### extend Int64 <: Serializable

```cangjie
extend Int64 <: Serializable<Int64>
```

功能：为 Int64 类型实现 [Serializable](#interface-serializablet) 接口。

父类型：

- [Serializable](#interface-serializablet)\<Int64>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Int64
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 Int64。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- Int64 - 反序列化后的 Int64。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不是 [DataModelInt](serialization_package_classes.md#class-datamodelint) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*

main() {
    // 先获得一个序列化后的DataModel
    let dataModel = 123.serialize()

    // 使用Int64的deserialize方法反序列化
    let result = Int64.deserialize(dataModel)

    println("Int64反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
Int64反序列化成功: 123
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 Int64 序列化为 [DataModelInt](serialization_package_classes.md#class-datamodelint)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModelInt](serialization_package_classes.md#class-datamodelint)。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*

main() {
    let intValue: Int64 = 123
    let dataModel = intValue.serialize()
    return 0
}
```

### extend Int8 <: Serializable

```cangjie
extend Int8 <: Serializable<Int8>
```

功能：为 Int8 类型实现 [Serializable](#interface-serializablet) 接口。

父类型：

- [Serializable](#interface-serializablet)\<Int8>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Int8
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 Int8。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- Int8 - 反序列化后的 Int8。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不是 [DataModelInt](serialization_package_classes.md#class-datamodelint) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*

main() {
    // 先获得一个序列化后的DataModel
    let dataModel = 123i8.serialize()

    // 使用Int8的deserialize方法反序列化
    let result = Int8.deserialize(dataModel)

    println("Int8反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
Int8反序列化成功: 123
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 Int8 序列化为 [DataModelInt](serialization_package_classes.md#class-datamodelint)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModelInt](serialization_package_classes.md#class-datamodelint)。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*

main() {
    let intValue: Int8 = 123
    let dataModel = intValue.serialize()
    return 0
}
```

### extend Rune <: Serializable

```cangjie
extend Rune <: Serializable<Rune>
```

功能：为 Rune 类型实现 [Serializable](#interface-serializablet) 接口。

父类型：

- [Serializable](#interface-serializablet)\<Rune>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Rune
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 Rune。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- Rune - 反序列化后的字符。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不是 [DataModelString](serialization_package_classes.md#class-datamodelstring) 时，则抛出此异常。
- Exception - 当 `dm` 的类型不是 Rune 时，则抛出此异常。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*

main() {
    // 先获得一个序列化后的DataModel
    let dataModel = r'A'.serialize()

    // 使用Rune的deserialize方法反序列化
    let result = Rune.deserialize(dataModel)

    println("Rune反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
Rune反序列化成功: A
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 Rune 序列化为 [DataModelString](serialization_package_classes.md#class-datamodelstring)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModelString](serialization_package_classes.md#class-datamodelstring)。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*

main() {
    let runeValue: Rune = 'A'
    let dataModel = runeValue.serialize()
    return 0
}
```

### extend String <: Serializable

```cangjie
extend String <: Serializable<String>
```

功能：为 String 类型实现 [Serializable](#interface-serializablet) 接口。

父类型：

- [Serializable](#interface-serializablet)\<String>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): String
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 String。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- String - 反序列化后的 String。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不是 [DataModelString](serialization_package_classes.md#class-datamodelstring) 时，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*

main() {
    // 先获得一个序列化后的DataModel
    let dataModel = ("测试字符串").serialize()

    // 使用String的deserialize方法反序列化
    let result = String.deserialize(dataModel)

    println("String反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
String反序列化成功: 测试字符串
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 String 序列化为 [DataModelString](serialization_package_classes.md#class-datamodelstring)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModelString](serialization_package_classes.md#class-datamodelstring)。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*

main() {
    let strValue: String = "测试字符串"
    let dataModel = strValue.serialize()
    return 0
}
```

### extend UInt16 <: Serializable

```cangjie
extend UInt16 <: Serializable<UInt16>
```

功能：为 UInt16 类型实现 [Serializable](#interface-serializablet) 接口。

父类型：

- [Serializable](#interface-serializablet)\<UInt16>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): UInt16
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 UInt16。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- UInt16 - 反序列化后的 UInt16。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不是 [DataModelInt](serialization_package_classes.md#class-datamodelint) 时，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*

main() {
    // 先获得一个序列化后的DataModel
    let dataModel = 123u16.serialize()

    // 使用UInt16的deserialize方法反序列化
    let result = UInt16.deserialize(dataModel)

    println("UInt16反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
UInt16反序列化成功: 123
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 UInt16 序列化为 [DataModelInt](serialization_package_classes.md#class-datamodelint)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModelInt](serialization_package_classes.md#class-datamodelint)。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*

main() {
    let uintValue: UInt16 = 123
    let dataModel = uintValue.serialize()
    return 0
}
```

### extend UInt32 <: Serializable

```cangjie
extend UInt32 <: Serializable<UInt32>
```

功能：为 UInt32 类型实现 [Serializable](#interface-serializablet) 接口。

父类型：

- [Serializable](#interface-serializablet)\<UInt32>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): UInt32
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 UInt32。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- UInt32 - 反序列化后的 UInt32。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不是 [DataModelInt](serialization_package_classes.md#class-datamodelint) 时，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*

main() {
    // 先获得一个序列化后的DataModel
    let dataModel = 123u32.serialize()

    // 使用UInt32的deserialize方法反序列化
    let result = UInt32.deserialize(dataModel)

    println("UInt32反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
UInt32反序列化成功: 123
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 UInt32 序列化为 [DataModelInt](serialization_package_classes.md#class-datamodelint)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModelInt](serialization_package_classes.md#class-datamodelint)。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*

main() {
    let uintValue: UInt32 = 123
    let dataModel = uintValue.serialize()
    return 0
}
```

### extend UInt64 <: Serializable

```cangjie
extend UInt64 <: Serializable<UInt64>
```

功能：为 UInt64 类型实现 [Serializable](#interface-serializablet) 接口。

父类型：

- [Serializable](#interface-serializablet)\<UInt64>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): UInt64
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 UInt64。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- UInt64 - 反序列化后的 UInt64。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不是 [DataModelInt](serialization_package_classes.md#class-datamodelint) 时，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*

main() {
    // 先获得一个序列化后的DataModel
    let dataModel = 123u64.serialize()

    // 使用UInt64的deserialize方法反序列化
    let result = UInt64.deserialize(dataModel)

    println("UInt64反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
UInt64反序列化成功: 123
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 UInt64 序列化为 [DataModelInt](serialization_package_classes.md#class-datamodelint)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModelInt](serialization_package_classes.md#class-datamodelint)。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*

main() {
    let uintValue: UInt64 = 123
    let dataModel = uintValue.serialize()
    return 0
}
```

### extend UInt8 <: Serializable

```cangjie
extend UInt8 <: Serializable<UInt8>
```

功能：为 UInt8 类型实现 [Serializable](#interface-serializablet) 接口。

父类型：

- [Serializable](#interface-serializablet)\<UInt8>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): UInt8
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 UInt8。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- UInt8 - 反序列化后的 UInt8。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不是 [DataModelInt](serialization_package_classes.md#class-datamodelint) 时，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*

main() {
    // 先获得一个序列化后的DataModel
    let dataModel = 123u8.serialize()

    // 使用UInt8的deserialize方法反序列化
    let result = UInt8.deserialize(dataModel)

    println("UInt8反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
UInt8反序列化成功: 123
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 UInt8 序列化为 [DataModelInt](serialization_package_classes.md#class-datamodelint)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModelInt](serialization_package_classes.md#class-datamodelint)。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*

main() {
    let uintValue: UInt8 = 123
    let dataModel = uintValue.serialize()
    return 0
}
```

### extend\<K, V> HashMap\<K, V> <: Serializable\<HashMap\<K, V>> where K <: Serializable\<K> & Hashable & Equatable\<K>, V <: Serializable\<V>

```cangjie
extend<K, V> HashMap<K, V> <: Serializable<HashMap<K, V>> where K <: Serializable<K> & Hashable & Equatable<K>, V <: Serializable<V>
```

功能：为 HashMap\<K, V> 类型实现 [Serializable](#interface-serializablet)\<HashMap\<K, V>> 接口。

父类型：

- [Serializable](#interface-serializablet)\<HashMap\<K, V>>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): HashMap<K, V>
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 HashMap\<K, V>。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- HashMap\<K, V> - 反序列化后的 HashMap\<K, V>。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 不是 [DataModelStruct](serialization_package_classes.md#class-datamodelstruct) 类型，或者 [DataModelStruct](serialization_package_classes.md#class-datamodelstruct) 类型的 `dm` 中的 [Field](serialization_package_classes.md#class-field) 不是 String 类型时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*
import std.collection.*

main() {
    // 先获得一个序列化后的DataModel
    let map = HashMap<String, Int64>()
    map.add("key1", 100)
    map.add("key2", 200)
    let dataModel = map.serialize()

    // 使用HashMap的deserialize方法反序列化
    let result = HashMap<String, Int64>.deserialize(dataModel)

    println("HashMap反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
HashMap反序列化成功: [(key1, 100), (key2, 200)]
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 HashMap\<K, V> 序列化为 [DataModelSeq](serialization_package_classes.md#class-datamodelseq)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModelSeq](serialization_package_classes.md#class-datamodelseq)。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当前 HashMap 实例中的 Key 不是 String 类型时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*
import std.collection.*

main() {
    let map = HashMap<String, Int64>()
    map.add("key1", 100)
    map.add("key2", 200)
    let dataModel = map.serialize()
    return 0
}
```

### extend\<T> Array\<T> <: Serializable\<Array\<T>> where T <: Serializable\<T>

```cangjie
extend<T> Array<T> <: Serializable<Array<T>> where T <: Serializable<T>
```

功能：为 Array\<T> 类型实现 [Serializable](#interface-serializablet)\<Array\<T>> 接口。

父类型：

- [Serializable](#interface-serializablet)\<Array\<T>>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Array<T>
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 Array\<T>。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- Array\<T> - 反序列化后的 Array\<T>。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不是 [DataModelSeq](serialization_package_classes.md#class-datamodelseq) 时，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*

main() {
    // 先获得一个序列化后的DataModel
    let arr = [1, 2, 3]
    let dataModel = arr.serialize()

    // 使用Array的deserialize方法反序列化
    let result = Array<Int64>.deserialize(dataModel)

    println("Array反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
Array反序列化成功: [1, 2, 3]
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 Array\<T> 序列化为 [DataModelSeq](serialization_package_classes.md#class-datamodelseq)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModelSeq](serialization_package_classes.md#class-datamodelseq)。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*

main() {
    let arr = [1, 2, 3]
    let dataModel = arr.serialize()
    return 0
}
```

### extend\<T> ArrayList\<T> <: Serializable\<ArrayList\<T>> where T <: Serializable\<T>

```cangjie
extend<T> ArrayList<T> <: Serializable<ArrayList<T>> where T <: Serializable<T>
```

功能：为 ArrayList\<T> 类型实现 [Serializable](#interface-serializablet)\<ArrayList\<T>> 接口。

父类型：

- [Serializable](#interface-serializablet)\<ArrayList\<T>>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): ArrayList<T>
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 ArrayList\<T>。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- ArrayList\<T> - 反序列化后的 ArrayList\<T>。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不是 [DataModelSeq](serialization_package_classes.md#class-datamodelseq) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*
import std.collection.*

main() {
    // 先获得一个序列化后的DataModel
    let arrayList = ArrayList<Int64>([100, 200])
    let dataModel = arrayList.serialize()

    // 使用ArrayList的deserialize方法反序列化
    let result = ArrayList<Int64>.deserialize(dataModel)

    println("ArrayList反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
ArrayList反序列化成功: [100, 200]
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 ArrayList\<T> 序列化为 [DataModelSeq](serialization_package_classes.md#class-datamodelseq)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModelSeq](serialization_package_classes.md#class-datamodelseq)。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*
import std.collection.*

main() {
    let arrayList = ArrayList<Int64>([100, 200])
    let dataModel = arrayList.serialize()
    return 0
}
```

### extend\<T> HashSet\<T> <: Serializable\<HashSet\<T>> where T <: Serializable\<T> & Hashable & Equatable\<T>

```cangjie
extend<T> HashSet<T> <: Serializable<HashSet<T>> where T <: Serializable<T> & Hashable & Equatable<T>
```

功能：为 HashSet\<T> 类型实现 [Serializable](#interface-serializablet)\<HashSet\<T>> 接口。

父类型：

- [Serializable](#interface-serializablet)\<HashSet\<T>>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): HashSet<T>
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 HashSet\<T>。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- HashSet\<T> - 反序列化后的 HashSet\<T>。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不是 [DataModelSeq](serialization_package_classes.md#class-datamodelseq) 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*
import std.collection.*

main() {
    // 先获得一个序列化后的DataModel
    let hashSet = HashSet<String>(["元素1", "元素2"])
    let dataModel = hashSet.serialize()

    // 使用HashSet的deserialize方法反序列化
    let result = HashSet<String>.deserialize(dataModel)

    println("HashSet反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
HashSet反序列化成功: [元素1, 元素2]
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 HashSet\<T> 序列化为 [DataModelSeq](serialization_package_classes.md#class-datamodelseq)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModelSeq](serialization_package_classes.md#class-datamodelseq)。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*
import std.collection.*

main() {
    let hashSet = HashSet<String>(["元素1", "元素2"])
    let dataModel = hashSet.serialize()
    return 0
}
```

### extend\<T> Option\<T> <: Serializable\<Option\<T>> where T <: Serializable\<T>

```cangjie
extend<T> Option<T> <: Serializable<Option<T>> where T <: Serializable<T>
```

功能：为 Option\<T> 类型实现 [Serializable](#interface-serializablet)\<Option\<T>> 接口。

父类型：

- [Serializable](#interface-serializablet)\<Option\<T>>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Option<T>
```

功能：将 [DataModel](serialization_package_classes.md#class-datamodel) 反序列化为 Option\<T>。

参数：

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - 需要被反序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- Option\<T> - 反序列化后的 Option\<T>。

异常：

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - 当 `dm` 的类型不支持反序列化到 T 类型时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.serialization.serialization.*

main() {
    // 先获得一个序列化后的DataModel
    let option = Some(123)
    let dataModel = option.serialize()

    // 使用Option的deserialize方法反序列化
    let result = Option<Int64>.deserialize(dataModel)

    println("Option反序列化成功: ${result}")
    return 0
}
```

运行结果：

```text
Option反序列化成功: Some(123)
```

#### func serialize()

```cangjie
public func serialize(): DataModel
```

功能：将 Option\<T> 中的 `T` 序列化为 [DataModel](serialization_package_classes.md#class-datamodel)。

返回值：

- [DataModel](serialization_package_classes.md#class-datamodel) - 序列化的 [DataModel](serialization_package_classes.md#class-datamodel)。

示例：

<!-- run -->
```cangjie
import stdx.serialization.serialization.*

main() {
    let option = Some(123)
    let dataModel = option.serialize()
    return 0
}
```
