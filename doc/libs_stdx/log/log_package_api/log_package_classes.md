# 类

## class Logger

```cangjie
public abstract class Logger <: Resource {}
```

功能：此抽象类提供基础的日志打印和管理功能。

父类型：

- Resource

### prop level

```cangjie
public open mut prop level: LogLevel
```

功能：获取和修改日志打印级别。

类型：[LogLevel](log_package_structs.md#struct-loglevel)

示例：

<!-- run -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建一个SimpleLogger（抽象类Logger的实现类）实例
    let logger = SimpleLogger(getStdOut())

    // 获取当前日志级别
    let currentLevel = logger.level
    println("当前日志级别: ${currentLevel}")
    logger.debug({=> "级别较低，本调试日志不被打印"}, [("type", "debug")])

    // 修改日志级别
    logger.level = LogLevel.DEBUG
    println("修改后的日志级别: ${logger.level}")
    logger.debug({=> "这是一个调试信息"}, [("type", "debug")])
    return 0
}
```

可能的运行结果：

```text
当前日志级别: INFO
修改后的日志级别: DEBUG
2026-01-19T06:41:10.610312112Z DEBUG 这是一个调试信息 type="debug"
```

### func debug(() -> String, Array\<Attr>)

```cangjie
public func debug(message: () -> String, attrs: Array<Attr>): Unit
```

功能：打印 [DEBUG](log_package_structs.md#static-const-debug) 级别的日志的便捷函数。

参数：

- message: () -> String - 日志消息。
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对。

示例：

<!-- run -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建一个SimpleLogger（抽象类Logger的实现类）实例并设置为DEBUG级别
    let logger = SimpleLogger(getStdOut())
    logger.level = LogLevel.DEBUG

    // 使用lambda表达式作为消息函数记录DEBUG日志
    logger.debug({=> "这是一个调试信息"}, [("type", "debug"), ("id", 123)])
    return 0
}
```

可能的运行结果：

```text
2026-01-12T11:07:09.245444333+08:00 DEBUG 这是一个调试信息 type="debug" id=123
```

### func debug(String, Array\<Attr>)

```cangjie
public func debug(message: String, attrs: Array<Attr>): Unit
```

功能：打印 [DEBUG](log_package_structs.md#static-const-debug) 级别的日志的便捷函数。

参数：

- message: String - 日志消息。
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对。

示例：

<!-- run -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建一个SimpleLogger（抽象类Logger的实现类）实例并设置为DEBUG级别
    let logger = SimpleLogger(getStdOut())
    logger.level = LogLevel.DEBUG

    // 使用字符串消息记录DEBUG日志（变长参数语法糖）
    logger.debug("这是一个调试信息")
    return 0
}
```

可能的运行结果：

```text
2026-01-12T11:08:03.320265151+08:00 DEBUG 这是一个调试信息
```

### func enabled(LogLevel)

```cangjie
public func enabled(level: LogLevel): Bool
```

功能：确定是否记录指定日志级别的日志消息。

这个函数允许调用者提前判断日志是否会被丢弃，以避免耗时的日志消息参数计算。

参数：

- level: [LogLevel](log_package_structs.md#struct-loglevel) - 日志级别。

返回值：

- Bool - 如果指定的日志级别处于使能状态，则返回 `true`；否则，返回 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建一个SimpleLogger（抽象类Logger的实现类）实例
    let logger = SimpleLogger(getStdOut())
    logger.level = LogLevel.INFO

    // 检查DEBUG级别是否启用（当前为INFO级别，所以DEBUG不会启用）
    let isDebugEnabled = logger.enabled(LogLevel.DEBUG)
    println("DEBUG级别是否启用: ${isDebugEnabled}")

    // 检查INFO级别是否启用
    let isInfoEnabled = logger.enabled(LogLevel.INFO)
    println("INFO级别是否启用: ${isInfoEnabled}")
    return 0
}
```

运行结果：

```text
DEBUG级别是否启用: false
INFO级别是否启用: true
```

### func error(() -> String, Array\<Attr>)

```cangjie
public func error(message: () -> String, attrs: Array<Attr>): Unit
```

功能：打印 [ERROR](log_package_structs.md#static-const-error) 级别的日志的便捷函数。

参数：

- message: () -> String - 日志消息。
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对。

示例：

<!-- run -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建一个SimpleLogger（抽象类Logger的实现类）实例
    let logger = SimpleLogger(getStdOut())

    // 使用lambda表达式作为消息函数记录ERROR日志（变长参数语法糖）
    logger.error({=> "这是一个错误信息"})
    return 0
}
```

可能的运行结果：

```text
2026-01-12T11:09:56.446050589+08:00 ERROR 这是一个错误信息
```

### func error(String, Array\<Attr>)

```cangjie
public func error(message: String, attrs: Array<Attr>): Unit
```

功能：打印 [ERROR](log_package_structs.md#static-const-error) 级别的日志的便捷函数。

参数：

- message: String - 日志消息。
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对。

示例：

<!-- run -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建一个SimpleLogger（抽象类Logger的实现类）实例
    let logger = SimpleLogger(getStdOut())

    // 使用字符串消息记录ERROR日志
    logger.error("这是一个错误信息", [("type", "error"), ("code", 404)])
    return 0
}
```

可能的运行结果：

```text
2026-01-12T11:11:52.781377362+08:00 ERROR 这是一个错误信息 type="error" code=404
```

### func fatal(() -> String, Array\<Attr>)

```cangjie
public func fatal(message: () -> String, attrs: Array<Attr>): Unit
```

功能：打印 [FATAL](log_package_structs.md#static-const-fatal) 级别的日志的便捷函数。

参数：

- message: () -> String - 日志消息。
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对。

示例：

<!-- run -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建一个SimpleLogger（抽象类Logger的实现类）实例
    let logger = SimpleLogger(getStdOut())

    // 使用lambda表达式作为消息函数记录FATAL日志
    logger.fatal({=> "这是一个严重错误信息"}, [("type", Exception("fatal exception")), ("code", 600)])
    return 0
}
```

可能的运行结果：

```text
2026-01-13T02:16:08.051647994Z FATAL 这是一个严重错误信息 type=["Exception: fatal exception","default.main()(test.cj:10)"] code=600
```

### func fatal(String, Array\<Attr>)

```cangjie
public func fatal(message: String, attrs: Array<Attr>): Unit
```

功能：打印 [FATAL](log_package_structs.md#static-const-fatal) 级别的日志的便捷函数。

参数：

- message: String - 日志消息。
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对。

示例：

<!-- run -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建一个SimpleLogger（抽象类Logger的实现类）实例
    let logger = SimpleLogger(getStdOut())

    // 使用字符串消息记录FATAL日志（变长参数语法糖）
    logger.fatal("这是一个严重错误信息")
    return 0
}
```

可能的运行结果：

```text
2026-01-12T11:14:45.193240448+08:00 FATAL 这是一个严重错误信息
```

### func info(() -> String, Array\<Attr>)

```cangjie
public func info(message: () -> String, attrs: Array<Attr>): Unit
```

功能：打印 [INFO](log_package_structs.md#static-const-info) 级别的日志的便捷函数。

参数：

- message: () -> String - 日志消息。
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对。

示例：

<!-- run -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建一个SimpleLogger（抽象类Logger的实现类）实例
    let logger = SimpleLogger(getStdOut())

    // 使用lambda表达式作为消息函数记录INFO日志（变长参数语法糖）
    logger.info({=> "这是一个信息"})
    return 0
}
```

可能的运行结果：

```text
2026-01-12T11:15:48.641498023+08:00 INFO 这是一个信息
```

### func info(String, Array\<Attr>)

```cangjie
public func info(message: String, attrs: Array<Attr>): Unit
```

功能：打印 [INFO](log_package_structs.md#static-const-info) 级别的日志的便捷函数。

参数：

- message: String - 日志消息。
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对。

示例：

<!-- run -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建一个SimpleLogger（抽象类Logger的实现类）实例
    let logger = SimpleLogger(getStdOut())

    // 使用字符串消息记录INFO日志（变长参数语法糖）
    logger.info("这是一个信息")
    return 0
}
```

可能的运行结果：

```text
2026-01-12T11:16:15.123456789+08:00 INFO 这是一个信息
```

### func log(LogLevel, () -> String, Array\<Attr>)

```cangjie
public open func log(level: LogLevel, message: () -> String, attrs: Array<Attr>): Unit
```

功能：打印日志的通用函数，需指定日志级别。

参数：

- level: [LogLevel](log_package_structs.md#struct-loglevel) - 日志级别。
- message: () -> String - 日志消息。
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对。

示例：

<!-- run -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建一个SimpleLogger（抽象类Logger的实现类）实例
    let logger = SimpleLogger(getStdOut())

    // 使用通用log函数记录不同级别的日志
    logger.log(LogLevel.WARN, {=> "这是一个警告信息"}, [("bool", true), ("array", [1, 2, 3])])
    return 0
}
```

可能的运行结果：

```text
2026-01-13T02:18:14.81202694Z WARN 这是一个警告信息 bool=true array=[1,2,3]
```

### func log(LogLevel, String, Array\<Attr>)

```cangjie
public open func log(level: LogLevel, message: String, attrs: Array<Attr>): Unit
```

功能：打印日志的通用函数，需指定日志级别。

参数：

- level: [LogLevel](log_package_structs.md#struct-loglevel) - 日志级别。
- message: String - 日志消息。
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对。

示例：

<!-- run -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建一个SimpleLogger（抽象类Logger的实现类）实例
    let logger = SimpleLogger(getStdOut())

    // 使用通用log函数记录不同级别的日志（变长参数语法糖）
    logger.log(LogLevel.INFO, "这是一个信息日志")
    return 0
}
```

可能的运行结果：

```text
2026-01-12T11:18:05.493054545+08:00 INFO 这是一个信息日志
```

### func log(LogRecord)

```cangjie
public open func log(record: LogRecord): Unit
```

功能：打印日志的通用函数。

参数：

- record: [LogRecord](log_package_classes.md#class-logrecord) - 日志级别。

示例：

<!-- run -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*
import std.time.*

main() {
    // 创建一个SimpleLogger（抽象类Logger的实现类）实例
    let logger = SimpleLogger(getStdOut())

    // 创建一个LogRecord实例
    let logRecord = LogRecord(DateTime.of(year: 2026, month: 1, dayOfMonth: 1), LogLevel.INFO, "通过LogRecord记录的信息")

    // 使用log函数记录LogRecord
    logger.log(logRecord)
    return 0
}
```

可能的运行结果：

```text
2026-01-01T00:00:00Z INFO 通过LogRecord记录的信息
```

### func trace(() -> String, Array\<Attr>)

```cangjie
public func trace(message: () -> String, attrs: Array<Attr>): Unit
```

功能：打印 [TRACE](log_package_structs.md#static-const-trace) 级别的日志的便捷函数。

参数：

- message: () -> String - 日志消息。
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对。

示例：

<!-- run -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建一个SimpleLogger（抽象类Logger的实现类）实例
    let logger = SimpleLogger(getStdOut())
    logger.level = LogLevel.TRACE

    // 使用lambda表达式作为消息函数记录TRACE日志（变长参数语法糖）
    logger.trace({=> "这是一个追踪信息"})
    return 0
}
```

可能的运行结果：

```text
2026-01-12T11:20:02.668866491+08:00 TRACE 这是一个追踪信息
```

### func trace(String, Array\<Attr>)

```cangjie
public func trace(message: String, attrs: Array<Attr>): Unit
```

功能：打印 [TRACE](log_package_structs.md#static-const-trace) 级别的日志的便捷函数。

参数：

- message: String - 日志消息。
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对。

示例：

<!-- run -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*
import std.collection.*

main() {
    // 创建一个SimpleLogger（抽象类Logger的实现类）实例
    let logger = SimpleLogger(getStdOut())
    logger.level = LogLevel.TRACE

    // 使用字符串消息记录TRACE日志
    logger.trace("这是一个追踪信息",
        [("type", "trace"), ("module", HashMap<String, String>([("name", "test01"), ("version", "1.0")]))])
    return 0
}
```

可能的运行结果：

```text
2026-01-13T02:21:10.752213995Z TRACE 这是一个追踪信息 type="trace" module={name:"test01",version:"1.0"}
```

### func warn(() -> String, Array\<Attr>)

```cangjie
public func warn(message: () -> String, attrs: Array<Attr>): Unit
```

功能：打印 [WARN](log_package_structs.md#static-const-warn) 级别的日志的便捷函数。

参数：

- message: () -> String - 日志消息。
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对。

示例：

<!-- run -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建一个SimpleLogger（抽象类Logger的实现类）实例
    let logger = SimpleLogger(getStdOut())

    // 使用lambda表达式作为消息函数记录WARN日志
    logger.warn({=> "这是一个警告信息"}, [("type", "warn"), ("module", "security")])
    return 0
}
```

可能的运行结果：

```text
2026-01-12T11:23:11.841638679+08:00 WARN 这是一个警告信息 type="warn" module="security"
```

### func warn(String, Array\<Attr>)

```cangjie
public func warn(message: String, attrs: Array<Attr>): Unit
```

功能：打印 [WARN](log_package_structs.md#static-const-warn) 级别的日志的便捷函数。

参数：

- message: String - 日志消息。
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对。

示例：

<!-- run -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建一个SimpleLogger（抽象类Logger的实现类）实例
    let logger = SimpleLogger(getStdOut())

    // 使用字符串消息记录WARN日志（变长参数语法糖）
    logger.warn("这是一个警告信息")
    return 0
}
```

可能的运行结果：

```text
2026-01-12T11:23:45.818200702+08:00 WARN 这是一个警告信息
```

### func withAttrs(Array\<Attr>)

```cangjie
public open func withAttrs(attrs: Array<Attr>): Logger
```

功能：创建当前对象的副本，新的副本会包含指定的属性。

参数：

- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对属性。

返回值：

- [Logger](#class-logger) - [Logger](#class-logger) 类的对象实例。

示例：

<!-- run -->
```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

main() {
    // 创建一个SimpleLogger（抽象类Logger的实现类）实例
    let baseLogger = SimpleLogger(getStdOut())

    // 使用withAttrs方法创建一个新的Logger实例，带有预设属性
    let enhancedLogger = baseLogger.withAttrs([("service", "user-service"), ("version", "1.0")])

    // 使用增强的logger记录信息
    enhancedLogger.info("服务启动成功")
    enhancedLogger.info("服务接收请求")
    return 0
}
```

可能的运行结果：

```text
2026-01-13T09:53:31.949826556+08:00 INFO 服务启动成功 service="user-service" version="1.0"
2026-01-13T09:53:31.949907056+08:00 INFO 服务接收请求 service="user-service" version="1.0"
```

## class LogRecord

```cangjie
public class LogRecord {
    public init(time: DateTime, level: LogLevel, msg: String, attrs: Array<Attr>)
}
```

功能：日志消息的“负载”。

记录结构作为参数传递给 [Logger](#class-logger) 类的 [log](#func-loglogrecord)方法。日志提供者处理这些结构以显示日志消息。记录是由日志对象自动创建，因此日志用户看不到。

### prop attrs

```cangjie
public mut prop attrs: Array<Attr>
```

功能：获取或设置日志数据键值对。

类型：Array\<[Attr](log_package_types.md#type-attr)>

示例：

<!-- verify -->
```cangjie
import stdx.log.*
import std.time.*

main() {
    // 创建一个LogRecord实例
    let logRecord = LogRecord(DateTime.now(), LogLevel.INFO, "测试消息", [("type", "test")])

    // 获取当前的attrs属性
    println("原始attrs长度: ${logRecord.attrs.size}")

    // 修改attrs属性
    logRecord.attrs = [("type", "modified"), ("newAttr", "value")]
    println("修改后attrs长度: ${logRecord.attrs.size}")

    return 0
}
```

运行结果：

```text
原始attrs长度: 1
修改后attrs长度: 2
```

### prop level

```cangjie
public prop level: LogLevel
```

功能：获取该条日志的打印级别。

类型：[LogLevel](log_package_structs.md#struct-loglevel)

示例：

<!-- verify -->
```cangjie
import stdx.log.*
import std.time.*

main() {
    // 创建一个LogRecord实例
    let logRecord = LogRecord(DateTime.now(), LogLevel.INFO, "测试消息", [("type", "test")])

    // 获取当前的level属性
    println("日志级别: ${logRecord.level}")

    return 0
}
```

运行结果：

```text
日志级别: INFO
```

### prop message

```cangjie
public mut prop message: String
```

功能：获取或设置日志消息。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.log.*
import std.time.*

main() {
    // 创建一个LogRecord实例
    let logRecord = LogRecord(DateTime.now(), LogLevel.INFO, "测试消息")

    // 获取当前的消息内容
    println("原始消息: ${logRecord.message}")

    // 修改消息内容
    logRecord.message = "修改后的消息"
    println("修改后消息: ${logRecord.message}")

    return 0
}
```

运行结果：

```text
原始消息: 测试消息
修改后消息: 修改后的消息
```

### prop time

```cangjie
public prop time: DateTime
```

功能：获取日志打印时的时间戳。

类型：DateTime

示例：

<!-- run -->
```cangjie
import stdx.log.*
import std.time.*

main() {
    // 创建一个LogRecord实例
    let logRecord = LogRecord(DateTime.now(), LogLevel.INFO, "测试消息")

    // 获取当前的时间戳
    println("日志时间戳: ${logRecord.time}")

    return 0
}
```

可能的运行结果：

```text
日志时间戳: 2026-01-13T10:04:57.582847051+08:00
```

### init(DateTime, LogLevel, String, Array\<Attr>)

```cangjie
public init(time: DateTime, level: LogLevel, msg: String, attrs: Array<Attr>)
```

功能：创建一个 [LogRecord](log_package_classes.md#class-logrecord) 实例，指定时间戳，日志打印级别，日志消息和日志数据键值对。

参数：

- time: DateTime - 记录日志时的时间戳
- level: [LogLevel](log_package_structs.md#struct-loglevel) - 日志级别。
- msg: String - 日志消息。
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对。

示例：

<!-- verify -->
```cangjie
import stdx.log.*
import std.time.*

main() {
    // 创建一个LogRecord实例
    var logRecord = LogRecord(DateTime.now(), LogLevel.WARN, "警告消息", [("type", "warning"), ("module", "auth")])

    // 输出创建的LogRecord信息
    println("创建的LogRecord消息: ${logRecord.message}")
    println("日志级别: ${logRecord.level}")
    println("属性数量: ${logRecord.attrs.size}")

    // 创建一个没有属性的LogRecord实例（变长参数语法糖）
    logRecord = LogRecord(DateTime.now(), LogLevel.INFO, "通知消息")

    // 输出创建的LogRecord信息
    println("创建的LogRecord消息: ${logRecord.message}")
    println("日志级别: ${logRecord.level}")
    println("属性数量: ${logRecord.attrs.size}")
}
```

运行结果：

```text
创建的LogRecord消息: 警告消息
日志级别: WARN
属性数量: 2
创建的LogRecord消息: 通知消息
日志级别: INFO
属性数量: 0
```

### func clone()

```cangjie
public func clone(): LogRecord
```

功能：创建当前对象的副本。

返回值：

- [LogRecord](log_package_classes.md#class-logrecord) - 当前对象的副本。

示例：

<!-- verify -->
```cangjie
import stdx.log.*
import std.time.*

main() {
    // 创建一个LogRecord实例
    let originalRecord = LogRecord(DateTime.now(), LogLevel.INFO, "原始消息", [("type", "original"), ("id", 1)])

    // 克隆LogRecord对象
    let clonedRecord = originalRecord.clone()

    // 验证克隆的对象
    println("原始消息: ${originalRecord.message}")
    println("克隆消息: ${clonedRecord.message}")

    return 0
}
```

运行结果：

```text
原始消息: 原始消息
克隆消息: 原始消息
```

## class LogWriter

```cangjie
public abstract class LogWriter {}
```

功能：[LogWriter](log_package_classes.md#class-logwriter) 提供了将仓颉对象序列化成日志输出目标的能力。

[LogWriter](log_package_classes.md#class-logwriter) 需要和 interface [LogValue](log_package_interfaces.md#interface-logvalue) 搭配使用，[LogWriter](log_package_classes.md#class-logwriter) 可以通过 writeValue 系列方法来将实现了 [LogValue](log_package_interfaces.md#interface-logvalue) 接口的类型写入到日志输出目标中。

### func endArray()

```cangjie
public func endArray(): Unit
```

功能：结束序列化当前的 [LogValue](log_package_interfaces.md#interface-logvalue) 数组。

异常：

- IllegalStateException - 当前 writer 没有匹配的 startArray 时。

示例：

<!-- verify -->
```cangjie
import stdx.log.*
import std.collection.*
import std.time.*

// 定义一个简单自定义的LogWriter实现用于演示，实际开发中请参考 samples 中示例
public class SimpleLogWriter <: LogWriter {
    var buffer = ""

    // 写入空值时，添加自定义内容
    public func writeNone(): Unit {
        buffer += " NONE"
    }
    // 写入整数时，添加自定义内容
    public func writeInt(v: Int64): Unit {
        buffer += "INT: ${v}"
    }
    // 写入布尔值时，添加自定义内容
    public func writeBool(v: Bool): Unit {
        buffer += "BOOL: ${v}"
    }
    // 写入浮点数时，添加自定义内容
    public func writeFloat(v: Float64): Unit {
        buffer += " FLOAT: ${v}"
    }
    // 写入字符串时，添加自定义内容
    public func writeString(v: String): Unit {
        buffer += " STRING: ${v}"
    }
    // 写入日期时间时，添加自定义内容
    public func writeDateTime(v: DateTime): Unit {
        buffer += " DATETIME: ${v}"
    }
    // 写入间隔时间时，添加自定义内容
    public func writeDuration(v: Duration): Unit {
        buffer += " DURATION: ${v}"
    }
    // 写入异常时，添加自定义内容
    public func writeException(v: Exception): Unit {
        buffer += " EXCEPTION: ${v.message}"
    }
    // 写入键时，添加自定义内容
    public func writeKey(v: String): Unit {
        buffer += " KEY: ${v} = "
    }
    // 写入值时，添加自定义内容
    public func writeValue(v: LogValue): Unit {
        v.writeTo(this)
    }
    // 写入数组时，添加自定义内容
    public func startArray(): Unit {
        buffer += "["
    }
    public func endArray(): Unit {
        buffer += "]"
    }
    // 写入对象时，添加自定义内容
    public func startObject(): Unit {
        buffer += "{"
    }
    public func endObject(): Unit {
        buffer += "}"
    }
}

main() {
    // 创建一个LogWriter实例
    let writer = SimpleLogWriter()

    // 创建一个HashMap实例
    let hashMap = HashMap<String, LogValue>([("myKey", 123)])
    // 创建一个Array实例
    let array: Array<LogValue> = [
        1,
        true,
        3.14,
        "hello",
        DateTime.of(
            year: 2024,
            month: May,
            dayOfMonth: 22,
            timeZone: TimeZone.UTC
        ),
        Duration.second,
        Exception("error"),
        Option<String>.None
    ]

    // 写入LogWriter
    hashMap.writeTo(writer)
    array.writeTo(writer)

    println("输出样式: ${writer.buffer}")

    return 0
}
```

运行结果：

```text
输出样式: { KEY: myKey = INT: 123}[INT: 1BOOL: true FLOAT: 3.140000 STRING: hello DATETIME: 2024-05-22T00:00:00Z DURATION: 1s EXCEPTION: error NONE]
```

### func endObject()

```cangjie
public func endObject(): Unit
```

功能：结束序列化当前的 [LogValue](log_package_interfaces.md#interface-logvalue) object。

异常：

- IllegalStateException - 当前 writer 的状态不应该结束一个 [LogValue](log_package_interfaces.md#interface-logvalue) object 时。

示例：
<!-- associated_example -->
参见 [func endArray](#func-endarray) 示例。

### func startArray()

```cangjie
public func startArray(): Unit
```

功能：开始序列化一个新的 [LogValue](log_package_interfaces.md#interface-logvalue) 数组，每一个 startArray 都必须有一个 endArray 对应。

异常：

- IllegalStateException - 当前 writer 的状态不应该写入 [LogValue](log_package_interfaces.md#interface-logvalue) array 时。

示例：
<!-- associated_example -->
参见 [func endArray](#func-endarray) 示例。

### func startObject()

```cangjie
public func startObject(): Unit
```

功能：开始序列化一个新的 [LogValue](log_package_interfaces.md#interface-logvalue) object，每一个 startObject 都必须有一个 endObject 对应。

异常：

- IllegalStateException - 当前 writer 的状态不应该写入 [LogValue](log_package_interfaces.md#interface-logvalue) object 时。

示例：
<!-- associated_example -->
参见 [func endArray](#func-endarray) 示例。

### func writeBool(Bool)

```cangjie
public func writeBool(v: Bool): Unit
```

功能：向日志输出目标中写入 Bool 值。

参数：

- v: Bool - 待写入的 Bool 值。

异常：

- IllegalStateException - 当前 writer 的状态不应该写入 value 时。

示例：
<!-- associated_example -->
参见 [func endArray](#func-endarray) 示例。

### func writeDateTime(DateTime)

```cangjie
public func writeDateTime(v: DateTime): Unit
```

功能：向日志输出目标中写入 DateTime 值。

参数：

- v: DateTime - 待写入的 DateTime 值。

异常：

- IllegalStateException - 当前 writer 的状态不应该写入 value 时。

示例：
<!-- associated_example -->
参见 [func endArray](#func-endarray) 示例。

### func writeDuration(Duration)

```cangjie
public func writeDuration(v: Duration): Unit
```

功能：向日志输出目标中写入 Duration 值。

参数：

- v: Duration - 待写入的 Duration 值。

异常：

- IllegalStateException - 当前 writer 的状态不应该写入 value 时。

示例：
<!-- associated_example -->
参见 [func endArray](#func-endarray) 示例。

### func writeException(Exception)

```cangjie
public func writeException(v: Exception): Unit
```

功能：向日志输出目标中写入 Exception 值。

参数：

- v: Exception - 待写入的 Exception 值。

异常：

- IllegalStateException - 当前 writer 的状态不应该写入 value 时，抛出该异常。

示例：
<!-- associated_example -->
参见 [func endArray](#func-endarray) 示例。

### func writeFloat(Float64)

```cangjie
public func writeFloat(v: Float64): Unit
```

功能：向日志输出目标中写入 Float64 值。

参数：

- v: Float64 - 待写入的 Float64 值。

异常：

- IllegalStateException - 当前 writer 的状态不应该写入 value 时。

示例：
<!-- associated_example -->
参见 [func endArray](#func-endarray) 示例。

### func writeInt(Int64)

```cangjie
public func writeInt(v: Int64): Unit
```

功能：向日志输出目标中写入 Int64 值。

参数：

- v: Int64 - 待写入的 Int64 值。

异常：

- IllegalStateException - 当前 writer 的状态不应该写入 value 时。

示例：
<!-- associated_example -->
参见 [func endArray](#func-endarray) 示例。

### func writeKey(String)

```cangjie
public func writeKey(v: String): Unit
```

功能：向日志输出目标中写入参数 `v` 指定的键名。

参数：

- v: String - 待写入的 Key 值。

异常：

- IllegalStateException - 当前 writer 的状态不应写入参数 `v` 指定字符串时。

示例：
<!-- associated_example -->
参见 [func endArray](#func-endarray) 示例。

### func writeNone()

```cangjie
public func writeNone(): Unit
```

功能：向日志输出目标中写入 None，具体写成什么格式由 Logger 的提供者自行决定。

异常：

- IllegalStateException - 当前 writer 的状态不应该写入 value 时。

示例：
<!-- associated_example -->
参见 [func endArray](#func-endarray) 示例。

### func writeString(String)

```cangjie
public func writeString(v: String): Unit
```

功能：向日志输出目标中写入 String 值。

参数：

- v: String  - 待写入的 String 值。

异常：

- IllegalStateException - 当前 writer 的状态不应该写入 value 时。

示例：
<!-- associated_example -->
参见 [func endArray](#func-endarray) 示例。

### func writeValue(LogValue)

```cangjie
public func writeValue(v: LogValue): Unit
```

功能：将实现了 [LogValue](log_package_interfaces.md#interface-logvalue) 接口的类型写入到日志输出目标中。该接口会调用 [LogValue](log_package_interfaces.md#interface-logvalue) 的 [writeTo](log_package_interfaces.md#func-writetologwriter) 方法向日志输出目标中写入数据。

log 包已经为基础类型 Int64、Float64、Bool、String 类型扩展实现了 [LogValue](log_package_interfaces.md#interface-logvalue)，并且为 DateTime、Duration、Exception、Collection 类型 Array、HashMap 和 TreeMap 以及 Option\<T> 扩展实现了 [LogValue](log_package_interfaces.md#interface-logvalue)。

参数：

- v: [LogValue](log_package_interfaces.md#interface-logvalue) - 待写入的 [LogValue](log_package_interfaces.md#interface-logvalue) 值。

异常：

- IllegalStateException - 当前 writer 的状态不应该写入 value 时。

示例：
<!-- associated_example -->
参见 [func endArray](#func-endarray) 示例。

## class NoopLogger

```cangjie
public class NoopLogger <: Logger {
    public init()
}
```

功能：[Logger](#class-logger) 的 NO-OP（无操作）实现，会丢弃所有的日志。

父类型：

- [Logger](#class-logger)

### prop level

```cangjie
public mut prop level: LogLevel
```

功能：永远只能获取到 OFF 日志打印级别，设置日志打印级别不会生效。

类型：[LogLevel](log_package_structs.md#struct-loglevel)

示例：

<!-- verify -->
```cangjie
import stdx.log.*

main() {
    // 创建一个NoopLogger实例
    let logger = NoopLogger()

    // 获取当前日志级别
    let currentLevel = logger.level
    println("初始日志级别: ${currentLevel}")

    // 尝试设置日志级别（不会生效）
    logger.level = LogLevel.DEBUG
    let newLevel = logger.level
    println("设置后的日志级别: ${newLevel}")

    return 0
}
```

运行结果：

```text
初始日志级别: OFF
设置后的日志级别: OFF
```

### init()

```cangjie
public init()
```

功能：创建一个 [NoopLogger](log_package_classes.md#class-nooplogger) 实例。

示例：

<!-- run -->
```cangjie
import stdx.log.*

main() {
    // 创建一个NoopLogger实例
    let logger = NoopLogger()
    return 0
}
```

### func close()

```cangjie
public func close(): Unit
```

功能：NOOP 实现。

示例：

<!-- verify -->
```cangjie
import stdx.log.*

main() {
    // 创建一个NoopLogger实例
    let logger = NoopLogger()

    // 调用close方法
    logger.close()

    println("close方法调用完成（无操作，空实现）")

    return 0
}
```

运行结果：

```text
close方法调用完成（无操作，空实现）
```

### func isClosed()

```cangjie
public func isClosed(): Bool
```

功能：NOOP 实现。

返回值：

- Bool - 是否关闭。

示例：

<!-- verify -->
```cangjie
import stdx.log.*

main() {
    // 创建一个NoopLogger实例
    let logger = NoopLogger()

    // 检查是否关闭
    let isClosed = logger.isClosed()
    println("日志记录器是否关闭（无操作，空实现）: ${isClosed}")

    return 0
}
```

运行结果：

```text
日志记录器是否关闭（无操作，空实现）: false
```

### func log(LogLevel, () -> String, Array\<Attr>)

```cangjie
public func log(level: LogLevel, message: () -> String, attrs: Array<Attr>): Unit
```

功能：NOOP 实现。

参数：

- level: [LogLevel](log_package_structs.md#struct-loglevel) - 日志级别。
- message: () -> String - 日志消息。
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对。

示例：

<!-- verify -->
```cangjie
import stdx.log.*

main() {
    // 创建一个NoopLogger实例
    let logger = NoopLogger()

    // 调用log方法（使用lambda表达式）
    logger.log(LogLevel.INFO, {=> "这是一条信息日志"}, [("type", "info"), ("id", 123)])

    println("log方法调用完成（无操作，空实现）")

    return 0
}
```

运行结果：

```text
log方法调用完成（无操作，空实现）
```

### func log(LogLevel, String, Array\<Attr>)

```cangjie
public func log(level: LogLevel, message: String, attrs: Array<Attr>): Unit
```

功能：NOOP 实现。

参数：

- level: [LogLevel](log_package_structs.md#struct-loglevel) - 日志级别。
- message: String - 日志消息。
- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对。

示例：

<!-- verify -->
```cangjie
import stdx.log.*

main() {
    // 创建一个NoopLogger实例
    let logger = NoopLogger()

    // 调用log方法（使用字符串消息）
    logger.log(LogLevel.WARN, "这是一条警告日志", [("type", "warn"), ("id", 456)])

    println("log方法调用完成（无操作，空实现）")

    return 0
}
```

运行结果：

```text
log方法调用完成（无操作，空实现）
```

### func log(LogRecord)

```cangjie
public func log(record: LogRecord): Unit
```

功能：NOOP 实现。

参数：

- record: [LogRecord](log_package_classes.md#class-logrecord) - 日志级别。

示例：

<!-- verify -->
```cangjie
import stdx.log.*
import std.time.*

main() {
    // 创建一个NoopLogger实例
    let logger = NoopLogger()

    // 创建一个LogRecord实例
    let record = LogRecord(DateTime.now(), LogLevel.ERROR, "这是一条错误日志", [("type", "error"), ("id", 789)])

    // 调用log方法（使用LogRecord）
    logger.log(record)

    println("log方法调用完成（无操作，空实现）")

    return 0
}
```

运行结果：

```text
log方法调用完成（无操作，空实现）
```

### func withAttrs(Array\<Attr>)

```cangjie
public func withAttrs(attrs: Array<Attr>): Logger
```

功能：NOOP 实现。

参数：

- attrs: Array\<[Attr](log_package_types.md#type-attr)> - 日志数据键值对。

返回值：

- [Logger](#class-logger) - Logger

示例：

<!-- verify -->
```cangjie
import stdx.log.*

main() {
    // 创建一个NoopLogger实例
    let logger = NoopLogger()

    // 调用withAttrs方法
    let newLogger = logger.withAttrs([("user", "admin"), ("session", "12345")])

    println("withAttrs方法调用完成（无操作，空实现）")

    return 0
}
```

运行结果：

```text
withAttrs方法调用完成（无操作，空实现）
```
