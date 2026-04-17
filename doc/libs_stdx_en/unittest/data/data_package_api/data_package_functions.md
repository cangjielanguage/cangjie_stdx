# Functions

## func csv\<T>(String, Rune, Rune, Rune, Option\<Rune>, Option\<Array\<String>>, Array\<UInt64>, Array\<UInt64>, Bool) where T <: Serializable\<T>

```cangjie
public func csv<T>(
 fileName: String,
 delimiter!: Rune = ',',
 quoteChar!: Rune = '"',
 escapeChar!: Rune = '"',
 commentChar!: Option<Rune> = None,
 header!: Option<Array<String>> = None,
 skipRows!: Array<UInt64> = [],
 skipColumns!: Array<UInt64> = [],
 skipEmptyLines!: Bool = false
): CsvStrategy<T> where T <: Serializable<T>
```

Function: This function reads data values of type T from a CSV file, where T must be serializable. The return value serves as a parameter source for parameterized testing.

Parameters:

- fileName: String - Path to the CSV file (can be relative), with no extension restrictions.
- delimiter!: Rune - Symbol used as the element separator in a row. Default is `,` (comma).
- quoteChar!: Rune - Symbol enclosing elements. Default is `"` (double quote).
- escapeChar!: Rune - Escape symbol for enclosed elements. Default is `"` (double quote).
- commentChar!: Option\<Rune> - Comment symbol that skips a line. Must appear at the start of a line. Default is `None` (no comment symbol).
- header!: Option\<Array\<String>> - Provides a way to override the first row.
    - When header is specified, the first row of the file is treated as a data row, and the specified header is used.
    - When header is specified and the first row is skipped via `skipRows`, the first row is ignored, and the specified header is used.
    - When header is not specified (i.e., value is `None`), the first row of the file is treated as the header. This is the default behavior.
- skipRows!: Array\<UInt64> - Specifies row numbers to skip (0-based indexing). Default is empty array `[]`.
- skipColumns!: Array\<UInt64> - Specifies column numbers to skip (0-based indexing). When columns are skipped and a custom header is provided, the header will correspond to the remaining columns. Default is empty array `[]`.
- skipEmptyLines!: Bool - Specifies whether to skip empty lines. Default is `false`.

Return Value:

- [CsvStrategy](data_package_classes.md#class-csvstrategyt)\<T> object, where T is serializable, with data values read from the CSV file.

Exceptions:

- IllegalStateException - Thrown if the CSV data structure is incorrect.

## func json\<T>(String) where T <: Serializable\<T>

```cangjie
public func json<T>(fileName: String): JsonStrategy<T> where T <: Serializable<T>
```

Function: This function reads data values of type T from a JSON file, where T must be serializable. The return value serves as a parameter source for parameterized testing.

Parameters:

- fileName: String - Path to the JSON file (can be relative).

Return Value:

- [JsonStrategy](data_package_classes.md#class-jsonstrategyt)\<T> - T is serializable, with data values read from the JSON file.

Example:

```cangjie
@Test[user in json("users.json")]
func test_user_age(user: User): Unit {
    @Expect(user.age, 100)
}
```

JSON file example:

```json
[
    {
        "age": 100
    },
    {
        "age": 100
    }
]
```

Create a class that implements the [Serializable](../../../serialization/serialization_package_api/serialization_package_interfaces.md#interface-serializable) interface to be used as a test function parameter.

<!--compile-->
```cangjie
import stdx.serialization.serialization.*
import std.convert.*

class User <: Serializable<User> {
    User(let age: Int64) {}

    public func serialize(): DataModel {
        DataModelStruct().add(Field("age", DataModelInt(age)))
    }

    public static func deserialize(dm: DataModel): User {
        if (let Some(dms) <- (dm as DataModelStruct)) {
            if (let Some(age) <- (dms.get("age") as DataModelInt)) {
                return User(age.getValue())
            }
        }

        throw Exception("Can't deserialize user.")
    }
}
```

Any type implementing [Serializable](../../../serialization/serialization_package_api/serialization_package_interfaces.md#interface-serializable) can be used as a parameter type, including default values:

```cangjie
@Test[user in json("numbers.json")]
func test(value: Int64)
```

```cangjie
@Test[user in json("names.json")]
func test(name: String)
```

## func tsv\<T>(String, Rune, Rune, Option\<Rune>, Option\<Array\<String>>, Array\<UInt64>, Array\<UInt64>, Bool) where T <: Serializable\<T>

```cangjie
public func tsv<T>(
    fileName: String,
    quoteChar!: Rune = '"',
    escapeChar!: Rune = '"',
    commentChar!: Option<Rune> = None,
    header!: Option<Array<String>> = None,
    skipRows!: Array<UInt64> = [],
    skipColumns!: Array<UInt64> = [],
    skipEmptyLines!: Bool = false
): CsvStrategy<T> where T <: Serializable<T>
```

Function: This function reads data values of type T from a TSV file, where T must be serializable. The return value serves as a parameter source for parameterized testing.

Parameters:

- fileName: String - Path to the TSV file (can be relative), with no extension restrictions.
- quoteChar!: Rune - Symbol enclosing elements. Default is `"` (double quote).
- escapeChar!: Rune - Escape symbol for enclosed elements. Default is `"` (double quote).
- commentChar!: Option\<Rune> - Comment symbol that skips a line. Must appear at the start of a line. Default is `None` (no comment symbol).
- header!: Option\<Array\<String>> - Provides a way to override the first row.
    - When header is specified, the first row of the file is treated as a data row, and the specified header is used.
    - When header is specified and the first row is skipped via `skipRows`, the first row is ignored, and the specified header is used.
    - When header is not specified (i.e., value is `None`), the first row (after skipping) is treated as the header. This is the default behavior.
- skipRows!: Array\<UInt64> - Specifies row numbers to skip (0-based indexing). Default is empty array `[]`.
- skipColumns!: Array\<UInt64> - Specifies column numbers to skip (0-based indexing). When columns are skipped and a custom header is provided, the header will correspond to the remaining columns. Default is empty array `[]`.
- skipEmptyLines!: Bool - Specifies whether to skip empty lines. Default is `false`.

Return Value:

- [CsvStrategy](data_package_classes.md#class-csvstrategyt)\<T> - T is serializable, with data values read from the TSV file.

Exceptions:

- IllegalStateException - Thrown if the TSV data structure is incorrect.

Example:

In unit tests, parameterized testing can be performed by passing CSV/TSV file paths.

Each row of CSV data should be represented as a [Serializable](../../../serialization/serialization_package_api/serialization_package_interfaces.md#interface-serializable)\<T> object, where member names correspond to column headers and member values are [DataModelString](../../../serialization/serialization_package_api/serialization_package_classes.md#class-datamodelstring) types from corresponding columns.

For example, a `testdata.csv` file with the following content:

```csv
username,age
Alex Great,21
Donald Sweet,28
```

There are several ways to serialize this data:

1. Represent the data as HashMap\<String, String> type.

    Example:

    <!--compile-->
    ```cangjie
    import std.collection.HashMap
    import std.unittest.*
    import std.unittest.testmacro.*

    @Test[user in csv("testdata.csv")]
    func testUser(user: HashMap<String, String>) {
        @Assert(user["username"] == "Alex Great" || user["username"] == "Donald Sweet")
        @Assert(user["age"] == "21" || user["age"] == "28")
    }
    ```

2. Represent the data as [Serializable](../../../serialization/serialization_package_api/serialization_package_interfaces.md#interface-serializable)\<T> type, where String data can be deserialized into [DataModelStruct](../../../serialization/serialization_package_api/serialization_package_classes.md#class-datamodelstruct) objects.

Example:

<!--compile-->
```cangjie
import serialization.serialization.*
import std.convert.*
import std.unittest.*
import std.unittest.testmacro.*

public class User <: Serializable<User> {
    public User(let name: String, let age: UInt32) {}

    public func serialize(): DataModel {
        let dms = DataModelStruct()
        dms.add(Field("username", DataModelString(name)))
        dms.add(Field("age", DataModelString(age.toString())))
        return dms
    }

    public static func deserialize(dm: DataModel): User {
        var data: DataModelStruct = match (dm) {
            case dms: DataModelStruct => dms
            case _ => throw DataModelException("this data is not DataModelStruct")
        }

        let name = String.deserialize(data.get("username"))
        let age = String.deserialize(data.get("age"))
        return User(name, UInt32.parse(age))
    }
}

@Test[user in csv("testdata.csv")]
func testUser(user: User) {
   @Assert(user.name == "Alex Great" || user.name == "Donald Sweet")
   @Assert(user.age == 21 || user.age == 28)
}
```