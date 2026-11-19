# Interfaces

## interface Serializable

```cangjie
public interface Serializable<T> {
    func serialize(): DataModel
    static func deserialize(dm: DataModel): T
}
```

Function: Defines serialization standards.

### static func deserialize(DataModel)

```cangjie
static func deserialize(dm: DataModel): T
```

Function: Deserializes a [DataModel](serialization_package_classes.md#class-datamodel) into an object.

> **Note:**
>
> Supported types implementing [Serializable](serialization_package_interfaces.md#interface-serializable) include:
>
> - Primitive data types: integer types, floating-point types, boolean type, character type, string type.
> - Collection types: Array, ArrayList, HashSet, HashMap, Option.
> - User-defined types implementing [Serializable](serialization_package_interfaces.md#interface-serializable)\<T>.

Parameters:

- dm: [DataModel](./serialization_package_classes.md#class-datamodel) - Data to be deserialized.

Return value:

- T - The deserialized object.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` type cannot be deserialized into type T.

### func serialize()

```cangjie
func serialize(): DataModel
```

Function: Serializes itself into a [DataModel](serialization_package_classes.md#class-datamodel).

Return value:

- [DataModel](serialization_package_classes.md#class-datamodel) - The serialized [DataModel](serialization_package_classes.md#class-datamodel).

### extend\<T> Array\<T> <: Serializable\<Array\<T>> where T <: Serializable\<T>

```cangjie
extend<T> Array<T> <: Serializable<Array<T>> where T <: Serializable<T>
```

Function: Implements [Serializable](#interface-serializable)\<Array\<T>> interface for Array\<T> type.

Parent types:

- [Serializable](#interface-serializable)\<Array\<T>>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Array<T>
```

Function: Deserializes a [DataModel](serialization_package_classes.md#class-datamodel) into Array\<T>.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return value:

- Array\<T> - The deserialized Array\<T>.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` type is not [DataModelSeq](serialization_package_classes.md#class-datamodelseq).

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes Array\<T> into [DataModelSeq](serialization_package_classes.md#class-datamodelseq).

Return value:

- [DataModel](serialization_package_classes.md#class-datamodel) - The serialized [DataModelSeq](serialization_package_classes.md#class-datamodelseq).

### extend\<T> ArrayList\<T> <: Serializable\<ArrayList\<T>> where T <: Serializable\<T>

```cangjie
extend<T> ArrayList<T> <: Serializable<ArrayList<T>> where T <: Serializable<T>
```

Function: Implements [Serializable](#interface-serializable)\<ArrayList\<T>> interface for ArrayList\<T> type.

Parent types:

- [Serializable](#interface-serializable)\<ArrayList\<T>>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): ArrayList<T>
```

Function: Deserializes a [DataModel](serialization_package_classes.md#class-datamodel) into ArrayList\<T>.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return value:

- ArrayList\<T> - The deserialized ArrayList\<T>.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` type is not [DataModelSeq](serialization_package_classes.md#class-datamodelseq).

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes ArrayList\<T> into [DataModelSeq](serialization_package_classes.md#class-datamodelseq).

Return value:

- [DataModel](serialization_package_classes.md#class-datamodel) - The serialized [DataModelSeq](serialization_package_classes.md#class-datamodelseq).

### extend Bool <: Serializable

```cangjie
extend Bool <: Serializable<Bool>
```

Function: Implements [Serializable](#interface-serializable) interface for Bool type.

Parent types:

- [Serializable](#interface-serializable)\<Bool>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Bool
```

Function: Deserializes a [DataModel](serialization_package_classes.md#class-datamodel) into Bool.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return value:

- Bool - The deserialized Bool.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` type is not [DataModelBool](serialization_package_classes.md#class-datamodelbool).

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes Bool into [DataModelBool](serialization_package_classes.md#class-datamodelbool).

Return value:

- [DataModel](serialization_package_classes.md#class-datamodel) - The serialized [DataModelBool](serialization_package_classes.md#class-datamodelbool).

### extend Float16 <: Serializable

```cangjie
extend Float16 <: Serializable<Float16>
```

Function: Implements [Serializable](#interface-serializable) interface for Float16 type.

Parent types:

- [Serializable](#interface-serializable)\<Float16>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Float16
```

Function: Deserializes a [DataModel](serialization_package_classes.md#class-datamodel) into Float16.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return value:

- Float16 - The deserialized Float16.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` type is neither [DataModelFloat](serialization_package_classes.md#class-datamodelfloat) nor [DataModelInt](serialization_package_classes.md#class-datamodelint), or when `dm` is a [DataModelInt](serialization_package_classes.md#class-datamodelint) but its value is out of the safe integer range of Float16 (-2047 ~ 2047).

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes Float16 into [DataModelFloat](serialization_package_classes.md#class-datamodelfloat).

Return value:

- [DataModel](serialization_package_classes.md#class-datamodel) - The serialized [DataModelFloat](serialization_package_classes.md#class-datamodelfloat).

### extend Float32 <: Serializable

```cangjie
extend Float32 <: Serializable<Float32>
```

Function: Implements [Serializable](#interface-serializable) interface for Float32 type.

Parent types:

- [Serializable](#interface-serializable)\<Float32>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Float32
```

Function: Deserializes a [DataModel](serialization_package_classes.md#class-datamodel) into Float32.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return value:

- Float32 - The deserialized Float32.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` type is neither [DataModelFloat](serialization_package_classes.md#class-datamodelfloat) nor [DataModelInt](serialization_package_classes.md#class-datamodelint), or when `dm` is a [DataModelInt](serialization_package_classes.md#class-datamodelint) but its value is out of the safe integer range of Float32 (-16777215 ~ 16777215).

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes Float32 into [DataModelFloat](serialization_package_classes.md#class-datamodelfloat).

Return value:

- [DataModel](serialization_package_classes.md#class-datamodel) - The serialized [DataModelFloat](serialization_package_classes.md#class-datamodelfloat).

### extend Float64 <: Serializable

```cangjie
extend Float64 <: Serializable<Float64>
```

Function: Implements [Serializable](#interface-serializable) interface for Float64 type.

Parent types:

- [Serializable](#interface-serializable)\<Float64>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Float64
```

Function: Deserializes a [DataModel](serialization_package_classes.md#class-datamodel) into Float64.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return value:

- Float64 - The deserialized Float64.Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when the type of `dm` is neither [DataModelFloat](serialization_package_classes.md#class-datamodelfloat) nor [DataModelInt](serialization_package_classes.md#class-datamodelint), or when `dm` is a [DataModelInt](serialization_package_classes.md#class-datamodelint) but its value is out of the safe integer range of Float64 (-9007199254740991 ~ 9007199254740991).

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes Float64 into [DataModelFloat](serialization_package_classes.md#class-datamodelfloat).

Return Value:

- [DataModel](serialization_package_classes.md#class-datamodel) - Serialized [DataModelFloat](serialization_package_classes.md#class-datamodelfloat).

### extend\<K, V> HashMap\<K, V> <: Serializable\<HashMap\<K, V>> where K <: Serializable\<K> & Hashable & Equatable\<K>, V <: Serializable\<V>

```cangjie
extend<K, V> HashMap<K, V> <: Serializable<HashMap<K, V>> where K <: Serializable<K> & Hashable & Equatable<K>, V <: Serializable<V>
```

Function: Implements the [Serializable](#interface-serializable)\<HashMap\<K, V>> interface for the HashMap\<K, V> type.

Parent Type:

- [Serializable](#interface-serializable)\<HashMap\<K, V>>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): HashMap<K, V>
```

Function: Deserializes [DataModel](serialization_package_classes.md#class-datamodel) into HashMap\<K, V>.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - The [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return Value:

- HashMap\<K, V> - The deserialized HashMap\<K, V>.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` is not of type [DataModelStruct](serialization_package_classes.md#class-datamodelstruct).
- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when K is not String type (the [Field](serialization_package_classes.md#class-field) name of a [DataModelStruct](serialization_package_classes.md#class-datamodelstruct) must be a String; only HashMap\<String, V> supports deserialization).

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes HashMap\<K, V> into [DataModelStruct](serialization_package_classes.md#class-datamodelstruct), where each key-value pair is wrapped as a [Field](serialization_package_classes.md#class-field) (the Field name is the key, and the Field data is the value).

Return Value:

- [DataModel](serialization_package_classes.md#class-datamodel) - Serialized [DataModelStruct](serialization_package_classes.md#class-datamodelstruct).

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when a Key in the current HashMap instance is not of String type.

### extend\<T> HashSet\<T> <: Serializable\<HashSet\<T>> where T <: Serializable\<T> & Hashable & Equatable\<T>

```cangjie
extend<T> HashSet<T> <: Serializable<HashSet<T>> where T <: Serializable<T> & Hashable & Equatable<T>
```

Function: Implements the [Serializable](#interface-serializable)\<HashSet\<T>> interface for the HashSet\<T> type.

Parent Type:

- [Serializable](#interface-serializable)\<HashSet\<T>>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): HashSet<T>
```

Function: Deserializes [DataModel](serialization_package_classes.md#class-datamodel) into HashSet\<T>.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - The [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return Value:

- HashSet\<T> - The deserialized HashSet\<T>.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` is not of type [DataModelSeq](serialization_package_classes.md#class-datamodelseq).

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes HashSet\<T> into [DataModelSeq](serialization_package_classes.md#class-datamodelseq).

Return Value:

- [DataModel](serialization_package_classes.md#class-datamodel) - Serialized [DataModelSeq](serialization_package_classes.md#class-datamodelseq).

### extend Int16 <: Serializable

```cangjie
extend Int16 <: Serializable<Int16>
```

Function: Implements the [Serializable](#interface-serializable) interface for the Int16 type.

Parent Type:

- [Serializable](#interface-serializable)\<Int16>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Int16
```

Function: Deserializes [DataModel](serialization_package_classes.md#class-datamodel) into Int16.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - The [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return Value:

- Int16 - The deserialized Int16.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` is not of type [DataModelInt](serialization_package_classes.md#class-datamodelint).
- Exception - Thrown when `dm` is a [DataModelInt](serialization_package_classes.md#class-datamodelint) but its value is out of the representable range of Int16 (-32768 ~ 32767), without truncation.

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes Int16 into [DataModelInt](serialization_package_classes.md#class-datamodelint).

Return Value:

- [DataModel](serialization_package_classes.md#class-datamodel) - Serialized [DataModelInt](serialization_package_classes.md#class-datamodelint).

### extend Int32 <: Serializable

```cangjie
extend Int32 <: Serializable<Int32>
```

Function: Implements the [Serializable](#interface-serializable) interface for the Int32 type.

Parent Type:

- [Serializable](#interface-serializable)\<Int32>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Int32
```

Function: Deserializes [DataModel](serialization_package_classes.md#class-datamodel) into Int32.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - The [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return Value:

- Int32 - The deserialized Int32.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` is not of type [DataModelInt](serialization_package_classes.md#class-datamodelint).
- Exception - Thrown when `dm` is a [DataModelInt](serialization_package_classes.md#class-datamodelint) but its value is out of the representable range of Int32 (-2147483648 ~ 2147483647), without truncation.

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes Int32 into [DataModelInt](serialization_package_classes.md#class-datamodelint).

Return Value:

- [DataModel](serialization_package_classes.md#class-datamodel) - Serialized [DataModelInt](serialization_package_classes.md#class-datamodelint).

### extend Int64 <: Serializable

```cangjie
extend Int64 <: Serializable<Int64>
```

Function: Implements the [Serializable](#interface-serializable) interface for the Int64 type.

Parent Type:

- [Serializable](#interface-serializable)\<Int64>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Int64
```

Function: Deserializes [DataModel](serialization_package_classes.md#class-datamodel) into Int64.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - The [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return Value:

- Int64 - The deserialized Int64.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` is not of type [DataModelInt](serialization_package_classes.md#class-datamodelint).

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes Int64 into [DataModelInt](serialization_package_classes.md#class-datamodelint).

Return Value:

- [DataModel](serialization_package_classes.md#class-datamodel) - Serialized [DataModelInt](serialization_package_classes.md#class-datamodelint).

### extend Int8 <: Serializable

```cangjie
extend Int8 <: Serializable<Int8>
```

Function: Implements the [Serializable](#interface-serializable) interface for the Int8 type.

Parent Type:

- [Serializable](#interface-serializable)\<Int8>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Int8
```

Function: Deserializes [DataModel](serialization_package_classes.md#class-datamodel) into Int8.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - The [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return Value:

- Int8 - The deserialized Int8.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` is not of type [DataModelInt](serialization_package_classes.md#class-datamodelint).
- Exception - Thrown when `dm` is a [DataModelInt](serialization_package_classes.md#class-datamodelint) but its value is out of the representable range of Int8 (-128 ~ 127), without truncation.

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes Int8 into [DataModelInt](serialization_package_classes.md#class-datamodelint).

Return Value:

- [DataModel](serialization_package_classes.md#class-datamodel) - Serialized [DataModelInt](serialization_package_classes.md#class-datamodelint).

### extend\<T> Option\<T> <: Serializable\<Option\<T>> where T <: Serializable\<T>

```cangjie
extend<T> Option<T> <: Serializable<Option<T>> where T <: Serializable<T>
```

Function: Implements the [Serializable](#interface-serializable)\<Option\<T>> interface for the Option\<T> type.

Parent Type:

- [Serializable](#interface-serializable)\<Option\<T>>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Option<T>
```

Function: Deserializes a [DataModel](serialization_package_classes.md#class-datamodel) into Option\<T>.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - The [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return Value:

- Option\<T> - The deserialized Option\<T>.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` type cannot be deserialized to type T.

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes the `T` in Option\<T> into a [DataModel](serialization_package_classes.md#class-datamodel).

Return Value:

- [DataModel](serialization_package_classes.md#class-datamodel) - The serialized [DataModel](serialization_package_classes.md#class-datamodel).

### extend Rune <: Serializable

```cangjie
extend Rune <: Serializable<Rune>
```

Function: Implements the [Serializable](#interface-serializable) interface for the Rune type.

Parent Type:

- [Serializable](#interface-serializable)\<Rune>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): Rune
```

Function: Deserializes a [DataModel](serialization_package_classes.md#class-datamodel) into a Rune.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - The [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return Value:

- Rune - The deserialized character.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` is not of type [DataModelString](serialization_package_classes.md#class-datamodelstring).
- Exception - Thrown when `dm` is a [DataModelString](serialization_package_classes.md#class-datamodelstring) whose content is not a single character.

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes a Rune into a [DataModelString](serialization_package_classes.md#class-datamodelstring).

Return Value:

- [DataModel](serialization_package_classes.md#class-datamodel) - The serialized [DataModelString](serialization_package_classes.md#class-datamodelstring).

### extend String <: Serializable

```cangjie
extend String <: Serializable<String>
```

Function: Implements the [Serializable](#interface-serializable) interface for the String type.

Parent Type:

- [Serializable](#interface-serializable)\<String>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): String
```

Function: Deserializes a [DataModel](serialization_package_classes.md#class-datamodel) into a String.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - The [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return Value:

- String - The deserialized String.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` is not of type [DataModelString](serialization_package_classes.md#class-datamodelstring).

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes a String into a [DataModelString](serialization_package_classes.md#class-datamodelstring).

Return Value:

- [DataModel](serialization_package_classes.md#class-datamodel) - The serialized [DataModelString](serialization_package_classes.md#class-datamodelstring).

### extend UInt16 <: Serializable

```cangjie
extend UInt16 <: Serializable<UInt16>
```

Function: Implements the [Serializable](#interface-serializable) interface for the UInt16 type.

Parent Type:

- [Serializable](#interface-serializable)\<UInt16>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): UInt16
```

Function: Deserializes a [DataModel](serialization_package_classes.md#class-datamodel) into a UInt16.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - The [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return Value:

- UInt16 - The deserialized UInt16.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` is not of type [DataModelInt](serialization_package_classes.md#class-datamodelint).
- Exception - Thrown when `dm` is a [DataModelInt](serialization_package_classes.md#class-datamodelint) but its value is out of the representable range of UInt16 (0 ~ 65535), without truncation.

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes a UInt16 into a [DataModelInt](serialization_package_classes.md#class-datamodelint).

Return Value:

- [DataModel](serialization_package_classes.md#class-datamodel) - The serialized [DataModelInt](serialization_package_classes.md#class-datamodelint).

### extend UInt32 <: Serializable

```cangjie
extend UInt32 <: Serializable<UInt32>
```

Function: Implements the [Serializable](#interface-serializable) interface for the UInt32 type.

Parent Type:

- [Serializable](#interface-serializable)\<UInt32>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): UInt32
```

Function: Deserializes a [DataModel](serialization_package_classes.md#class-datamodel) into a UInt32.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - The [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return Value:

- UInt32 - The deserialized UInt32.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` is not of type [DataModelInt](serialization_package_classes.md#class-datamodelint).
- Exception - Thrown when `dm` is a [DataModelInt](serialization_package_classes.md#class-datamodelint) but its value is out of the representable range of UInt32 (0 ~ 4294967295), without truncation.

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes a UInt32 into a [DataModelInt](serialization_package_classes.md#class-datamodelint).

Return Value:

- [DataModel](serialization_package_classes.md#class-datamodel) - The serialized [DataModelInt](serialization_package_classes.md#class-datamodelint).

### extend UInt64 <: Serializable

```cangjie
extend UInt64 <: Serializable<UInt64>
```

Function: Implements the [Serializable](#interface-serializable) interface for the UInt64 type.

Parent Type:

- [Serializable](#interface-serializable)\<UInt64>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): UInt64
```

Function: Deserializes a [DataModel](serialization_package_classes.md#class-datamodel) into a UInt64.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - The [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return Value:

- UInt64 - The deserialized UInt64.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` is not of type [DataModelInt](serialization_package_classes.md#class-datamodelint).
- Exception - Thrown when `dm` is a [DataModelInt](serialization_package_classes.md#class-datamodelint) but its value is out of the representable range of UInt64 (0 ~ 18446744073709551615), without truncation.

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes a UInt64 into a [DataModelInt](serialization_package_classes.md#class-datamodelint). Throws an Exception when the UInt64 value is greater than Int64.Max (9223372036854775807), as it cannot be represented by the [DataModelInt](serialization_package_classes.md#class-datamodelint) carrier.

Return Value:

- [DataModel](serialization_package_classes.md#class-datamodel) - The serialized [DataModelInt](serialization_package_classes.md#class-datamodelint).

### extend UInt8 <: Serializable

```cangjie
extend UInt8 <: Serializable<UInt8>
```

Function: Implements the [Serializable](#interface-serializable) interface for the UInt8 type.

Parent Type:

- [Serializable](#interface-serializable)\<UInt8>

#### static func deserialize(DataModel)

```cangjie
public static func deserialize(dm: DataModel): UInt8
```

Function: Deserializes a [DataModel](serialization_package_classes.md#class-datamodel) into a UInt8.

Parameters:

- dm: [DataModel](serialization_package_classes.md#class-datamodel) - The [DataModel](serialization_package_classes.md#class-datamodel) to be deserialized.

Return Value:

- UInt8 - The deserialized UInt8.

Exceptions:

- [DataModelException](serialization_package_exceptions.md#class-datamodelexception) - Thrown when `dm` is not of type [DataModelInt](serialization_package_classes.md#class-datamodelint).
- Exception - Thrown when `dm` is a [DataModelInt](serialization_package_classes.md#class-datamodelint) but its value is out of the representable range of UInt8 (0 ~ 255), without truncation.

#### func serialize()

```cangjie
public func serialize(): DataModel
```

Function: Serializes a UInt8 into a [DataModelInt](serialization_package_classes.md#class-datamodelint).

Return Value:

- [DataModel](serialization_package_classes.md#class-datamodel) - The serialized [DataModelInt](serialization_package_classes.md#class-datamodelint).
