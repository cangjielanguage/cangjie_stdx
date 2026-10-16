# stdx.encoding.json

## 功能介绍

json 包用于对 JSON 数据的处理，实现 String, JsonValue, DataModel 之间的相互转换。

JsonValue 是对 JSON 数据格式的封装，包括 object, array, string, number, true, false 和 null。

DataModel 详细信息可参考：[serialization 包文档](../../serialization/serialization_package_api/serialization_package_classes.md#class-datamodel)。

JSON 语法规则可参考：[介绍 JSON](https://www.json.org/json-zh.html)。

JSON 数据转换标准可参考：[ECMA-404 The JSON Data Interchange Standard](https://www.ecma-international.org/publications-and-standards/standards/ecma-404/)。

## API 列表

### 接口

| 接口名  | 功能  |
| ------------ | ------------ |
| [ToJson](./json_package_api/encoding_json_package_interfaces.md#interface-tojson) | 用于实现 JsonValue 和 DataModel 的相互转换。 |

### 类

|  类名 | 功能  |
| ------------ | ------------ |
| [JsonArray](./json_package_api/encoding_json_package_classes.md#class-jsonarray) | 用于封装数组类型的 JSON 数据。 |
| [JsonBool](./json_package_api/encoding_json_package_classes.md#class-jsonbool) | 用于封装 true 或者 false 的 JSON 数据。 |
| [JsonFloat](./json_package_api/encoding_json_package_classes.md#class-jsonfloat) | 用于封装浮点类型的 JSON 数据。 |
| [JsonInt](./json_package_api/encoding_json_package_classes.md#class-jsonint) | 用于封装整数类型的 JSON 数据。 |
| [JsonNull](./json_package_api/encoding_json_package_classes.md#class-jsonnull) | 用于封装 null 的 JSON 数据。 |
| [JsonObject](./json_package_api/encoding_json_package_classes.md#class-jsonobject) | 用于封装 object 类型的 JSON 数据。 |
| [JsonString](./json_package_api/encoding_json_package_classes.md#class-jsonstring) | 用于封装字符串类型的 JSON 数据。 |
| [JsonValue](./json_package_api/encoding_json_package_classes.md#class-jsonvalue) | 此类为 JSON 数据层，主要用于 JsonValue 和 String 数据之间的互相转换。 |

### 枚举

|  枚举名 | 功能  |
| ------------ | ------------ |
| [JsonKind](./json_package_api/encoding_json_package_enums.md#enum-jsonkind) | 表示 JsonValue 的具体类型。 |

### 异常类

| 异常类名  | 功能  |
| ------------ | ------------ |
|[JsonException](./json_package_api/encoding_json_package_exceptions.md#class-jsonexception)| 用于 JsonValue 类型使用时出现异常的场景。 |
