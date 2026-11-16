# Class

## class Logger

```cangjie
public abstract class Logger <: Resource {
}
```

Functionality: This abstract class provides basic logging and log management capabilities.

Parent Type:

- Resource

### prop level

```cangjie
public open mut prop level: LogLevel
```

Functionality: Gets and modifies the log level.

Type: [LogLevel](log_package_structs.md#struct-loglevel)

### func debug(String, Array\<Attr>)

```cangjie
public func debug(message: String, attrs: Array<Attr>): Unit
```

Functionality: Convenience function for logging at [DEBUG](log_package_structs.md#static-const-debug) level.

Parameters:

- message: String - The log message.
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Key-value pairs of log data.

### func debug(() -> String, Array\<Attr>)

```cangjie
public func debug(message: () -> String, attrs: Array<Attr>): Unit
```

Functionality: Convenience function for logging at [DEBUG](log_package_structs.md#static-const-debug) level.

Parameters:

- message: () -> String - The log message.
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Key-value pairs of log data.

### func enabled(LogLevel)

```cangjie
public func enabled(level: LogLevel): Bool
```

Functionality: Determines whether log messages at the specified level will be recorded.

This function allows callers to check in advance whether logs will be discarded to avoid costly computation of log message parameters.

Parameters:

- level: [LogLevel](log_package_structs.md#struct-loglevel) - The log level.

Return Value:

- Bool - Returns `true` if the specified log level is enabled; otherwise, returns `false`.

### func error(String, Array\<Attr>)

```cangjie
public func error(message: String, attrs: Array<Attr>): Unit
```

Functionality: Convenience function for logging at [ERROR](log_package_structs.md#static-const-error) level.

Parameters:

- message: String - The log message.
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Key-value pairs of log data.

### func error(() -> String, Array\<Attr>)

```cangjie
public func error(message: () -> String, attrs: Array<Attr>): Unit
```

Functionality: Convenience function for logging at [ERROR](log_package_structs.md#static-const-error) level.

Parameters:

- message: () -> String - The log message.
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Key-value pairs of log data.

### func fatal(String, Array\<Attr>)

```cangjie
public func fatal(message: String, attrs: Array<Attr>): Unit
```

Functionality: Convenience function for logging at [FATAL](log_package_structs.md#static-const-fatal) level.

Parameters:

- message: String - The log message.
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Key-value pairs of log data.

### func fatal(() -> String, Array\<Attr>)

```cangjie
public func fatal(message: () -> String, attrs: Array<Attr>): Unit
```

Functionality: Convenience function for logging at [FATAL](log_package_structs.md#static-const-fatal) level.

Parameters:

- message: () -> String - The log message.
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Key-value pairs of log data.

### func info(String, Array\<Attr>)

```cangjie
public func info(message: String, attrs: Array<Attr>): Unit
```

Functionality: Convenience function for logging at [INFO](log_package_structs.md#static-const-info) level.

Parameters:

- message: String - The log message.
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Key-value pairs of log data.

### func info(() -> String, Array\<Attr>)

```cangjie
public func info(message: () -> String, attrs: Array<Attr>): Unit
```

Functionality: Convenience function for logging at [INFO](log_package_structs.md#static-const-info) level.

Parameters:

- message: () -> String - The log message.
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Key-value pairs of log data.

### func log(LogLevel, String, Array\<Attr>)

```cangjie
public open func log(level: LogLevel, message: String, attrs: Array<Attr>): Unit
```

Functionality: Generic logging function that requires specifying the log level.

Parameters:

- level: [LogLevel](log_package_structs.md#struct-loglevel) - The log level.
- message: String - The log message.
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Key-value pairs of log data.

### func log(LogLevel, () -> String, Array\<Attr>)

```cangjie
public open func log(level: LogLevel, message: () -> String, attrs: Array<Attr>): Unit
```

Functionality: Generic logging function that requires specifying the log level.

Parameters:

- level: [LogLevel](log_package_structs.md#struct-loglevel) - The log level.
- message: () -> String - The log message.
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Key-value pairs of log data.

### func log(LogRecord)

```cangjie
public open func log(record: LogRecord): Unit
```

Functionality: Generic logging function.

Parameters:

- record: [LogRecord](log_package_classes.md#class-logrecord) - The log level.

### func trace(String, Array\<Attr>)

```cangjie
public func trace(message: String, attrs: Array<Attr>): Unit
```

Functionality: Convenience function for logging at [TRACE](log_package_structs.md#static-const-trace) level.

Parameters:

- message: String - The log message.
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Key-value pairs of log data.

### func trace(() -> String, Array\<Attr>)

```cangjie
public func trace(message: () -> String, attrs: Array<Attr>): Unit
```

Functionality: Convenience function for logging at [TRACE](log_package_structs.md#static-const-trace) level.

Parameters:

- message: () -> String - The log message.
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Key-value pairs of log data.

### func warn(String, Array\<Attr>)

```cangjie
public func warn(message: String, attrs: Array<Attr>): Unit
```

Functionality: Convenience function for logging at [WARN](log_package_structs.md#static-const-warn) level.

Parameters:

- message: String - The log message.
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Key-value pairs of log data.

### func warn(() -> String, Array\<Attr>)

```cangjie
public func warn(message: () -> String, attrs: Array<Attr>): Unit
```

Functionality: Convenience function for logging at [WARN](log_package_structs.md#static-const-warn) level.

Parameters:

- message: () -> String - The log message.
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Key-value pairs of log data.

### func withAttrs(Array\<Attr>)

```cangjie
public open func withAttrs(attrs: Array<Attr>): Logger
```

Functionality: Creates a copy of the current object with the specified attributes.

Parameters:

- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Key-value pairs of log data attributes.

Return Value:

- [Logger](log_package_classes.md#class-logger) - An instance of the [Logger](log_package_classes.md#class-logger) class.

## class LogRecord

```cangjie
public class LogRecord {
    public init(time: DateTime, level: LogLevel, msg: String, attrs: Array<Attr>)
}
```

Functionality: The "payload" of a log message.

The record structure is passed as a parameter to the [log](log_package_classes.md#func-loglogrecord) method of the [Logger](log_package_classes.md#class-logger) class. Log providers process these structures to display log messages. Records are automatically created by log objects and are not visible to log users.

### init(DateTime, LogLevel, String, Array\<Attr>)

```cangjie
public init(time: DateTime, level: LogLevel, msg: String, attrs: Array<Attr>)
```

Functionality: Creates a [LogRecord](log_package_classes.md#class-logrecord) instance with specified timestamp, log level, log message, and key-value pairs of log data.

Parameters:

- time: DateTime - The timestamp when the log was recorded.
- level: [LogLevel](log_package_structs.md#struct-loglevel) - The log level.
- msg: String - The log message.
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Key-value pairs of log data.

### prop attrs

```cangjie
public mut prop attrs: Array<Attr>
```

Functionality: Gets or sets the key-value pairs of log data.

Type: Array\<[Attr](log_package_types.md#type-attr)>

### prop level

```cangjie
public prop level: LogLevel
```

Functionality: Gets the log level of this log record.Type: [LogLevel](log_package_structs.md#struct-loglevel)

### prop message

```cangjie
public mut prop message: String
```

Function: Gets or sets the log message.

Type: String

### prop time

```cangjie
public prop time: DateTime
```

Function: Gets the timestamp when the log was printed.

Type: DateTime

### func clone()

```cangjie
public func clone(): LogRecord
```

Function: Creates a copy of the current object.

Return value:

- [LogRecord](log_package_classes.md#class-logrecord) - A copy of the current object.

## class LogWriter

```cangjie
public abstract class LogWriter {
}
```

Function: [LogWriter](log_package_classes.md#class-logwriter) provides the capability to serialize Cangjie objects into log output targets.

[LogWriter](log_package_classes.md#class-logwriter) needs to be used in conjunction with the interface [LogValue](log_package_interfaces.md#interface-logvalue). [LogWriter](log_package_classes.md#class-logwriter) can write types that implement the [LogValue](log_package_interfaces.md#interface-logvalue) interface into log output targets through the writeValue series of methods.

### func endArray()

```cangjie
public func endArray(): Unit
```

Function: Ends serialization of the current [LogValue](log_package_interfaces.md#interface-logvalue) array.

Exceptions:

- IllegalStateException - When the current writer does not have a matching startArray.

### func endObject()

```cangjie
public func endObject(): Unit
```

Function: Ends serialization of the current [LogValue](log_package_interfaces.md#interface-logvalue) object.

Exceptions:

- IllegalStateException - When the current writer's state should not end a [LogValue](log_package_interfaces.md#interface-logvalue) object.

### func startArray()

```cangjie
public func startArray(): Unit
```

Function: Starts serialization of a new [LogValue](log_package_interfaces.md#interface-logvalue) array. Every startArray must have a corresponding endArray.

Exceptions:

- IllegalStateException - When the current writer's state should not write a [LogValue](log_package_interfaces.md#interface-logvalue) array.

### func startObject()

```cangjie
public func startObject(): Unit
```

Function: Starts serialization of a new [LogValue](log_package_interfaces.md#interface-logvalue) object. Every startObject must have a corresponding endObject.

Exceptions:

- IllegalStateException - When the current writer's state should not write a [LogValue](log_package_interfaces.md#interface-logvalue) object.

### func writeBool(Bool)

```cangjie
public func writeBool(v: Bool): Unit
```

Function: Writes a Bool value to the log output target.

Parameters:

- v: Bool - The Bool value to be written.

Exceptions:

- IllegalStateException - When the current writer's state should not write a value.

### func writeFloat(Float64)

```cangjie
public func writeFloat(v: Float64): Unit
```

Function: Writes a Float64 value to the log output target.

Parameters:

- v: Float64 - The Float64 value to be written.

Exceptions:

- IllegalStateException - When the current writer's state should not write a value.

### func writeDateTime(DateTime)

```cangjie
public func writeDateTime(v: DateTime): Unit
```

Function: Writes a DateTime value to the log output target.

Parameters:

- v: DateTime - The DateTime value to be written.

Exceptions:

- IllegalStateException - When the current writer's state should not write a value.

### func writeDuration(Duration)

```cangjie
public func writeDuration(v: Duration): Unit
```

Function: Writes a Duration value to the log output target.

Parameters:

- v: Duration - The Duration value to be written.

Exceptions:

- IllegalStateException - When the current writer's state should not write a value.

### func writeException(Exception)

```cangjie
public func writeException(v: Exception): Unit
```

Function: Writes an Exception value to the log output target.

Parameters:

- v: Exception - The Exception value to be written.

Exceptions:

- IllegalStateException - When the current writer's state should not write a value, this exception is thrown.

### func writeInt(Int64)

```cangjie
public func writeInt(v: Int64): Unit
```

Function: Writes an Int64 value to the log output target.

Parameters:

- v: Int64 - The Int64 value to be written.

Exceptions:

- IllegalStateException - When the current writer's state should not write a value.

### func writeKey(String)

```cangjie
public func writeKey(v: String): Unit
```

Function: Writes the key name specified by the parameter `v` to the log output target.

Parameters:

- v: String - The Key value to be written.

Exceptions:

- IllegalStateException - When the current writer's state should not write the string specified by the parameter `v`.

### func writeNone()

```cangjie
public func writeNone(): Unit
```

Function: Writes None to the log output target. The specific format is determined by the Logger provider.

Exceptions:

- IllegalStateException - When the current writer's state should not write a value.

### func writeString(String)

```cangjie
public func writeString(v: String): Unit
```

Function: Writes a String value to the log output target.

Parameters:

- v: String - The String value to be written.

Exceptions:

- IllegalStateException - When the current writer's state should not write a value.

### func writeValue(LogValue)

```cangjie
public func writeValue(v: LogValue): Unit
```

Function: Writes a type that implements the [LogValue](log_package_interfaces.md#interface-logvalue) interface to the log output target. This method calls the [writeTo](log_package_interfaces.md#func-writetologwriter) method of [LogValue](log_package_interfaces.md#interface-logvalue) to write data to the log output target.

The log package has extended implementations of [LogValue](log_package_interfaces.md#interface-logvalue) for basic types Int64, Float64, Bool, String, as well as for DateTime, Duration, Exception, Collection types Array, HashMap, TreeMap, and Option\<T>.

Parameters:

- v: [LogValue](log_package_interfaces.md#interface-logvalue) - The [LogValue](log_package_interfaces.md#interface-logvalue) value to be written.

Exceptions:

- IllegalStateException - When the current writer's state should not write a value.

## class NoopLogger

```cangjie
public class NoopLogger <: Logger {
    public init()
}
```

Function: A NO-OP (no operation) implementation of [Logger](log_package_classes.md#class-logger) that discards all logs.

Parent type:

- [Logger](#class-logger)

### init()

```cangjie
public init()
```

Function: Creates a [NoopLogger](log_package_classes.md#class-nooplogger) instance.

### prop level

```cangjie
public mut prop level: LogLevel
```

Function: Always returns the OFF log level. Setting the log level has no effect.

Type: [LogLevel](log_package_structs.md#struct-loglevel)

### func close()

```cangjie
public func close(): Unit
```

Function: NOOP implementation.

### func isClosed()

```cangjie
public func isClosed(): Bool
```

Function: NOOP implementation.

Return value:- Bool

### func log(LogLevel, String, Array\<Attr>)

```cangjie
public func log(level: LogLevel, message: String, attrs: Array<Attr>): Unit
```

Function: NOOP implementation.

Parameters:

- level: [LogLevel](log_package_structs.md#struct-loglevel) - Log level.
- message: String - Log message.
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Log data key-value pairs.

### func log(LogLevel, () -> String, Array\<Attr>)

```cangjie
public func log(level: LogLevel, message: () -> String, attrs: Array<Attr>): Unit
```

Function: NOOP implementation.

Parameters:

- level: [LogLevel](log_package_structs.md#struct-loglevel) - Log level.
- message: () -> String - Log message.
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Log data key-value pairs.

### func log(LogRecord)

```cangjie
public func log(record: LogRecord): Unit
```

Function: NOOP implementation.

Parameters:

- record: [LogRecord](log_package_classes.md#class-logrecord) - Log level.

### func withAttrs(Array\<Attr>)

```cangjie
public func withAttrs(attrs: Array<Attr>): Logger
```

Function: NOOP implementation.

Parameters:

- attrs: Array\<[Attr](log_package_types.md#type-attr)> - Log data key-value pairs.

Return value:

- [Logger](#class-logger) - Logger