# Classes

## class JsonArray

```cangjie
public class JsonArray <: JsonValue {
    public init()
    public init(list: ArrayList<JsonValue>)
    public init(list: Array<JsonValue>)
}
```

Functionality: This class is a subclass implementation of [JsonValue](encoding_json_package_classes.md#class-jsonvalue), primarily used for encapsulating array-type JSON data.

Parent Type:

- [JsonValue](#class-jsonvalue)

Example:

For usage examples, see [JsonArray Usage Samples](../json_samples/json_array_sample.md).

### init()

```cangjie
public init()
```

Functionality: Creates an empty [JsonArray](encoding_json_package_classes.md#class-jsonarray).

<!--Del_sink-->
### init(this @local!)

```cangjie
public exclave init(this @local!)
```

Function: Creates an empty [JsonArray](encoding_json_package_classes.md#class-jsonarray) instance.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The `@local!` instance being constructed.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    println("size=${ja.size()}")
}
```

Output:

```text
size=0
```
<!--DelEnd_sink-->
### init(Array\<JsonValue>)

```cangjie
public init(list: Array<JsonValue>)
```

Functionality: Encapsulates the specified Array instance into a [JsonArray](encoding_json_package_classes.md#class-jsonarray) instance.

Parameters:

- list: Array\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> - The Array used to create the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

<!--Del_sink-->
### init(this @local!, Array\<JsonValue> @local!)

```cangjie
public exclave init(this @local!, list: Array<JsonValue> @local!)
```

Function: Constructs a [JsonArray](encoding_json_package_classes.md#class-jsonarray) instance from the specified Array.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The `@local!` instance being constructed.
- list: Array\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local! - The `@local!` Array used to create the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    let arr: Array<JsonValue> @local! = [v1, v2]
    let ja: JsonArray @local! = JsonArray(arr) @local!
    let s: String @local! = ja.toString()
    println("ja=${String(s)}")
    println("size=${ja.size()}")
}
```

Output:

```text
ja=[1,2]
size=2
```
<!--DelEnd_sink-->
### init(ArrayList\<JsonValue>)

```cangjie
public init(list: ArrayList<JsonValue>)
```

Functionality: Encapsulates the specified ArrayList instance into a [JsonArray](encoding_json_package_classes.md#class-jsonarray) instance.

Parameters:

- list: ArrayList\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> - The ArrayList used to create the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

<!--Del_sink-->
### init(this @local!, ArrayList\<JsonValue> @local!)

```cangjie
public exclave init(this @local!, list: ArrayList<JsonValue> @local!)
```

Function: Constructs a [JsonArray](encoding_json_package_classes.md#class-jsonarray) instance from the specified ArrayList.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The `@local!` instance being constructed.
- list: ArrayList\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local! - The `@local!` ArrayList used to create the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

main() {
    let list: ArrayList<JsonValue> @local! = ArrayList<JsonValue>() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    list.add(v1)
    list.add(v2)
    let ja: JsonArray @local! = JsonArray(list) @local!
    let s: String @local! = ja.toString()
    println("ja=${String(s)}")
    println("size=${ja.size()}")
}
```

Output:

```text
ja=[1,2]
size=2
```
<!--DelEnd_sink-->
### func add(JsonValue)

```cangjie
public func add(jv: JsonValue): JsonArray
```

Functionality: Adds a [JsonValue](encoding_json_package_classes.md#class-jsonvalue) to the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

Parameters:

- jv: [JsonValue](encoding_json_package_classes.md#class-jsonvalue) - The [JsonValue](encoding_json_package_classes.md#class-jsonvalue) to be added.

Return Value:

- [JsonArray](encoding_json_package_classes.md#class-jsonarray) - The [JsonArray](encoding_json_package_classes.md#class-jsonarray) after adding the data.

<!--Del_sink-->
### func add(JsonValue)

```cangjie
public exclave func add(this @local!, jv: JsonValue @local!): JsonArray @local!
```

Function: Adds [JsonValue](encoding_json_package_classes.md#class-jsonvalue) data to the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.
- jv: [JsonValue](encoding_json_package_classes.md#class-jsonvalue) @local! - The [JsonValue](encoding_json_package_classes.md#class-jsonvalue) data to be added.

Return Value:

- [JsonArray](encoding_json_package_classes.md#class-jsonarray) @local! - The [JsonArray](encoding_json_package_classes.md#class-jsonarray) after adding the data.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    let s: String @local! = ja.toString()
    println("ja=${String(s)}")
    println("size=${ja.size()}")
}
```

Output:

```text
ja=[1,2]
size=2
```
<!--DelEnd_sink-->
### func get(Int64)

```cangjie
public func get(index: Int64): Option<JsonValue>
```

Functionality: Retrieves the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) at the specified index in the [JsonArray](encoding_json_package_classes.md#class-jsonarray), encapsulated in an Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)>.

Parameters:

- index: Int64 - The specified index.

Return Value:

- Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> - The encapsulated [JsonValue](encoding_json_package_classes.md#class-jsonvalue) data at the corresponding index.

<!--Del_sink-->
### func get(Int64)

```cangjie
public exclave func get(this @local!, index: Int64): Option<JsonValue> @local!
```

Function: Gets the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) at the specified index in the [JsonArray](encoding_json_package_classes.md#class-jsonarray), encapsulated in an Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)>.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.
- index: Int64 - The specified index.

Return Value:

- Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local! - The [JsonValue](encoding_json_package_classes.md#class-jsonvalue) at the specified index, encapsulated in an Option.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    match (ja.get(0)) {
        case Some(v) =>
            let sv: String @local! = v.toString()
            println("first=${String(sv)}")
        case None => println("none")
    }
}
```

Output:

```text
first=1
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func get(Int64)

```cangjie
public exclave func get(this @local?, index: Int64): Option<JsonValue> @local?
```

Function: Gets the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) at the specified index in the [JsonArray](encoding_json_package_classes.md#class-jsonarray), encapsulated in an Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)>.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.
- index: Int64 - The specified index.

Return Value:

- Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local? - The [JsonValue](encoding_json_package_classes.md#class-jsonvalue) at the specified index, encapsulated in an Option.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    match (ja.get(1)) {
        case Some(v) =>
            let sv: String @local! = v.toString()
            println("second=${String(sv)}")
        case None => println("none")
    }
}
```

Output:

```text
second=2
```
<!--DelEnd_sink-->
### func getItems()

```cangjie
public func getItems(): ArrayList<JsonValue>
```

Functionality: Retrieves the items data from the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

Return Value:

- ArrayList\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> - The items data of the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

<!--Del_sink-->
### func getItems()

```cangjie
public exclave func getItems(this @local!): ArrayList<JsonValue> @local!
```

Function: Gets the items data from the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- ArrayList\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local! - The items data of the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    let items: ArrayList<JsonValue> @local! = ja.getItems()
    println("size=${items.size}")
}
```

Output:

```text
size=2
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func getItems()

```cangjie
public func getItems(this @local?): ArrayList<JsonValue> @local?
```

Function: Gets the items data from the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- ArrayList\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local? - The items data of the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    let items: ArrayList<JsonValue> @local? = ja.getItems()
    println("size=${items.size}")
}
```

Output:

```text
size=2
```
<!--DelEnd_sink-->
### func kind()

```cangjie
public func kind(): JsonKind
```

Functionality: Returns the [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsArray) to which the current [JsonArray](encoding_json_package_classes.md#class-jsonarray) belongs.

Return Value:

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - The [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsArray) to which the current [JsonArray](encoding_json_package_classes.md#class-jsonarray) belongs.

<!--Del_sink-->
### func kind()

```cangjie
public func kind(this @local?): JsonKind
```

Function: Returns the [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsArray) to which the current [JsonArray](encoding_json_package_classes.md#class-jsonarray) belongs.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - The [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsArray) to which the current `@local?` [JsonArray](encoding_json_package_classes.md#class-jsonarray) belongs.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    match (ja.kind()) {
        case JsonKind.JsArray => println("kind is JsArray")
        case _ => println("kind is not JsArray")
    }
}
```

Output:

```text
kind is JsArray
```
<!--DelEnd_sink-->
### func size()

```cangjie
public func size(): Int64
```

Functionality: Retrieves the number of [JsonValue](encoding_json_package_classes.md#class-jsonvalue) elements in the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

Return Value:

- Int64 - The number of [JsonValue](encoding_json_package_classes.md#class-jsonvalue) elements in the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

<!--Del_sink-->
### func size()

```cangjie
public func size(this @local?): Int64
```

Function: Gets the number of [JsonValue](encoding_json_package_classes.md#class-jsonvalue) elements in the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- Int64 - The number of [JsonValue](encoding_json_package_classes.md#class-jsonvalue) elements in the current [JsonArray](encoding_json_package_classes.md#class-jsonarray).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    println("size=${ja.size()}")
}
```

Output:

```text
size=2
```
<!--DelEnd_sink-->
### func toJsonString()

```cangjie
public func toJsonString(): String
```

Functionality: Converts the [JsonArray](encoding_json_package_classes.md#class-jsonarray) into a JSON-formatted string (with spaces and line breaks).

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toJsonString()

```cangjie
public exclave func toJsonString(this @local!): String @local!
```

Function: Converts the current [JsonArray](encoding_json_package_classes.md#class-jsonarray) into a JSON-formatted string (with spaces and line breaks).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted JSON-formatted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    let s: String @local! = ja.toJsonString()
    println(String(s))
}
```

Output:

```text
[
  1,
  2
]
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toJsonString()

```cangjie
public func toJsonString(this @local?): String
```

Function: Converts the current [JsonArray](encoding_json_package_classes.md#class-jsonarray) into a JSON-formatted string (with spaces and line breaks).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    let s: String = ja.toJsonString()
    println(s)
}
```

Output:

```text
[
  1,
  2
]
```
<!--DelEnd_sink-->
### func toJsonString(Int64, Bool, String)

```cangjie
public func toJsonString(depth: Int64, bracketInNewLine!: Bool = false, indent!: String = "  "): String
```

Functionality: Converts the [JsonArray](encoding_json_package_classes.md#class-jsonarray) into a JSON-formatted string. This function specifies the initial indentation depth, whether to indent before the first bracket, and the indentation string.

Parameters:

- depth: Int64 - The specified indentation depth.
- bracketInNewLine!: Bool - If `true`, prefixes the first bracket with `depth` copies of `indent`. If `false`, adds no indentation before the first bracket. This parameter does not insert a line break.
- indent!: String - The specified indentation string, which can only contain combinations of spaces and tabs. Defaults to two spaces.

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- IllegalArgumentException - Thrown if depth is negative or if indent contains characters other than ' ' and '\t'.
- JsonException - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toJsonString(Int64, Bool, String)

```cangjie
public exclave func toJsonString(this @local!, depth: Int64, bracketInNewLine!: Bool = false, indent!: String @~local = "  "): String @local!
```

Function: Converts the current [JsonArray](encoding_json_package_classes.md#class-jsonarray) into a JSON-formatted string. This function specifies the initial indentation depth, whether to indent the first bracket, and the indentation string.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.
- depth: Int64 - Initial indentation depth and starting JSON write depth. Nested values increase the write depth further.
- bracketInNewLine!: Bool - If `true`, prefixes the first bracket with `depth` copies of `indent`. If `false`, adds no indentation before the first bracket. This parameter does not insert a line break.
- indent!: String @~local - The specified indentation string. The indentation string can only consist of spaces and tabs. Defaults to two spaces.

Return Value:

- String @local! - The converted JSON-formatted string.

Exceptions:

- IllegalArgumentException - Thrown if `depth` is negative or if `indent` contains characters other than ' ' or '\t'.
- JsonException - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    let s: String @local! = ja.toJsonString(1, bracketInNewLine: true, indent: " ")
    println(String(s))
}
```

Output:

```text
 [
  1,
  2
 ]
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toJsonString(Int64, Bool, String)

```cangjie
public func toJsonString(this @local?, depth: Int64, bracketInNewLine!: Bool = false, indent!: String @local? = "  "): String
```

Function: Converts the current [JsonArray](encoding_json_package_classes.md#class-jsonarray) into a JSON-formatted string. This function specifies the initial indentation depth, whether to indent the first bracket, and the indentation string.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.
- depth: Int64 - Initial indentation depth and starting JSON write depth. Nested values increase the write depth further.
- bracketInNewLine!: Bool - If `true`, prefixes the first bracket with `depth` copies of `indent`. If `false`, adds no indentation before the first bracket. This parameter does not insert a line break.
- indent!: String @local? - The specified indentation string. The indentation string can only consist of spaces and tabs. Defaults to two spaces.

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- IllegalArgumentException - Thrown if `depth` is negative or if `indent` contains characters other than ' ' or '\t'.
- JsonException - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    let s: String = ja.toJsonString(1, bracketInNewLine: true, indent: " ")
    println(s)
}
```

Output:

```text
 [
  1,
  2
 ]
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(): String
```

Function: Converts a [JsonArray](encoding_json_package_classes.md#class-jsonarray) into a JSON-formatted string (with spaces and line breaks) without escaping the HTML special character `&` in string values; `&` in object keys is still escaped as `\u0026`.

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public exclave func toJsonStringWithoutEscaping(this @local!): String @local!
```

Function: Converts the current [JsonArray](encoding_json_package_classes.md#class-jsonarray) into a JSON-formatted string (with spaces and line breaks) without escaping the HTML special character `&`.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted JSON-formatted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    let s: String @local! = ja.toJsonStringWithoutEscaping()
    println(String(s))
}
```

Output:

```text
[
  1,
  2
]
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(this @local?): String
```

Function: Converts the current [JsonArray](encoding_json_package_classes.md#class-jsonarray) into a JSON-formatted string (with spaces and line breaks) without escaping the HTML special character `&`.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    let s: String = ja.toJsonStringWithoutEscaping()
    println(s)
}
```

Output:

```text
[
  1,
  2
]
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping(Int64, Bool, String)

```cangjie
public func toJsonStringWithoutEscaping(depth: Int64, bracketInNewLine!: Bool = false, indent!: String = "  "): String
```

Function: Converts a [JsonArray](encoding_json_package_classes.md#class-jsonarray) into a JSON-formatted string. This function specifies the initial indentation depth, whether to indent before the first bracket, and the indentation string, without escaping the HTML special character `&` in string values; `&` in object keys is still escaped as `\u0026`.

Parameters:

- depth: Int64 - The specified indentation depth.
- bracketInNewLine!: Bool - If `true`, prefixes the first bracket with `depth` copies of `indent`. If `false`, adds no indentation before the first bracket. This parameter does not insert a line break.
- indent!: String - The specified indentation string. The indentation string can only contain combinations of spaces and tabs, defaulting to two spaces.

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- IllegalArgumentException - Throws an exception if depth is negative or if indent contains characters other than ' ' and '\t'.
- JsonException - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toJsonStringWithoutEscaping(Int64, Bool, String)

```cangjie
public exclave func toJsonStringWithoutEscaping(this @local!, depth: Int64, bracketInNewLine!: Bool = false, indent!: String @~local = "  "): String @local!
```

Function: Converts the current [JsonArray](encoding_json_package_classes.md#class-jsonarray) into a JSON-formatted string. This function specifies the initial indentation depth, whether to indent the first bracket, and the indentation string, without escaping the HTML special character `&`.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.
- depth: Int64 - Initial indentation depth and starting JSON write depth. Nested values increase the write depth further.
- bracketInNewLine!: Bool - If `true`, prefixes the first bracket with `depth` copies of `indent`. If `false`, adds no indentation before the first bracket. This parameter does not insert a line break.
- indent!: String @~local - The specified indentation string. The indentation string can only consist of spaces and tabs. Defaults to two spaces.

Return Value:

- String @local! - The converted JSON-formatted string.

Exceptions:

- IllegalArgumentException - Thrown if `depth` is negative or if `indent` contains characters other than ' ' or '\t'.
- JsonException - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    let s: String @local! = ja.toJsonStringWithoutEscaping(1, bracketInNewLine: true, indent: " ")
    println(String(s))
}
```

Output:

```text
 [
  1,
  2
 ]
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toJsonStringWithoutEscaping(Int64, Bool, String)

```cangjie
public func toJsonStringWithoutEscaping(this @local?, depth: Int64, bracketInNewLine!: Bool = false, indent!: String @local? = "  "): String
```

Function: Converts the current [JsonArray](encoding_json_package_classes.md#class-jsonarray) into a JSON-formatted string. This function specifies the initial indentation depth, whether to indent the first bracket, and the indentation string, without escaping the HTML special character `&`.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.
- depth: Int64 - Initial indentation depth and starting JSON write depth. Nested values increase the write depth further.
- bracketInNewLine!: Bool - If `true`, prefixes the first bracket with `depth` copies of `indent`. If `false`, adds no indentation before the first bracket. This parameter does not insert a line break.
- indent!: String @local? - The specified indentation string. The indentation string can only consist of spaces and tabs. Defaults to two spaces.

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- IllegalArgumentException - Thrown if `depth` is negative or if `indent` contains characters other than ' ' or '\t'.
- JsonException - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    let s: String = ja.toJsonStringWithoutEscaping(1, bracketInNewLine: true, indent: " ")
    println(s)
}
```

Output:

```text
 [
  1,
  2
 ]
```
<!--DelEnd_sink-->
### func toString()

```cangjie
public func toString(): String
```

Functionality: Converts the [JsonArray](encoding_json_package_classes.md#class-jsonarray) into a string.

Return Value:

- String - The converted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toString()

```cangjie
public exclave func toString(this @local?): String @local!
```

Function: Converts the current [JsonArray](encoding_json_package_classes.md#class-jsonarray) into a string.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- String @local! - The converted `@local!` string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    let s: String @local! = ja.toString()
    println("ja=${String(s)}")
}
```

Output:

```text
ja=[1,2]
```
<!--DelEnd_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(): String
```

Function: Converts a [JsonArray](encoding_json_package_classes.md#class-jsonarray) to a string without escaping the HTML special character `&` in string values; `&` in object keys is still escaped as `\u0026`.

Return Value:

- String - The converted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public exclave func toStringWithoutEscaping(this @local!): String @local!
```

Function: Converts the current [JsonArray](encoding_json_package_classes.md#class-jsonarray) into a string without escaping the HTML special character `&`.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    let s: String @local! = ja.toStringWithoutEscaping()
    println("ja=${String(s)}")
}
```

Output:

```text
ja=[1,2]
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(this @local?): String
```

Function: Converts the current [JsonArray](encoding_json_package_classes.md#class-jsonarray) into a string without escaping the HTML special character `&`.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- String - The converted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    let s: String = ja.toStringWithoutEscaping()
    println("ja=${s}")
}
```

Output:

```text
ja=[1,2]
```
<!--DelEnd_sink-->
### operator func [](Int64)

```cangjie
public operator func [](index: Int64): JsonValue
```

Functionality: Retrieves the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) at the specified index in the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

Parameters:

- index: Int64 - The specified index.

Return Value:

- [JsonValue](encoding_json_package_classes.md#class-jsonvalue) - The [JsonValue](encoding_json_package_classes.md#class-jsonvalue) at the corresponding index.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if the index is not a valid index for the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

<!--Del_sink-->
### operator func \[](Int64)

```cangjie
public exclave operator func [](this @local!, index: Int64): JsonValue @local!
```

Function: Gets the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) at the specified index in the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.
- index: Int64 - The specified index.

Return Value:

- [JsonValue](encoding_json_package_classes.md#class-jsonvalue) @local! - The [JsonValue](encoding_json_package_classes.md#class-jsonvalue) at the specified index.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if the index does not exist in the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(10) @local!
    let v2: JsonValue @local! = JsonInt(20) @local!
    ja.add(v1)
    ja.add(v2)
    let v: JsonValue @local! = ja[0]
    let ji: JsonInt @local! = v.asInt()
    println("first=${ji.getValue()}")
}
```

Output:

```text
first=10
```
<!--DelEnd_sink-->

<!--Del_sink-->
### operator func \[](Int64)

```cangjie
public exclave operator func [](this @local?, index: Int64): JsonValue @local?
```

Function: Gets the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) at the specified index in the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.
- index: Int64 - The specified index.

Return Value:

- [JsonValue](encoding_json_package_classes.md#class-jsonvalue) @local? - The [JsonValue](encoding_json_package_classes.md#class-jsonvalue) at the specified index.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if the index does not exist in the [JsonArray](encoding_json_package_classes.md#class-jsonarray).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeArray(): JsonArray @local? {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    ja
}

main() {
    let ja: JsonArray @local? = makeArray()
    let v: JsonValue @local? = ja[1]
    let s: String @local! = v.toString()
    println("second=${String(s)}")
}
```

Output:

```text
second=2
```
<!--DelEnd_sink-->
## class JsonBool

```cangjie
public class JsonBool <: JsonValue {
    public init(bv: Bool)
}
```

Functionality: This class is a subclass implementation of [JsonValue](encoding_json_package_classes.md#class-jsonvalue), primarily used for encapsulating JSON data representing true or false.

Parent Type:

- [JsonValue](#class-jsonvalue)

### init(Bool)

```cangjie
public init(bv: Bool)
```

Functionality: Encapsulates the specified Bool instance into a [JsonBool](encoding_json_package_classes.md#class-jsonbool) instance.

Parameters:

- bv: Bool - The Bool type.

<!--Del_sink-->
### init(this @local!, Bool)

```cangjie
public exclave init(this @local!, bv: Bool)
```

Function: Encapsulates the specified Bool instance into a [JsonBool](encoding_json_package_classes.md#class-jsonbool) instance.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The `@local!` instance being constructed.
- bv: Bool - The Bool value used to create the [JsonBool](encoding_json_package_classes.md#class-jsonbool).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jb: JsonBool @local! = JsonBool(true) @local!
    println("value=${jb.getValue()}")
}
```

Output:

```text
value=true
```
<!--DelEnd_sink-->
### func getValue()

```cangjie
public func getValue(): Bool
```

Functionality: Retrieves the actual value of the value in [JsonBool](encoding_json_package_classes.md#class-jsonbool).

Return Value:

- Bool - The actual value of the value.

<!--Del_sink-->
### func getValue()

```cangjie
public func getValue(this @local?): Bool
```

Function: Gets the actual value of value in the [JsonBool](encoding_json_package_classes.md#class-jsonbool).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- Bool - The actual value of value.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeBool(): JsonBool @local? {
    let b: JsonBool @local! = JsonBool(true) @local!
    b
}

main() {
    let jb: JsonBool @local? = makeBool()
    println("value=${jb.getValue()}")
}
```

Output:

```text
value=true
```
<!--DelEnd_sink-->
### func kind()

```cangjie
public func kind(): JsonKind
```

Functionality: Returns the [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsBool) to which the current [JsonBool](encoding_json_package_classes.md#class-jsonbool) belongs.

Return Value:

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - The [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsBool) to which the current [JsonBool](encoding_json_package_classes.md#class-jsonbool) belongs.

<!--Del_sink-->
### func kind()

```cangjie
public func kind(this @local?): JsonKind
```

Function: Returns the [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsBool) to which the current [JsonBool](encoding_json_package_classes.md#class-jsonbool) belongs.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - The [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsBool) to which the current `@local?` [JsonBool](encoding_json_package_classes.md#class-jsonbool) belongs.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeBool(): JsonBool @local? {
    let b: JsonBool @local! = JsonBool(true) @local!
    b
}

main() {
    let jb: JsonBool @local? = makeBool()
    match (jb.kind()) {
        case JsonKind.JsBool => println("kind is JsBool")
        case _ => println("kind is not JsBool")
    }
}
```

Output:

```text
kind is JsBool
```
<!--DelEnd_sink-->
### func toJsonString()

```cangjie
public func toJsonString(): String
```

Functionality: Converts the [JsonBool](encoding_json_package_classes.md#class-jsonbool) into a JSON-formatted string (with spaces and line breaks).

Return Value:

- String - The converted JSON-formatted string.

<!--Del_sink-->
### func toJsonString()

```cangjie
public exclave func toJsonString(this @local!): String @local!
```

Function: Converts the current [JsonBool](encoding_json_package_classes.md#class-jsonbool) into a JSON-formatted string (with spaces and line breaks).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted JSON-formatted string.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jb: JsonBool @local! = JsonBool(true) @local!
    let s: String @local! = jb.toJsonString()
    println("s=${String(s)}")
}
```

Output:

```text
s=true
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(): String
```

Function: Equivalent to toJsonString().

Return Value:

- String - The converted JSON-formatted string.

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public exclave func toJsonStringWithoutEscaping(this @local!): String @local!
```

Function: Converts the current [JsonBool](encoding_json_package_classes.md#class-jsonbool) into a JSON-formatted string (with spaces and line breaks).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted JSON-formatted string.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jb: JsonBool @local! = JsonBool(true) @local!
    let s: String @local! = jb.toJsonStringWithoutEscaping()
    println("s=${String(s)}")
}
```

Output:

```text
s=true
```
<!--DelEnd_sink-->
### func toString()

```cangjie
public func toString(): String
```

Functionality: Converts the [JsonBool](encoding_json_package_classes.md#class-jsonbool) into a string.

Return Value:

- String - The converted string.

<!--Del_sink-->
### func toString()

```cangjie
public exclave func toString(this @local?): String @local!
```

Function: Converts the current [JsonBool](encoding_json_package_classes.md#class-jsonbool) into a string.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- String @local! - The converted `@local!` string.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeBool(): JsonBool @local? {
    let b: JsonBool @local! = JsonBool(true) @local!
    b
}

main() {
    let jb: JsonBool @local? = makeBool()
    let s: String @local! = jb.toString()
    println("s=${String(s)}")
}
```

Output:

```text
s=true
```
<!--DelEnd_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(): String
```

Function: Equivalent to toString().

Return Value:

- String - The converted string.

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public exclave func toStringWithoutEscaping(this @local!): String @local!
```

Function: Converts the current [JsonBool](encoding_json_package_classes.md#class-jsonbool) into a string.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted string.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jb: JsonBool @local! = JsonBool(true) @local!
    let s: String @local! = jb.toStringWithoutEscaping()
    println("s=${String(s)}")
}
```

Output:

```text
s=true
```
<!--DelEnd_sink-->
## class JsonFloat

```cangjie
public class JsonFloat <: JsonValue {
    public init(fv: Float64)
    public init(v: Int64)
}
```

Functionality: This class is a subclass implementation of [JsonValue](encoding_json_package_classes.md#class-jsonvalue), primarily used for encapsulating floating-point type JSON data.

Parent Type:

- [JsonValue](#class-jsonvalue)

### init(Float64)

```cangjie
public init(fv: Float64)
```

Functionality: Encapsulates the specified Float64 instance into a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) instance.

Parameters:

- fv: Float64 - The Float64 type.

<!--Del_sink-->
### init(this @local!, Float64)

```cangjie
public exclave init(this @local!, fv: Float64)
```

Function: Encapsulates the specified Float64 instance into a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) instance.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The `@local!` instance being constructed.
- fv: Float64 - The Float64 value used to create the [JsonFloat](encoding_json_package_classes.md#class-jsonfloat).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jf: JsonFloat @local! = JsonFloat(1.5) @local!
    println("value=${jf.getValue()}")
}
```

Output:

```text
value=1.500000
```
<!--DelEnd_sink-->
### init(Int64)

```cangjie
public init(v: Int64)
```

Functionality: Encapsulates the specified Int64 instance into a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) instance.

Parameters:

- v: Int64 - The Int64 type.

<!--Del_sink-->
### init(this @local!, Int64)

```cangjie
public exclave init(this @local!, v: Int64)
```

Function: Encapsulates the specified Int64 instance into a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) instance.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The `@local!` instance being constructed.
- v: Int64 - The Int64 value used to create the [JsonFloat](encoding_json_package_classes.md#class-jsonfloat).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jf: JsonFloat @local! = JsonFloat(42) @local!
    println("value=${jf.getValue()}")
}
```

Output:

```text
value=42.000000
```
<!--DelEnd_sink-->
### func getValue()

```cangjie
public func getValue(): Float64
```

Function: Gets the actual value of the value in [JsonFloat](encoding_json_package_classes.md#class-jsonfloat).

Return Value:

- Float64 - The actual value of the value.

<!--Del_sink-->
### func getValue()

```cangjie
public func getValue(this @local?): Float64
```

Function: Gets the actual value of value in the [JsonFloat](encoding_json_package_classes.md#class-jsonfloat).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- Float64 - The actual value of value.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeFloat(): JsonFloat @local? {
    let f: JsonFloat @local! = JsonFloat(3.5) @local!
    f
}

main() {
    let jf: JsonFloat @local? = makeFloat()
    println("value=${jf.getValue()}")
}
```

Output:

```text
value=3.500000
```
<!--DelEnd_sink-->
### func kind()

```cangjie
public func kind(): JsonKind
```

Function: Returns the [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsFloat) to which the current [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) belongs.

Return Value:

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - The [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsFloat) to which the current [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) belongs.

<!--Del_sink-->
### func kind()

```cangjie
public func kind(this @local?): JsonKind
```

Function: Returns the [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsFloat) to which the current [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) belongs.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - The [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsFloat) to which the current `@local?` [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) belongs.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeFloat(): JsonFloat @local? {
    let f: JsonFloat @local! = JsonFloat(3.5) @local!
    f
}

main() {
    let jf: JsonFloat @local? = makeFloat()
    match (jf.kind()) {
        case JsonKind.JsFloat => println("kind is JsFloat")
        case _ => println("kind is not JsFloat")
    }
}
```

Output:

```text
kind is JsFloat
```
<!--DelEnd_sink-->
### func toJsonString()

```cangjie
public func toJsonString(): String
```

Function: Converts [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) into a JSON-formatted string (with spaces and line breaks).

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the wrapped Float64 value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toJsonString()

```cangjie
public exclave func toJsonString(this @local!): String @local!
```

Function: Converts the current [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) into a JSON-formatted string (with spaces and line breaks).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted JSON-formatted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the wrapped Float64 value is NaN or positive/negative infinity.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jf: JsonFloat @local! = JsonFloat(3.5) @local!
    let s: String @local! = jf.toJsonString()
    println("s=${String(s)}")
}
```

Output:

```text
s=3.500000
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(): String
```

Function: Equivalent to toJsonString().

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the wrapped Float64 value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public exclave func toJsonStringWithoutEscaping(this @local!): String @local!
```

Function: Converts the current [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) into a JSON-formatted string (with spaces and line breaks).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted JSON-formatted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the wrapped Float64 value is NaN or positive/negative infinity.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jf: JsonFloat @local! = JsonFloat(3.5) @local!
    let s: String @local! = jf.toJsonStringWithoutEscaping()
    println("s=${String(s)}")
}
```

Output:

```text
s=3.500000
```
<!--DelEnd_sink-->
### func toString()

```cangjie
public func toString(): String
```

Function: Converts [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) into a string.

Return Value:

- String - The converted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the wrapped Float64 value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toString()

```cangjie
public exclave func toString(this @local?): String @local!
```

Function: Converts the current [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) into a string.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- String @local! - The converted `@local!` string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the wrapped Float64 value is NaN or positive/negative infinity.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeFloat(): JsonFloat @local? {
    let f: JsonFloat @local! = JsonFloat(3.5) @local!
    f
}

main() {
    let jf: JsonFloat @local? = makeFloat()
    let s: String @local! = jf.toString()
    println("s=${String(s)}")
}
```

Output:

```text
s=3.500000
```
<!--DelEnd_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(): String
```

Function: Equivalent to toString().

Return Value:

- String - The converted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the wrapped Float64 value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public exclave func toStringWithoutEscaping(this @local!): String @local!
```

Function: Converts the current [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) into a string.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the wrapped Float64 value is NaN or positive/negative infinity.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jf: JsonFloat @local! = JsonFloat(3.5) @local!
    let s: String @local! = jf.toStringWithoutEscaping()
    println("s=${String(s)}")
}
```

Output:

```text
s=3.500000
```
<!--DelEnd_sink-->
## class JsonInt

```cangjie
public class JsonInt <: JsonValue {
    public init(iv: Int64)
}
```

Function: This class is an implementation subclass of [JsonValue](encoding_json_package_classes.md#class-jsonvalue), primarily used to encapsulate integer-type JSON data.

Parent Type:

- [JsonValue](#class-jsonvalue)

### init(Int64)

```cangjie
public init(iv: Int64)
```

Function: Encapsulates the specified Int64 instance into a [JsonInt](encoding_json_package_classes.md#class-jsonint) instance.

Parameters:

- iv: Int64 - The Int64 used to create [JsonInt](encoding_json_package_classes.md#class-jsonint).

<!--Del_sink-->
### init(this @local!, Int64)

```cangjie
public exclave init(this @local!, iv: Int64)
```

Function: Encapsulates the specified Int64 instance into a [JsonInt](encoding_json_package_classes.md#class-jsonint) instance.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The `@local!` instance being constructed.
- iv: Int64 - The Int64 value used to create the [JsonInt](encoding_json_package_classes.md#class-jsonint).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ji: JsonInt @local! = JsonInt(123) @local!
    println("value=${ji.getValue()}")
}
```

Output:

```text
value=123
```
<!--DelEnd_sink-->
### func getValue()

```cangjie
public func getValue(): Int64
```

Function: Gets the actual value of the value in [JsonInt](encoding_json_package_classes.md#class-jsonint).

Return Value:

- Int64 - The actual value of the value.

<!--Del_sink-->
### func getValue()

```cangjie
public func getValue(this @local?): Int64
```

Function: Gets the actual value of value in the [JsonInt](encoding_json_package_classes.md#class-jsonint).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- Int64 - The actual value of value.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeInt(): JsonInt @local? {
    let i: JsonInt @local! = JsonInt(123) @local!
    i
}

main() {
    let ji: JsonInt @local? = makeInt()
    println("value=${ji.getValue()}")
}
```

Output:

```text
value=123
```
<!--DelEnd_sink-->
### func kind()

```cangjie
public func kind(): JsonKind
```

Function: Returns the [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsInt) to which the current [JsonInt](encoding_json_package_classes.md#class-jsonint) belongs.

Return Value:

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - The [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsInt) to which the current [JsonInt](encoding_json_package_classes.md#class-jsonint) belongs.

<!--Del_sink-->
### func kind()

```cangjie
public func kind(this @local?): JsonKind
```

Function: Returns the [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsInt) to which the current [JsonInt](encoding_json_package_classes.md#class-jsonint) belongs.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - The [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsInt) to which the current `@local?` [JsonInt](encoding_json_package_classes.md#class-jsonint) belongs.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeInt(): JsonInt @local? {
    let i: JsonInt @local! = JsonInt(123) @local!
    i
}

main() {
    let ji: JsonInt @local? = makeInt()
    match (ji.kind()) {
        case JsonKind.JsInt => println("kind is JsInt")
        case _ => println("kind is not JsInt")
    }
}
```

Output:

```text
kind is JsInt
```
<!--DelEnd_sink-->
### func toJsonString()

```cangjie
public func toJsonString(): String
```

Function: Converts [JsonInt](encoding_json_package_classes.md#class-jsonint) into a JSON-formatted string (with spaces and line breaks).

Return Value:

- String - The converted JSON-formatted string.

<!--Del_sink-->
### func toJsonString()

```cangjie
public exclave func toJsonString(this @local!): String @local!
```

Function: Converts the current [JsonInt](encoding_json_package_classes.md#class-jsonint) into a JSON-formatted string (with spaces and line breaks).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted JSON-formatted string.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ji: JsonInt @local! = JsonInt(123) @local!
    let s: String @local! = ji.toJsonString()
    println("s=${String(s)}")
}
```

Output:

```text
s=123
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(): String
```

Function: Equivalent to toJsonString().

Return value:

- String - The converted JSON-formatted string.

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public exclave func toJsonStringWithoutEscaping(this @local!): String @local!
```

Function: Converts the current [JsonInt](encoding_json_package_classes.md#class-jsonint) into a JSON-formatted string (with spaces and line breaks).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted JSON-formatted string.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ji: JsonInt @local! = JsonInt(123) @local!
    let s: String @local! = ji.toJsonStringWithoutEscaping()
    println("s=${String(s)}")
}
```

Output:

```text
s=123
```
<!--DelEnd_sink-->
### func toString()

```cangjie
public func toString(): String
```

Function: Converts [JsonInt](encoding_json_package_classes.md#class-jsonint) into a string.

Return Value:

- String - The converted string.

<!--Del_sink-->
### func toString()

```cangjie
public exclave func toString(this @local?): String @local!
```

Function: Converts the current [JsonInt](encoding_json_package_classes.md#class-jsonint) into a string.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- String @local! - The converted `@local!` string.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeInt(): JsonInt @local? {
    let i: JsonInt @local! = JsonInt(123) @local!
    i
}

main() {
    let ji: JsonInt @local? = makeInt()
    let s: String @local! = ji.toString()
    println("s=${String(s)}")
}
```

Output:

```text
s=123
```
<!--DelEnd_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(): String
```

Function: Equivalent to toString().

Return Value:

- String - The converted string.

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public exclave func toStringWithoutEscaping(this @local!): String @local!
```

Function: Converts the current [JsonInt](encoding_json_package_classes.md#class-jsonint) into a string.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted string.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ji: JsonInt @local! = JsonInt(123) @local!
    let s: String @local! = ji.toStringWithoutEscaping()
    println("s=${String(s)}")
}
```

Output:

```text
s=123
```
<!--DelEnd_sink-->
## class JsonNull

```cangjie
public class JsonNull <: JsonValue
```

Function: This class is an implementation subclass of [JsonValue](encoding_json_package_classes.md#class-jsonvalue), primarily used to encapsulate null JSON data.

Parent Type:

- [JsonValue](#class-jsonvalue)

### func kind()

```cangjie
public func kind(): JsonKind
```

Function: Returns the [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsNull) to which the current [JsonNull](encoding_json_package_classes.md#class-jsonnull) belongs.

Return Value:

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - The [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsNull) to which the current [JsonNull](encoding_json_package_classes.md#class-jsonnull) belongs.

<!--Del_sink-->
### func kind()

```cangjie
public func kind(this @local?): JsonKind
```

Function: Returns the [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsNull) to which the current [JsonNull](encoding_json_package_classes.md#class-jsonnull) belongs.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - The [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsNull) to which the current `@local?` [JsonNull](encoding_json_package_classes.md#class-jsonnull) belongs.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeNull(): JsonNull @local? {
    let n: JsonNull @local! = JsonNull() @local!
    n
}

main() {
    let n: JsonNull @local? = makeNull()
    match (n.kind()) {
        case JsonKind.JsNull => println("kind is JsNull")
        case _ => println("kind is not JsNull")
    }
}
```

Output:

```text
kind is JsNull
```
<!--DelEnd_sink-->
### func toJsonString()

```cangjie
public func toJsonString(): String
```

Function: Converts [JsonNull](encoding_json_package_classes.md#class-jsonnull) into a JSON-formatted string (with spaces and line breaks).

Return Value:

- String - The converted JSON-formatted string.

<!--Del_sink-->
### func toJsonString()

```cangjie
public exclave func toJsonString(this @local!): String @local!
```

Function: Converts the current [JsonNull](encoding_json_package_classes.md#class-jsonnull) into a JSON-formatted string (with spaces and line breaks).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted JSON-formatted string.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let n: JsonNull @local! = JsonNull() @local!
    let s: String @local! = n.toJsonString()
    println("s=${String(s)}")
}
```

Output:

```text
s=null
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(): String
```

Function: Equivalent to toJsonString().

Return value:

- String - The converted JSON-formatted string.

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public exclave func toJsonStringWithoutEscaping(this @local!): String @local!
```

Function: Converts the current [JsonNull](encoding_json_package_classes.md#class-jsonnull) into a JSON-formatted string (with spaces and line breaks).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted JSON-formatted string.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let n: JsonNull @local! = JsonNull() @local!
    let s: String @local! = n.toJsonStringWithoutEscaping()
    println("s=${String(s)}")
}
```

Output:

```text
s=null
```
<!--DelEnd_sink-->
### func toString()

```cangjie
public func toString(): String
```

Function: Converts [JsonNull](encoding_json_package_classes.md#class-jsonnull) into a string.

Return Value:

- String - The converted string.

<!--Del_sink-->
### func toString()

```cangjie
public exclave func toString(this @local?): String @local!
```

Function: Converts the current [JsonNull](encoding_json_package_classes.md#class-jsonnull) into a string.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- String @local! - The converted `@local!` string.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeNull(): JsonNull @local? {
    let n: JsonNull @local! = JsonNull() @local!
    n
}

main() {
    let n: JsonNull @local? = makeNull()
    let s: String @local! = n.toString()
    println("s=${String(s)}")
}
```

Output:

```text
s=null
```
<!--DelEnd_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(): String
```

Function: Equivalent to toString().

Return Value:

- String - The converted string.

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public exclave func toStringWithoutEscaping(this @local!): String @local!
```

Function: Converts the current [JsonNull](encoding_json_package_classes.md#class-jsonnull) into a string.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted string.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let n: JsonNull @local! = JsonNull() @local!
    let s: String @local! = n.toStringWithoutEscaping()
    println("s=${String(s)}")
}
```

Output:

```text
s=null
```
<!--DelEnd_sink-->
## class JsonObject

```cangjie
public class JsonObject <: JsonValue {
    public init()
    public init(map: HashMap<String, JsonValue>)
}
```

Function: This class is an implementation subclass of [JsonValue](encoding_json_package_classes.md#class-jsonvalue), primarily used to encapsulate object-type JSON data.

Parent Type:

- [JsonValue](#class-jsonvalue)

### init()

```cangjie
public init()
```

Function: Creates an empty [JsonObject](encoding_json_package_classes.md#class-jsonobject).

<!--Del_sink-->
### init(this @local!)

```cangjie
public exclave init(this @local!)
```

Function: Creates an empty [JsonObject](encoding_json_package_classes.md#class-jsonobject) instance.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The `@local!` instance being constructed.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    println("size=${jo.size()}")
}
```

Output:

```text
size=0
```
<!--DelEnd_sink-->
### init(HashMap\<String, JsonValue>)

```cangjie
public init(map: HashMap<String, JsonValue>)
```

Function: Encapsulates the specified HashMap instance into a [JsonObject](encoding_json_package_classes.md#class-jsonobject) instance.

Parameters:

- map: HashMap\<String, [JsonValue](encoding_json_package_classes.md#class-jsonvalue)> - data.

<!--Del_sink-->
### init(this @local!, HashMap\<String, JsonValue> @local!)

```cangjie
public exclave init(this @local!, map: HashMap<String, JsonValue> @local!)
```

Function: Constructs a [JsonObject](encoding_json_package_classes.md#class-jsonobject) instance from the specified HashMap.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The `@local!` instance being constructed.
- map: HashMap\<String, [JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local! - The `@local!` HashMap used to create the [JsonObject](encoding_json_package_classes.md#class-jsonobject).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

main() {
    let map: HashMap<String, JsonValue> @local! = HashMap<String, JsonValue>() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    map.add(k, v)
    let jo: JsonObject @local! = JsonObject(map) @local!
    let s: String @local! = jo.toString()
    println("jo=${String(s)}")
    println("size=${jo.size()}")
}
```

Output:

```text
jo={"hello":"world"}
size=1
```
<!--DelEnd_sink-->
### func containsKey(String)

```cangjie
public func containsKey(key: String): Bool
```

Function: Determines whether the key exists in [JsonObject](encoding_json_package_classes.md#class-jsonobject).

Parameters:

- key: String - The specified key.

Return Value:

- Bool - Returns true if the key exists, otherwise false.

<!--Del_sink-->
### func containsKey(String)

```cangjie
public func containsKey(this @local?, key: String @local?): Bool
```

Function: Determines whether the key exists in the [JsonObject](encoding_json_package_classes.md#class-jsonobject).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.
- key: String @local? - The specified key.

Return Value:

- Bool - Returns true if the key exists, otherwise false.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let k: String @local? = "hello"
    println("contains=${jo.containsKey(k)}")
    let missing: String @local? = "foo"
    println("missing=${jo.containsKey(missing)}")
}
```

Output:

```text
contains=true
missing=false
```
<!--DelEnd_sink-->
### func get(String)

```cangjie
public func get(key: String): Option<JsonValue>
```

Function: Gets the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) corresponding to the key in [JsonObject](encoding_json_package_classes.md#class-jsonobject), encapsulated in Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)>.

Parameters:

- key: String - The specified key.

Return Value:

- Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> - The encapsulated form of the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) corresponding to the key.

<!--Del_sink-->
### func get(String)

```cangjie
public exclave func get(this @local!, key: String @local!): Option<JsonValue> @local!
```

Function: Gets the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) corresponding to the key in the [JsonObject](encoding_json_package_classes.md#class-jsonobject), encapsulated in an Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)>.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.
- key: String @local! - The specified key.

Return Value:

- Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local! - The [JsonValue](encoding_json_package_classes.md#class-jsonvalue) corresponding to the key, encapsulated in an Option.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    match (jo.get("hello")) {
        case Some(found) =>
            let sv: String @local! = found.toString()
            println("found=${String(sv)}")
        case None => println("none")
    }
}
```

Output:

```text
found="world"
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func get(String)

```cangjie
public exclave func get(this @local?, key: String @local?): Option<JsonValue> @local?
```

Function: Gets the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) corresponding to the key in the [JsonObject](encoding_json_package_classes.md#class-jsonobject), encapsulated in an Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)>.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.
- key: String @local? - The specified key.

Return Value:

- Option\<[JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local? - The [JsonValue](encoding_json_package_classes.md#class-jsonvalue) corresponding to the key, encapsulated in an Option.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let k: String @local? = "hello"
    match (jo.get(k)) {
        case Some(found) =>
            let sv: String @local! = found.toString()
            println("found=${String(sv)}")
        case None => println("none")
    }
}
```

Output:

```text
found="world"
```
<!--DelEnd_sink-->
### func getFields()

```cangjie
public func getFields(): HashMap<String, JsonValue>
```

Function: Gets the fields data in [JsonObject](encoding_json_package_classes.md#class-jsonobject).

Return Value:

- HashMap\<String, [JsonValue](encoding_json_package_classes.md#class-jsonvalue)> - The fields data of [JsonObject](encoding_json_package_classes.md#class-jsonobject).

<!--Del_sink-->
### func getFields()

```cangjie
public exclave func getFields(this @local!): HashMap<String, JsonValue> @local!
```

Function: Gets the fields data from the [JsonObject](encoding_json_package_classes.md#class-jsonobject).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- HashMap\<String, [JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local! - The fields data of the [JsonObject](encoding_json_package_classes.md#class-jsonobject).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let fields: HashMap<String, JsonValue> @local! = jo.getFields()
    println("size=${jo.size()}")
    println("empty=${fields.isEmpty()}")
}
```

Output:

```text
size=1
empty=false
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func getFields()

```cangjie
public func getFields(this @local?): HashMap<String, JsonValue> @local?
```

Function: Gets the fields data from the [JsonObject](encoding_json_package_classes.md#class-jsonobject).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- HashMap\<String, [JsonValue](encoding_json_package_classes.md#class-jsonvalue)> @local? - The fields data of the [JsonObject](encoding_json_package_classes.md#class-jsonobject).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*
import std.collection.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let fields: HashMap<String, JsonValue> @local? = jo.getFields()
    println("size=${jo.size()}")
    println("empty=${fields.isEmpty()}")
}
```

Output:

```text
size=1
empty=false
```
<!--DelEnd_sink-->
### func kind()

```cangjie
public func kind(): JsonKind
```

Function: Returns the [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsObject) to which the current [JsonObject](encoding_json_package_classes.md#class-jsonobject) belongs.

Return Value:

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - The [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsObject) to which the current [JsonObject](encoding_json_package_classes.md#class-jsonobject) belongs.

<!--Del_sink-->
### func kind()

```cangjie
public func kind(this @local?): JsonKind
```

Function: Returns the [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsObject) to which the current [JsonObject](encoding_json_package_classes.md#class-jsonobject) belongs.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - The [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsObject) to which the current `@local?` [JsonObject](encoding_json_package_classes.md#class-jsonobject) belongs.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    match (jo.kind()) {
        case JsonKind.JsObject => println("kind is JsObject")
        case _ => println("kind is not JsObject")
    }
}
```

Output:

```text
kind is JsObject
```
<!--DelEnd_sink-->
### func put(String, JsonValue)

```cangjie
public func put(key: String, v: JsonValue): Unit
```

Function: Adds key-[JsonValue](encoding_json_package_classes.md#class-jsonvalue) data to [JsonObject](encoding_json_package_classes.md#class-jsonobject).

Parameters:

- key: String - The key to be added.
- v: [JsonValue](encoding_json_package_classes.md#class-jsonvalue) - The [JsonValue](encoding_json_package_classes.md#class-jsonvalue) corresponding to the key.

<!--Del_sink-->
### func put(String, JsonValue)

```cangjie
public exclave func put(this @local!, key: String @local!, v: JsonValue @local!): Unit
```

Function: Adds key-[JsonValue](encoding_json_package_classes.md#class-jsonvalue) data to the [JsonObject](encoding_json_package_classes.md#class-jsonobject).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.
- key: String @local! - The specified key.
- v: [JsonValue](encoding_json_package_classes.md#class-jsonvalue) @local! - The [JsonValue](encoding_json_package_classes.md#class-jsonvalue) data corresponding to the key.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let s: String @local! = jo.toString()
    println("jo=${String(s)}")
}
```

Output:

```text
jo={"hello":"world"}
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func put(String, JsonValue)

```cangjie
public exclave func put(this @local!, key: String @local?, v: JsonValue @local!): Unit
```

Function: Adds key-[JsonValue](encoding_json_package_classes.md#class-jsonvalue) data to the [JsonObject](encoding_json_package_classes.md#class-jsonobject). The key is deep-copied into an owned `String @local!` when stored.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.
- key: String @local? - The specified key.
- v: [JsonValue](encoding_json_package_classes.md#class-jsonvalue) @local! - The [JsonValue](encoding_json_package_classes.md#class-jsonvalue) data corresponding to the key.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local? = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let s: String @local! = jo.toString()
    println("jo=${String(s)}")
}
```

Output:

```text
jo={"hello":"world"}
```
<!--DelEnd_sink-->
### func size()

```cangjie
public func size(): Int64
```

Function: Gets the number of string-[JsonValue](encoding_json_package_classes.md#class-jsonvalue) pairs stored in the fields of [JsonObject](encoding_json_package_classes.md#class-jsonobject).

Return Value:

- Int64 - The size of the fields in [JsonObject](encoding_json_package_classes.md#class-jsonobject).

<!--Del_sink-->
### func size()

```cangjie
public func size(this @local?): Int64
```

Function: Gets the number of string-[JsonValue](encoding_json_package_classes.md#class-jsonvalue) pairs stored in the fields of the [JsonObject](encoding_json_package_classes.md#class-jsonobject).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- Int64 - The size of the fields in the [JsonObject](encoding_json_package_classes.md#class-jsonobject).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    println("size=${jo.size()}")
}
```

Output:

```text
size=1
```
<!--DelEnd_sink-->
### func toJsonString()

```cangjie
public func toJsonString(): String
```

Function: Converts [JsonObject](encoding_json_package_classes.md#class-jsonobject) into a JSON-formatted string (with spaces and line breaks).

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toJsonString()

```cangjie
public exclave func toJsonString(this @local!): String @local!
```

Function: Converts the current [JsonObject](encoding_json_package_classes.md#class-jsonobject) into a JSON-formatted string (with spaces and line breaks).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted JSON-formatted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let s: String @local! = jo.toJsonString()
    println(String(s))
}
```

Output:

```text
{
  "hello": "world"
}
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toJsonString()

```cangjie
public func toJsonString(this @local?): String
```

Function: Converts the current [JsonObject](encoding_json_package_classes.md#class-jsonobject) into a JSON-formatted string (with spaces and line breaks).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let s: String = jo.toJsonString()
    println(s)
}
```

Output:

```text
{
  "hello": "world"
}
```
<!--DelEnd_sink-->
### func toJsonString(Int64, Bool, String)

```cangjie
public func toJsonString(depth: Int64, bracketInNewLine!: Bool = false, indent!: String = "  "): String
```

Function: Converts [JsonObject](encoding_json_package_classes.md#class-jsonobject) into a JSON-formatted string. This function specifies the initial indentation depth, whether to indent before the first bracket, and the indentation string.

Parameters:

- depth: Int64 - Indentation depth.
- bracketInNewLine!: Bool - If `true`, prefixes the first bracket with `depth` copies of `indent`. If `false`, adds no indentation before the first bracket. This parameter does not insert a line break.
- indent!: String - The specified indentation string. The indentation string can only consist of spaces and tabs. Defaults to two spaces.

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- IllegalArgumentException - Thrown if `depth` is negative or if `indent` contains characters other than ' ' or '\t'.
- JsonException - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toJsonString(Int64, Bool, String)

```cangjie
public exclave func toJsonString(this @local!, depth: Int64, bracketInNewLine!: Bool = false, indent!: String @~local = "  "): String @local!
```

Function: Converts the current [JsonObject](encoding_json_package_classes.md#class-jsonobject) into a JSON-formatted string. This function specifies the initial indentation depth, whether to indent the first bracket, and the indentation string.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.
- depth: Int64 - Initial indentation depth and starting JSON write depth. Nested values increase the write depth further.
- bracketInNewLine!: Bool - If `true`, prefixes the first bracket with `depth` copies of `indent`. If `false`, adds no indentation before the first bracket. This parameter does not insert a line break.
- indent!: String @~local - The specified indentation string. The indentation string can only consist of spaces and tabs. Defaults to two spaces.

Return Value:

- String @local! - The converted JSON-formatted string.

Exceptions:

- IllegalArgumentException - Thrown if `depth` is negative or if `indent` contains characters other than ' ' or '\t'.
- JsonException - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let s: String @local! = jo.toJsonString(1, bracketInNewLine: true, indent: " ")
    println(String(s))
}
```

Output:

```text
 {
  "hello": "world"
 }
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toJsonString(Int64, Bool, String)

```cangjie
public func toJsonString(this @local?, depth: Int64, bracketInNewLine!: Bool = false, indent!: String @local? = "  "): String
```

Function: Converts the current [JsonObject](encoding_json_package_classes.md#class-jsonobject) into a JSON-formatted string. This function specifies the initial indentation depth, whether to indent the first bracket, and the indentation string.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.
- depth: Int64 - Initial indentation depth and starting JSON write depth. Nested values increase the write depth further.
- bracketInNewLine!: Bool - If `true`, prefixes the first bracket with `depth` copies of `indent`. If `false`, adds no indentation before the first bracket. This parameter does not insert a line break.
- indent!: String @local? - The specified indentation string. The indentation string can only consist of spaces and tabs. Defaults to two spaces.

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- IllegalArgumentException - Thrown if `depth` is negative or if `indent` contains characters other than ' ' or '\t'.
- JsonException - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let s: String = jo.toJsonString(1, bracketInNewLine: true, indent: " ")
    println(s)
}
```

Output:

```text
 {
  "hello": "world"
 }
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(): String
```

Function: Converts a [JsonObject](encoding_json_package_classes.md#class-jsonobject) into a JSON-formatted string (with spaces and line breaks) without escaping the HTML special character `&` in string values; `&` in object keys is still escaped as `\u0026`.

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public exclave func toJsonStringWithoutEscaping(this @local!): String @local!
```

Function: Converts the current [JsonObject](encoding_json_package_classes.md#class-jsonobject) into a JSON-formatted string (with spaces and line breaks) without escaping the HTML special character `&`.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted JSON-formatted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let s: String @local! = jo.toJsonStringWithoutEscaping()
    println(String(s))
}
```

Output:

```text
{
  "hello": "world"
}
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(this @local?): String
```

Function: Converts the current [JsonObject](encoding_json_package_classes.md#class-jsonobject) into a JSON-formatted string (with spaces and line breaks) without escaping the HTML special character `&`.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let s: String = jo.toJsonStringWithoutEscaping()
    println(s)
}
```

Output:

```text
{
  "hello": "world"
}
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping(Int64, Bool, String)

```cangjie
public func toJsonStringWithoutEscaping(depth: Int64, bracketInNewLine!: Bool = false, indent!: String = "  "): String
```

Function: Converts a [JsonObject](encoding_json_package_classes.md#class-jsonobject) into a JSON-formatted string. This function specifies the initial indentation depth, whether to indent before the first bracket, and the indentation string, without escaping the HTML special character `&` in string values; `&` in object keys is still escaped as `\u0026`.

Parameters:

- depth: Int64 - The indentation depth.
- bracketInNewLine!: Bool - If `true`, prefixes the first bracket with `depth` copies of `indent`. If `false`, adds no indentation before the first bracket. This parameter does not insert a line break.
- indent!: String - The specified indentation string. The indentation string can only consist of combinations of spaces and tabs, defaulting to two spaces.

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- IllegalArgumentException - Throws an exception if the depth is negative or if the indentation string contains characters other than ' ' and '\t'.
- JsonException - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toJsonStringWithoutEscaping(Int64, Bool, String)

```cangjie
public exclave func toJsonStringWithoutEscaping(this @local!, depth: Int64, bracketInNewLine!: Bool = false, indent!: String @~local = "  "): String @local!
```

Function: Converts the current [JsonObject](encoding_json_package_classes.md#class-jsonobject) into a JSON-formatted string. This function specifies the initial indentation depth, whether to indent the first bracket, and the indentation string, without escaping the HTML special character `&`.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.
- depth: Int64 - Initial indentation depth and starting JSON write depth. Nested values increase the write depth further.
- bracketInNewLine!: Bool - If `true`, prefixes the first bracket with `depth` copies of `indent`. If `false`, adds no indentation before the first bracket. This parameter does not insert a line break.
- indent!: String @~local - The specified indentation string. The indentation string can only consist of spaces and tabs. Defaults to two spaces.

Return Value:

- String @local! - The converted JSON-formatted string.

Exceptions:

- IllegalArgumentException - Thrown if `depth` is negative or if `indent` contains characters other than ' ' or '\t'.
- JsonException - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let s: String @local! = jo.toJsonStringWithoutEscaping(1, bracketInNewLine: true, indent: " ")
    println(String(s))
}
```

Output:

```text
 {
  "hello": "world"
 }
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toJsonStringWithoutEscaping(Int64, Bool, String)

```cangjie
public func toJsonStringWithoutEscaping(this @local?, depth: Int64, bracketInNewLine!: Bool = false, indent!: String @local? = "  "): String
```

Function: Converts the current [JsonObject](encoding_json_package_classes.md#class-jsonobject) into a JSON-formatted string. This function specifies the initial indentation depth, whether to indent the first bracket, and the indentation string, without escaping the HTML special character `&`.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.
- depth: Int64 - Initial indentation depth and starting JSON write depth. Nested values increase the write depth further.
- bracketInNewLine!: Bool - If `true`, prefixes the first bracket with `depth` copies of `indent`. If `false`, adds no indentation before the first bracket. This parameter does not insert a line break.
- indent!: String @local? - The specified indentation string. The indentation string can only consist of spaces and tabs. Defaults to two spaces.

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- IllegalArgumentException - Thrown if `depth` is negative or if `indent` contains characters other than ' ' or '\t'.
- JsonException - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let s: String = jo.toJsonStringWithoutEscaping(1, bracketInNewLine: true, indent: " ")
    println(s)
}
```

Output:

```text
 {
  "hello": "world"
 }
```
<!--DelEnd_sink-->
### func toString()

```cangjie
public func toString(): String
```

Function: Converts a [JsonObject](encoding_json_package_classes.md#class-jsonobject) to a string.

Return Value:

- String - The converted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toString()

```cangjie
public exclave func toString(this @local?): String @local!
```

Function: Converts the current [JsonObject](encoding_json_package_classes.md#class-jsonobject) into a string.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- String @local! - The converted `@local!` string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let s: String @local! = jo.toString()
    println("jo=${String(s)}")
}
```

Output:

```text
jo={"hello":"world"}
```
<!--DelEnd_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(): String
```

Function: Converts a [JsonObject](encoding_json_package_classes.md#class-jsonobject) to a string without escaping the HTML special character `&` in string values; `&` in object keys is still escaped as `\u0026`.

Return value:

- String - The converted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the JSON write depth exceeds 100, or the content being serialized contains a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) whose value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public exclave func toStringWithoutEscaping(this @local!): String @local!
```

Function: Converts the current [JsonObject](encoding_json_package_classes.md#class-jsonobject) into a string without escaping the HTML special character `&`.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let s: String @local! = jo.toStringWithoutEscaping()
    println("jo=${String(s)}")
}
```

Output:

```text
jo={"hello":"world"}
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(this @local?): String
```

Function: Converts the current [JsonObject](encoding_json_package_classes.md#class-jsonobject) into a string without escaping the HTML special character `&`.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- String - The converted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let s: String = jo.toStringWithoutEscaping()
    println("jo=${s}")
}
```

Output:

```text
jo={"hello":"world"}
```
<!--DelEnd_sink-->
### operator func [](String)

```cangjie
public operator func [](key: String): JsonValue
```

Function: Retrieves the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) associated with the specified `key` in the [JsonObject](encoding_json_package_classes.md#class-jsonobject).

Parameters:

- key: String - The specified key.

Return Value:

- [JsonValue](encoding_json_package_classes.md#class-jsonvalue) - The [JsonValue](encoding_json_package_classes.md#class-jsonvalue) associated with the `key`.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if the `key` is not a valid key in the [JsonObject](encoding_json_package_classes.md#class-jsonobject).

<!--Del_sink-->
### operator func \[](String)

```cangjie
public exclave operator func [](this @local!, key: String @local!): JsonValue @local!
```

Function: Gets the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) corresponding to the key in the [JsonObject](encoding_json_package_classes.md#class-jsonobject).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.
- key: String @local! - The specified key.

Return Value:

- [JsonValue](encoding_json_package_classes.md#class-jsonvalue) @local! - The [JsonValue](encoding_json_package_classes.md#class-jsonvalue) corresponding to the key.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if the key does not exist in the [JsonObject](encoding_json_package_classes.md#class-jsonobject).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let v2: JsonValue @local! = jo[k]
    let js: JsonString @local! = v2.asString()
    let sv: String @local! = js.getValue()
    println("value=${String(sv)}")
}
```

Output:

```text
value=world
```
<!--DelEnd_sink-->

<!--Del_sink-->
### operator func \[](String)

```cangjie
public exclave operator func [](this @local?, key: String @local?): JsonValue @local?
```

Function: Gets the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) corresponding to the key in the [JsonObject](encoding_json_package_classes.md#class-jsonobject).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.
- key: String @local? - The specified key.

Return Value:

- [JsonValue](encoding_json_package_classes.md#class-jsonvalue) @local? - The [JsonValue](encoding_json_package_classes.md#class-jsonvalue) corresponding to the key.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if the key does not exist in the [JsonObject](encoding_json_package_classes.md#class-jsonobject).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeObject(): JsonObject @local? {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    jo
}

main() {
    let jo: JsonObject @local? = makeObject()
    let k: String @local? = "hello"
    let v: JsonValue @local? = jo[k]
    let s: String @local! = v.toString()
    println("value=${String(s)}")
}
```

Output:

```text
value="world"
```
<!--DelEnd_sink-->
## class JsonString

```cangjie
public class JsonString <: JsonValue {
    public init(sv: String)
}
```

Function: This class is a subclass implementation of [JsonValue](encoding_json_package_classes.md#class-jsonvalue), primarily used to encapsulate string-type JSON data.

Parent Type:

- [JsonValue](#class-jsonvalue)

### init(String)

```cangjie
public init(sv: String)
```

Function: Encapsulates the specified `String` instance into a [JsonString](encoding_json_package_classes.md#class-jsonstring) instance.

Parameters:

- sv: String - The String type.

<!--Del_sink-->
### init(this @local!, String @local!)

```cangjie
public exclave init(this @local!, sv: String @local!)
```

Function: Constructs a [JsonString](encoding_json_package_classes.md#class-jsonstring) instance from the specified string.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The `@local!` instance being constructed.
- sv: String @local! - The `@local!` string used to create the [JsonString](encoding_json_package_classes.md#class-jsonstring).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let s: String @local! = "hello"
    let js: JsonString @local! = JsonString(s) @local!
    let v: String @local! = js.getValue()
    println("value=${String(v)}")
}
```

Output:

```text
value=hello
```
<!--DelEnd_sink-->
### func getValue()

```cangjie
public func getValue(): String
```

Function: Retrieves the actual value of the `value` in the [JsonString](encoding_json_package_classes.md#class-jsonstring).

Return Value:

- String - The actual value of `value`.

<!--Del_sink-->
### func getValue()

```cangjie
public exclave func getValue(this @local!): String @local!
```

Function: Gets the actual value of value in the [JsonString](encoding_json_package_classes.md#class-jsonstring).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The actual value of value.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let s: String @local! = "hello"
    let js: JsonString @local! = JsonString(s) @local!
    let v: String @local! = js.getValue()
    println("value=${String(v)}")
}
```

Output:

```text
value=hello
```
<!--DelEnd_sink-->

<!--Del_sink-->
### func getValue()

```cangjie
public exclave func getValue(this @local?): String @local?
```

Function: Gets the actual value of value in the [JsonString](encoding_json_package_classes.md#class-jsonstring).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- String @local? - The actual value of value.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeStr(): JsonString @local? {
    let s: String @local! = "hello"
    let js: JsonString @local! = JsonString(s) @local!
    js
}

main() {
    let js: JsonString @local? = makeStr()
    let v: String @local? = js.getValue()
    println("value=${String(v)}")
}
```

Output:

```text
value=hello
```
<!--DelEnd_sink-->
### func kind()

```cangjie
public func kind(): JsonKind
```

Function: Returns the [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsString) to which the current [JsonString](encoding_json_package_classes.md#class-jsonstring) belongs.

Return Value:

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - The [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsString) of the current [JsonString](encoding_json_package_classes.md#class-jsonstring).

<!--Del_sink-->
### func kind()

```cangjie
public func kind(this @local?): JsonKind
```

Function: Returns the [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsString) to which the current [JsonString](encoding_json_package_classes.md#class-jsonstring) belongs.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - The [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type (JsString) to which the current `@local?` [JsonString](encoding_json_package_classes.md#class-jsonstring) belongs.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeStr(): JsonString @local? {
    let s: String @local! = "hello"
    let js: JsonString @local! = JsonString(s) @local!
    js
}

main() {
    let js: JsonString @local? = makeStr()
    match (js.kind()) {
        case JsonKind.JsString => println("kind is JsString")
        case _ => println("kind is not JsString")
    }
}
```

Output:

```text
kind is JsString
```
<!--DelEnd_sink-->
### func toJsonString()

```cangjie
public func toJsonString(): String
```

Function: Converts the [JsonString](encoding_json_package_classes.md#class-jsonstring) into a JSON-formatted string (with spaces and line breaks).

Return Value:

- String - The converted JSON-formatted string.

<!--Del_sink-->
### func toJsonString()

```cangjie
public exclave func toJsonString(this @local!): String @local!
```

Function: Converts the current [JsonString](encoding_json_package_classes.md#class-jsonstring) into a JSON-formatted string (with spaces and line breaks).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted JSON-formatted string.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let s: String @local! = "hello"
    let js: JsonString @local! = JsonString(s) @local!
    let r: String @local! = js.toJsonString()
    println("s=${String(r)}")
}
```

Output:

```text
s="hello"
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(): String
```

Function: Converts a [JsonString](encoding_json_package_classes.md#class-jsonstring) into a JSON-formatted string (with spaces and line breaks) without escaping HTML special characters such as `&`.

Return Value:

- String - The converted JSON-formatted string.

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public exclave func toJsonStringWithoutEscaping(this @local!): String @local!
```

Function: Converts the current [JsonString](encoding_json_package_classes.md#class-jsonstring) into a JSON-formatted string (with spaces and line breaks) without escaping the HTML special character `&`.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted JSON-formatted string.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let s: String @local! = "hello"
    let js: JsonString @local! = JsonString(s) @local!
    let r: String @local! = js.toJsonStringWithoutEscaping()
    println("s=${String(r)}")
}
```

Output:

```text
s="hello"
```
<!--DelEnd_sink-->
### func toString()

```cangjie
public func toString(): String
```

Function: Converts the [JsonString](encoding_json_package_classes.md#class-jsonstring) into a string.

Return Value:

- String - The converted string.

<!--Del_sink-->
### func toString()

```cangjie
public exclave func toString(this @local?): String @local!
```

Function: Converts the current [JsonString](encoding_json_package_classes.md#class-jsonstring) into a string.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- String @local! - The converted `@local!` string.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeStr(): JsonString @local? {
    let s: String @local! = "hello"
    let js: JsonString @local! = JsonString(s) @local!
    js
}

main() {
    let js: JsonString @local? = makeStr()
    let s: String @local! = js.toString()
    println("s=${String(s)}")
}
```

Output:

```text
s="hello"
```
<!--DelEnd_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(): String
```

Function: Converts a [JsonString](encoding_json_package_classes.md#class-jsonstring) to a string without escaping HTML special characters, such as `&`.

Return Value:

- String - The converted string.

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public exclave func toStringWithoutEscaping(this @local!): String @local!
```

Function: Converts the current [JsonString](encoding_json_package_classes.md#class-jsonstring) into a string without escaping the HTML special character `&`.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted string.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let s: String @local! = "hello"
    let js: JsonString @local! = JsonString(s) @local!
    let r: String @local! = js.toStringWithoutEscaping()
    println("s=${String(r)}")
}
```

Output:

```text
s="hello"
```
<!--DelEnd_sink-->
## class JsonValue

```cangjie
sealed abstract class JsonValue <: ToString
```

Function: This class serves as the JSON data layer, primarily used for bidirectional conversion between [JsonValue](encoding_json_package_classes.md#class-jsonvalue) and `String` data.

The abstract class [JsonValue](encoding_json_package_classes.md#class-jsonvalue) provides interfaces for converting between `String` and specific JSON types, as well as functionality for determining specific JSON types.

Parent Type:

- ToString

Example:

For usage examples, see [JsonValue and String Conversion](../json_samples/json_value_sample.md).

### static func fromStr(String)

```cangjie
public static func fromStr(s: String): JsonValue
```

Function: Parses string data into a [JsonValue](encoding_json_package_classes.md#class-jsonvalue). For integers, prefixes '0b', '0o', and '0x' (case-insensitive) are supported, representing binary, octal, and hexadecimal, respectively. If parsing a non-empty string fails, the thrown [JsonException](encoding_json_package_exceptions.md#class-jsonexception) message contains the erroneous character, line number, and column number. Column numbers exclude leading ASCII spaces but count tab characters.

When parsing a `String` into a [JsonValue](encoding_json_package_classes.md#class-jsonvalue), the escape character `\` must be followed by a JSON-supported escape character (`b`, `f`, `n`, `r`, `t`, `u`, `\`, `"`, `/`). The format for `\u` is `\uXXXX`, where `X` is a hexadecimal digit (e.g., `\u0041` represents the character 'A').

Parameters:

- s: String - The input string, which must be valid JSON.

Return Value:

- [JsonValue](encoding_json_package_classes.md#class-jsonvalue) - The converted [JsonValue](encoding_json_package_classes.md#class-jsonvalue).

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if string parsing fails or a native buffer allocation fails while parsing a number; Error values thrown by an allocator are not converted to JsonException.

Example:

```cangjie
import stdx.encoding.json.*

main() {
    println(JsonString("\b | \f | \n | \r | \t | A | \\ | \" | /").toString())
    println(JsonValue.fromStr("\"\\b\"").toString())
    println(JsonValue.fromStr("\"\\f\"").toString())
    println(JsonValue.fromStr("\"\\n\"").toString())
    println(JsonValue.fromStr("\"\\r\"").toString())
    println(JsonValue.fromStr("\"\\t\"").toString())
    println(JsonValue.fromStr("\"\\u0041\"").toString())
    println(JsonValue.fromStr("\"\\\\\"").toString())
    println(JsonValue.fromStr("\"\\\"\"").toString())
    println(JsonValue.fromStr("\"\\/\"").toString())
}
```

Output:

```text
"\b | \f | \n | \r | \t | A | \\ | \" | /"
"\b"
"\f"
"\n"
"\r"
"\t"
"A"
"\\"
"\""
"/"
```

<!--Del_sink-->
### static func fromStr(String)

```cangjie
public exclave static func fromStr(s: String @local!): JsonValue @local!
```

Function: Parses string data into a [JsonValue](encoding_json_package_classes.md#class-jsonvalue).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- s: String @local! - The input string.

Return Value:

- [JsonValue](encoding_json_package_classes.md#class-jsonvalue) @local! - The parsed [JsonValue](encoding_json_package_classes.md#class-jsonvalue).

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if string parsing fails or a native buffer allocation fails while parsing a number; Error values thrown by an allocator are not converted to JsonException.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let s: String @local! = ##"[1, 2, 3]"##
    let v: JsonValue @local! = JsonValue.fromStr(s)
    let a: JsonArray @local! = v.asArray()
    println("size=${a.size()}")
}
```

Output:

```text
size=3
```
<!--DelEnd_sink-->

<!--Del_sink-->
### static func fromStr(String)

```cangjie
public exclave static func fromStr(s: String @local?): JsonValue @local!
```

Function: Parses string data into a [JsonValue](encoding_json_package_classes.md#class-jsonvalue). The string is first deep-copied into a `@local!` string before parsing.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- s: String @local? - The input string.

Return Value:

- [JsonValue](encoding_json_package_classes.md#class-jsonvalue) @local! - The parsed [JsonValue](encoding_json_package_classes.md#class-jsonvalue).

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if string parsing fails or a native buffer allocation fails while parsing a number; Error values thrown by an allocator are not converted to JsonException.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeStr(): String @local? {
    let s: String @local! = ##"123"##
    s
}

main() {
    let s: String @local? = makeStr()
    let v: JsonValue @local! = JsonValue.fromStr(s)
    let ji: JsonInt @local! = v.asInt()
    println("value=${ji.getValue()}")
}
```

Output:

```text
value=123
```
<!--DelEnd_sink-->
### func asArray()

```cangjie
public func asArray(): JsonArray
```

Function: Converts the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a [JsonArray](encoding_json_package_classes.md#class-jsonarray).

Return Value:

- [JsonArray](encoding_json_package_classes.md#class-jsonarray) - The converted [JsonArray](encoding_json_package_classes.md#class-jsonarray).

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

<!--Del_sink-->
### func asArray()

```cangjie
public exclave func asArray(this @local!): JsonArray @local!
```

Function: Converts the current [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a [JsonArray](encoding_json_package_classes.md#class-jsonarray).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- [JsonArray](encoding_json_package_classes.md#class-jsonarray) @local! - The converted [JsonArray](encoding_json_package_classes.md#class-jsonarray).

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let ja: JsonArray @local! = JsonArray() @local!
    let v1: JsonValue @local! = JsonInt(1) @local!
    let v2: JsonValue @local! = JsonInt(2) @local!
    ja.add(v1)
    ja.add(v2)
    let v: JsonValue @local! = ja
    let a: JsonArray @local! = v.asArray()
    println("size=${a.size()}")
}
```

Output:

```text
size=2
```
<!--DelEnd_sink-->
### func asBool()

```cangjie
public func asBool(): JsonBool
```

Function: Converts the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a [JsonBool](encoding_json_package_classes.md#class-jsonbool).

Return Value:

- [JsonBool](encoding_json_package_classes.md#class-jsonbool) - The converted [JsonBool](encoding_json_package_classes.md#class-jsonbool).

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

<!--Del_sink-->
### func asBool()

```cangjie
public exclave func asBool(this @local!): JsonBool @local!
```

Function: Converts the current [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a [JsonBool](encoding_json_package_classes.md#class-jsonbool).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- [JsonBool](encoding_json_package_classes.md#class-jsonbool) @local! - The converted [JsonBool](encoding_json_package_classes.md#class-jsonbool).

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let v: JsonValue @local! = JsonBool(true) @local!
    let jb: JsonBool @local! = v.asBool()
    println("value=${jb.getValue()}")
}
```

Output:

```text
value=true
```
<!--DelEnd_sink-->
### func asFloat()

```cangjie
public func asFloat(): JsonFloat
```

Function: Converts the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat).

Return Value:

- [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) - The converted [JsonFloat](encoding_json_package_classes.md#class-jsonfloat).

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

<!--Del_sink-->
### func asFloat()

```cangjie
public exclave func asFloat(this @local!): JsonFloat @local!
```

Function: Converts the current [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat). If the current object is a [JsonInt](encoding_json_package_classes.md#class-jsonint), the [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) is constructed from its integer value.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) @local! - The converted [JsonFloat](encoding_json_package_classes.md#class-jsonfloat).

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let v: JsonValue @local! = JsonInt(42) @local!
    let jf: JsonFloat @local! = v.asFloat()
    println("value=${jf.getValue()}")
}
```

Output:

```text
value=42.000000
```
<!--DelEnd_sink-->
### func asInt()

```cangjie
public func asInt(): JsonInt
```

Function: Converts the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a [JsonInt](encoding_json_package_classes.md#class-jsonint).

Return Value:

- [JsonInt](encoding_json_package_classes.md#class-jsonint) - The converted [JsonInt](encoding_json_package_classes.md#class-jsonint).

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

<!--Del_sink-->
### func asInt()

```cangjie
public exclave func asInt(this @local!): JsonInt @local!
```

Function: Converts the current [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a [JsonInt](encoding_json_package_classes.md#class-jsonint).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- [JsonInt](encoding_json_package_classes.md#class-jsonint) @local! - The converted [JsonInt](encoding_json_package_classes.md#class-jsonint).

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let v: JsonValue @local! = JsonInt(123) @local!
    let ji: JsonInt @local! = v.asInt()
    println("value=${ji.getValue()}")
}
```

Output:

```text
value=123
```
<!--DelEnd_sink-->
### func asNull()

```cangjie
public func asNull(): JsonNull
```

Function: Converts the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a [JsonNull](encoding_json_package_classes.md#class-jsonnull).

Return Value:

- [JsonNull](encoding_json_package_classes.md#class-jsonnull) - The converted [JsonNull](encoding_json_package_classes.md#class-jsonnull).

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

<!--Del_sink-->
### func asNull()

```cangjie
public exclave func asNull(this @local!): JsonNull @local!
```

Function: Converts the current [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a [JsonNull](encoding_json_package_classes.md#class-jsonnull).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- [JsonNull](encoding_json_package_classes.md#class-jsonnull) @local! - The converted [JsonNull](encoding_json_package_classes.md#class-jsonnull).

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let v: JsonValue @local! = JsonNull() @local!
    let n: JsonNull @local! = v.asNull()
    let s: String @local! = n.toString()
    println("n=${String(s)}")
}
```

Output:

```text
n=null
```
<!--DelEnd_sink-->
### func asObject()

```cangjie
public func asObject(): JsonObject
```

Function: Converts the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a [JsonObject](encoding_json_package_classes.md#class-jsonobject).

Return Value:

- [JsonObject](encoding_json_package_classes.md#class-jsonobject) - The converted [JsonObject](encoding_json_package_classes.md#class-jsonobject).

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

<!--Del_sink-->
### func asObject()

```cangjie
public exclave func asObject(this @local!): JsonObject @local!
```

Function: Converts the current [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a [JsonObject](encoding_json_package_classes.md#class-jsonobject).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- [JsonObject](encoding_json_package_classes.md#class-jsonobject) @local! - The converted [JsonObject](encoding_json_package_classes.md#class-jsonobject).

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let jo: JsonObject @local! = JsonObject() @local!
    let k: String @local! = "hello"
    let v: JsonValue @local! = JsonString("world") @local!
    jo.put(k, v)
    let v2: JsonValue @local! = jo
    let o: JsonObject @local! = v2.asObject()
    println("size=${o.size()}")
}
```

Output:

```text
size=1
```
<!--DelEnd_sink-->
### func asString()

```cangjie
public func asString(): JsonString
```

Function: Converts the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a [JsonString](encoding_json_package_classes.md#class-jsonstring).

Return Value:

- [JsonString](encoding_json_package_classes.md#class-jsonstring) - The converted [JsonString](encoding_json_package_classes.md#class-jsonstring).

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

<!--Del_sink-->
### func asString()

```cangjie
public exclave func asString(this @local!): JsonString @local!
```

Function: Converts the current [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a [JsonString](encoding_json_package_classes.md#class-jsonstring).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- [JsonString](encoding_json_package_classes.md#class-jsonstring) @local! - The converted [JsonString](encoding_json_package_classes.md#class-jsonstring).

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown if conversion fails.

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let s: String @local! = "hello"
    let v: JsonValue @local! = JsonString(s) @local!
    let js: JsonString @local! = v.asString()
    let sv: String @local! = js.getValue()
    println("value=${String(sv)}")
}
```

Output:

```text
value=hello
```
<!--DelEnd_sink-->
### func kind()

```cangjie
public func kind(): JsonKind
```

Function: Returns the [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type of the current [JsonValue](encoding_json_package_classes.md#class-jsonvalue).

Return Value:

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - The [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type of the current [JsonValue](encoding_json_package_classes.md#class-jsonvalue).

<!--Del_sink-->
### func kind()

```cangjie
public open func kind(this @local?): JsonKind
```

Function: Returns the [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type to which the current [JsonValue](encoding_json_package_classes.md#class-jsonvalue) belongs.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- [JsonKind](encoding_json_package_enums.md#enum-jsonkind) - The [JsonKind](encoding_json_package_enums.md#enum-jsonkind) type to which the current `@local?` [JsonValue](encoding_json_package_classes.md#class-jsonvalue) belongs.

Exceptions:

- UnimplementedException - Thrown if the call is bound to the default [JsonValue](encoding_json_package_classes.md#class-jsonvalue) implementation (the concrete subclass does not override the local version of this method).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeValue(): JsonValue @local? {
    let v: JsonValue @local! = JsonInt(123) @local!
    v
}

main() {
    let v: JsonValue @local? = makeValue()
    match (v.kind()) {
        case JsonKind.JsInt => println("kind is JsInt")
        case _ => println("kind is not JsInt")
    }
}
```

Output:

```text
kind is JsInt
```
<!--DelEnd_sink-->
### func toJsonString()

```cangjie
public func toJsonString(): String
```

Function: Converts the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a JSON-formatted string (with spaces and line breaks).

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the serialization implemented by the concrete subclass fails, for example when the JSON write depth exceeds 100 or a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toJsonString()

```cangjie
public open func toJsonString(this @local!): String @local!
```

Function: Converts the current [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a JSON-formatted string (with spaces and line breaks).

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted JSON-formatted string.

Exceptions:

- JsonException - Thrown when the serialization implemented by the concrete subclass fails, for example when the JSON write depth exceeds 100 or a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) value is NaN or positive/negative infinity.
- UnimplementedException - Thrown if the call is bound to the default [JsonValue](encoding_json_package_classes.md#class-jsonvalue) implementation (the concrete subclass does not override the local version of this method).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let v: JsonValue @local! = JsonInt(123) @local!
    let s: String @local! = v.toJsonString()
    println("s=${String(s)}")
}
```

Output:

```text
s=123
```
<!--DelEnd_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public func toJsonStringWithoutEscaping(): String
```

Function: Converts a [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a JSON-formatted string (with spaces and line breaks) without escaping the HTML special character `&` in string values; `&` in object keys is still escaped as `\u0026`.

Return Value:

- String - The converted JSON-formatted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the serialization implemented by the concrete subclass fails, for example when the JSON write depth exceeds 100 or a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toJsonStringWithoutEscaping()

```cangjie
public open func toJsonStringWithoutEscaping(this @local!): String @local!
```

Function: Converts the current [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a JSON-formatted string (with spaces and line breaks) without escaping the HTML special character `&`.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted JSON-formatted string.

Exceptions:

- JsonException - Thrown when the serialization implemented by the concrete subclass fails, for example when the JSON write depth exceeds 100 or a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) value is NaN or positive/negative infinity.
- UnimplementedException - Thrown if the call is bound to the default [JsonValue](encoding_json_package_classes.md#class-jsonvalue) implementation (the concrete subclass does not override the local version of this method).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let v: JsonValue @local! = JsonInt(123) @local!
    let s: String @local! = v.toJsonStringWithoutEscaping()
    println("s=${String(s)}")
}
```

Output:

```text
s=123
```
<!--DelEnd_sink-->
### func toString()

```cangjie
public func toString(): String
```

Function: Converts the [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a string.

Return Value:

- String - The converted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the serialization implemented by the concrete subclass fails, for example when the JSON write depth exceeds 100 or a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toString()

```cangjie
public open func toString(this @local?): String @local!
```

Function: Converts the current [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a string.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local? - The current `@local?` instance on which the method is called.

Return Value:

- String @local! - The converted `@local!` string.

Exceptions:

- JsonException - Thrown when the serialization implemented by the concrete subclass fails, for example when the JSON write depth exceeds 100 or a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) value is NaN or positive/negative infinity.
- UnimplementedException - Thrown if the call is bound to the default [JsonValue](encoding_json_package_classes.md#class-jsonvalue) implementation (the concrete subclass does not override the local version of this method).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

exclave func makeValue(): JsonValue @local? {
    let v: JsonValue @local! = JsonInt(123) @local!
    v
}

main() {
    let v: JsonValue @local? = makeValue()
    let s: String @local! = v.toString()
    println("s=${String(s)}")
}
```

Output:

```text
s=123
```
<!--DelEnd_sink-->
### func toStringWithoutEscaping()

```cangjie
public func toStringWithoutEscaping(): String
```

Function: Converts [JsonValue](encoding_json_package_classes.md#class-jsonvalue) to a string without escaping the HTML special character `&` in string values; `&` in object keys is still escaped as `\u0026`.

Return Value:

- String - The converted string.

Exceptions:

- [JsonException](encoding_json_package_exceptions.md#class-jsonexception) - Thrown when the serialization implemented by the concrete subclass fails, for example when the JSON write depth exceeds 100 or a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) value is NaN or positive/negative infinity.

<!--Del_sink-->
### func toStringWithoutEscaping()

```cangjie
public open func toStringWithoutEscaping(this @local!): String @local!
```

Function: Converts the current [JsonValue](encoding_json_package_classes.md#class-jsonvalue) into a string without escaping the HTML special character `&`.

> **Note:**
>
> - Experimental API, for test verification only; the specification and implementation may still change; use with caution.
> - Platform not supported: OpenHarmony.

Parameters:

- this @local! - The current `@local!` instance on which the method is called.

Return Value:

- String @local! - The converted string.

Exceptions:

- JsonException - Thrown when the serialization implemented by the concrete subclass fails, for example when the JSON write depth exceeds 100 or a [JsonFloat](encoding_json_package_classes.md#class-jsonfloat) value is NaN or positive/negative infinity.
- UnimplementedException - Thrown if the call is bound to the default [JsonValue](encoding_json_package_classes.md#class-jsonvalue) implementation (the concrete subclass does not override the local version of this method).

Example:

<!-- verify -->
```cangjie
import stdx.encoding.json.*

main() {
    let v: JsonValue @local! = JsonInt(123) @local!
    let s: String @local! = v.toStringWithoutEscaping()
    println("s=${String(s)}")
}
```

Output:

```text
s=123
```
<!--DelEnd_sink-->
