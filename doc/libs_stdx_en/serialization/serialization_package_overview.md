# stdx.serialization.serialization

## Function Description

The serialization package provides capabilities for serialization and deserialization.

Serialization refers to the process of converting a data structure or object state into a storable format (such as saving to a file, storing in a buffer, or transmitting over a network), allowing the original state to be restored later in the same or another computer environment. Conversely, the reverse operation of extracting data structures from a sequence of bytes is called deserialization.

User-defined types can support serialization and deserialization by implementing the `Serializable` interface.

## API List

### Functions

| Function Name                                                | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [field\<T>(String, T)](./serialization_package_api/serialization_package_functions.md#func-fieldtstring-t-where-t--serializablet) | Used to encapsulate a set of data `name` and `data` into a `Field` object. |

### Interfaces

| Interface Name                                               | Description                  |
| ------------------------------------------------------------ | ---------------------------- |
| [Serializable](./serialization_package_api/serialization_package_interfaces.md#interface-serializable) | Used to standardize serialization. |

### Classes

| Class Name                                                    | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [DataModel](./serialization_package_api/serialization_package_classes.md/#class-datamodel) | Intermediate data layer.                                     |
| [DataModelBool](./serialization_package_api/serialization_package_classes.md/#class-datamodelbool) | This class is a subclass of `DataModel`, implementing encapsulation for `Bool` type data. |
| [DataModelFloat](./serialization_package_api/serialization_package_classes.md/#class-datamodelfloat) | This class is a subclass of `DataModel`, implementing encapsulation for `Float64` type data. |
| [DataModelInt](./serialization_package_api/serialization_package_classes.md/#class-datamodelint) | This class is a subclass of `DataModel`, implementing encapsulation for `Int64` type data. |
| [DataModelNull](./serialization_package_api/serialization_package_classes.md/#class-datamodelnull) | This class is a subclass of `DataModel`, implementing encapsulation for `Null` type data. |
| [DataModelSeq](./serialization_package_api/serialization_package_classes.md/#class-datamodelseq) | This class is a subclass of `DataModel`, implementing encapsulation for ArrayList\<DataModel> type data. |
| [DataModelString](./serialization_package_api/serialization_package_classes.md/#class-datamodelstring) | This class is a subclass of `DataModel`, implementing encapsulation for `String` type data. |
| [DataModelStruct](./serialization_package_api/serialization_package_classes.md/#class-datamodelstruct) | This class is a subclass of `DataModel`, used to convert `class` objects to `DataModel`. |
| [Field](./serialization_package_api/serialization_package_classes.md/#class-field) | Used to store elements of `DataModelStruct`.                 |

### Exception Classes

| Exception Class Name                                         | Description                  |
| ------------------------------------------------------------ | ---------------------------- |
| [DataModelException](./serialization_package_api/serialization_package_exceptions.md/#class-datamodelexception) | Exception class for `DataModel`. |