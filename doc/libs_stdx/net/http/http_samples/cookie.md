# cookie

示例：

<!-- verify -->
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

    // 构建客户端实例
    let client = ClientBuilder().build()

    // 发送第一个请求，服务器会返回 Set-Cookie 响应头
    // 客户端自动从响应头的 Set-Cookie 中读取 Cookie，存入 CookieJar
    let response1 = client.get("http://127.0.0.1:${server.port}/cookie")
    println("第一次响应状态: ${response1.status}")

    // 休眠 1 秒，等待第一个 Cookie 过期，第二个 Cookie 仍然有效
    sleep(Duration.second)
    // 发送第二个请求，客户端会自动从 CookieJar 中取出有效的 Cookie 放入请求头
    let response2 = client.get("http://127.0.0.1:${server.port}/cookie")
    println("第二次响应状态: ${response2.status}")

    // 关闭客户端和服务器
    client.close()
    server.close()
}

func startServer(): Unit {
    // 注册处理器：设置两个 Cookie
    server.distributor.register(
        "/cookie",
        {
            httpContext =>
                // 创建第一个 Cookie，过期时间为 2 秒
                let cookie1 = Cookie("cookie1", "value1", maxAge: 2, path: "/")
                // 创建第二个 Cookie，过期时间为 1 秒
                let cookie2 = Cookie("cookie2", "value2", maxAge: 1, path: "/")
                // 通过 Set-Cookie 响应头发送 Cookie
                httpContext
                    .responseBuilder
                    .header("Set-Cookie", cookie1.toSetCookieString())
                    .header("Set-Cookie", cookie2.toSetCookieString())
                    .body("Cookies已设置")
                // 打印服务器端收到的 Cookie
                let cookieHeader = httpContext.request.headers.getFirst("cookie") ?? "无Cookie"
                println("服务器收到的Cookie: ${cookieHeader}")
                httpContext.responseBuilder.body("收到Cookie: ${cookieHeader}")
        }
    )
    server.logger.level = LogLevel.OFF
    server.serve()
}
```

运行结果：

```text
服务器收到的Cookie: 无Cookie
第一次响应状态: 200
服务器收到的Cookie: cookie1=value1
第二次响应状态: 200
```