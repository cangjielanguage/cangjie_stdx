# 日志打印示例

## 库开发场景记录日志

下面是开发仓颉库时，打印日志的示例。

示例：

<!-- run -->

```cangjie
import stdx.log.*
import stdx.logger.*
import std.env.*

// 定义一个数据库连接类
public class PGConnection {
    let objId: Int64 = 1
    let logger = getGlobalLogger(("name", "PGConnection"))

    public func close(): Unit {
        // 使用 trace 级别记录日志
        logger.trace("driver conn closed", ("id", objId))
    }
}

main(): Unit {
    // 创建 SimpleLogger 并设置日志级别
    let simpleLogger = SimpleLogger(getStdOut())
    simpleLogger.level = LogLevel.TRACE
    
    // 设置为全局日志记录器
    setGlobalLogger(simpleLogger)
    
    // 使用连接类并记录日志
    var conn = PGConnection()
    conn.close()
}
```

运行结果可能如下：

```text
2024-11-21T20:16:43.33200773+08:00 TRACE driver conn closed name="PGConnection" id=1
```

## 应用程序开发场景日志打印

下面是自定义 PasswordFilter 和 TextLogger 日志打印示例。

示例：

<!-- run -->

```cangjie
import std.time.*
import std.io.*
import std.env.*
import std.collection.*
import std.sync.AtomicBool
import std.time.DateTime
import stdx.log.*

// 密码过滤器：将密码值替换为 "***"
public class PasswordFilter <: Logger {
    var _level = LogLevel.INFO
    let processor: Logger

    public init(logger: Logger) {
        processor = logger
    }

    public mut prop level: LogLevel {
        get() {
            _level
        }
        set(v) {
            _level = v
        }
    }

    public func withAttrs(attrs: Array<Attr>): Logger {
        this
    }

    public func log(level: LogLevel, message: String, attrs: Array<Attr>): Unit {
        let record: LogRecord = LogRecord(DateTime.now(), level, message, attrs)
        log(record)
    }

    public func log(level: LogLevel, message: () -> String, attrs: Array<Attr>): Unit {
        let record: LogRecord = LogRecord(DateTime.now(), level, message(), attrs)
        log(record)
    }

    // 核心过滤逻辑：将密码字段替换为 "***"
    public func log(record: LogRecord): Unit {
        var attrs = record.attrs.clone()
        for (i in 0..attrs.size) {
            var attr = attrs[i]
            if (attr[0] == "password") {
                attrs[i] = (attr[0], "***")
            }
        }
        let filteredRecord = LogRecord(record.time, record.level, record.message, attrs)
        processor.log(filteredRecord)
    }

    public func isClosed(): Bool {
        false
    }
    public func close(): Unit {}
}

main() {
    // 创建 TextLogger 并设置日志级别
    let textLogger = TextLogger(getStdOut())
    textLogger.level = LogLevel.TRACE

    // 用 PasswordFilter 包装 TextLogger
    let passwordFilter = PasswordFilter(textLogger)
    setGlobalLogger(passwordFilter)

    // 获取全局日志记录器
    let logger = getGlobalLogger([("name", "main")])
    let user = User()

    // 记录不同级别的日志
    // INFO 级别日志，密码会被过滤
    logger.info("Hello, World!", ("k1", [[1, 4], [2, 5], [3]]), ("password", "v22222"))

    // DEBUG 级别日志
    logger.debug("Logging in user ${user.name} with birthday ${user.birthdayCalendar}")

    // ERROR 级别日志，使用延迟求值
    logger.log(LogLevel.ERROR, "long-running operation msg", ("k1", 100), ("k2", user.birthdayCalendar),
        ("oper", ToStringWrapper({=> "Some long-running operation returned"})))

    // 使用源码位置注解
    logger.log(LogLevel.ERROR, "long-running operation msg", ("sourcePackage", @sourcePackage()),
        ("sourceFile", @sourceFile()), ("sourceLine", @sourceLine()), ("birthdayCalendar", user.birthdayCalendar),
        ("oper", ToStringWrapper({=> "Some long-running operation returned"})))

    // TRACE 级别日志，使用 HashMap
    let m = HashMap<String, String>()
    m.add("k1", "1")
    m.add("k2", "2")
    m.add("k3", "3")
    logger.trace({=> "Some long-running operation returned"}, ("k1", m))

    let m2 = HashMap<String, LogValue>()
    m2.add("g1", m)
    logger.trace({=> "Some long-running operation returned"}, ("k2", m2))
}

// 用户类
public class User {
    public prop name: String {
        get() {
            "foo"
        }
    }
    public prop birthdayCalendar: DateTime {
        get() {
            DateTime.now()
        }
    }
}

// 延迟求值的 ToString 包装器
public class ToStringWrapper <: ToString & LogValue {
    let _fn: () -> String
    public init(fn: () -> String) {
        _fn = fn
    }
    public func toString(): String {
        _fn()
    }
    public func writeTo(w: LogWriter): Unit {
        w.writeValue(_fn())
    }
}

// 自定义文本日志记录器
public class TextLogger <: Logger {
    let w: TextLogWriter
    let _closed = AtomicBool(false)
    let bo: BufferedOutputStream<OutputStream>
    let _attrs = ArrayList<Attr>()
    var _level = LogLevel.INFO

    public init(output: OutputStream) {
        bo = BufferedOutputStream<OutputStream>(output)
        w = TextLogWriter(bo)
    }

    public mut prop level: LogLevel {
        get() {
            _level
        }
        set(v) {
            _level = v
        }
    }

    public func withAttrs(attrs: Array<Attr>): Logger {
        if (attrs.size > 0) {
            let nl = TextLogger(w.out)
            nl._attrs.add(all: attrs)
            return nl
        }
        return this
    }

    public func log(level: LogLevel, message: String, attrs: Array<Attr>): Unit {
        if (this.enabled(level)) {
            let record: LogRecord = LogRecord(DateTime.now(), level, message, attrs)
            log(record)
        }
    }

    public func log(level: LogLevel, message: () -> String, attrs: Array<Attr>): Unit {
        if (this.enabled(level)) {
            let record: LogRecord = LogRecord(DateTime.now(), level, message(), attrs)
            log(record)
        }
    }

    // 格式化输出日志
    public func log(record: LogRecord): Unit {
        // write time
        w.writeKey("time")
        w.writeValue(record.time)
        w.writeString(" ")
        // write level
        w.writeKey("level")
        w.writeString(record.level.toString())
        w.writeString(" ")
        // write message
        w.writeKey("msg")
        w.writeValue(record.message)
        w.writeString(" ")
        // write source

        // write attrs
        for (i in 0..record.attrs.size) {
            let attr = record.attrs[i]
            w.writeKey(attr[0])
            w.writeValue(attr[1])
            if (i < record.attrs.size - 1) {
                w.writeString(" ")
            }
        }
        w.writeString("\n")
        bo.flush()
    }

    public func isClosed(): Bool {
        _closed.load()
    }
    public func close(): Unit {
        if (isClosed()) {
            return
        }
        _closed.store(true)
    }
}

// 文本日志写入器
class TextLogWriter <: LogWriter {
    var out: OutputStream
    init(out: OutputStream) {
        this.out = out
    }
    public func writeNone(): Unit {
        out.write("None".toArray())
    }
    public func writeInt(v: Int64): Unit {
        out.write(v.toString().toArray())
    }
    public func writeUInt(v: UInt64): Unit {
        out.write(v.toString().toArray())
    }
    public func writeBool(v: Bool): Unit {
        out.write(v.toString().toArray())
    }
    public func writeFloat(v: Float64): Unit {
        out.write(v.toString().toArray())
    }
    public func writeString(v: String): Unit {
        out.write(v.toArray())
    }
    public func writeDateTime(v: DateTime): Unit {
        out.write(v.toString().toArray())
    }
    public func writeDuration(v: Duration): Unit {
        out.write(v.toString().toArray())
    }
    public func writeException(v: Exception): Unit {
        out.write(v.toString().toArray())
    }
    public func writeKey(v: String): Unit {
        out.write(v.toString().toArray())
        out.write("=".toArray())
    }
    public func writeValue(v: LogValue): Unit {
        match (v) {
            case vv: String =>
                out.write("\"".toArray())
                out.write(vv.toArray())
                out.write("\"".toArray())
            case vv: ToString =>
                out.write("\"".toArray())
                out.write(vv.toString().toArray())
                out.write("\"".toArray())
            case _ =>
                out.write("\"".toArray())
                v.writeTo(this)
                out.write("\"".toArray())
        }
    }
    public func startArray(): Unit {
        out.write("[".toArray())
    }
    public func endArray(): Unit {
        out.write("]".toArray())
    }
    public func startObject(): Unit {
        out.write("{".toArray())
    }
    public func endObject(): Unit {
        out.write("}".toArray())
    }
}
```

运行结果可能如下：

```text
time="2026-07-14T12:13:02.121809006Z" level=INFO msg="Hello, World!" k1="[[1, 4], [2, 5], [3]]" password="***"
time="2026-07-14T12:13:02.121921099Z" level=DEBUG msg="Logging in user foo with birthday 2026-07-14T12:13:02.121918326Z" 
time="2026-07-14T12:13:02.121930263Z" level=ERROR msg="long-running operation msg" k1="100" k2="2026-07-14T12:13:02.121930072Z" oper="Some long-running operation returned"
time="2026-07-14T12:13:02.121944376Z" level=ERROR msg="long-running operation msg" sourcePackage="default" sourceFile="test01.cj" sourceLine="261" birthdayCalendar="2026-07-14T12:13:02.12194406Z" oper="Some long-running operation returned"
time="2026-07-14T12:13:02.12197184Z" level=TRACE msg="Some long-running operation returned" k1="[(k1, 1), (k2, 2), (k3, 3)]"
time="2026-07-14T12:13:02.122015002Z" level=TRACE msg="Some long-running operation returned" k2="{g1="[(k1, 1), (k2, 2), (k3, 3)]"}"
```
