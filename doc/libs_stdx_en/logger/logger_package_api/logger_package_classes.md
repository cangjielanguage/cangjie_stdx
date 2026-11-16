# Classes

## class JsonLogger

```cangjie
public class JsonLogger <: Logger {
    public init(output: OutputStream)
}
```

Functionality: This class implements JSON-formatted log output, with entries like `{"time":"2024-07-27T11:51:59+08:00","level":"INFO","msg":"foo","name":"bar"}`.

Parent Type:

- [Logger](../../log/log_package_api/log_package_classes.md#class-logger)

### init(OutputStream)

```cangjie
public init(output: OutputStream)
```

Functionality: Creates a [JsonLogger](logger_package_classes.md#class-jsonlogger) object.

Parameters:

- output: OutputStream - The bound output stream where formatted logs will be written.

### prop level

```cangjie
public mut prop level: LogLevel
```

Functionality: Gets and sets the log level.

Type: [LogLevel](../../log/log_package_api/log_package_structs.md#struct-loglevel)

### func close()

```cangjie
public func close(): Unit
```

Functionality: Closes the Logger.

### func isClosed()

```cangjie
public func isClosed(): Bool
```

Functionality: Checks whether the Logger is closed.

Return Value:

- Bool - Whether it's closed.

### func log(LogRecord)

```cangjie
public func log(record: LogRecord): Unit
```

Functionality: General logging function.

Parameters:

- record: [LogRecord](../../log/log_package_api/log_package_classes.md#class-logrecord) - The log level.

### func withAttrs(Array\<Attr>)

```cangjie
public func withAttrs(attrs: Array<Attr>): Logger
```

Functionality: Creates a copy of the current object with specified attributes.

Parameters:

- attrs: Array\<[Attr](../../log/log_package_api/log_package_types.md#type-attr)> - Key-value pair attributes for log data.

Return Value:

- [Logger](../../log/log_package_api/#class-logger) - An instance of the [Logger](../../log/log_package_api/#class-logger) class.

## class SimpleLogger

```cangjie
public class SimpleLogger <: Logger {
    public init(output: OutputStream)
}
```

Functionality: This class implements text-formatted log output, with entries like `2024-07-27T11:50:47.6616733+08:00 INFO foo name="bar"`.

Parent Type:

- [Logger](../../log/log_package_api/log_package_classes.md#class-logger)

### init(OutputStream)

```cangjie
public init(output: OutputStream)
```

Functionality: Creates a [SimpleLogger](logger_package_classes.md#class-simplelogger) object.

Parameters:

- output: OutputStream - The bound output stream where formatted logs will be written.

### prop level

```cangjie
public mut prop level: LogLevel
```

Functionality: Gets and sets the log level.

Type: [LogLevel](../../log/log_package_api/log_package_structs.md#struct-loglevel)

### func close()

```cangjie
public func close(): Unit
```

Functionality: Closes the Logger.

### func isClosed()

```cangjie
public func isClosed(): Bool
```

Functionality: Checks whether the Logger is closed.

Return Value:

- Bool - Whether it's closed.

### func log(LogRecord)

```cangjie
public func log(record: LogRecord): Unit
```

Functionality: General logging function.

Parameters:

- record: [LogRecord](../../log/log_package_api/log_package_classes.md#class-logrecord) - The log level.

### func withAttrs(Array\<Attr>)

```cangjie
public func withAttrs(attrs: Array<Attr>): Logger
```

Functionality: Creates a copy of the current object with specified attributes.

Parameters:

- attrs: Array\<[Attr](../../log/log_package_api/log_package_types.md#type-attr)> - Key-value pair attributes for log data.

Return Value:

- [Logger](../../log/log_package_api/#class-logger) - An instance of the [Logger](../../log/log_package_api/#class-logger) class.

## class TextLogger

```cangjie
public class TextLogger <: Logger {
    public init(output: OutputStream)
}
```

Functionality: This class implements text-formatted log output, with entries like `time=2024-07-27T11:52:40.3226881+08:00 level="INFO" msg="foo" name="bar"`.

Parent Type:

- [Logger](../../log/log_package_api/log_package_classes.md#class-logger)

### init(OutputStream)

```cangjie
public init(output: OutputStream)
```

Functionality: Creates a [TextLogger](logger_package_classes.md#class-textlogger) object.

Parameters:

- output: OutputStream - The bound output stream where formatted logs will be written.

### prop level

```cangjie
public mut prop level: LogLevel
```

Functionality: Gets and sets the log level.

Type: [LogLevel](../../log/log_package_api/log_package_structs.md#struct-loglevel)

### func close()

```cangjie
public func close(): Unit
```

Functionality: Closes the Logger.

### func isClosed()

```cangjie
public func isClosed(): Bool
```

Functionality: Checks whether the Logger is closed.

Return Value:

- Bool - Whether it's closed.

### func log(LogRecord)

```cangjie
public func log(record: LogRecord): Unit
```

Functionality: General logging function.

Parameters:

- record: [LogRecord](../../log/log_package_api/log_package_classes.md#class-logrecord) - The log level.

### func withAttrs(Array\<Attr>)

```cangjie
public func withAttrs(attrs: Array<Attr>): Logger
```

Functionality: Creates a copy of the current object with specified attributes.

Parameters:

- attrs: Array\<[Attr](../../log/log_package_api/log_package_types.md#type-attr)> - Key-value pair attributes for log data.

Return Value:

- [Logger](../../log/log_package_api/#class-logger) - An instance of the [Logger](../../log/log_package_api/#class-logger) class.