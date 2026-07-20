# log

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

let server = ServerBuilder().addr("127.0.0.1").port(0).build()

main() {
    // 启动服务器
    spawn {
        startServer()
    }
    sleep(Duration.second) // 等待服务器启动

    // 构建客户端实例，开启客户端日志
    let client = ClientBuilder().build()
    client.logger.level = LogLevel.DEBUG

    // 发送请求
    let response = client.get("http://127.0.0.1:${server.port}/index")
    println("响应状态: ${response.status}")

    // 关闭客户端和服务器
    client.close()
    server.close()
}

func startServer(): Unit {
    // 注册请求处理器
    server.distributor.register("/index", {
        httpContext => httpContext.responseBuilder.body("Hello 仓颉!")
    })
    // 开启服务器端日志，设置日志级别为 DEBUG
    server.logger.level = LogLevel.DEBUG
    server.serve()
}
```

运行结果：

```text
（...大量log省略展示...）
响应状态: 200
```
