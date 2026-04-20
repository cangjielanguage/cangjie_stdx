# stdx.unittest.data

## Feature Description

The unittest.data library provides the capability to supply test data in serialized formats when writing unit test code for Cangjie projects. It currently supports formats such as json/csv/tsv.

For standard testing capabilities, please refer to the standard library API documentation.

## API List

### Functions

|              Function Name          |            Functionality           |
| --------------------------- | ------------------------ |
| [csv\<T>(String, Rune, Rune, Rune, Option\<Rune>, Option\<Array\<String>>, Array\<UInt64>, Array\<UInt64>, Bool)](./data_package_api/data_package_functions.md#func-csvtstring-rune-rune-rune-optionrune-optionarraystring-arrayuint64-arrayuint64-bool-where-t--serializablet) | This function reads data values of type T from a CSV file, where T must be serializable. The return value serves as a parameter source for parameterized testing. |
| [json\<T>(String)](./data_package_api/data_package_functions.md#func-jsontstring-where-t--serializablet) | This function reads data values of type T from a JSON file, where T must be serializable. The return value serves as a parameter source for parameterized testing. |
| [tsv\<T>(String, Rune, Rune, Option\<Rune>, Option\<Array\<String>>, Array\<UInt64>, Array\<UInt64>, Bool)](./data_package_api/data_package_functions.md#func-tsvtstring-rune-rune-optionrune-optionarraystring-arrayuint64-arrayuint64-bool-where-t--serializablet) | This function reads data values of type T from a TSV file, where T must be serializable. The return value serves as a parameter source for parameterized testing. |

### Classes

|              Class Name          |            Functionality           |
| --------------------------- | ------------------------ |
| [CsvStrategy](./data_package_api/data_package_classes.md#class-csvstrategyt) | The serialization implementation of `DataStrategy` for CSV data format. |
| [JsonStrategy](./data_package_api/data_package_classes.md#class-jsonstrategyt) | The serialization implementation of `DataStrategy` for JSON data format. |
| [SerializableProvider](./data_package_api/data_package_classes.md#class-serializableprovidert) | Implementation of the DataProvider interface for obtaining serialized data. |