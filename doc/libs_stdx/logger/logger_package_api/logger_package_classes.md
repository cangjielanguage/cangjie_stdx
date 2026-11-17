# 类

## class JsonLogger

```cangjie
public class JsonLogger <: Logger {
    public init(output: OutputStream)
}
```

功能：此类实现了输出 `JSON` 格式的日志打印功能，形如 `{"time":"2024-07-27T11:51:59+08:00","level":"INFO","msg":"foo","name":"bar"}`。

父类型：

- [Logger](../../log/log_package_api/log_package_classes.md#class-logger)

### prop level

```cangjie
public mut prop level: LogLevel
```

功能：获取和修改日志打印级别。

类型：[LogLevel](../../log/log_package_api/log_package_structs.md#struct-loglevel)

示例：

<!-- verify -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建JsonLogger实例，使用标准输出流
    let logger = JsonLogger(getStdOut())

    // 获取当前的日志级别
    let currentLevel = logger.level
    println("默认日志级别: ${currentLevel}")

    // 设置一个新的日志级别
    logger.level = LogLevel.DEBUG

    // 再次获取日志级别以确认更改
    let updatedLevel = logger.level
    println("更新后的日志级别: ${updatedLevel}")

    return 0
}
```

运行结果：

```text
默认日志级别: INFO
更新后的日志级别: DEBUG
```

### init(OutputStream)

```cangjie
public init(output: OutputStream)
```

功能：创建 [JsonLogger](logger_package_classes.md#class-jsonlogger) 对象。

参数：

- output: OutputStream - 绑定的输出流，日志格式化后将写入该输出流。

示例：

<!-- run -->
```cangjie
import stdx.logger.*
import std.env.*

main() {
    // 使用标准输出流创建JsonLogger实例
    let logger = JsonLogger(getStdOut())
    return 0
}
```

### func close()

```cangjie
public func close(): Unit
```

功能：关闭 Logger。

示例：

<!-- verify -->
```cangjie
import stdx.logger.*
import std.env.*

main() {
    // 创建JsonLogger实例
    let logger = JsonLogger(getStdOut())

    // 检查logger是否关闭
    let isClosedBefore = logger.isClosed()
    println("关闭前状态: ${isClosedBefore}")

    // 关闭logger
    logger.close()

    // 再次检查是否关闭
    let isClosedAfter = logger.isClosed()
    println("关闭后状态: ${isClosedAfter}")

    return 0
}
```

运行结果：

```text
关闭前状态: false
关闭后状态: true
```

### func isClosed()

```cangjie
public func isClosed(): Bool
```

功能：判断当前 Logger 是否关闭。

返回值：

- Bool - 是否关闭。

示例：
<!-- associated_example -->
参见 [func close](#func-close) 示例。

### func log(LogRecord)

```cangjie
public func log(record: LogRecord): Unit
```

功能：打印日志的通用函数。

参数：

- record: [LogRecord](../../log/log_package_api/log_package_classes.md#class-logrecord) - 日志级别。

示例：

<!-- verify -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*
import std.time.*

main() {
    // 创建JsonLogger实例
    let logger = JsonLogger(getStdOut())

    // 创建一个LogRecord实例
    let dateTime = DateTime.of(year: 2026, month: 1, dayOfMonth: 1, timeZone: TimeZone.UTC)
    let logRecord = LogRecord(dateTime, LogLevel.INFO, "这是一个测试消息")

    // 使用log方法记录日志
    logger.log(logRecord)
    return 0
}
```

运行结果：

```text
{"time":"2026-01-01T00:00:00Z","level":"INFO","msg":"这是一个测试消息"}
```

### func withAttrs(Array\<Attr>)

```cangjie
public func withAttrs(attrs: Array<Attr>): Logger
```

功能：创建当前对象的副本，新的副本会包含指定的属性。

参数：

- attrs: Array\<[Attr](../../log/log_package_api/log_package_types.md#type-attr)> - 日志数据键值对属性。

返回值：

- [Logger](../../log/log_package_api/log_package_classes.md#class-logger) - [Logger](../../log/log_package_api/log_package_classes.md#class-logger) 类的对象实例。

示例：

<!-- verify -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*
import std.time.*

main() {
    // 创建JsonLogger实例
    let logger = JsonLogger(getStdOut())

    // 创建一个LogRecord实例
    let dateTime = DateTime.of(year: 2026, month: 1, dayOfMonth: 1, timeZone: TimeZone.UTC)
    let logRecord = LogRecord(dateTime, LogLevel.INFO, "这是一个测试消息")

    // 使用log方法记录日志，发现日志中不包含属性
    logger.log(logRecord)

    // 创建属性数组
    let attr1: (String, LogValue) = ("key1", "value1")
    let attr2: (String, LogValue) = ("key2", 123)
    let attrs = [attr1, attr2]

    // 使用withAttrs方法创建带属性的logger副本
    let loggerWithAttrs = logger.withAttrs(attrs)

    // 再次使用log方法记录日志，发现日志中包含属性
    loggerWithAttrs.log(logRecord)
    return 0
}
```

运行结果：

```text
{"time":"2026-01-01T00:00:00Z","level":"INFO","msg":"这是一个测试消息"}
{"time":"2026-01-01T00:00:00Z","level":"INFO","msg":"这是一个测试消息","key1":"value1","key2":123}
```

## class SimpleLogger

```cangjie
public class SimpleLogger <: Logger {
    public init(output: OutputStream)
}
```

功能：此类实现了输出文本格式的日志打印功能，形如 `2024-07-27T11:50:47.6616733+08:00 INFO foo name="bar"`。

父类型：

- [Logger](../../log/log_package_api/log_package_classes.md#class-logger)

### prop level

```cangjie
public mut prop level: LogLevel
```

功能：获取和修改日志打印级别。

类型：[LogLevel](../../log/log_package_api/log_package_structs.md#struct-loglevel)

示例：

<!-- verify -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建SimpleLogger实例，使用标准输出流
    let logger = SimpleLogger(getStdOut())

    // 获取当前的日志级别
    let currentLevel = logger.level
    println("默认日志级别: ${currentLevel}")

    // 设置一个新的日志级别
    logger.level = LogLevel.DEBUG

    // 再次获取日志级别以确认更改
    let updatedLevel = logger.level
    println("更新后的日志级别: ${updatedLevel}")

    return 0
}
```

运行结果：

```text
默认日志级别: INFO
更新后的日志级别: DEBUG
```

### init(OutputStream)

```cangjie
public init(output: OutputStream)
```

功能：创建 [SimpleLogger](logger_package_classes.md#class-simplelogger) 对象。

参数：

- output: OutputStream - 绑定的输出流，日志格式化后将写入该输出流。

示例：

<!-- run -->
```cangjie
import stdx.logger.*
import std.env.*

main() {
    // 使用标准输出流创建SimpleLogger实例
    let logger = SimpleLogger(getStdOut())
    return 0
}
```

### func close()

```cangjie
public func close(): Unit
```

功能：关闭 Logger。

示例：

<!-- verify -->
```cangjie
import stdx.logger.*
import std.env.*

main() {
    // 创建SimpleLogger实例
    let logger = SimpleLogger(getStdOut())

    // 检查logger是否关闭
    let isClosedBefore = logger.isClosed()
    println("关闭前状态: ${isClosedBefore}")

    // 关闭logger
    logger.close()

    // 再次检查是否关闭
    let isClosedAfter = logger.isClosed()
    println("关闭后状态: ${isClosedAfter}")

    return 0
}
```

运行结果：

```text
关闭前状态: false
关闭后状态: true
```

### func isClosed()

```cangjie
public func isClosed(): Bool
```

功能：判断当前 Logger 是否关闭。

返回值：

- Bool - 是否关闭。

示例：
<!-- associated_example -->
参见 [func close](#func-close) 示例。

### func log(LogRecord)

```cangjie
public func log(record: LogRecord): Unit
```

功能：打印日志的通用函数。

参数：

- record: [LogRecord](../../log/log_package_api/log_package_classes.md#class-logrecord) - 日志级别。

示例：

<!-- verify -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*
import std.time.*

main() {
    // 创建SimpleLogger实例
    let logger = SimpleLogger(getStdOut())

    // 创建一个LogRecord实例
    let dateTime = DateTime.of(year: 2026, month: 1, dayOfMonth: 1, timeZone: TimeZone.UTC)
    let logRecord = LogRecord(dateTime, LogLevel.INFO, "这是一个测试消息")

    // 使用log方法记录日志
    logger.log(logRecord)
    return 0
}
```

运行结果：

```text
2026-01-01T00:00:00Z INFO 这是一个测试消息
```

### func withAttrs(Array\<Attr>)

```cangjie
public func withAttrs(attrs: Array<Attr>): Logger
```

功能：创建当前对象的副本，新的副本会包含指定的属性。

参数：

- attrs: Array\<[Attr](../../log/log_package_api/log_package_types.md#type-attr)> - 日志数据键值对属性。

返回值：

- [Logger](../../log/log_package_api/log_package_classes.md#class-logger) - [Logger](../../log/log_package_api/log_package_classes.md#class-logger) 类的对象实例。

示例：

<!-- verify -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*
import std.time.*

main() {
    // 创建SimpleLogger实例
    let logger = SimpleLogger(getStdOut())

    // 创建一个LogRecord实例
    let dateTime = DateTime.of(year: 2026, month: 1, dayOfMonth: 1, timeZone: TimeZone.UTC)
    let logRecord = LogRecord(dateTime, LogLevel.INFO, "这是一个测试消息")

    // 使用log方法记录日志，发现日志中不包含属性
    logger.log(logRecord)

    // 创建属性数组
    let attr1: (String, LogValue) = ("key1", "value1")
    let attr2: (String, LogValue) = ("key2", 123)
    let attrs = [attr1, attr2]

    // 使用withAttrs方法创建带属性的logger副本
    let loggerWithAttrs = logger.withAttrs(attrs)

    // 再次使用log方法记录日志，发现日志中包含属性
    loggerWithAttrs.log(logRecord)
    return 0
}
```

运行结果：

```text
2026-01-01T00:00:00Z INFO 这是一个测试消息 
2026-01-01T00:00:00Z INFO 这是一个测试消息 key1="value1" key2=123
```

## class TextLogger

```cangjie
public class TextLogger <: Logger {
    public init(output: OutputStream)
}
```

功能：此类实现了输出文本格式的日志打印功能，形如 `time=2024-07-27T11:52:40.3226881+08:00 level="INFO" msg="foo" name="bar"`。

父类型：

- [Logger](../../log/log_package_api/log_package_classes.md#class-logger)

### prop level

```cangjie
public mut prop level: LogLevel
```

功能：获取和修改日志打印级别。

类型：[LogLevel](../../log/log_package_api/log_package_structs.md#struct-loglevel)

示例：

<!-- verify -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建TextLogger实例，使用标准输出流
    let logger = TextLogger(getStdOut())

    // 获取当前的日志级别
    let currentLevel = logger.level
    println("默认日志级别: ${currentLevel}")

    // 设置一个新的日志级别
    logger.level = LogLevel.DEBUG

    // 再次获取日志级别以确认更改
    let updatedLevel = logger.level
    println("更新后的日志级别: ${updatedLevel}")

    return 0
}
```

运行结果：

```text
默认日志级别: INFO
更新后的日志级别: DEBUG
```

### init(OutputStream)

```cangjie
public init(output: OutputStream)
```

功能：创建 [TextLogger](logger_package_classes.md#class-textlogger) 对象。

参数：

- output: OutputStream - 绑定的输出流，日志格式化后将写入该输出流。

示例：

<!-- run -->
```cangjie
import stdx.logger.*
import std.env.*

main() {
    // 使用标准输出流创建TextLogger实例
    let logger = TextLogger(getStdOut())
    return 0
}
```

### func close()

```cangjie
public func close(): Unit
```

功能：关闭 Logger。

示例：

<!-- verify -->
```cangjie
import stdx.logger.*
import std.env.*

main() {
    // 创建TextLogger实例
    let logger = TextLogger(getStdOut())

    // 检查logger是否关闭
    let isClosedBefore = logger.isClosed()
    println("关闭前状态: ${isClosedBefore}")

    // 关闭logger
    logger.close()

    // 再次检查是否关闭
    let isClosedAfter = logger.isClosed()
    println("关闭后状态: ${isClosedAfter}")

    return 0
}
```

运行结果：

```text
关闭前状态: false
关闭后状态: true
```

### func isClosed()

```cangjie
public func isClosed(): Bool
```

功能：判断当前 Logger 是否关闭。

返回值：

- Bool - 是否关闭。

示例：
<!-- associated_example -->
参见 [func close](#func-close) 示例。

### func log(LogRecord)

```cangjie
public func log(record: LogRecord): Unit
```

功能：打印日志的通用函数。

参数：

- record: [LogRecord](../../log/log_package_api/log_package_classes.md#class-logrecord) - 日志级别。

示例：

<!-- verify -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*
import std.time.*

main() {
    // 创建TextLogger实例
    let logger = TextLogger(getStdOut())

    // 创建一个LogRecord实例
    let dateTime = DateTime.of(year: 2026, month: 1, dayOfMonth: 1, timeZone: TimeZone.UTC)
    let logRecord = LogRecord(dateTime, LogLevel.INFO, "这是一个测试消息")

    // 使用log方法记录日志
    logger.log(logRecord)
    return 0
}
```

运行结果：

```text
time=2026-01-01T00:00:00Z level="INFO" msg="这是一个测试消息"
```

### func withAttrs(Array\<Attr>)

```cangjie
public func withAttrs(attrs: Array<Attr>): Logger
```

功能：创建当前对象的副本，新的副本会包含指定的属性。

参数：

- attrs: Array\<[Attr](../../log/log_package_api/log_package_types.md#type-attr)> - 日志数据键值对属性。

返回值：

- [Logger](../../log/log_package_api/log_package_classes.md#class-logger) - [Logger](../../log/log_package_api/log_package_classes.md#class-logger) 类的对象实例。

示例：

<!-- verify -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*
import std.time.*

main() {
    // 创建TextLogger实例
    let logger = TextLogger(getStdOut())

    // 创建一个LogRecord实例
    let dateTime = DateTime.of(year: 2026, month: 1, dayOfMonth: 1, timeZone: TimeZone.UTC)
    let logRecord = LogRecord(dateTime, LogLevel.INFO, "这是一个测试消息")

    // 使用log方法记录日志，发现日志中不包含属性
    logger.log(logRecord)

    // 创建属性数组
    let attr1: (String, LogValue) = ("key1", "value1")
    let attr2: (String, LogValue) = ("key2", 123)
    let attrs = [attr1, attr2]

    // 使用withAttrs方法创建带属性的logger副本
    let loggerWithAttrs = logger.withAttrs(attrs)

    // 再次使用log方法记录日志，发现日志中包含属性
    loggerWithAttrs.log(logRecord)
    return 0
}
```

运行结果：

```text
time=2026-01-01T00:00:00Z level="INFO" msg="这是一个测试消息"
time=2026-01-01T00:00:00Z level="INFO" msg="这是一个测试消息" key1="value1" key2=123
```
