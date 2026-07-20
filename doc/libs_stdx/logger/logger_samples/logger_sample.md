# 日志打印示例

## JsonLogger 示例

[JsonLogger](../logger_package_api/logger_package_classes.md#class-jsonlogger) 输出 JSON 格式日志。

<!-- run -->

```cangjie
import std.io.{OutputStream, BufferedOutputStream}
import std.env.*
import stdx.log.*
import stdx.logger.*

main() {
    let bo = BufferedOutputStream<OutputStream>(getStdOut())
    let logger = JsonLogger(bo)
    logger.level = LogLevel.INFO
    
    logger.info("服务启动", ("port", 8080), ("mode", "production"))
    logger.warn("连接超时", ("host", "example.com"), ("timeout", 30))
    logger.error("数据库连接失败", ("error", "connection refused"))
    
    logger.close()
}
```

可能的运行结果：

```text
{"time":"2024-07-18T07:57:45Z","level":"INFO","msg":"服务启动","port":8080,"mode":"production"}
{"time":"2024-07-18T07:57:45Z","level":"WARN","msg":"连接超时","host":"example.com","timeout":30}
{"time":"2024-07-18T07:57:45Z","level":"ERROR","msg":"数据库连接失败","error":"connection refused"}
```

## SimpleLogger 示例

[SimpleLogger](../logger_package_api/logger_package_classes.md#class-simplelogger) 输出易读的纯文本格式日志。

<!-- run -->

```cangjie
import std.io.{OutputStream, BufferedOutputStream}
import std.env.*
import stdx.log.*
import stdx.logger.*

main() {
    let bo = BufferedOutputStream<OutputStream>(getStdOut())
    let logger = SimpleLogger(bo)
    logger.level = LogLevel.INFO
    
    logger.info("服务启动", ("port", 8080))
    logger.warn("内存使用率高", ("usage", "85%"))
    logger.error("请求失败", ("code", 500))
    
    logger.close()
}
```

可能的运行结果：

```text
{"time":"2026-07-15T01:52:27Z","level":"INFO","msg":"服务启动","port":8080,"mode":"production"}
{"time":"2026-07-15T01:52:27Z","level":"WARN","msg":"连接超时","host":"example.com","timeout":30}
{"time":"2026-07-15T01:52:27Z","level":"ERROR","msg":"数据库连接失败","error":"connection refused"}
```

## TextLogger 示例

[TextLogger](../logger_package_api/logger_package_classes.md#class-textlogger) 输出键值对格式日志。

<!-- run -->

```cangjie
import std.io.{OutputStream, BufferedOutputStream}
import std.env.*
import stdx.log.*
import stdx.logger.*

main() {
    let bo = BufferedOutputStream<OutputStream>(getStdOut())
    let logger = TextLogger(bo)
    logger.level = LogLevel.INFO
    
    logger.info("用户登录", ("userId", "12345"), ("ip", "192.168.1.1"))
    logger.error("支付失败", ("orderId", "ORD001"), ("reason", "余额不足"))
    
    logger.close()
}
```

可能的运行结果：

```text
time=2026-07-15T01:55:54.692673348Z level="INFO" msg="用户登录" userId="12345" ip="192.168.1.1"
time=2026-07-15T01:55:54.692751937Z level="ERROR" msg="支付失败" orderId="ORD001" reason="余额不足"
```

## 全局日志器示例

使用 `setGlobalLogger` 和 `getGlobalLogger` 在多模块间共享日志器。

<!-- run -->

```cangjie
import std.io.{OutputStream, BufferedOutputStream}
import std.env.*
import stdx.log.*
import stdx.logger.*

main() {
    let bo = BufferedOutputStream<OutputStream>(getStdOut())
    let logger = SimpleLogger(bo)
    logger.level = LogLevel.DEBUG
    
    setGlobalLogger(logger)
    let gLogger = getGlobalLogger([("module", "main")])
    
    gLogger.debug("调试信息")
    gLogger.info("处理完成", ("count", 100))
    
    gLogger.close()
}
```

可能的运行结果：

```text
2026-07-15T01:56:35.747500928Z DEBUG 调试信息 module="main"
2026-07-15T01:56:35.747543178Z INFO 处理完成 module="main" count=100
```

## 延迟求值示例

当日志级别未开启时，lambda 表达式不会执行，避免不必要的性能开销。

<!-- compile -->

```cangjie
import std.io.{OutputStream, BufferedOutputStream}
import std.env.*
import stdx.log.*
import stdx.logger.*

main() {
    let bo = BufferedOutputStream<OutputStream>(getStdOut())
    let logger = SimpleLogger(bo)
    logger.level = LogLevel.INFO
    
    logger.trace({=> "这个 lambda 不会执行，因为 TRACE 级别未开启"})
    logger.debug({=> "这个 lambda 不会执行，因为 DEBUG 级别未开启"})
    logger.info({=> "这个 lambda 会执行"})
    
    logger.close()
}
```

可能的运行结果：

```text
2026-07-15T01:57:15.306434111Z INFO 这个 lambda 会执行
```

## 源码位置示例

使用内置注解 `@sourceFile`、`@sourceLine`、`@sourcePackage` 记录日志来源。

<!-- compile -->

```cangjie
import std.io.{OutputStream, BufferedOutputStream}
import std.env.*
import stdx.log.*
import stdx.logger.*

main() {
    let bo = BufferedOutputStream<OutputStream>(getStdOut())
    let logger = SimpleLogger(bo)
    logger.level = LogLevel.ERROR

    logger.error("发生错误", ("file", @sourceFile()), ("line", @sourceLine()), ("package", @sourcePackage()))

    logger.close()
}
```

可能的运行结果：

```text
2026-07-15T01:58:10.273561192Z ERROR 发生错误 file="test.cj" line=13 package="default"
```