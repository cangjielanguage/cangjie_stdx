# 类

## class Client

```cangjie
public class Client
```

功能：发送 Http request、随时关闭等。用户可以通过 Client 实例发送 HTTP/1.1 或 HTTP/2 请求。

> **说明：**
>
> [Client](http_package_classes.md#class-client) 文档中未明确说明支持版本的配置，在 HTTP/1.1 与 HTTP/2 都会生效。

### prop autoRedirect

```cangjie
public prop autoRedirect: Bool
```

功能：客户端是否会自动进行重定向，304 状态码默认不重定向。

类型：Bool

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建启用自动重定向的Client
    let client = ClientBuilder().build()
    println("默认自动重定向设置: ${client.autoRedirect}")

    // 创建禁用自动重定向的Client
    let noRedirectClient = ClientBuilder().autoRedirect(false).build()
    println("禁用自动重定向设置: ${noRedirectClient.autoRedirect}")

    client.close()
    noRedirectClient.close()
}
```

运行结果：

```text
默认自动重定向设置: true
禁用自动重定向设置: false
```

### prop connector

```cangjie
public prop connector: (SocketAddress) -> StreamingSocket
```

功能：客户端调用此函数获取到服务器的连接。

类型：(SocketAddress) -> StreamingSocket

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import std.net.*

main(): Unit {
    // 创建Client实例
    let client = ClientBuilder().build()

    // 获取默认的connector函数
    let _ = client.connector

    // 创建自定义connector的Client
    let customConnector = {
        sa: SocketAddress =>
            let socket = TcpSocket(sa)
            socket.connect()
            return socket
    }

    // 创建自定义connector的Client实例
    let customClient = ClientBuilder().connector(customConnector).build()

    client.close()
    customClient.close()
}
```

### prop cookieJar

```cangjie
public prop cookieJar: ?CookieJar
```

功能：用于存储客户端所有 [Cookie](http_package_classes.md#class-cookie)，如果配置为 None，则不会启用 [Cookie](http_package_classes.md#class-cookie)。

类型：?[CookieJar](http_package_interfaces.md#interface-cookiejar)

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建Client实例
    let client = ClientBuilder().build()

    // 检查默认的cookieJar设置
    match (client.cookieJar) {
        case Some(jar) => println("默认启用了CookieJar")
        case None => println("默认未启用CookieJar")
    }

    // 创建禁用Cookie的Client
    let noCookieClient = ClientBuilder().cookieJar(None).build()
    match (noCookieClient.cookieJar) {
        case Some(_) => println("CookieJar仍然启用")
        case None => println("已禁用CookieJar")
    }

    client.close()
    noCookieClient.close()
}
```

运行结果：

```text
默认启用了CookieJar
已禁用CookieJar
```

### prop enablePush

```cangjie
public prop enablePush: Bool
```

功能：客户端 HTTP/2 是否支持服务器推送，默认值为 true。

类型：Bool

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建Client实例
    let client = ClientBuilder().build()

    // 检查默认的HTTP/2推送设置
    println("默认HTTP/2推送设置: ${client.enablePush}")

    // 创建禁用HTTP/2推送的Client
    let noPushClient = ClientBuilder().enablePush(false).build()
    println("禁用HTTP/2推送设置: ${noPushClient.enablePush}")

    client.close()
    noPushClient.close()
}
```

运行结果：

```text
默认HTTP/2推送设置: true
禁用HTTP/2推送设置: false
```

### prop headerTableSize

```cangjie
public prop headerTableSize: UInt32
```

功能：获取客户端 HTTP/2 Hpack 动态表的初始值，默认值为 4096。

类型：UInt32

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建Client实例
    let client = ClientBuilder().build()

    // 获取默认的HTTP/2头部表大小
    println("默认HTTP/2头部表大小: ${client.headerTableSize}")

    // 创建自定义头部表大小的Client
    let customClient = ClientBuilder().headerTableSize(8192).build()
    println("自定义HTTP/2头部表大小: ${customClient.headerTableSize}")

    client.close()
    customClient.close()
}
```

运行结果：

```text
默认HTTP/2头部表大小: 4096
自定义HTTP/2头部表大小: 8192
```

### prop httpProxy

```cangjie
public prop httpProxy: String
```

功能：获取客户端 http 代理，默认使用系统环境变量 http_proxy 的值，用字符串表示，格式为：`"http://host:port"`，例如：`"http://192.168.1.1:80"`。

类型：String

示例：

<!-- verify -->
```cangjie
import std.env.*
import stdx.net.http.*

main(): Unit {
    // 创建Client实例
    let client = ClientBuilder().build()
    println("默认HTTP代理: ${client.httpProxy}")

    // 设置一个环境变量
    setVariable("http_proxy", "http://192.168.1.1:8080")

    // 创建Client实例
    let clientWithEnv = ClientBuilder().build()

    // 获取拥有环境变量的HTTP代理设置，会使用环境变量中的值
    println("拥有环境变量的HTTP代理: ${clientWithEnv.httpProxy}")

    // 创建自定义HTTP代理的Client
    let proxyClient = ClientBuilder().httpProxy("http://192.168.1.1:8081").build()
    println("自定义HTTP代理: ${proxyClient.httpProxy}")

    client.close()
    clientWithEnv.close()
    proxyClient.close()
}
```

运行结果：

```text
默认HTTP代理: 
拥有环境变量的HTTP代理: http://192.168.1.1:8080
自定义HTTP代理: http://192.168.1.1:8081
```

### prop httpsProxy

```cangjie
public prop httpsProxy: String
```

功能：获取客户端 https 代理，默认使用系统环境变量 https_proxy 的值，用字符串表示，格式为：`"http://host:port"`，例如：`"http://192.168.1.1:443"`。

类型：String

示例：

<!-- verify -->
```cangjie
import std.env.*
import stdx.net.http.*

main(): Unit {
    // 创建Client实例
    let client = ClientBuilder().build()
    println("默认HTTPS代理: ${client.httpsProxy}")

    // 设置一个环境变量
    setVariable("https_proxy", "http://192.168.1.1:8080")

    // 创建Client实例
    let clientWithEnv = ClientBuilder().build()

    // 获取拥有环境变量的HTTPS代理设置，会使用环境变量中的值
    println("拥有环境变量的HTTPS代理: ${clientWithEnv.httpsProxy}")

    // 创建自定义HTTPS代理的Client
    let proxyClient = ClientBuilder().httpProxy("http://192.168.1.1:8081").build()
    println("自定义HTTPS代理: ${proxyClient.httpsProxy}")

    client.close()
    clientWithEnv.close()
    proxyClient.close()
}
```

运行结果：

```text
默认HTTPS代理: 
拥有环境变量的HTTPS代理: http://192.168.1.1:8080
自定义HTTPS代理: http://192.168.1.1:8080
```

### prop initialWindowSize

```cangjie
public prop initialWindowSize: UInt32
```

功能：获取客户端 HTTP/2 流控窗口初始值，默认值为 65535 ，取值范围为 0 至 2^31 - 1。

类型：UInt32

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建Client实例
    let client = ClientBuilder().build()

    // 获取默认的HTTP/2初始窗口大小
    println("默认HTTP/2初始窗口大小: ${client.initialWindowSize}")

    // 创建自定义窗口大小的Client
    let customClient = ClientBuilder().initialWindowSize(131072).build()
    println("自定义HTTP/2初始窗口大小: ${customClient.initialWindowSize}")

    client.close()
    customClient.close()
}
```

运行结果：

```text
默认HTTP/2初始窗口大小: 65535
自定义HTTP/2初始窗口大小: 131072
```

### prop logger

```cangjie
public prop logger: Logger
```

功能：获取客户端日志记录器，设置 logger.level 将立即生效，记录器应该是线程安全的。

类型：[Logger](../../../log/log_package_api/log_package_classes.md#class-logger)

示例：

<!-- verify -->
```cangjie
import stdx.log.*
import stdx.net.http.*

main(): Unit {
    // 创建Client实例
    let client = ClientBuilder().build()

    // 只要设置就会生效
    client.logger.level = LogLevel.WARN

    // 获取当前日志记录器等级
    let defaultLogger = client.logger
    println("当前日志记录器等级: ${defaultLogger.level}")

    client.close()
}
```

运行结果：

```text
当前日志记录器等级: WARN
```

### prop maxConcurrentStreams

```cangjie
public prop maxConcurrentStreams: UInt32
```

功能：获取客户端 HTTP/2 初始最大并发流数量，默认值为 2^31 - 1。

类型：UInt32

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建Client实例
    let client = ClientBuilder().build()

    // 获取默认的HTTP/2最大并发流数
    println("默认HTTP/2最大并发流数: ${client.maxConcurrentStreams}")

    // 创建自定义并发流数的Client
    let customClient = ClientBuilder().maxConcurrentStreams(100).build()
    println("自定义HTTP/2最大并发流数: ${customClient.maxConcurrentStreams}")

    client.close()
    customClient.close()
}
```

运行结果：

```text
默认HTTP/2最大并发流数: 2147483647
自定义HTTP/2最大并发流数: 100
```

### prop maxFrameSize

```cangjie
public prop maxFrameSize: UInt32
```

功能：获取客户端 HTTP/2 初始最大帧大小。默认值为 16384. 取值范围为 2^14 至 2^24 - 1。

类型：UInt32

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建Client实例
    let client = ClientBuilder().build()

    // 获取默认的HTTP/2最大帧大小
    println("默认HTTP/2最大帧大小: ${client.maxFrameSize}")

    // 创建自定义帧大小的Client
    let customClient = ClientBuilder().maxFrameSize(32768).build()
    println("自定义HTTP/2最大帧大小: ${customClient.maxFrameSize}")

    client.close()
    customClient.close()
}
```

运行结果：

```text
默认HTTP/2最大帧大小: 16384
自定义HTTP/2最大帧大小: 32768
```

### prop maxHeaderListSize

```cangjie
public prop maxHeaderListSize: UInt32
```

功能：获取客户端支持的 HTTP/2 最大头部（Header）大小。这个大小指的是响应头部中所有头部字段（Header Field）的最大允许长度之和，其中包括所有字段名称（name）的长度、字段值（value）的长度以及每个字段自动添加的伪头开销（通常每个字段会有 32 字节的开销，这包括了 HTTP/2 协议本身为头部字段添加的伪头部信息）。默认情况下，这个最大长度被设置为 UInt32.Max。

类型：UInt32

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建Client实例
    let client = ClientBuilder().build()

    // 获取默认的HTTP/2最大头部列表大小
    println("默认HTTP/2最大头部列表大小: ${client.maxHeaderListSize}")

    // 创建自定义头部列表大小的Client
    let customClient = ClientBuilder().maxHeaderListSize(65536).build()
    println("自定义HTTP/2最大头部列表大小: ${customClient.maxHeaderListSize}")

    client.close()
    customClient.close()
}
```

运行结果：

```text
默认HTTP/2最大头部列表大小: 4294967295
自定义HTTP/2最大头部列表大小: 65536
```

### prop poolSize

```cangjie
public prop poolSize: Int64
```

功能：配置 HTTP/1.1 客户端使用的连接池的大小，亦可表示对同一个主机（host:port）同时存在的连接数的最大值。

类型：Int64

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建Client实例
    let client = ClientBuilder().build()

    // 获取默认的连接池大小
    println("默认连接池大小: ${client.poolSize}")

    // 创建自定义连接池大小的Client
    let customClient = ClientBuilder().poolSize(20).build()
    println("自定义连接池大小: ${customClient.poolSize}")

    client.close()
    customClient.close()
}
```

运行结果：

```text
默认连接池大小: 10
自定义连接池大小: 20
```

### prop readTimeout

```cangjie
public prop readTimeout: Duration
```

功能：获取客户端设定的读取整个响应的超时时间，默认值为 15 秒。

类型：Duration

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建Client实例
    let client = ClientBuilder().build()

    // 获取默认的读取超时时间
    println("默认读取超时时间: ${client.readTimeout}")

    // 创建自定义读取超时时间的Client
    let customClient = ClientBuilder().readTimeout(Duration.second * 30).build()
    println("自定义读取超时时间: ${customClient.readTimeout}")

    client.close()
    customClient.close()
}
```

运行结果：

```text
默认读取超时时间: 15s
自定义读取超时时间: 30s
```

### prop writeTimeout

```cangjie
public prop writeTimeout: Duration
```

功能：获取客户端设定的写请求的超时时间，默认值为 15 秒。

类型：Duration

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建Client实例
    let client = ClientBuilder().build()

    // 获取默认的写入超时时间
    println("默认写入超时时间: ${client.writeTimeout}")

    // 创建自定义写入超时时间的Client
    let customClient = ClientBuilder().writeTimeout(Duration.second * 30).build()
    println("自定义写入超时时间: ${customClient.writeTimeout}")

    client.close()
    customClient.close()
}
```

运行结果：

```text
默认写入超时时间: 15s
自定义写入超时时间: 30s
```

### func close()

```cangjie
public func close(): Unit
```

功能：关闭客户端建立的所有连接，调用后不能继续发送请求。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建Client实例
    let client = ClientBuilder().build()

    // 关闭Client
    client.close()
}
```

### func connect(String, HttpHeaders, Protocol)

```cangjie
public func connect(url: String, header!: HttpHeaders = HttpHeaders(), version!: Protocol = HTTP1_1): (HttpResponse, ?StreamingSocket)
```

功能：发送 CONNECT 请求与服务器建立隧道，返回建连成功后的连接，连接由用户负责关闭。服务器返回 2xx 表示建连成功，否则建连失败（不支持自动重定向，3xx 也视为失败）。

参数：

- url: String - 请求的 url。
- header!: [HttpHeaders](http_package_classes.md#class-httpheaders) - 请求头，默认为空请求头。
- version!: [Protocol](http_package_enums.md#enum-protocol) - 请求的协议，默认为 [HTTP1_1](./http_package_enums.md#enum-protocol)。

返回值：

- ([HttpResponse](http_package_classes.md#class-httpresponse), ?StreamingSocket) - 返回元组类型，其中 [HttpResponse](http_package_classes.md#class-httpresponse) 实例表示服务器返回的响应体，Option\<StreamingSocket> 实例表示请求成功时返回 headers 之后连接。

异常：

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - 当参数 url 不符合 [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) 解析规范时，抛出异常。
- IllegalArgumentException - 当被编码的字符不符合 UTF-8 的字节序列规则时，抛出异常。
- 其余同 func send。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 启动服务器
    spawn {
        =>
            // 构建 Server 实例
            let server = ServerBuilder().addr("127.0.0.1").port(8080).build()
            // 注册 HttpRequestHandler
            server.distributor.register("", {
                httpContext => httpContext.responseBuilder.status(200)
            })
            server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 创建客户端
    let client = ClientBuilder().build()

    // 向服务器发起connect请求
    let (resp, _) = client.connect("http://127.0.0.1:8080")
    println("建立隧道成功, 状态码: ${resp.status}")
}
```

运行结果：

```text
建立隧道成功, 状态码: 200
```

### func delete(String)

```cangjie
public func delete(url: String): HttpResponse
```

功能：请求方法为 DELETE 的便捷请求函数。

参数：

- url: String - 请求的 url。

返回值：

- [HttpResponse](http_package_classes.md#class-httpresponse) - 服务端返回的响应。

异常：

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - 当参数 url 不符合 [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) 解析规范时，抛出异常。
- IllegalArgumentException - 当被编码的字符不符合 UTF-8 的字节序列规则时，抛出异常。
- 其余同 func send。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 启动服务器
    spawn {
        =>
            let server = ServerBuilder().addr("127.0.0.1").port(8080).build()
            server.distributor.register("/delete-test", {
                httpContext => if (httpContext.request.method == "DELETE") {
                    httpContext.responseBuilder.status(200).body("Resource deleted successfully")
                } else {
                    httpContext.responseBuilder.status(405).body("Method Not Allowed")
                }
            })
            server.serve()
    }
    // 等待服务器启动
    sleep(Duration.second)

    // 创建Client实例
    let client = ClientBuilder().build()

    // 发送DELETE请求
    let response = client.delete("http://127.0.0.1:8080/delete-test")
    println("响应状态码: ${response.status}")

    // 读取响应体
    let bodyBuf = Array<UInt8>(1024, repeat: 0)
    let readLength = response.body.read(bodyBuf)
    println("响应体: ${String.fromUtf8(bodyBuf[..readLength])}")
}
```

运行结果：

```text
响应状态码: 200
响应体: Resource deleted successfully
```

### func get(String)

```cangjie
public func get(url: String): HttpResponse
```

功能：请求方法为 GET 的便捷请求函数。

参数：

- url: String - 请求的 url。

返回值：

- [HttpResponse](http_package_classes.md#class-httpresponse) - 服务端返回的响应。

异常：

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - 当参数 url 不符合 [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) 解析规范时，抛出异常。
- IllegalArgumentException - 当被编码的字符不符合 UTF-8 的字节序列规则时，抛出异常。
- 其余同 func send。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 启动服务器
    spawn {
        =>
            // 构建 Server 实例
            let server = ServerBuilder().addr("127.0.0.1").port(8080).build()
            // 注册 HttpRequestHandler
            server.distributor.register("/index", {
                httpContext => httpContext.responseBuilder.body("Hello 仓颉!")
            })
            // 启动服务
            server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 创建 Client
    let client = ClientBuilder().build()
    // 发送GET请求
    let resp = client.get("http://127.0.0.1:8080/index")

    // 读取响应体
    let bodyBuf = Array<UInt8>(1024, repeat: 0)
    let bytesRead = resp.body.read(bodyBuf)
    println("响应体: ${String.fromUtf8(bodyBuf[..bytesRead])}")
}
```

运行结果：

```text
响应体: Hello 仓颉!
```

### func getTlsConfig()

```cangjie
public func getTlsConfig(): ?TlsConfig
```

功能：获取客户端设定的 TLS 层配置。

返回值：

- ?[TlsConfig](../../tls/common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconfig) - 客户端设定的 TLS 层配置，如果没有设置则返回 None。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建普通Client实例
    let client = ClientBuilder().build()

    // 检查默认的TLS配置
    match (client.getTlsConfig()) {
        case Some(config) => println("找到了TLS配置")
        case None => println("未设置TLS配置")
    }

    client.close()
}
```

运行结果：

```text
未设置TLS配置
```

### func head(String)

```cangjie
public func head(url: String): HttpResponse
```

功能：请求方法为 HEAD 的便捷请求函数。

参数：

- url: String - 请求的 url。

返回值：

- [HttpResponse](http_package_classes.md#class-httpresponse) - 服务端返回的响应。

异常：

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - 当参数 url 不符合 [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) 解析规范时，抛出异常。
- IllegalArgumentException - 当被编码的字符不符合 UTF-8 的字节序列规则时，抛出异常。
- 其余同 func send。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 启动服务器
    spawn {
        =>
            // 构建 Server 实例
            let server = ServerBuilder().addr("127.0.0.1").port(8080).build()
            // 注册 HttpRequestHandler
            server.distributor.register("/index", {
                httpContext => httpContext.responseBuilder.status(200)
            })
            server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 创建客户端
    let client = ClientBuilder().build()

    // 发送HEAD请求
    let resp = client.head("http://127.0.0.1:8080/index")
    println("状态码: ${resp.status}")
}
```

运行结果：

```text
状态码: 200
```

### func options(String)

```cangjie
public func options(url: String): HttpResponse
```

功能：请求方法为 OPTIONS 的便捷请求函数。

参数：

- url: String - 请求的 url。

返回值：

- [HttpResponse](http_package_classes.md#class-httpresponse) - 服务端返回的响应。

异常：

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - 当参数 url 不符合 [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) 解析规范时，抛出异常。
- IllegalArgumentException - 当被编码的字符不符合 UTF-8 的字节序列规则时，抛出异常。
- 其余同 func send。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 启动测试服务器
    spawn {
        =>
            let server = ServerBuilder().addr("127.0.0.1").port(8084).build()
            server.distributor.register("/options-test", {
                httpContext => if (httpContext.request.method == "OPTIONS") {
                    httpContext
                        .responseBuilder
                        .status(200)
                        .header("Allow", "OPTIONS, GET, HEAD, POST, PUT, DELETE")
                        .header("Content-Length", "0")
                } else {
                    httpContext.responseBuilder.status(405).body("Method Not Allowed")
                }
            })
            server.serve()
    }
    // 等待服务器启动
    sleep(Duration.second)

    // 创建Client实例
    let client = ClientBuilder().build()

    // 发送OPTIONS请求
    let response = client.options("http://127.0.0.1:8084/options-test")
    println("响应状态码: ${response.status}")
    println("允许的方法: ${response.headers.getFirst("allow") ?? "未设置"}")
}
```

运行结果：

```text
响应状态码: 200
允许的方法: OPTIONS, GET, HEAD, POST, PUT, DELETE
```

### func post(String, Array\<UInt8>)

```cangjie
public func post(url: String, body: Array<UInt8>): HttpResponse
```

功能：请求方法为 POST 的便捷请求函数。

参数：

- url: String - 请求的 url。
- body: Array\<UInt8> - 请求体。

返回值：

- [HttpResponse](http_package_classes.md#class-httpresponse) - 服务端返回的响应。

异常：

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - 当参数 url 不符合 [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) 解析规范时，抛出异常。
- IllegalArgumentException - 当被编码的字符不符合 UTF-8 的字节序列规则时，抛出异常。
- 其余同 func send。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 启动服务器
    spawn {
        =>
            let server = ServerBuilder().addr("127.0.0.1").port(8088).build()
            server.distributor.register("/post-bytes", {
                httpContext => if (httpContext.request.method == "POST") {
                    // 读取请求体
                    let bodyBuf = Array<UInt8>(1024, repeat: 0)
                    let readLength = httpContext.request.body.read(bodyBuf)
                    println("服务端收到请求体: ${String.fromUtf8(bodyBuf[..readLength])}")

                    httpContext.responseBuilder.status(200).body("收到${readLength}字节的POST请求")
                } else {
                    httpContext.responseBuilder.status(405).body("Method Not Allowed")
                }
            })
            server.serve()
    }
    // 等待服务器启动
    sleep(Duration.second)

    // 创建Client实例
    let client = ClientBuilder().build()

    // 发送POST请求（字节数组形式的请求体）
    let postData: Array<UInt8> = [72, 101, 108, 108, 111, 32, 228, 184, 150, 231, 149, 140, 33] // "Hello 世界!"
    let response = client.post("http://127.0.0.1:8088/post-bytes", postData)
    println("响应状态码: ${response.status}")

    // 读取响应体
    let bodyBuf = Array<UInt8>(1024, repeat: 0)
    let readLength = response.body.read(bodyBuf)
    println("响应体: ${String.fromUtf8(bodyBuf[..readLength])}")
}
```

运行结果：

```text
服务端收到请求体: Hello 世界!
响应状态码: 200
响应体: 收到13字节的POST请求
```

### func post(String, InputStream)

```cangjie
public func post(url: String, body: InputStream): HttpResponse
```

功能：请求方法为 POST 的便捷请求函数。

参数：

- url: String - 请求的 url。
- body: InputStream - 请求体。

返回值：

- [HttpResponse](http_package_classes.md#class-httpresponse) - 服务端返回的响应。

异常：

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - 当参数 url 不符合 [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) 解析规范时，抛出异常。
- IllegalArgumentException - 当被编码的字符不符合 UTF-8 的字节序列规则时，抛出异常。
- 其余同 func send。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.net.http.*

main(): Unit {
    // 启动服务器
    spawn {
        =>
            let server = ServerBuilder().addr("127.0.0.1").port(8089).build()
            server.distributor.register("/post-stream", {
                httpContext => if (httpContext.request.method == "POST") {
                    // 读取请求体
                    let bodyBuf = Array<UInt8>(1024, repeat: 0)
                    let readLength = httpContext.request.body.read(bodyBuf)
                    println("服务端收到请求体: ${String.fromUtf8(bodyBuf[..readLength])}")

                    httpContext.responseBuilder.status(200).body("收到${readLength}字节的流式POST请求")
                } else {
                    httpContext.responseBuilder.status(405).body("Method Not Allowed")
                }
            })
            server.serve()
    }
    // 等待服务器启动
    sleep(Duration.second)

    // 创建Client实例
    let client = ClientBuilder().build()

    // 创建字节数组输入流
    let dataBytes: Array<UInt8> = [72, 101, 108, 108, 111, 32, 228, 184, 150, 231, 149, 140, 33] // "Hello 世界!"
    let inputStream = ByteBuffer(dataBytes)

    // 发送POST请求（InputStream形式的请求体）
    let response = client.post("http://127.0.0.1:8089/post-stream", inputStream)
    println("响应状态码: ${response.status}")

    // 读取响应体
    let bodyBuf = Array<UInt8>(1024, repeat: 0)
    let readLength = response.body.read(bodyBuf)
    println("响应体: ${String.fromUtf8(bodyBuf[..readLength])}")
}
```

运行结果：

```text
服务端收到请求体: Hello 世界!
响应状态码: 200
响应体: 收到13字节的流式POST请求
```

### func post(String, String)

```cangjie
public func post(url: String, body: String): HttpResponse
```

功能：请求方法为 POST 的便捷请求函数。

参数：

- url: String - 请求的 url。
- body: String - 请求体。

返回值：

- [HttpResponse](http_package_classes.md#class-httpresponse) - 服务端返回的响应。

异常：

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - 当参数 url 不符合 [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) 解析规范时，抛出异常。
- IllegalArgumentException - 当被编码的字符不符合 UTF-8 的字节序列规则时，抛出异常。
- 其余同 func send。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.net.http.*

main(): Unit {
    // 启动服务器
    spawn {
        =>
            let server = ServerBuilder().addr("127.0.0.1").port(8090).build()
            server.distributor.register("/post-string", {
                httpContext => if (httpContext.request.method == "POST") {
                    // 读取请求体
                    let bodyBuf = Array<UInt8>(1024, repeat: 0)
                    let readLength = httpContext.request.body.read(bodyBuf)
                    let requestBody = String.fromUtf8(bodyBuf[..readLength])
                    println("服务端收到请求体: ${requestBody}")

                    httpContext.responseBuilder.status(200).body("收到POST请求，内容长度: ${readLength}")
                } else {
                    httpContext.responseBuilder.status(405).body("Method Not Allowed")
                }
            })
            server.serve()
    }
    // 等待服务器启动
    sleep(Duration.second)

    // 创建Client实例
    let client = ClientBuilder().build()

    // 发送POST请求（字符串形式的请求体）
    let postData = "Hello 仓颉 HTTP!"
    let response = client.post("http://127.0.0.1:8090/post-string", postData)
    println("响应状态码: ${response.status}")

    // 读取响应体
    let bodyBuf = Array<UInt8>(1024, repeat: 0)
    let readLength = response.body.read(bodyBuf)
    println("响应体: ${String.fromUtf8(bodyBuf[..readLength])}")
}
```

运行结果：

```text
服务端收到请求体: Hello 仓颉 HTTP!
响应状态码: 200
响应体: 收到POST请求，内容长度: 18
```

### func put(String, Array\<UInt8>)

```cangjie
public func put(url: String, body: Array<UInt8>): HttpResponse
```

功能：请求方法为 PUT 的便捷请求函数。

参数：

- url: String - 请求的 url。
- body: Array\<UInt8> - 请求体。

返回值：

- [HttpResponse](http_package_classes.md#class-httpresponse) - 服务端返回的响应。

异常：

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - 当参数 url 不符合 [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) 解析规范时，抛出异常。
- IllegalArgumentException - 当被编码的字符不符合 UTF-8 的字节序列规则时，抛出异常。
- 其余同 func send。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.net.http.*

main(): Unit {
    // 启动服务器
    spawn {
        =>
            let server = ServerBuilder().addr("127.0.0.1").port(8091).build()
            server.distributor.register("/put-bytes", {
                httpContext => if (httpContext.request.method == "PUT") {
                    // 读取请求体
                    let bodyBuf = Array<UInt8>(1024, repeat: 0)
                    let readLength = httpContext.request.body.read(bodyBuf)
                    let requestBody = String.fromUtf8(bodyBuf[..readLength])
                    println("服务端收到请求体: ${requestBody}")

                    httpContext.responseBuilder.status(200).body("收到${readLength}字节的PUT请求")
                } else {
                    httpContext.responseBuilder.status(405).body("Method Not Allowed")
                }
            })
            server.serve()
    }
    // 等待服务器启动
    sleep(Duration.second)

    // 创建Client实例
    let client = ClientBuilder().build()

    // 发送PUT请求（字节数组形式的请求体）
    let putData: Array<UInt8> = [72, 101, 108, 108, 111, 32, 228, 184, 150, 231, 149, 140, 33] // "Hello 世界!"
    let response = client.put("http://127.0.0.1:8091/put-bytes", putData)
    println("响应状态码: ${response.status}")

    // 读取响应体
    let bodyBuf = Array<UInt8>(1024, repeat: 0)
    let readLength = response.body.read(bodyBuf)
    println("响应体: ${String.fromUtf8(bodyBuf[..readLength])}")
}
```

运行结果：

```text
服务端收到请求体: Hello 世界!
响应状态码: 200
响应体: 收到13字节的PUT请求
```

### func put(String, InputStream)

```cangjie
public func put(url: String, body: InputStream): HttpResponse
```

功能：请求方法为 PUT 的便捷请求函数。

参数：

- url: String - 请求的 url。
- body: InputStream - 请求体。

返回值：

- [HttpResponse](http_package_classes.md#class-httpresponse) - 服务端返回的响应。

异常：

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - 当参数 url 不符合 [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) 解析规范时，抛出异常。
- IllegalArgumentException - 当被编码的字符不符合 UTF-8 的字节序列规则时，抛出异常。
- 其余同 func send。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.net.http.*

main(): Unit {
    // 启动服务器
    spawn {
        =>
            let server = ServerBuilder().addr("127.0.0.1").port(8092).build()
            server.distributor.register("/put-stream", {
                httpContext => if (httpContext.request.method == "PUT") {
                    // 读取请求体
                    let bodyBuf = Array<UInt8>(1024, repeat: 0)
                    let readLength = httpContext.request.body.read(bodyBuf)
                    let requestBody = String.fromUtf8(bodyBuf[..readLength])
                    println("服务端收到请求体: ${requestBody}")

                    httpContext.responseBuilder.status(200).body("收到${readLength}字节的流式PUT请求")
                } else {
                    httpContext.responseBuilder.status(405).body("Method Not Allowed")
                }
            })
            server.serve()
    }
    // 等待服务器启动
    sleep(Duration.second)

    // 创建Client实例
    let client = ClientBuilder().build()

    // 创建字节数组输入流
    let updateBytes: Array<UInt8> = [83, 116, 114, 101, 97, 109, 105, 110, 103, 32, 117, 112, 100, 97, 116, 101] // "Streaming update"
    let inputStream = ByteBuffer(updateBytes)

    // 发送PUT请求（InputStream形式的请求体）
    let response = client.put("http://127.0.0.1:8092/put-stream", inputStream)
    println("响应状态码: ${response.status}")

    // 读取响应体
    let bodyBuf = Array<UInt8>(1024, repeat: 0)
    let readLength = response.body.read(bodyBuf)
    println("响应体: ${String.fromUtf8(bodyBuf[..readLength])}")
}
```

运行结果：

```text
服务端收到请求体: Streaming update
响应状态码: 200
响应体: 收到16字节的流式PUT请求
```

### func put(String, String)

```cangjie
public func put(url: String, body: String): HttpResponse
```

功能：请求方法为 PUT 的便捷请求函数。

参数：

- url: String - 请求的 url。
- body: String - 请求体。

返回值：

- [HttpResponse](http_package_classes.md#class-httpresponse) - 服务端返回的响应。

异常：

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - 当参数 url 不符合 [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) 解析规范时，抛出异常。
- IllegalArgumentException - 当被编码的字符不符合 UTF-8 的字节序列规则时，抛出异常。
- 其余同 func send。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.net.http.*

main(): Unit {
    // 启动服务器
    spawn {
        =>
            let server = ServerBuilder().addr("127.0.0.1").port(8093).build()
            server.distributor.register("/put-string", {
                httpContext => if (httpContext.request.method == "PUT") {
                    // 读取请求体
                    let bodyBuf = Array<UInt8>(1024, repeat: 0)
                    let readLength = httpContext.request.body.read(bodyBuf)
                    let requestBody = String.fromUtf8(bodyBuf[..readLength])
                    println("服务端收到请求体: ${requestBody}")

                    httpContext.responseBuilder.status(200).body("收到PUT请求，内容长度${readLength}")
                } else {
                    httpContext.responseBuilder.status(405).body("Method Not Allowed")
                }
            })
            server.serve()
    }
    // 等待服务器启动
    sleep(Duration.second)

    // 创建Client实例
    let client = ClientBuilder().build()

    // 发送PUT请求（字符串形式的请求体）
    let putData = "Update 仓颉 HTTP data"
    let response = client.put("http://127.0.0.1:8093/put-string", putData)
    println("响应状态码: ${response.status}")

    // 读取响应体
    let bodyBuf = Array<UInt8>(1024, repeat: 0)
    let readLength = response.body.read(bodyBuf)
    println("响应体: ${String.fromUtf8(bodyBuf[..readLength])}")
}
```

运行结果：

```text
服务端收到请求体: Update 仓颉 HTTP data
响应状态码: 200
响应体: 收到PUT请求，内容长度23
```

### func send(HttpRequest)

```cangjie
public func send(req: HttpRequest): HttpResponse
```

功能：通用请求函数，发送 [HttpRequest](http_package_classes.md#class-httprequest) 到 url 中的服务器，接收 [HttpResponse](http_package_classes.md#class-httpresponse)。

> **注意：**
>
> - 对于 HTTP/1.1，如果请求中有 body 要发，那么需要保证 Content-Length 和 Transfer-Encoding: chunked 必有且只有一个，以 chunked 形式发时，每段 chunk 最大为 8192 字节；如果用户发送的 body 为自己实现的 InputStream 类，则需要自己保证 Content-Length 和 Transfer-Encoding: chunked 设置且只设置了一个；如果用户采用默认的 body 发送，Content-Length 和 Transfer-Encoding: chunked 都缺失时，我们会为其补上 Content-Length header，值为 body.size；
> - 用户如果设置了 Content-Length，则需要保证其正确性：如果所发 body 的内容大于等于 Content-Length 的值，我们会发送长度为 Content-Length 值的数据；如果所发 body 的内容小于 Content-Length 的值，此时如果 body 是默认的 body，则会抛出 [HttpException](http_package_exceptions.md#class-httpexception)，如果 body 是用户自己实现的 InputStream 类，其行为便无法保证（可能会造成服务器端的读 request 超时或者客户端的收 response 超时）；
> - 升级函数通过 [WebSocket](http_package_classes.md#class-websocket) 的 upgradeFromClient 或 [Client](http_package_classes.md#class-client) 的 [upgrade](http_package_funcs.md#func-upgradehttpcontext) 接口发出，调用 client 的其他函数发送 [upgrade](http_package_funcs.md#func-upgradehttpcontext) 请求会抛出异常；
> - 协议规定 TRACE 请求无法携带内容，故用户发送带有 body 的 TRACE 请求时会抛出异常；
> - HTTP/1.1 默认对同一个服务器的连接数不超过 10 个。response 的 body 需要用户调用 `body.read(buf: Array<Byte>)` 函数去读。body 被读完后，连接才能被客户端对象复用，否则请求相同的服务器也会新建连接。新建连接时如果连接数超出限制则会抛出 [HttpException](http_package_exceptions.md#class-httpexception)；
> - body.read 函数将 body 读完之后返回 0，如果读的时候连接断开会抛出 [ConnectionException](http_package_exceptions.md#class-connectionexception)；
> - HTTP/1.1 的升级请求如果收到 101 响应，则表示切换协议，此连接便不归 client 管理；
> - 下文的快捷请求函数的注意点与 send 相同。

参数：

- req: [HttpRequest](http_package_classes.md#class-httprequest) - 发送的请求。

返回值：

- [HttpResponse](http_package_classes.md#class-httpresponse) - 服务端返回处理该请求的响应。

异常：

- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - 请求中 [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) 错误时抛此异常。
- SocketException - Socket 连接出现错误时抛此异常。
- [ConnectionException](http_package_exceptions.md#class-connectionexception) - 从连接中读数据时对端已关闭连接抛此异常。
- SocketTimeoutException - Socket 连接超时抛此异常。
- [TlsException](../../tls/common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - Tls 连接建立失败或通信异常抛此异常。
- [HttpException](http_package_exceptions.md#class-httpexception) - 当用户未使用 http 库提供的 API 升级 [WebSocket](http_package_classes.md#class-websocket) 时抛此异常。
- [HttpTimeoutException](http_package_exceptions.md#class-httptimeoutexception) - 请求超时或读 [HttpResponse](http_package_classes.md#class-httpresponse).body 超时抛此异常。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.net.http.*

main(): Unit {
    // 启动服务器
    spawn {
        =>
            let server = ServerBuilder().addr("127.0.0.1").port(8094).build()
            server.distributor.register(
                "/custom-request",
                {
                    httpContext =>
                        let request = httpContext.request
                        let method = request.method
                        let path = request.url.path
                        let userAgent = request.headers.getFirst("user-agent")
                        request.body
                        println("服务端收到请求: 方法=${method}, 路径=${path}, User-Agent=${userAgent ?? "未知"}")

                        httpContext.responseBuilder.status(200).body("服务端已收到请求")
                }
            )
            server.serve()
    }
    // 等待服务器启动
    sleep(Duration.second)

    // 创建Client实例
    let client = ClientBuilder().build()

    // 构建自定义请求
    let request = HttpRequestBuilder()
        .method("PATCH")
        .url("http://127.0.0.1:8094/custom-request")
        .header("User-Agent", "MyCustomClient/1.0")
        .body("自定义请求体内容")
        .build()

    // 发送自定义请求
    let response = client.send(request)
    println("响应状态码: ${response.status}")

    // 读取响应体
    let bodyBuf = Array<UInt8>(1024, repeat: 0)
    let readLength = response.body.read(bodyBuf)
    println("响应体: ${String.fromUtf8(bodyBuf[..readLength])}")
}
```

运行结果：

```text
服务端收到请求: 方法=PATCH, 路径=/custom-request, User-Agent=MyCustomClient/1.0
响应状态码: 200
响应体: 服务端已收到请求
```

### func upgrade(HttpRequest)

```cangjie
public func upgrade(req: HttpRequest): (HttpResponse, ?StreamingSocket)
```

功能：发送请求并升级协议，用户设置请求头，返回升级后的连接（如果升级成功），连接由用户负责关闭。

> **说明：**
>
> - 服务器返回 101 表示升级成功，获取到了 StreamingSocket；
> - 必选请求头：
>     - Upgrade:  protocol-name ["/" protocol-version]；
>     - Connection: Upgrade（在请求头包含 Upgrade 字段时会自动添加）；
> - 不支持 HTTP/1.0、HTTP/2；
> - 不支持 HTTP/1.1 CONNECT 方法的 [HttpRequest](http_package_classes.md#class-httprequest)。

参数：

- req: [HttpRequest](http_package_classes.md#class-httprequest) - 升级时发送的请求。

返回值：

- ([HttpResponse](http_package_classes.md#class-httpresponse),?StreamingSocket) - 返回一个元组，[HttpResponse](http_package_classes.md#class-httpresponse) 实例表示服务器返回的响应，?StreamingSocket 实例表示获取的底层连接，升级失败时为 None。

异常：

- [HttpException](http_package_exceptions.md#class-httpexception) -
    - 请求报文或响应报文不符合协议；
    - 请求报文不含 Upgrade 头；
    - 发送 CONNECT 请求；
    - 发送带 body 的 TRACE 请求；
- SocketException，[ConnectionException](http_package_exceptions.md#class-connectionexception) - Socket 连接出现异常或被关闭；
- SocketTimeoutException - Socket 连接超时；
- [TlsException](../../tls/common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - Tls 连接建立失败或通信异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 启动服务器
    spawn {
        =>
            let server = ServerBuilder().addr("127.0.0.1").port(8094).build()
            server.distributor.register(
                "/upgrade",
                {
                    httpContext =>
                        httpContext.responseBuilder.status(101)
                        // 升级连接
                        let streamingSocket = upgrade(httpContext)
                        // 通过streamingSocket写入数据
                        streamingSocket.write("Hello Cangjie!".toArray())
                }
            )
            server.serve()
    }
    // 等待服务器启动
    sleep(Duration.second)

    // 创建Client实例
    let client = ClientBuilder().build()

    // 必须添加Upgrade头才支持升级连接
    let headers = HttpHeaders()
    headers.add("Upgrade", "abc")

    // 创建HttpRequest实例
    let req = HttpRequestBuilder().url("http://127.0.0.1:8094/upgrade").get().setHeaders(headers).build()

    // 升级连接
    let (resp, streamingSocket) = client.upgrade(req)
    let buf = Array<UInt8>(1024, repeat: 0)

    // 通过streamingSocket读取数据
    let readLength = streamingSocket?.read(buf) ?? 0
    println("状态码: ${resp.status}")
    println("读取内容: ${String.fromUtf8(buf[..readLength])}, 长度: ${readLength}")
    streamingSocket?.close()
}
```

运行结果：

```text
状态码: 101
读取内容: Hello Cangjie!, 长度: 14
```

## class ClientBuilder

```cangjie
public class ClientBuilder {
    public init()
}
```

功能：用于 [Client](http_package_classes.md#class-client) 实例的构建，[Client](http_package_classes.md#class-client) 没有公开的构造函数，用户只能通过 [ClientBuilder](http_package_classes.md#class-clientbuilder) 得到 [Client](http_package_classes.md#class-client) 实例。[ClientBuilder](http_package_classes.md#class-clientbuilder) 文档中未明确说明支持版本的配置，在 HTTP/1.1 与 HTTP/2 都会生效。

> **说明：**
>
> 该类提供了一系列配置参数的函数，配置完成后调用 [build](./http_package_classes.md#func-build) 函数构造出 [Client](./http_package_classes.md#class-client) 实例。配置函数中说明了参数的取值范围，但配置函数本身不做参数合法性校验，[build](./http_package_classes.md#func-build) 时统一进行校验。

### init()

```cangjie
public init()
```

功能：创建新的 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main(): Unit {
    let _ = ClientBuilder()
}
```

### func autoRedirect(Bool)

```cangjie
public func autoRedirect(auto: Bool): ClientBuilder
```

功能：配置客户端是否会自动进行重定向。重定向会请求 Location 头的资源，协议规定，Location 只能包含一个 URI 引用 Location = URI-reference，详见 [RFC 9110 10.2.2.](https://httpwg.org/specs/rfc9110.html#rfc.section.10.2.2)。304 状态码默认不重定向。

参数：

- auto: Bool - 默认值为 true，即开启自动重定向。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

示例：
<!-- associated_example -->
参见 [prop autoRedirect](#prop-autoredirect) 示例。

### func build()

```cangjie
public func build(): Client
```

功能：构造 [Client](http_package_classes.md#class-client) 实例。

此处会对各参数的值进行检查，如果取值非法，将抛出异常。各参数的取值范围详见设置参数相关的函数。

返回值：

- [Client](http_package_classes.md#class-client) - 用当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例中的配置构建的 [Client](http_package_classes.md#class-client) 实例。

异常：

- IllegalArgumentException - 配置项有非法参数时抛出此异常。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 链式调用可以一次性设置多个属性
    let customClient = ClientBuilder().poolSize(20).maxHeaderListSize(65536).build()
    customClient.close()
}
```

### func connector((SocketAddress) -> StreamingSocket)

```cangjie
public func connector(c: (SocketAddress) -> StreamingSocket): ClientBuilder
```

功能：客户端调用此函数获取到服务器的连接。

参数：

- c: (SocketAddress) ->StreamingSocket - 入参为 SocketAddress 实例，返回值类型为 StreamingSocket 的函数类型。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

示例：
<!-- associated_example -->
参见 [prop connector](#prop-connector) 示例。

### func cookieJar(?CookieJar)

```cangjie
public func cookieJar(cookieJar: ?CookieJar): ClientBuilder
```

功能：用于存储客户端所有 [Cookie](http_package_classes.md#class-cookie)。

参数：

- cookieJar: ?[CookieJar](http_package_interfaces.md#interface-cookiejar) - 默认使用一个空的 [CookieJar](http_package_interfaces.md#interface-cookiejar)，如果配置为 None 则不会启用 [Cookie](http_package_classes.md#class-cookie)。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

示例：
<!-- associated_example -->
参见 [prop cookieJar](#prop-cookiejar) 示例。

### func enablePush(Bool)

```cangjie
public func enablePush(enable: Bool): ClientBuilder
```

功能：配置客户端 HTTP/2 是否支持服务器推送。

参数：

- enable: Bool - 默认值 true。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

示例：
<!-- associated_example -->
参见 [prop enablePush](#prop-enablepush) 示例。

### func headerTableSize(UInt32)

```cangjie
public func headerTableSize(size: UInt32): ClientBuilder
```

功能：配置客户端 HTTP/2 Hpack 动态表初始值。

参数：

- size: UInt32 - 默认值 4096。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

示例：
<!-- associated_example -->
参见 [prop headerTableSize](#prop-headertablesize) 示例。

### func httpProxy(String)

```cangjie
public func httpProxy(addr: String): ClientBuilder
```

功能：设置客户端 http 代理，默认使用系统环境变量 http_proxy 的值。

参数：

- addr: String - 格式为：`"http://host:port"`，例如：`"http://192.168.1.1:80"`。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

示例：
<!-- associated_example -->
参见 [prop httpProxy](#prop-httpproxy) 示例。

### func httpsProxy(String)

```cangjie
public func httpsProxy(addr: String): ClientBuilder
```

功能：设置客户端 https 代理，默认使用系统环境变量 https_proxy 的值。

参数：

- addr: String - 格式为：`"http://host:port"`，例如：`"http://192.168.1.1:443"`。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

示例：
<!-- associated_example -->
参见 [prop httpsProxy](#prop-httpsproxy) 示例。

### func initialWindowSize(UInt32)

```cangjie
public func initialWindowSize(size: UInt32): ClientBuilder
```

功能：配置客户端 HTTP/2 流控窗口初始值。

参数：

- size: UInt32 - 默认值 65535 ， 取值范围为 0 至 2^31 - 1。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

示例：
<!-- associated_example -->
参见 [prop initialWindowSize](#prop-initialwindowsize) 示例。

### func logger(Logger)

```cangjie
public func logger(logger: Logger): ClientBuilder
```

功能：设定客户端的 logger，默认 logger 级别为 INFO，logger 内容将写入 Console.stdout。

参数：

- logger: [Logger](../../../log/log_package_api/log_package_classes.md#class-logger) - 需要是线程安全的，默认使用内置线程安全 logger。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.logger.*
import std.env.*

main(): Unit {
    // 创建SimpleLogger实例，使用标准输出流
    let logger = SimpleLogger(getStdOut())
    let client = ClientBuilder().logger(logger).build()
    client.close()
}
```

### func maxConcurrentStreams(UInt32)

```cangjie
public func maxConcurrentStreams(size: UInt32): ClientBuilder
```

功能：配置客户端 HTTP/2 初始最大并发流数量。

参数：

- size: UInt32 - 默认值为 2^31 - 1。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

示例：
<!-- associated_example -->
参见 [prop maxConcurrentStreams](#prop-maxconcurrentstreams) 示例。

### func maxFrameSize(UInt32)

```cangjie
public func maxFrameSize(size: UInt32): ClientBuilder
```

功能：配置客户端 HTTP/2 初始最大帧大小。

参数：

- size: UInt32 - 默认值为 16384。取值范围为 2^14 至 2^24 - 1。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

示例：
<!-- associated_example -->
参见 [prop maxFrameSize](#prop-maxframesize) 示例。

### func maxHeaderListSize(UInt32)

```cangjie
public func maxHeaderListSize(size: UInt32): ClientBuilder
```

功能：获取客户端支持的 HTTP/2 最大头部（Header）大小。这个大小指的是响应头部中所有头部字段（Header Field）的最大允许长度之和，其中包括所有字段名称（name）的长度、字段值（value）的长度以及每个字段自动添加的伪头开销（通常每个字段会有 32 字节的开销，这包括了 HTTP/2 协议本身为头部字段添加的伪头部信息）。默认情况下，这个最大长度被设置为 UInt32.Max。

参数：

- size: UInt32 - 客户端接收的 HTTP/2 响应 headers 最大长度。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

示例：
<!-- associated_example -->
参见 [prop maxHeaderListSize](#prop-maxheaderlistsize) 示例。

### func noProxy()

```cangjie
public func noProxy(): ClientBuilder
```

功能：调用此函数后，客户端不使用任何代理。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import std.env.*
import stdx.net.http.*

main(): Unit {
    // 先设置代理环境变量
    setVariable("http_proxy", "http://192.168.1.1:8080")

    // 使用ClientBuilder设置不使用代理
    let client = ClientBuilder().noProxy().build()

    println("即使有代理设置，客户端也不会使用代理: ${client.httpProxy}")

    // 关闭客户端
    client.close()
}
```

运行结果：

```text
即使有代理设置，客户端也不会使用代理: 
```

### func poolSize(Int64)

```cangjie
public func poolSize(size: Int64): ClientBuilder
```

功能：配置 HTTP/1.1 客户端使用的连接池的大小，亦可表示对同一个主机（host:port）同时存在的连接数的最大值。

参数：

- size: Int64 - 默认 10，poolSize 需要大于 0。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

异常：

- [HttpException](http_package_exceptions.md#class-httpexception) - 如果传参小于等于 0，则会抛出该异常。

示例：
<!-- associated_example -->
参见 [prop poolSize](#prop-poolsize) 示例。

### func readTimeout(Duration)

```cangjie
public func readTimeout(timeout: Duration): ClientBuilder
```

功能：设定客户端读取一个响应的最大时长。

参数：

- timeout: Duration - 默认 15s，Duration.Max 代表不限制，如果传入负的 Duration 将被替换为 Duration.Zero。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

示例：
<!-- associated_example -->
参见 [prop readTimeout](#prop-readtimeout) 示例。

### func tlsConfig(TlsConfig)

```cangjie
public func tlsConfig(config: TlsConfig): ClientBuilder
```

功能：设置 TLS 层配置，默认不对其进行设置。

参数：

- config: [TlsConfig](../../tls/common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconfig) - 设定支持 tls 客户端需要的配置信息。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.net.tls.*

main(): Unit {
    // 配置 TlsClientConfig
    var tls = TlsClientConfig()
    tls.supportedAlpnProtocols = ["h2"]

    // 创建 TlsClientConfig 实例并配置
    let client = ClientBuilder().tlsConfig(tls).build()
    client.close()
}
```

### func writeTimeout(Duration)

```cangjie
public func writeTimeout(timeout: Duration): ClientBuilder
```

功能：设定客户端发送一个请求的最大时长。

参数：

- timeout: Duration - 默认 15 秒，Duration.Max 代表不限制，如果传入负的 Duration 将被替换为 Duration.Zero。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

示例：
<!-- associated_example -->
参见 [prop writeTimeout](#prop-writetimeout) 示例。

## class Cookie

```cangjie
public class Cookie {
    public init(name: String, value: String, expires!: ?DateTime = None, maxAge!: ?Int64 = None,
        domain!: String = "", path!: String = "", secure!: Bool = false, httpOnly!: Bool = false)
}
```

功能：HTTP 本身是无状态的，server 为了知道 client 的状态，提供个性化的服务，便可以通过 [Cookie](http_package_classes.md#class-cookie) 来维护一个有状态的会话。

> **说明：**
>
> - 用户首次访问某站点时，server 通过 `Set-Cookie` header 将 name/value 对，以及 attribute-value 传给用户代理；用户代理随后对该站点的请求中便可以将 name/value 加入到 Cookie header 中；
> - [Cookie](http_package_classes.md#class-cookie) 类提供了构建 [Cookie](http_package_classes.md#class-cookie) 对象，并将 [Cookie](http_package_classes.md#class-cookie) 对象转成 `Set-Cookie` header 值的函数，提供了获取 [Cookie](http_package_classes.md#class-cookie) 对象各属性值的函数；
> - [Cookie](http_package_classes.md#class-cookie) 的各个属性的要求和作用见 [RFC 6265](https://httpwg.org/specs/rfc6265.html)；
> - 下文中 cookie-name，cookie-value，expires-av 等名字采用 [RFC 6265](https://httpwg.org/specs/rfc6265.html) 中的术语，详情请见协议。

### prop cookieName

```cangjie
public prop cookieName: String
```

功能：获取 [Cookie](http_package_classes.md#class-cookie) 对象的 cookie-name 值。

类型：String

示例：
<!-- associated_example -->
参见 [init](#initstring-string-datetime-int64-string-string-bool-bool) 示例。

### prop cookieValue

```cangjie
public prop cookieValue: String
```

功能：获取 [Cookie](http_package_classes.md#class-cookie) 对象的 cookie-value 值。

类型：String

示例：
<!-- associated_example -->
参见 [init](#initstring-string-datetime-int64-string-string-bool-bool) 示例。

### prop domain

```cangjie
public prop domain: String
```

功能：获取 [Cookie](http_package_classes.md#class-cookie) 对象的 domain-av 值。

类型：String

示例：
<!-- associated_example -->
参见 [init](#initstring-string-datetime-int64-string-string-bool-bool) 示例。

### prop expires

```cangjie
public prop expires: ?DateTime
```

功能：获取 [Cookie](http_package_classes.md#class-cookie) 对象的 expires-av 值。

类型：?DateTime

示例：
<!-- associated_example -->
参见 [init](#initstring-string-datetime-int64-string-string-bool-bool) 示例。

### prop httpOnly

```cangjie
public prop httpOnly: Bool
```

功能：获取 [Cookie](http_package_classes.md#class-cookie) 对象的 httpOnly-av 值。

类型：Bool

示例：
<!-- associated_example -->
参见 [init](#initstring-string-datetime-int64-string-string-bool-bool) 示例。

### prop maxAge

```cangjie
public prop maxAge: ?Int64
```

功能：获取 [Cookie](http_package_classes.md#class-cookie) 对象的 max-age-av 值。

类型：?Int64

示例：
<!-- associated_example -->
参见 [init](#initstring-string-datetime-int64-string-string-bool-bool) 示例。

### prop others

```cangjie
public prop others: ArrayList<String>
```

功能：获取未被解析的属性。

类型：ArrayList\<String>

示例：
<!-- associated_example -->
参见 [init](#initstring-string-datetime-int64-string-string-bool-bool) 示例。

### prop path

```cangjie
public prop path: String
```

功能：获取 [Cookie](http_package_classes.md#class-cookie) 对象的 path-av 值。

类型：String

示例：
<!-- associated_example -->
参见 [init](#initstring-string-datetime-int64-string-string-bool-bool) 示例。

### prop secure

```cangjie
public prop secure: Bool
```

功能：获取 [Cookie](http_package_classes.md#class-cookie) 对象的 secure-av 值。

类型：Bool

示例：
<!-- associated_example -->
参见 [init](#initstring-string-datetime-int64-string-string-bool-bool) 示例。

### init(String, String, ?DateTime, ?Int64, String, String, Bool, Bool)

```cangjie
public init(name: String, value: String, expires!: ?DateTime = None, maxAge!: ?Int64 = None,
    domain!: String = "", path!: String = "", secure!: Bool = false, httpOnly!: Bool = false)
```

功能：[Cookie](http_package_classes.md#class-cookie) 构造器。

该构造器会检查传入的各项属性是否满足协议要求，如果不满足则会产生 IllegalArgumentException。具体要求见 [RFC 6265 4.1.1.](https://httpwg.org/specs/rfc6265.html#sane-set-cookie-syntax)。

> **注意：**
>
> [Cookie](http_package_classes.md#class-cookie) 各属性中只有 cookie-name，cookie-value 是必需的，必须传入 name，value 参数，但 value 参数可以传入空字符串。

参数：

- name: String - cookie-name 属性。

    ```text
    name         = token 
    token        = 1*tchar
    tchar        = "!" / "#" / "$" / "%" / "&" / "'" / "*"
                   / "+" / "-" / "." / "^" / "_" / "`" / "|" / "~"
                   / DIGIT / ALPHA
    ```

- value: String - cookie-value 属性。

    ```text
    value        = *cookie-octet / ( DQUOTE *cookie-octet DQUOTE )
    cookie-octet = %x21 / %x23-2B / %x2D-3A / %x3C-5B / %x5D-7E
                ; US-ASCII characters excluding CTLs,
                ; whitespace DQUOTE, comma, semicolon,
                ; and backslash
    ```

- expires!: ?DateTime - 设置 [Cookie](http_package_classes.md#class-cookie) 的过期时间，默认为 None，时间必须在 1601 年之后。
- maxAge!: ?Int64 - [Cookie](http_package_classes.md#class-cookie) 的最大生命周期，默认为 None，如果 [Cookie](http_package_classes.md#class-cookie) 既有 expires 属性，也有 maxAge，这两个过期时间都会失效，[Cookie](http_package_classes.md#class-cookie) 会被降级为会话级，Client 打开期间有效，Client 关闭后就失效。

    ```text
    max-age-av     = "Max-Age=" non-zero-digit *DIGIT
    non-zero-digit = %x31-39
                    ; digits 1 through 9
    DIGIT          = %x30-39
                    ; digits 0 through 9
    ```

- domain!: String - 默认为空字符串，表示收到该 [Cookie](http_package_classes.md#class-cookie) 的客户端只会发送该 [Cookie](http_package_classes.md#class-cookie) 给原始服务器。如果设置了合法的 domain，则收到该 [Cookie](http_package_classes.md#class-cookie) 的客户端只会发送该 [Cookie](http_package_classes.md#class-cookie) 给所有该 domain 的子域（在这基础上还需满足其他属性条件要求）。

    ```text
    domain          = <subdomain> | " "
    <subdomain>   ::= <label> | <subdomain> "." <label>
    <label>       ::= <letter> [ [ <ldh-str> ] <let-dig> ]
    <ldh-str>     ::= <let-dig-hyp> | <let-dig-hyp> <ldh-str>
    <let-dig-hyp> ::= <let-dig> | "-"
    <let-dig>     ::= <letter> | <digit>
    <letter>      ::= any one of the 52 alphabetic characters A through Z in upper case and a through z in lower case
    <digit>       ::= any one of the ten digits 0 through 9
    RFC 1035 2.3.1.
    而 RFC 1123 2.1. 放松了对 label 首字符必须是 letter 的限制
    因此，对 domain 的要求为：
    1、总长度小于等于 255，由若干个 label 组成
    2、label 与 label 之间通过 "." 分隔，每个 label 长度小于等于 63
    3、label 的开头和结尾必须是数字或者字母，label 的中间字符必须是数字、字母或者 "-"
    ```

- path!: String - 默认为空字符串，客户端会根据 url 计算出默认的 path 属性，见 RFC 6265 5.1.4.。 收到该 [Cookie](http_package_classes.md#class-cookie) 的客户端只会发送该 [Cookie](http_package_classes.md#class-cookie) 给所有该 path 的子目录（在这基础上还需满足其他属性条件要求）。

    ```text
    path            = <any RUNE except CTLs or ";">
    RUNE            = <any [USASCII] character>
    CTLs            = <controls>
    ```

- secure!: Bool - 默认为 false，如果设置为 true，该 [Cookie](http_package_classes.md#class-cookie) 只会在安全协议请求中发送。
- httpOnly!: Bool - 默认为 false，如果设置为 true，该 [Cookie](http_package_classes.md#class-cookie) 只会在 HTTP 协议请求中发送。

异常：

- IllegalArgumentException - 传入的参数不符合协议要求时抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*
import std.time.*

main(): Unit {
    // expires 和 maxAge 是互斥的，不能同时设置，此处仅做演示
    let cookie = Cookie("myCookieName", "myCookieValue",
        expires: DateTime.of(year: 2099, month: 1, dayOfMonth: 1, timeZone: TimeZone.UTC), maxAge: 3600,
        domain: "example.com", path: "/", secure: true, httpOnly: true)
    println("cookieName: ${cookie.cookieName}")
    println("cookieValue: ${cookie.cookieValue}")
    println("expires: ${cookie.expires}")
    println("maxAge: ${cookie.maxAge}")
    println("domain: ${cookie.domain}")
    println("path: ${cookie.path}")
    println("secure: ${cookie.secure}")
    println("httpOnly: ${cookie.httpOnly}")
    println("others: ${cookie.others}")
    println("toSetCookieString(): ${cookie.toSetCookieString()}")
}
```

运行结果：

```text
cookieName: myCookieName
cookieValue: myCookieValue
expires: Some(2099-01-01T00:00:00Z)
maxAge: Some(3600)
domain: example.com
path: /
secure: true
httpOnly: true
others: []
toSetCookieString(): myCookieName=myCookieValue; Expires=Thu, 01 Jan 2099 00:00:00 UTC; Max-Age=3600; Domain=example.com; Path=/; Secure; HttpOnly
```

### func toSetCookieString()

```cangjie
public func toSetCookieString(): String
```

功能：提供将 [Cookie](http_package_classes.md#class-cookie) 转成字符串形式的函数，方便 server 设置 `Set-Cookie` header。

> **注意：**
>
> - [Cookie](http_package_classes.md#class-cookie) 各属性（包含 name，value）在对象创建时就被检查了，因此 toSetCookieString() 函数不会产生异常；
> - [Cookie](http_package_classes.md#class-cookie) 必需的属性是 cookie-pair 即 cookie-name "=" cookie-value，cookie-value 可以为空字符串，toSetCookieString() 函数只会将设置过的属性写入字符串，即只有 "cookie-name=" 是必有的，其余部分是否存在取决于是否设置。

返回值：

- String - 字符串对象，用于设置 `Set-Cookie` header。

示例：
<!-- associated_example -->
参见 [init](#initstring-string-datetime-int64-string-string-bool-bool) 示例。

## class FileHandler

```cangjie
public class FileHandler <: HttpRequestHandler {
    public init(path: String, handlerType!: FileHandlerType = DownLoad, bufferSize!: Int64 = 64 * 1024)
    public init(path: String, handlerType!: FileHandlerType = DownLoad, bufferSize!: Int64 = 64 * 1024, validator!: (String) -> Bool)
}
```

功能：用于处理文件下载或者文件上传。

文件下载：

- 构造 [FileHandler](http_package_classes.md#class-filehandler) 时需要传入待下载文件的路径，目前一个 [FileHandler](http_package_classes.md#class-filehandler) 只能处理一个文件的下载；
- 下载文件只能使用 GET 请求，其他请求返回 400 状态码；
- 文件如果不存在，将返回 404 状态码。

文件上传：

- 构造 [FileHandler](http_package_classes.md#class-filehandler) 时需要传入一个存在的目录路径，上传到服务端的文件将保存在这个目录中；
- 上传文件时只能使用 POST 请求，其他请求返回 400 状态码；
- 上传数据的 http 报文必须是 `multipart/form-data` 格式的，`Content-Type` 头字段的值为 `multipart/form-data; boundary=----XXXXX`；
- 上传文件的文件名存放在 `form-data` 数据报文中，报文数据格式为 `Content-Disposition: form-data; name="xxx"; filename="xxxx"`，文件名是 `filename` 字段的值；
- 目前 form-data 中必须包含 filename 字段；
- 如果请求报文不正确，将返回 400 状态码；
- 如果出现其他异常，例如文件处理异常，将返回 500 状态码。

父类型：

- [HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler)

### init(String, FileHandlerType, Int64)

```cangjie
public init(path: String, handlerType!: FileHandlerType = DownLoad, bufferSize!: Int64 = 64 * 1024)
```

功能：[FileHandler](http_package_classes.md#class-filehandler) 的构造函数。

参数：

- path: String - [FileHandler](http_package_classes.md#class-filehandler) 构造时需要传入的文件或者目录路径字符串，上传模式中只能传入存在的目录路径；路径中存在../时，用户需要确认标准化后的绝对路径是期望传入的路径。
- handlerType!: [FileHandlerType](http_package_enums.md#enum-filehandlertype) - 构造 [FileHandler](http_package_classes.md#class-filehandler) 时指定当前 [FileHandler](http_package_classes.md#class-filehandler) 的工作模式，默认为 DownLoad 下载模式。
- bufferSize!: Int64 - 内部从网络读取或者写入的缓冲区大小，默认值为 64*1024（64k），若小于 4096，则使用 4096 作为缓冲区大小。

异常：

- [HttpException](http_package_exceptions.md#class-httpexception) - 当 path 不存在时，抛出异常。
- IllegalArgumentException - 参数错误时抛出异常，如 path 为空或者包含空字符串等。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import stdx.net.http.*

// 此示例为文件下载演示，上传文件演示请参见另一个构造函数
main(): Unit {
    // 创建一个有内容的临时文件给服务端，作为文件下载的测试文件
    let fileServer = "./filehandler_download.txt"
    try (file = File(fileServer, Write)) {
        file.write("file-content file-content".toArray())
    }
    // 启动服务器
    spawn {
        =>
            var server = ServerBuilder().addr("127.0.0.1").port(8080).build()
            server.distributor.register("/file", FileHandler(fileServer))
            server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 客户端访问服务器，下载文件
    let client = ClientBuilder().build()
    let resp = client.get("http://127.0.0.1:8080/file")

    // 创建一个缓冲区用于读取响应体
    var buf = Array<UInt8>(10, repeat: 0)

    // 创建一个空的临时文件给服务端，作为文件下载的接收容器
    let fileClient = "./filehandler_download_empty.txt"
    try (file = File(fileClient, Write)) {
        while (true) {
            // 读取响应体
            let readLenth = resp.body.read(buf)
            println("客户端读取了 ${readLenth} 字节")
            if (readLenth <= 0) {
                break
            }
            file.write(buf[..readLenth])
        }
    }
    // 删除测试文件
    removeIfExists(fileServer)
    removeIfExists(fileClient)
}
```

运行结果：

```text
客户端读取了 10 字节
客户端读取了 10 字节
客户端读取了 5 字节
客户端读取了 0 字节
```

### init(String, FileHandlerType, Int64, (String) -> Bool)

```cangjie
public init(path: String, handlerType!: FileHandlerType = DownLoad, bufferSize!: Int64 = 64 * 1024, validator!: (String) -> Bool)
```

功能：[FileHandler](http_package_classes.md#class-filehandler) 的构造函数。

参数：

- path: String - [FileHandler](http_package_classes.md#class-filehandler) 构造时需要传入的文件或者目录路径字符串，上传模式中只能传入存在的目录路径；路径中存在../时，用户需要确认标准化后的绝对路径是期望传入的路径。
- handlerType!: [FileHandlerType](http_package_enums.md#enum-filehandlertype) - 构造 [FileHandler](http_package_classes.md#class-filehandler) 时指定当前 [FileHandler](http_package_classes.md#class-filehandler) 的工作模式，默认为 DownLoad 下载模式。
- bufferSize!: Int64 - 内部从网络读取或者写入的缓冲区大小，默认值为 64*1024（64k），若小于 4096，则使用 4096 作为缓冲区大小。
- validator!: (String) -> Bool - 用户自定义的文件名校验函数，仅上传模式有效。入参是上传的文件在 multipart 数据报文中的 filename，返回值是用户自定义函数的校验结果。如果校验结果是 false，则中断上传请求，并返回“400 Bad Request”，同时删除本次请求已上传到 path 目录的文件。

异常：

- [HttpException](http_package_exceptions.md#class-httpexception) - 当 path 不存在时，抛出异常。
- IllegalArgumentException - 参数错误时抛出异常，如 path 为空或者包含空字符串等。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import stdx.net.http.*

// 此示例为文件上传演示，下载文件演示请参见另一个构造函数
main(): Unit {
    // 启动服务器
    spawn {
        =>
            var server = ServerBuilder().addr("127.0.0.1").port(8080).build()
            // 注册文件上传程序，并且设置文件类型验证器（txt 文件）
            server
                .distributor
                .register("/file",
                    FileHandler("./", handlerType: UpLoad, validator: {str: String => str.endsWith(".txt")}))
            server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 客户端访问服务器，上传文件
    let client = ClientBuilder().build()
    // 创建一个边界字符串用于分隔表单数据
    let boundary = "----WebKitFormBoundary7B8HS8VxGf4OHfS7"

    // 创建一个文件名用于上传
    let fileName = "upload.txt"

    // 创建一个 HTTP 请求
    let req = HttpRequestBuilder()
        .post()
        .url("http://127.0.0.1:8080/file")
        .header("Content-Type", "multipart/form-data; boundary=${boundary}")
        .body(buildBodyData(fileName, boundary))
        .build()
    // 发送请求并获取响应
    let resp = client.send(req)
    println("上传成功? ${resp.status == 200}")

    // 删除上传的文件
    removeIfExists(fileName)
}

// 构建 HTTP 请求体数据
func buildBodyData(fileName: String, boundary: String): Array<Byte> {
    let body = ByteBuffer()
    body.write("--${boundary}\r\n".toArray())
    body.write("Content-Disposition: form-data; name=\"myFile\"; filename=\"${fileName}\"".toArray())
    body.write("\r\n".toArray())
    body.write("Content-Type: text/plain\r\n\r\n".toArray())
    body.write("这是待上传的文件内的数据".toArray())
    body.write("\r\n".toArray())
    body.write("--${boundary}--\r\n".toArray())
    return body.bytes()
}
```

运行结果：

```text
上传成功? true
```

### func handle(HttpContext)

```cangjie
public func handle(ctx: HttpContext): Unit
```

功能：根据请求对响应数据进行处理。

参数：

- ctx: [HttpContext](http_package_classes.md#class-httpcontext) - Http 请求上下文。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import stdx.net.http.*

// 此示例为文件下载演示
main(): Unit {
    // 创建一个有内容的临时文件给服务端，作为文件下载的测试文件
    let fileServer = "./filehandler_download.txt"
    try (file = File(fileServer, Write)) {
        file.write("file-content file-content".toArray())
    }
    // 启动服务器
    spawn {
        =>
            var server = ServerBuilder().addr("127.0.0.1").port(8080).build()
            server.distributor.register(
                "/file",
                {
                    httpContext =>
                        let fileHandler = FileHandler(fileServer)
                        // 处理文件下载请求
                        fileHandler.handle(httpContext)
                }
            )
            server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 客户端访问服务器，下载文件
    let client = ClientBuilder().build()
    let resp = client.get("http://127.0.0.1:8080/file")

    // 创建一个缓冲区用于读取响应体
    var buf = Array<UInt8>(10, repeat: 0)

    // 创建一个空的临时文件给服务端，作为文件下载的接收容器
    let fileClient = "./filehandler_download_empty.txt"
    try (file = File(fileClient, Write)) {
        while (true) {
            // 读取响应体
            let readLenth = resp.body.read(buf)
            println("客户端读取了 ${readLenth} 字节")
            if (readLenth <= 0) {
                break
            }
            file.write(buf[..readLenth])
        }
    }
    // 删除测试文件
    removeIfExists(fileServer)
    removeIfExists(fileClient)
}
```

运行结果：

```text
客户端读取了 10 字节
客户端读取了 10 字节
客户端读取了 5 字节
客户端读取了 0 字节
```

## class FuncHandler

```cangjie
public class FuncHandler <: HttpRequestHandler {
    public FuncHandler(let handler: (HttpContext) -> Unit)
}
```

功能：[HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler) 接口包装类，把单个函数包装成 [HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler)。

父类型：

- [HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler)

### FuncHandler((HttpContext) -> Unit)

```cangjie
public FuncHandler(let handler: (HttpContext) -> Unit)
```

功能：[FuncHandler](http_package_classes.md#class-funchandler) 的构造函数。

参数：

- handler: ([HttpContext](http_package_classes.md#class-httpcontext)) -> Unit - 是调用 handle 的处理函数。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 定义一个可复用，逻辑复杂的处理函数
    let funcHandler = FuncHandler({ctx: HttpContext => ctx.responseBuilder.body("模拟逻辑很复杂")})

    // 启动服务器
    spawn {
        =>
            let server = ServerBuilder().addr("127.0.0.1").port(8080).build()
            // 直接注册处理函数
            server.distributor.register("/test1", funcHandler)
            // 可以对HttpContext进行特殊处理
            server.distributor.register(
                "/test2",
                {
                    httpContext =>
                        println("获得${httpContext.request.method}请求")
                        funcHandler.handle(httpContext)
                }
            )
            server.serve()
    }
    // 等待服务器启动
    sleep(Duration.second)

    // 创建Client实例
    let client = ClientBuilder().build()

    // 发送GET请求，但是不处理响应体
    let response = client.get("http://127.0.0.1:8080/test2")
    println("响应状态码: ${response.status}")
}
```

运行结果：

```text
获得GET请求
响应状态码: 200
```

### func handle(HttpContext)

```cangjie
public func handle(ctx: HttpContext): Unit
```

功能：处理 Http 请求。

参数：

- ctx: [HttpContext](http_package_classes.md#class-httpcontext) - Http 请求上下文。

示例：
<!-- associated_example -->
参见 [FuncHandler](#funchandlerhttpcontext---unit) 示例。

## class HttpContext

```cangjie
public class HttpContext
```

功能：Http 请求上下文，作为 [HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler).handle 函数的参数在服务端使用。

### prop clientCertificate

```cangjie
public prop clientCertificate: ?Array<Certificate>
```

功能：获取 Http 客户端证书。

类型：?Array\<[Certificate](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-certificate)>

示例：

<!-- verify -->
```cangjie
import std.io.*
import std.fs.*
import std.process.*
import stdx.net.tls.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*
import stdx.net.tls.common.*
import stdx.net.http.*

main(): Unit {
    // OpenSSL 官方标准、无风险的测试命令用来本地生成证书和私钥
    // 生成服务器私钥、证书、证书请求路径
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"
    let serverCsr = "./server.csr"

    // 根证书/私钥路径
    let rootCrt = "./rootCA.crt"
    let rootKey = "./rootCA.key"

    // 客户端私钥、证书、证书请求路径
    let clientKey = "./client.key"
    let clientCrt = "./client.crt"
    let clientCsr = "./client.csr"

    // 生成根CA证书
    let rootCmd = "openssl req -x509 -newkey rsa:4096 -nodes -keyout ${rootKey} -out ${rootCrt} -days 3650 -subj \"/C=CN/ST=Beijing/L=Beijing/O=MyCA/OU=CA/CN=MyRootCA\""
    executeWithOutput("sh", ["-c", rootCmd])

    // 生成服务器私钥+证书请求（CSR） 
    let csrCmd = "openssl req -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCsr} -subj \"/C=CN/ST=Beijing/L=Beijing/O=MyServer/OU=Server/CN=localhost\""
    executeWithOutput("sh", ["-c", csrCmd])

    // 用根CA签发服务器证书
    let signCmd = "openssl x509 -req -in ${serverCsr} -CA ${rootCrt} -CAkey ${rootKey} -CAcreateserial -out ${serverCrt} -days 365 -sha256"
    executeWithOutput("sh", ["-c", signCmd])

    // 生成客户端私钥+证书请求（CSR）
    let clientCsrCmd = "openssl req -newkey rsa:2048 -nodes -keyout ${clientKey} -out ${clientCsr} -subj \"/C=CN/ST=Beijing/L=Beijing/O=MyClient/OU=Client/CN=MyClient\""
    executeWithOutput("sh", ["-c", clientCsrCmd])

    // 用根CA签发客户端证书（和服务端同根CA，服务端会信任）
    let clientSignCmd = "openssl x509 -req -in ${clientCsr} -CA ${rootCrt} -CAkey ${rootKey} -CAcreateserial -out ${clientCrt} -days 365 -sha256"
    executeWithOutput("sh", ["-c", clientSignCmd])

    // 读取根证书PEM
    let pem = String.fromUtf8(File.readFrom(rootCrt))

    // 启动服务器
    spawn {
        =>
            // 对服务器证书以及私钥进行解析 
            let pemString = String.fromUtf8(File.readFrom(serverCrt))
            let keyString = String.fromUtf8(File.readFrom(serverKey))

            let certificate = X509Certificate.decodeFromPem(pemString)
            let privateKey = GeneralPrivateKey.decodeFromPem(keyString)

            // 创建 TLS 服务器配置
            var config = TlsServerConfig(certificate, privateKey)

            // 只有开启客户端身份验证，才会得到客户端证书
            config.clientIdentityRequired = Required
            config.verifyMode = CustomCA(X509Certificate.decodeFromPem(pem).map({c => c}))

            // 构建带 TLS 配置的 Server 实例
            let server = ServerBuilder().addr("127.0.0.1").tlsConfig(config).port(8080).build()

            // 注册 HttpRequestHandler
            server.distributor.register("/index", {
                httpContext => println("Hello 客户端，你的证书数量是${httpContext.clientCertificate?.size ?? 0}")
            })
            // 启动服务
            server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 客户端配置
    var config = TlsClientConfig()
    let clientPem = String.fromUtf8(File.readFrom(clientCrt))
    let clientKeyStr = String.fromUtf8(File.readFrom(clientKey))
    let clientPriKey = GeneralPrivateKey.decodeFromPem(clientKeyStr)

    // 设置客户端证书和私钥
    config.certificate = (X509Certificate.decodeFromPem(clientPem).map({c => c}), clientPriKey)
    // 设置验证模式
    config.verifyMode = CustomCA(X509Certificate.decodeFromPem(pem).map({c => c}))

    // 创建带 TLS 配置的 Client 实例
    let client = ClientBuilder().tlsConfig(config).build()

    // 发送https GET请求，忽略响应
    let _ = client.get("https://127.0.0.1:8080/index")

    // 删除生成的文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
    removeIfExists(serverCsr)
    removeIfExists(clientKey)
    removeIfExists(clientCrt)
    removeIfExists(clientCsr)
    removeIfExists(rootKey)
    removeIfExists(rootCrt)
}
```

运行结果：

```text
Hello 客户端，你的证书数量是2
```

### prop request

```cangjie
public prop request: HttpRequest
```

功能：获取 Http 请求。

类型：[HttpRequest](http_package_classes.md#class-httprequest)

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 启动服务器
    spawn {
        =>
            // 构建 Server 实例
            let server = ServerBuilder().addr("127.0.0.1").port(8080).build()
            // 注册 HttpRequestHandler
            server.distributor.register("/index", {
                httpContext => if (httpContext.request.method == "GET") {
                    println("isClosed: ${httpContext.isClosed()}")
                    httpContext.responseBuilder.body("Hello 仓颉!")
                } else {
                    httpContext.responseBuilder.status(404)
                }
            })
            // 启动服务
            server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 创建 Client
    let client = ClientBuilder().build()

    // 发送GET请求
    let resp = client.get("http://127.0.0.1:8080/index")

    // 读取响应体
    let bodyBuf = Array<UInt8>(100, repeat: 0)
    let bytesRead = resp.body.read(bodyBuf)
    println("响应体: ${String.fromUtf8(bodyBuf[..bytesRead])}")
}
```

运行结果：

```text
isClosed: false
响应体: Hello 仓颉!
```

### prop responseBuilder

```cangjie
public prop responseBuilder: HttpResponseBuilder
```

功能：获取 Http 响应构建器。

类型：[HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder)

示例：
<!-- associated_example -->
参见 [prop request](#prop-request) 示例。

### func isClosed()

```cangjie
public func isClosed(): Bool
```

功能：使用 HTTP/1.1 协议时，判断 socket 是否已关闭；使用 HTTP/2 协议时，判断 HTTP/2 流是否已关闭。

返回值：

- Bool - 如果 HTTP/1.1 的 socket 或 HTTP/2 的流已关闭，返回 true，否则返回 false。

示例：
<!-- associated_example -->
参见 [prop request](#prop-request) 示例。

## class HttpHeaders

```cangjie
public class HttpHeaders <: Iterable<(String, Collection<String>)>
```

功能：此类用于表示 Http 报文中的 header 和 trailer，定义了相关增、删、改、查操作。

> **说明：**
>
> - header 和 trailer 为键值映射集，由若干 field-line 组成，每一个 field-line 包含一个键 (field -name) 和若干值 (field-value)。
> - field-name 由 token 字符组成，不区分大小写，在该类中将转为小写保存。
> - field-value 由 vchar，SP 和 HTAB 组成，vchar 表示可见的 US-ASCII 字符，不得包含前后空格，不得为空值。
> - 详见 [rfc 9110](https://www.rfc-editor.org/rfc/rfc9110.html#name-fields)。

示例：

```text
Example-Field: Foo, Bar
key: Example-Field, value: Foo, Bar
field-name = token
token = 1*tchar
tchar = "!" / "#" / "$" / "%" / "&" / "'" / "*"
/ "+" / "-" / "." / "^" / "_" / "`" / "|" / "~"
/ DIGIT / ALPHA
; any VCHAR, except delimiters
```

父类型：

- Iterable\<(String, Collection\<String>)>

### func add(String, String)

```cangjie
public func add(name: String, value: String): Unit
```

功能：添加指定键值对。如果 name 已经存在，将在其对应的值列表中添加 value；如果 name 不存在，则添加 name 字段及其值 value。

参数：

- name: String - [HttpHeaders](http_package_classes.md#class-httpheaders) 的字段名称。
- value: String - [HttpHeaders](http_package_classes.md#class-httpheaders) 的字段值。

异常：

- [HttpException](http_package_exceptions.md#class-httpexception) - 如果传入的 name/value 包含不合法元素，将抛出此异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    let headers = HttpHeaders()

    // 添加不同key的header
    headers.add("Content-Type", "application/json")
    headers.add("Authorization", "Bearer token123")

    // 添加相同key的header，后添加的会覆盖先添加的
    headers.add("Accept", "application/json")
    headers.add("Accept", "text/plain")

    println("Content-Type = ${headers.get("Content-Type").toArray()}")
    println("Accept = ${headers.get("Accept").toArray()}")
}
```

运行结果：

```text
Content-Type = [application/json]
Accept = [application/json, text/plain]
```

### func del(String)

```cangjie
public func del(name: String): Unit
```

功能：删除指定 name 对应的键值对。

参数：

- name: String - 删除的字段名称。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    let headers = HttpHeaders()

    // 添加一些header
    headers.add("Content-Type", "application/json")
    headers.add("Authorization", "Bearer token123")

    println("删除前:")
    println("Content-Type = ${headers.get("Content-Type").toArray()}")
    println("Authorization = ${headers.get("Authorization").toArray()}")

    // 删除指定header
    headers.del("Authorization")

    println("删除后:")
    println("Content-Type = ${headers.get("Content-Type").toArray()}")
    println("Authorization = ${headers.get("Authorization").toArray()}")
}
```

运行结果：

```text
删除前:
Content-Type = [application/json]
Authorization = [Bearer token123]
删除后:
Content-Type = [application/json]
Authorization = []
```

### func get(String)

```cangjie
public func get(name: String): Collection<String>
```

功能：获取指定 name 对应的 value 值。

参数：

- name: String - 字段名称，不区分大小写。

返回值：

- Collection\<String> - name 对应的 value 集合，如果指定 name 不存在，返回空集合。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    let headers = HttpHeaders()

    // 添加header，包括重复key的情况
    headers.add("Content-Type", "application/json")
    headers.add("Accept", "text/html")
    headers.add("Accept", "application/xml")

    // 获取存在的header
    let contentTypeValues = headers.get("Content-Type")
    println("Content-Type values: ${contentTypeValues.toArray()}")

    // 获取有多个值的header
    let acceptValues = headers.get("Accept")
    println("Accept values: ${acceptValues.toArray()}")

    // 获取不存在的header（不区分大小写）
    let notExistValues = headers.get("X-Custom-Header")
    println("X-Custom-Header values: ${notExistValues.toArray()}")
    println("是否为空: ${notExistValues.isEmpty()}")
}
```

运行结果：

```text
Content-Type values: [application/json]
Accept values: [text/html, application/xml]
X-Custom-Header values: []
是否为空: true
```

### func getFirst(String)

```cangjie
public func getFirst(name: String): ?String
```

功能：获取指定 name 对应的第一个 value 值。

参数：

- name: String - 字段名称，不区分大小写。

返回值：

- ?String - name 对应的第一个 value 值，如果指定 name 不存在，返回 None。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    let headers = HttpHeaders()

    // 添加header，包括重复key的情况
    headers.add("Content-Type", "application/json")
    headers.add("Accept", "text/html")
    headers.add("Accept", "application/xml")

    // 获取存在的header的第一个值
    match (headers.getFirst("Content-Type")) {
        case Some(v) => println("Content-Type第一个值: ${v}")
        case None => println("Content-Type不存在")
    }

    // 获取有多个值的header的第一个值
    match (headers.getFirst("Accept")) {
        case Some(v) => println("Accept第一个值: ${v}")
        case None => println("Accept不存在")
    }

    // 获取不存在的header（返回None）
    match (headers.getFirst("X-Custom-Header")) {
        case Some(v) => println("X-Custom-Header值: ${v}")
        case None => println("X-Custom-Header不存在")
    }
}
```

运行结果：

```text
Content-Type第一个值: application/json
Accept第一个值: text/html
X-Custom-Header不存在
```

### func isEmpty()

```cangjie
public func isEmpty(): Bool
```

功能：判断当前实例是否为空，即没有任何键值对。

返回值：

- Bool - 如果当前实例为空，返回 true，否则返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    let headers = HttpHeaders()

    // 检查空headers
    println("初始是否为空: ${headers.isEmpty()}")

    // 添加header
    headers.add("Content-Type", "application/json")
    println("添加后是否为空: ${headers.isEmpty()}")

    // 删除所有header
    headers.del("Content-Type")
    println("删除后是否为空: ${headers.isEmpty()}")
}
```

运行结果：

```text
初始是否为空: true
添加后是否为空: false
删除后是否为空: true
```

### func iterator()

```cangjie
public func iterator(): Iterator<(String, Collection<String>)>
```

功能：获取迭代器，可用于遍历所有键值对。

返回值：

- Iterator\<(String, Collection\<String>)> - 该键值集的迭代器。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    let headers = HttpHeaders()

    // 添加多个header
    headers.add("Content-Type", "application/json")
    headers.add("Accept", "text/html")
    headers.add("Accept", "application/xml")
    headers.add("Authorization", "Bearer token123")

    // 使用迭代器遍历所有header
    println("遍历所有header:")
    for ((name, values) in headers) {
        println(" ${name}: ${values.toArray()}")
    }
}
```

运行结果：

```text
遍历所有header:
 content-type: [application/json]
 accept: [text/html, application/xml]
 authorization: [Bearer token123]
```

### func set(String, String)

```cangjie
public func set(name: String, value: String): Unit
```

功能：设置指定键值对。如果 name 已经存在，传入的 value 将会覆盖之前的值。

参数：

- name: String - [HttpHeaders](http_package_classes.md#class-httpheaders) 的字段名称。
- value: String - [HttpHeaders](http_package_classes.md#class-httpheaders) 的字段值。

异常：

- [HttpException](http_package_exceptions.md#class-httpexception) - 如果传入的 name/values 包含不合法元素，将抛出此异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    let headers = HttpHeaders()

    // 使用add添加header（可以重复添加相同key）
    headers.add("Accept", "text/html")
    headers.add("Accept", "application/xml")
    println("add后 Accept: ${headers.get("Accept").toArray()}")

    // 使用set设置header（会覆盖之前的所有值）
    headers.set("Accept", "application/json")
    println("set后 Accept: ${headers.get("Accept").toArray()}")
}
```

运行结果：

```text
add后 Accept: [text/html, application/xml]
set后 Accept: [application/json]
```

## class HttpRequest

```cangjie
public class HttpRequest <: ToString
```

功能：此类为 Http 请求类。

客户端发送请求时，需要构造一个 [HttpRequest](http_package_classes.md#class-httprequest) 实例，再编码成字节报文发出。

服务端处理请求时，需要把收到的请求解析成 [HttpRequest](http_package_classes.md#class-httprequest) 实例，并传给 handler 处理函数。

父类型：

- ToString

### prop body

```cangjie
public prop body: InputStream
```

功能：获取 body。

> **注意：**
>
> - body 不支持并发读取；
> - 默认 InputStream 实现类的 read 函数不支持多次读取。

类型：InputStream

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建带有body的请求
    let req = HttpRequestBuilder().method("POST").url("http://example.com/api").body("Hello World").build()

    // 创建buffer并读取body内容
    let buffer = Array<Byte>(1024, repeat: 0)
    let bytesRead = req.body.read(buffer)

    // 将读取的内容转换为字符串
    let bodyContent = String.fromUtf8(buffer[0..bytesRead])
    println("读取字节数: ${bytesRead}")
    println("Body内容: ${bodyContent}")
}
```

运行结果：

```text
读取字节数: 11
Body内容: Hello World
```

### prop bodySize

```cangjie
public prop bodySize: Option<Int64>
```

功能：获取请求 body 长度。

> **说明：**
>
> - 如果未设置 body，则 bodySize 为 Some(0)。
> - 如果 body 长度已知，即通过 Array\<UInt8> 或 String 传入 body，或传入的 InputStream 有确定的 length (length >= 0)，则 bodySize 为 Some(Int64)。
> - 如果 body 长度未知，即通过用户自定义的 InputStream 实例传入 body 且 InputStream 实例没有确定的 length (length < 0)，则 bodySize 为 None。

类型：Option\<Int64>

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建带有String body的请求（长度已知）
    let req = HttpRequestBuilder().method("POST").url("http://example.com/api").body("Hello World").build()

    println("String body长度: ${req.bodySize ?? 0}")
}
```

运行结果：

```text
String body长度: 11
```

### prop form

```cangjie
public prop form: Form
```

功能：获取请求中的表单信息。

> **说明：**
>
> - 如果请求方法为 POST，PUT，PATCH，且 content-type 包含 application/x-www-form-urlencoded，获取请求 body 部分，用 form 格式解析。
> - 如果请求方法不为 POST，PUT，PATCH，获取请求 url 中 query 部分。

> **注意：**
>
> - 如果用该接口读取了 body，body 已被消费完，后续将无法通过 body.read 读取 body。
> - 如果 form 不符合 [Form](../../../encoding/url/url_package_api/url_package_classes.md#class-form) 格式，抛 [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) 异常。

类型：[Form](../../../encoding/url/url_package_api/url_package_classes.md#class-form)

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建带有表单数据的POST请求
    let req = HttpRequestBuilder()
        .method("POST")
        .url("http://example.com/api")
        .header("Content-Type", "application/x-www-form-urlencoded")
        .body("name=张三&age=25")
        .build()

    // 获取表单数据
    let form = req.form

    println("name: ${form.get("name") ?? ""}")
    println("age: ${form.get("age") ?? ""}")
}
```

运行结果：

```text
name: 张三
age: 25
```

### prop headers

```cangjie
public prop headers: HttpHeaders
```

功能：获取 headers，headers 详述见 [HttpHeaders](http_package_classes.md#class-httpheaders) 类，获取后，可通过调用 [HttpHeaders](http_package_classes.md#class-httpheaders) 实例成员函数，修改该请求的 headers。

类型：[HttpHeaders](http_package_classes.md#class-httpheaders)

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建请求并设置headers
    let req = HttpRequestBuilder()
        .method("GET")
        .url("http://example.com/api")
        .header("Accept", "application/json")
        .build()

    // 获取并修改headers
    let headers = req.headers
    println("Accept: ${headers.getFirst("Accept")}")
}
```

运行结果：

```text
Accept: Some(application/json)
```

### prop isPersistent

```cangjie
public prop isPersistent: Bool
```

功能：表示该请求是否为长连接。

请求 header 包含 `Connection: close` 为 false。不包含为 true。

> **说明：**
>
> - 对于服务端，isPersistent 为 false 表示处理完该请求应该关闭连接。
> - 对于客户端，isPersistent 为 false 表示如果收到响应后服务端未关闭连接，客户端应主动关闭连接。

类型：Bool

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建默认请求（长连接）
    let req1 = HttpRequestBuilder().method("GET").url("http://example.com/api").build()

    println("默认请求isPersistent: ${req1.isPersistent}")

    // 创建带Connection: close的请求（短连接）
    let req2 = HttpRequestBuilder().method("GET").url("http://example.com/api").header("Connection", "close").build()

    println("带Connection: close的isPersistent: ${req2.isPersistent}")
}
```

运行结果：

```text
默认请求isPersistent: true
带Connection: close的isPersistent: false
```

### prop method

```cangjie
public prop method: String
```

功能：获取 method。如 "GET", "POST"，request 实例的 method 无法修改。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建GET请求
    let getReq = HttpRequestBuilder().method("GET").url("http://example.com/api").build()

    println("GET请求方法: ${getReq.method}")

    // 创建POST请求
    let postReq = HttpRequestBuilder().method("POST").url("http://example.com/api").build()

    println("POST请求方法: ${postReq.method}")
}
```

运行结果：

```text
GET请求方法: GET
POST请求方法: POST
```

### prop readTimeout

```cangjie
public prop readTimeout: ?Duration
```

功能：表示该请求的请求级读超时时间。None 表示没有设置；Some(Duration) 表示已设置。

类型：?Duration

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建设置了超时时间的请求
    let req = HttpRequestBuilder().method("GET").url("http://example.com/api").readTimeout(Duration.second * 30).build()

    match (req.readTimeout) {
        case Some(timeout) => println("设置了读超时: ${timeout}")
        case None => println("未设置读超时")
    }
}
```

运行结果：

```text
设置了读超时: 30s
```

### prop remoteAddr

```cangjie
public prop remoteAddr: String
```

功能：用于服务端，获取对端地址，即客户端地址，格式为 ip: port，用户无法设置，自定义的 request 对象调用该属性返回 ""，服务端 handler 中调用该属性返回客户端地址。

类型：String

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 启动服务器
    spawn {
        =>
            // 构建 Server 实例
            let server = ServerBuilder().addr("127.0.0.1").port(8080).build()
            // 注册 HttpRequestHandler
            server.distributor.register(
                "/index",
                {
                    httpContext =>
                        let request = httpContext.request
                        println("远程地址: ${request.remoteAddr}")
                }
            )
            // 启动服务
            server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 创建 Client
    let client = ClientBuilder().build()
    // 发送GET请求
    client.get("http://127.0.0.1:8080/index")
}
```

运行结果：

```text
远程地址: 127.0.0.1:54321
```

### prop trailers

```cangjie
public prop trailers: HttpHeaders
```

功能：获取 trailers，trailers 详述见 [HttpHeaders](http_package_classes.md#class-httpheaders) 类，获取后，可通过调用 [HttpHeaders](http_package_classes.md#class-httpheaders) 实例成员函数，修改该请求的 trailers。

类型：[HttpHeaders](http_package_classes.md#class-httpheaders)

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 启动服务器
    spawn {
        =>
            // 构建 Server 实例
            let server = ServerBuilder().addr("127.0.0.1").port(8080).build()
            // 注册 HttpRequestHandler
            server.distributor.register(
                "/index",
                {
                    httpContext => httpContext
                        .responseBuilder
                        .header("Trailer", "X-Checksum, X-Transfer-Time")
                        .header("Content-Type", "text/plain")
                        // 必须使用分块传输编码，才能在响应中获取trailers
                        .header("Transfer-Encoding", "chunked")
                        .body("Hello Cangjie!")
                        .trailer("X-Checksum", "md5:123456")
                        .trailer("X-Transfer-Time", "50ms")
                }
            )
            // 启动服务
            server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 创建 Client
    let client = ClientBuilder().build()

    // 发送GET请求
    let resp = client.get("http://127.0.0.1:8080/index")

    // 循环调用直到返回 0，trailers 才会被填充
    let buffer = Array<Byte>(1024, repeat: 0)
    var bytesRead = 0
    while (true) {
        let len = resp.body.read(buffer[bytesRead..])
        if (len == 0) {
            break
        }
        bytesRead += len
    }
    let bodyContent = String.fromUtf8(buffer[0..bytesRead])
    println("先读取完响应body, trailers 才会被填充: ${bodyContent}")

    // 读取trailers
    let trailers = resp.trailers

    // 使用迭代器遍历所有header
    println("遍历所有trailers:")
    for ((name, values) in trailers) {
        println(" ${name}: ${values.toArray()}")
    }
}
```

运行结果：

```text
先读取完响应body, trailers 才会被填充: Hello Cangjie!
遍历所有trailers:
 x-checksum: [md5:123456]
 x-transfer-time: [50ms]
```

### prop url

```cangjie
public prop url: URL
```

功能：获取 url，表示客户端访问的 url。

类型：[URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url)

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建带有完整URL的请求
    let req = HttpRequestBuilder().method("GET").url("http://example.com:8080/path?key=value&foo=bar").build()

    // 获取URL各组成部分
    let url = req.url
    println("完整URL: ${url}")
    println("协议: ${url.scheme}")
    println("主机: ${url.hostName}")
    println("端口: ${url.port}")
    println("路径: ${url.path}")
}
```

运行结果：

```text
完整URL: http://example.com:8080/path?key=value&foo=bar
协议: http
主机: example.com
端口: 8080
路径: /path
```

### prop version

```cangjie
public prop version: Protocol
```

功能：获取 http 版本，如 HTTP1_1 和 HTTP2_0，request 实例的 version 无法修改。

类型：[Protocol](http_package_enums.md#enum-protocol)

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建HTTP/1.1请求（默认）
    let req1 = HttpRequestBuilder().method("GET").url("http://example.com/api").build()

    println("默认HTTP版本: ${req1.version}")

    // 创建HTTP/2请求
    let req2 = HttpRequestBuilder().method("GET").url("http://example.com/api").version(Protocol.HTTP2_0).build()

    println("HTTP/2版本: ${req2.version}")
}
```

运行结果：

```text
默认HTTP版本: HTTP/1.1
HTTP/2版本: HTTP/2.0
```

### prop writeTimeout

```cangjie
public prop writeTimeout: ?Duration
```

功能：表示该请求的请求级写超时时间，None 表示没有设置；Some(Duration) 表示设置了写超时时间。

类型：?Duration

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建未设置写超时时间的请求
    let req1 = HttpRequestBuilder().method("GET").url("http://example.com/api").build()

    match (req1.writeTimeout) {
        case Some(timeout) => println("设置了写超时: ${timeout}")
        case None => println("未设置写超时")
    }

    // 创建设置了写超时时间的请求
    let req2 = HttpRequestBuilder()
        .method("POST")
        .url("http://example.com/api")
        .writeTimeout(Duration.second * 60)
        .build()

    match (req2.writeTimeout) {
        case Some(timeout) => println("设置了写超时: ${timeout}")
        case None => println("未设置写超时")
    }
}
```

运行结果：

```text
未设置写超时
设置了写超时: 1m
```

### func toString()

```cangjie
public override func toString(): String
```

功能：把请求转换为字符串，包括 start line，headers，body size，trailers。例如：`"GET /path HTTP/1.1\r\nhost: www.example.com\r\n\r\nbody size: 5\r\nbar: foo\r\n"`。

返回值：

- String - 请求的字符串表示。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    let req = HttpRequestBuilder()
        .method("POST")
        .url("http://example.com/hello")
        .header("x-test", "1")
        .header("Content-Type", "text/plain")
        .body("abc")
        .build()

    // 不调用 toString() 也行，会自动调用
    println("POST请求信息:")
    println("-----------------------------")
    println(req.toString())
    println("-----------------------------")
}
```

运行结果：

```text
POST请求信息:
-----------------------------
POST /hello HTTP/1.1
x-test: 1
content-type: text/plain

body size: 3

-----------------------------
```

## class HttpRequestBuilder

```cangjie
public class HttpRequestBuilder {
    public init()
    public init(request: HttpRequest)
}
```

功能：[HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 类用于构造 [HttpRequest](http_package_classes.md#class-httprequest) 实例。

### init()

```cangjie
public init()
```

功能：构造一个新 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder)。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main(): Unit {
    let _ = HttpRequestBuilder()
}
```

### init(HttpRequest)

```cangjie
public init(request: HttpRequest)
```

功能：基于已有 HttpRequest 实例构造 HttpRequestBuilder。

> **说明：**
>
> - body 特殊处理：因 body 是 InputStream 类型（流式数据），对原始 request 的 body 进行读写操作，会影响通过该 Builder 构建出的新 HttpRequest 的 body。
> - 深拷贝项：Builder 的 headers、trailers 是原始 request 对应属性的深拷贝（修改 Builder 的 headers/trailers 不会影响原始 request）。
> - 浅拷贝项：method、url、readTimeout 等其余不可变属性，均为原始 request 的浅拷贝（不可变对象无需深拷贝）。

参数：

- request: [HttpRequest](http_package_classes.md#class-httprequest) - 传入的 [HttpRequest](http_package_classes.md#class-httprequest) 对象。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main(): Unit {
    let req = HttpRequestBuilder()
        .method("GET")
        .url("http://example.com/hello")
        .header("x-test", "1")
        .body("abc")
        .build()

    let _ = HttpRequestBuilder(req)
}
```

### func addHeaders(HttpHeaders)

```cangjie
public func addHeaders(headers: HttpHeaders): HttpRequestBuilder
```

功能：向请求 header 添加参数 [HttpHeaders](http_package_classes.md#class-httpheaders) 中的键值对。

参数：

- headers: [HttpHeaders](http_package_classes.md#class-httpheaders) - 传入的 header 对象。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建基础请求
    let builder = HttpRequestBuilder().method("GET").url("http://example.com/api").header("Accept", "application/json")

    // 创建额外的headers
    let extraHeaders = HttpHeaders()
    extraHeaders.add("Authorization", "Bearer token123")
    extraHeaders.add("X-Custom-Header", "custom-value")

    // 使用addHeaders添加多个header
    let req = builder.addHeaders(extraHeaders).build()

    // 验证headers已添加
    let headers = req.headers
    println("Accept: ${headers.getFirst("Accept")}")
    println("Authorization: ${headers.getFirst("Authorization")}")
    println("X-Custom-Header: ${headers.getFirst("X-Custom-Header")}")
}
```

运行结果：

```text
Accept: Some(application/json)
Authorization: Some(Bearer token123)
X-Custom-Header: Some(custom-value)
```

### func addTrailers(HttpHeaders)

```cangjie
public func addTrailers(trailers: HttpHeaders): HttpRequestBuilder
```

功能：向请求 trailer 添加参数 [HttpHeaders](http_package_classes.md#class-httpheaders) 中的键值对。

参数：

- trailers: [HttpHeaders](http_package_classes.md#class-httpheaders) - 传入的 trailer 对象。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建基础请求
    let builder = HttpRequestBuilder()
        .method("POST")
        .url("http://example.com/api")
        .header("Content-Type", "application/json")

    // 创建额外的trailers
    let extraTrailers = HttpHeaders()
    extraTrailers.add("X-Checksum", "md5:abc123")
    extraTrailers.add("X-Timestamp", "1234567890")

    // 使用addTrailers添加多个trailer
    let req = builder.addTrailers(extraTrailers).build()

    // 验证trailers已添加
    let trailers = req.trailers
    println("X-Checksum: ${trailers.getFirst("X-Checksum")}")
    println("X-Timestamp: ${trailers.getFirst("X-Timestamp")}")
}
```

运行结果：

```text
X-Checksum: Some(md5:abc123)
X-Timestamp: Some(1234567890)
```

### func body(Array\<UInt8>)

```cangjie
public func body(body: Array<UInt8>): HttpRequestBuilder
```

功能：设置请求 body。如果已经设置过，调用该函数将替换原 body。

参数：

- body: Array\<UInt8> - 字节数组形式的请求体。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建字节数组body
    let bodyData = "Hello from Array<UInt8>".toArray()

    // 使用字节数组创建请求
    let req = HttpRequestBuilder()
        .method("POST")
        .url("http://example.com/api")
        .header("Content-Type", "text/plain")
        .body(bodyData)
        .build()

    // 读取并验证body
    let buffer = Array<Byte>(1024, repeat: 0)
    let bytesRead = req.body.read(buffer)
    let content = String.fromUtf8(buffer[0..bytesRead])

    println("Body大小: ${req.bodySize}")
    println("Body内容: ${content}")
}
```

运行结果：

```text
Body大小: Some(23)
Body内容: Hello from Array<UInt8>
```

### func body(InputStream)

```cangjie
public func body(body: InputStream): HttpRequestBuilder
```

功能：设置请求 body。如果已经设置过，调用该函数将替换原 body。

参数：

- body: InputStream - 流形式的请求体。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.net.http.*

main(): Unit {
    // 创建一个流
    let body = ByteBuffer("Hello World".toArray())

    // 创建一个简单的POST请求
    let req = HttpRequestBuilder()
        .method("POST")
        .url("http://example.com/api")
        .header("Content-Type", "text/plain")
        .body(body)
        .build()

    // 读取并验证body
    let buffer = Array<Byte>(1024, repeat: 0)
    let bytesRead = req.body.read(buffer)
    let content = String.fromUtf8(buffer[0..bytesRead])

    println("Body大小: ${req.bodySize}")
    println("Body内容: ${content}")
}
```

运行结果：

```text
Body大小: Some(11)
Body内容: Hello World
```

### func body(String)

```cangjie
public func body(body: String): HttpRequestBuilder
```

功能：设置请求 body，如果已经设置过，调用该函数将替换原 body 调用该函数设置请求 body，则 body 将以内置的 InputStream 实现类表示，其大小已知。

参数：

- body: String - 字符串形式的请求体。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用String设置请求body
    let req = HttpRequestBuilder()
        .method("POST")
        .url("http://example.com/api")
        .header("Content-Type", "application/json")
        .body("{\"name\": \"张三\", \"age\": 25}")
        .build()

    // 读取并验证body
    let buffer = Array<Byte>(1024, repeat: 0)
    let bytesRead = req.body.read(buffer)
    let content = String.fromUtf8(buffer[0..bytesRead])

    println("Body大小: ${req.bodySize}")
    println("Body内容: ${content}")
}
```

运行结果：

```text
Body大小: Some(29)
Body内容: {"name": "张三", "age": 25}
```

### func build()

```cangjie
public func build(): HttpRequest
```

功能：根据 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例生成一个 [HttpRequest](http_package_classes.md#class-httprequest) 实例。

返回值：

- [HttpRequest](http_package_classes.md#class-httprequest) - 根据当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例构造出来的 [HttpRequest](http_package_classes.md#class-httprequest) 实例。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用builder构建GET请求
    let getReq = HttpRequestBuilder()
        .method("GET")
        .url("http://example.com/users")
        .header("Accept", "application/json")
        .build()

    println("GET请求方法: ${getReq.method}")
    println("GET请求URL: ${getReq.url}")
}
```

运行结果：

```text
GET请求方法: GET
GET请求URL: http://example.com/users
```

### func connect()

```cangjie
public func connect(): HttpRequestBuilder
```

功能：构造 method 为 "CONNECT" 的请求的便捷函数。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用connect便捷方法创建CONNECT请求
    let req = HttpRequestBuilder().url("http://example.com:8080").connect().build()
    println("CONNECT方法: ${req.method}")
}
```

运行结果：

```text
CONNECT方法: CONNECT
```

### func delete()

```cangjie
public func delete(): HttpRequestBuilder
```

功能：构造 method 为 "DELETE" 的请求的便捷函数。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用delete便捷方法创建DELETE请求
    let req = HttpRequestBuilder().url("http://example.com/api/123").delete().build()
    println("DELETE方法: ${req.method}")
}
```

运行结果：

```text
DELETE方法: DELETE
```

### func get()

```cangjie
public func get(): HttpRequestBuilder
```

功能：构造 method 为 "GET" 的请求的便捷函数。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用get便捷方法创建GET请求
    let req = HttpRequestBuilder().url("http://example.com/api").get().build()
    println("GET方法: ${req.method}")
}
```

运行结果：

```text
GET方法: GET
```

### func head()

```cangjie
public func head(): HttpRequestBuilder
```

功能：构造 method 为 "HEAD" 的请求的便捷函数。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用head便捷方法创建HEAD请求
    let req = HttpRequestBuilder().url("http://example.com/api").head().build()
    println("HEAD方法: ${req.method}")
}
```

运行结果：

```text
HEAD方法: HEAD
```

### func header(String, String)

```cangjie
public func header(name: String, value: String): HttpRequestBuilder
```

功能：向请求 header 添加指定键值对，规则同 [HttpHeaders](http_package_classes.md#class-httpheaders) 类的 add 函数。

参数：

- name: String - 请求头的 key。
- value: String - 请求头的 value。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

异常：

- [HttpException](http_package_exceptions.md#class-httpexception) - 如果传入的 name 或 value 包含不合法元素，将抛出此异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用header方法添加多个请求头
    let req = HttpRequestBuilder()
        .method("GET")
        .url("http://example.com/api")
        .header("Accept", "application/json")
        .header("Authorization", "Bearer token123")
        .header("X-Request-ID", "req-456")
        .build()

    let headers = req.headers
    println("Accept: ${headers.getFirst("Accept")}")
    println("Authorization: ${headers.getFirst("Authorization")}")
    println("X-Request-ID: ${headers.getFirst("X-Request-ID")}")
}
```

运行结果：

```text
Accept: Some(application/json)
Authorization: Some(Bearer token123)
X-Request-ID: Some(req-456)
```

### func method(String)

```cangjie
public func method(method: String): HttpRequestBuilder
```

功能：设置请求 method，默认请求 method 为 "GET"。

参数：

- method: String - 请求方法，必须由 token 字符组成，如果传入空字符串，method 值将自动设置为 "GET"。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

异常：

- [HttpException](http_package_exceptions.md#class-httpexception) - 参数 method 非法时抛出此异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用method方法设置自定义HTTP方法
    let req1 = HttpRequestBuilder().url("http://example.com/api").method("GET").build()
    println("GET请求: ${req1.method}")

    // 使用PATCH方法
    let req2 = HttpRequestBuilder()
        .url("http://example.com/api/123")
        .method("PATCH")
        .header("Content-Type", "application/json")
        .body("{\"field\": \"value\"}")
        .build()
    println("PATCH请求: ${req2.method}")
}
```

运行结果：

```text
GET请求: GET
PATCH请求: PATCH
```

### func options()

```cangjie
public func options(): HttpRequestBuilder
```

功能：构造 method 为 "OPTIONS" 的请求的便捷函数。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用options便捷方法创建OPTIONS请求
    let req = HttpRequestBuilder().url("http://example.com/api").options().build()
    println("OPTIONS方法: ${req.method}")
}
```

运行结果：

```text
OPTIONS方法: OPTIONS
```

### func post()

```cangjie
public func post(): HttpRequestBuilder
```

功能：构造 method 为 "POST" 的请求的便捷函数。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用post便捷方法创建POST请求
    let req = HttpRequestBuilder()
        .url("http://example.com/api")
        .header("Content-Type", "application/json")
        .body("{\"name\": \"test\"}")
        .post()
        .build()
    println("POST方法: ${req.method}")
}
```

运行结果：

```text
POST方法: POST
```

### func priority(Int64, Bool)

```cangjie
public func priority(urg: Int64, inc: Bool): HttpRequestBuilder
```

功能：设置 priority 头的便捷函数，调用此函数后，将生成 priority 头，形如："priority: urgency=x, i"。如果通过设置请求头的函数设置了 priority 字段，调用此函数无效。如果多次调用此函数，以最后一次为准。

参数：

- urg: Int64 - 表示请求优先级，取值范围为 [0, 7]，0 表示最高优先级。
- inc: Bool - 同优先级请求的处理方式：true 表示希望服务器把「和当前请求优先级相同」的这类请求一起并发处理；false 表示希望服务器对这类请求一个一个串行处理，不并发。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

异常：

- [HttpException](./http_package_exceptions.md#class-httpexception) - 当参数 urg 取值非法，即不在 [0, 7] 范围内时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 设置高优先级请求（urgency=0表示最高优先级）
    let highPriorityReq = HttpRequestBuilder()
        .method("GET")
        .url("http://example.com/api/critical")
        .priority(0, true)
        .build()
    let priority = highPriorityReq.headers.getFirst("priority") ?? ""
    println("priority: ${priority}")
}
```

运行结果：

```text
priority: u=0, i
```

### func put()

```cangjie
public func put(): HttpRequestBuilder
```

功能：构造 method 为 "PUT" 的请求的便捷函数。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用put便捷方法创建PUT请求
    let req = HttpRequestBuilder()
        .url("http://example.com/api/123")
        .header("Content-Type", "application/json")
        .body("{\"name\": \"updated\"}")
        .put()
        .build()
    println("PUT方法: ${req.method}")
}
```

运行结果：

```text
PUT方法: PUT
```

### func readTimeout(Duration)

```cangjie
public func readTimeout(timeout: Duration): HttpRequestBuilder
```

功能：设置此请求的读超时时间。如果传入的 Duration 为负，则会自动转为 0。如果用户设置了此读超时时间，那么该请求的读超时以此为准；如果用户没有设置，那么该请求的读超时以 [Client](http_package_classes.md#class-client) 为准。

参数：

- timeout: Duration - 用户设置的此请求的读超时时间。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 设置30秒读超时
    let req1 = HttpRequestBuilder()
        .method("GET")
        .url("http://example.com/api")
        .readTimeout(Duration.second * 30)
        .build()

    match (req1.readTimeout) {
        case Some(timeout) => println("读超时: ${timeout}")
        case None => println("没有设置读超时")
    }
}
```

运行结果：

```text
读超时: 30s
```

### func setHeaders(HttpHeaders)

```cangjie
public func setHeaders(headers: HttpHeaders): HttpRequestBuilder
```

功能：设置请求 header，如果已经设置过，调用该函数将替换原 header。

参数：

- headers: [HttpHeaders](http_package_classes.md#class-httpheaders) - 传入的 header 对象。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建新的headers对象
    let newHeaders = HttpHeaders()
    newHeaders.add("Content-Type", "application/json")

    // 使用setHeaders替换所有headers
    let req = HttpRequestBuilder()
        .method("POST")
        .url("http://example.com/api")
        .header("Old-Header", "old-value") // 这个会被替换掉
        .setHeaders(newHeaders)
        .build()

    let headers = req.headers
    println("Content-Type: ${headers.getFirst("Content-Type")}")
    println("Old-Header: ${headers.getFirst("Old-Header")}") // 应该是None
}
```

运行结果：

```text
Content-Type: Some(application/json)
Old-Header: None
```

### func setTrailers(HttpHeaders)

```cangjie
public func setTrailers(trailers: HttpHeaders): HttpRequestBuilder
```

功能：设置请求 trailer，如果已经设置过，调用该函数将替换原 trailer。

参数：

- trailers: [HttpHeaders](http_package_classes.md#class-httpheaders) - 传入的 trailer 对象。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建新的trailers对象
    let newTrailers = HttpHeaders()
    newTrailers.add("X-Checksum", "sha256:abc123")
    newTrailers.add("X-Timestamp", "1234567890")

    // 使用setTrailers替换所有trailers
    let req = HttpRequestBuilder()
        .method("POST")
        .url("http://example.com/api")
        .trailer("Old-Trailer", "old-value") // 这个会被替换掉
        .setTrailers(newTrailers)
        .build()

    let trailers = req.trailers
    println("X-Checksum: ${trailers.getFirst("X-Checksum")}")
    println("X-Timestamp: ${trailers.getFirst("X-Timestamp")}")
    println("Old-Trailer: ${trailers.getFirst("Old-Trailer")}") // 应该是None
}
```

运行结果：

```text
X-Checksum: Some(sha256:abc123)
X-Timestamp: Some(1234567890)
Old-Trailer: None
```

### func trace()

```cangjie
public func trace(): HttpRequestBuilder
```

功能：构造 method 为 "TRACE" 的请求的便捷函数。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用trace便捷方法创建TRACE请求
    let req = HttpRequestBuilder().url("http://example.com/api").trace().build()
    println("TRACE方法: ${req.method}")
}
```

运行结果：

```text
TRACE方法: TRACE
```

### func trailer(String, String)

```cangjie
public func trailer(name: String, value: String): HttpRequestBuilder
```

功能：向请求 trailer 添加指定键值对，规则同 [HttpHeaders](http_package_classes.md#class-httpheaders) 类的 add 函数。

参数：

- name: String - 请求头的 key。
- value: String - 请求头的 value。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

异常：

- [HttpException](http_package_exceptions.md#class-httpexception) - 如果传入的 name 或 value 包含不合法元素，将抛出此异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用trailer方法添加多个trailer
    let req = HttpRequestBuilder()
        .method("POST")
        .url("http://example.com/api")
        .header("Content-Type", "application/json")
        .body("{\"data\": \"test\"}")
        .trailer("X-Checksum", "md5:def789")
        .trailer("X-Request-Time", "100ms")
        .build()

    let trailers = req.trailers
    println("X-Checksum: ${trailers.getFirst("X-Checksum")}")
    println("X-Request-Time: ${trailers.getFirst("X-Request-Time")}")
}
```

运行结果：

```text
X-Checksum: Some(md5:def789)
X-Request-Time: Some(100ms)
```

### func url(String)

```cangjie
public func url(rawUrl: String): HttpRequestBuilder
```

功能：设置请求 url，默认 url 为空的 [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) 对象。

参数：

- rawUrl: String - 待解析成 url 对象的字符串，该字符串格式详见 [URL.parse](../../../encoding/url/url_package_api/url_package_classes.md#static-func-parsestring) 函数。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

异常：

- IllegalArgumentException - 当被编码的字符不符合 UTF8 的字节序列规则时，抛出异常。
- [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) - 当传入字符串不符合 [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) 格式时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用url方法设置请求URL
    let req = HttpRequestBuilder().method("GET").url("http://example.com/api/users").build()
    println("URL: ${req.url}")
}
```

运行结果：

```text
URL: http://example.com/api/users
```

### func url(URL)

```cangjie
public func url(url: URL): HttpRequestBuilder
```

功能：设置请求 url，默认 url 为空的 [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) 对象，即 [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url).parse("")。

参数：

- url: [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) - URL 对象。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*
import stdx.encoding.url.*

main(): Unit {
    // 使用URL对象设置请求URL
    let url = URL.parse("http://example.com:9090/api/v1/users?id=123")

    let req = HttpRequestBuilder().method("GET").url(url).build()

    println("URL: ${req.url}")
    println("协议: ${req.url.scheme}")
    println("路径: ${req.url.path}")
    println("查询: ${req.url.query}")
}
```

运行结果：

```text
URL: http://example.com:9090/api/v1/users?id=123
协议: http
路径: /api/v1/users
查询: Some(id=123)
```

### func version(Protocol)

```cangjie
public func version(version: Protocol): HttpRequestBuilder
```

功能：设置请求的 http 协议版本，默认为 UnknownProtocol("")，客户端会根据 tls 配置自动选择协议。

参数：

- version: [Protocol](http_package_enums.md#enum-protocol) - 协议版本。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 默认HTTP/1.1
    let req1 = HttpRequestBuilder().method("GET").url("http://example.com/api").build()
    println("默认版本: ${req1.version}")

    // 显式设置HTTP/1.1
    let req2 = HttpRequestBuilder().method("GET").url("http://example.com/api").version(Protocol.HTTP1_1).build()
    println("HTTP/1.1: ${req2.version}")

    // 设置HTTP/2
    let req3 = HttpRequestBuilder().method("GET").url("http://example.com/api").version(Protocol.HTTP2_0).build()
    println("HTTP/2: ${req3.version}")
}
```

运行结果：

```text
默认版本: HTTP/1.1
HTTP/1.1: HTTP/1.1
HTTP/2: HTTP/2.0
```

### func writeTimeout(Duration)

```cangjie
public func writeTimeout(timeout: Duration): HttpRequestBuilder
```

功能：设置此请求的写超时时间。如果传入的 Duration 为负，则会自动转为 0。如果用户设置了此写超时时间，那么该请求的写超时以此为准；如果用户没有设置，那么该请求的写超时以 [Client](http_package_classes.md#class-client) 为准。

参数：

- timeout: Duration - 用户设置的此请求的写超时时间。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 设置30秒写超时
    let req = HttpRequestBuilder()
        .method("POST")
        .url("http://example.com/api")
        .writeTimeout(Duration.second * 30)
        .build()

    match (req.writeTimeout) {
        case Some(timeout) => println("写超时: ${timeout}")
        case None => println("没有设置写超时")
    }
}
```

运行结果：

```text
写超时: 30s
```

## class HttpResponse

```cangjie
public class HttpResponse <: ToString
```

功能：Http 响应类。

此类定义了 http 中响应 Response 的相关接口，客户端用该类读取服务端返回的响应。

父类型：

- ToString

### prop body

```cangjie
public prop body: InputStream
```

功能：获取 body。

> **注意：**
>
> - body 不支持并发读取；
> - 默认 InputStream 实现类的 read 函数不支持多次读取。

类型：InputStream

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用 HttpResponseBuilder 构造响应
    let resp = HttpResponseBuilder().status(200).header("Content-Type", "text/plain").body("Hello World").build()

    // 读取响应 body
    let buffer = Array<Byte>(1024, repeat: 0)
    let bytesRead = resp.body.read(buffer)
    let bodyContent = String.fromUtf8(buffer[0..bytesRead])

    println("状态码: ${resp.status}")
    println("Body大小: ${resp.bodySize}")
    println("Body内容: ${bodyContent}")
}
```

运行结果：

```text
状态码: 200
Body大小: Some(11)
Body内容: Hello World
```

### prop bodySize

```cangjie
public prop bodySize: Option<Int64>
```

功能：获取响应 body 长度。

> - 如果未设置 body，则 bodySize 为 Some(0)；
> - 如果 body 长度已知，即通过 Array\<UInt8> 或 String 传入 body，或传入的 InputStream 有确定的 length (length >= 0)，则 bodySize 为 Some(Int64)；
> - 如果 body 长度未知，即通过用户自定义的 InputStream 实例传入 body 且 InputStream 实例没有确定的 length (length < 0)，则 bodySize 为 None。

类型：Option\<Int64>

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 构造带有String body的响应（长度已知）
    let resp1 = HttpResponseBuilder().status(200).body("Hello World").build()
    println("String body大小: ${resp1.bodySize}")

    // 构造不带有body的响应
    let resp2 = HttpResponseBuilder().status(204).build()
    println("无body时大小: ${resp2.bodySize}")
}
```

运行结果：

```text
String body大小: Some(11)
无body时大小: Some(0)
```

### prop headers

```cangjie
public prop headers: HttpHeaders
```

功能：获取 headers，headers 详述见 [HttpHeaders](http_package_classes.md#class-httpheaders) 类，获取后，可通过调用 [HttpHeaders](http_package_classes.md#class-httpheaders) 实例成员函数，修改该请求的 headers。

类型：[HttpHeaders](http_package_classes.md#class-httpheaders)

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 构造带有headers的响应
    let resp = HttpResponseBuilder()
        .status(200)
        .header("Content-Type", "application/json")
        .header("X-Request-ID", "req-123")
        .body("{\"status\": \"ok\"}")
        .build()

    // 获取并修改headers
    let headers = resp.headers
    println("Content-Type: ${headers.getFirst("Content-Type")}")
    println("X-Request-ID: ${headers.getFirst("X-Request-ID")}")

    // 添加新header
    headers.add("X-Custom-Header", "custom-value")
    println("X-Custom-Header: ${headers.getFirst("X-Custom-Header")}")
}
```

运行结果：

```text
Content-Type: Some(application/json)
X-Request-ID: Some(req-123)
X-Custom-Header: Some(custom-value)
```

### prop isPersistent

```cangjie
public prop isPersistent: Bool
```

功能：表示该响应是否为长连接，即响应 header 是否不包含 `Connection: close`。包含 `Connection: close` 为 false，否则为 true。

对于服务端，isPersistent 为 false 表示处理完该请求应关闭连接；

对于客户端，isPersistent 为 false 表示读完响应体后客户端应主动关闭连接。

类型：Bool

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 构造默认响应（长连接）
    let resp1 = HttpResponseBuilder().status(200).body("OK").build()
    println("默认响应isPersistent: ${resp1.isPersistent}")

    // 构造带Connection: close的响应（短连接）
    let resp2 = HttpResponseBuilder().status(200).header("Connection", "close").body("OK").build()
    println("带Connection: close的isPersistent: ${resp2.isPersistent}")
}
```

运行结果：

```text
默认响应isPersistent: true
带Connection: close的isPersistent: false
```

### prop request

```cangjie
public prop request: Option<HttpRequest>
```

功能：获取该响应对应的请求，默认为 None。

类型：Option\<[HttpRequest](http_package_classes.md#class-httprequest)>

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 构造请求
    let req = HttpRequestBuilder().method("GET").url("http://example.com/api").build()

    // 构造响应对应该请求
    let resp = HttpResponseBuilder().status(200).request(req).body("OK").build()

    // 获取响应对应的请求
    match (resp.request) {
        case Some(r) => println("请求方法: ${r.method}")
        case None => println("无关联请求")
    }
}
```

运行结果：

```text
请求方法: GET
```

### prop status

```cangjie
public prop status: UInt16
```

功能：获取响应的状态码，默认值为 200。状态码由 100~599 的三位数字组成，状态码所反映的具体信息可参考 [RFC 9110](https://httpwg.org/specs/rfc9110.html#status.codes)。

类型：UInt16

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 构造200 OK响应
    let resp = HttpResponseBuilder().status(200).body("OK").build()
    println("成功响应状态码: ${resp.status}")
}
```

运行结果：

```text
成功响应状态码: 200
```

### prop trailers

```cangjie
public prop trailers: HttpHeaders
```

功能：获取 trailers，trailers 详述见 [HttpHeaders](http_package_classes.md#class-httpheaders) 类，获取后，可通过调用 [HttpHeaders](http_package_classes.md#class-httpheaders) 实例成员函数，修改该请求的 trailers。

类型：[HttpHeaders](http_package_classes.md#class-httpheaders)

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 构造带有trailers的响应
    let resp = HttpResponseBuilder()
        .status(200)
        .header("Trailer", "X-Checksum, X-Timestamp")
        .body("Response data")
        .trailer("X-Checksum", "md5:abc123")
        .trailer("X-Timestamp", "1234567890")
        .build()

    // 获取trailers
    let trailers = resp.trailers
    println("X-Checksum: ${trailers.getFirst("X-Checksum")}")
    println("X-Timestamp: ${trailers.getFirst("X-Timestamp")}")
}
```

运行结果：

```text
X-Checksum: Some(md5:abc123)
X-Timestamp: Some(1234567890)
```

### prop version

```cangjie
public prop version: Protocol
```

功能：获取响应的协议版本，默认值为 [HTTP1_1](./http_package_enums.md#enum-protocol)。

类型：[Protocol](http_package_enums.md#enum-protocol)

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 构造HTTP/1.1响应（默认）
    let resp1 = HttpResponseBuilder().status(200).body("OK").build()
    println("默认HTTP版本: ${resp1.version}")

    // 构造HTTP/2响应
    let resp2 = HttpResponseBuilder().status(200).version(Protocol.HTTP2_0).body("OK").build()
    println("HTTP/2版本: ${resp2.version}")
}
```

运行结果：

```text
默认HTTP版本: HTTP/1.1
HTTP/2版本: HTTP/2.0
```

### func close()

```cangjie
public func close(): Unit
```

功能：如果用户不再需要未读完的 body 数据，可以调用此接口关闭连接以释放资源。如果是 HTTP/2 协议，会发送一个 Reset 帧关闭对应的流。

> **注意：**
>
> 如果使用者已读完 body，无需调用此接口再释放资源。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 构造一个带body的响应
    let resp = HttpResponseBuilder().status(200).body("这是一个巨大的不想读完的响应体").build()

    // 在未读完body时关闭连接释放资源
    resp.close()
}
```

### func toString()

```cangjie
public override func toString(): String
```

功能：把响应转换为字符串，包括 status-line，headers，body size， trailers。

返回值：

- String - 响应的字符串表示。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 构造一个完整的响应
    let resp = HttpResponseBuilder()
        .status(200)
        .header("Content-Type", "application/json")
        .header("Content-Length", "12")
        .body("this is body")
        .build()

    // 转换为字符串表示
    println("响应信息:")
    println(resp.toString())
}
```

运行结果：

```text
响应信息:
HTTP/1.1 200 OK
content-type: application/json
content-length: 12

body size: 12

```

### extend HttpResponse

```cangjie
extend HttpResponse
```

功能：为 HttpResponse 扩展 HTTP/2.0 特有的方法。

#### func getPush()

```cangjie
public func getPush(): Option<ArrayList<HttpResponse>>
```

功能：获取服务器推送的响应，返回 None 代表未开启服务器推送功能，返回空 ArrayList 代表无服务器推送的响应。

返回值：

- Option\<ArrayList\<[HttpResponse](http_package_classes.md#class-httpresponse)>> - 服务器推送的响应列表。

示例：
<!-- associated_example -->
参见 [static func getPusher](#static-func-getpusherhttpcontext) 示例。

## class HttpResponseBuilder

```cangjie
public class HttpResponseBuilder {
    public init()
}
```

功能：用于构造 [HttpResponse](http_package_classes.md#class-httpresponse) 实例。

### init()

```cangjie
public init()
```

功能：构造一个新 [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder)。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main(): Unit {
    let _ = HttpResponseBuilder()
}
```

### func addHeaders(HttpHeaders)

```cangjie
public func addHeaders(headers: HttpHeaders): HttpResponseBuilder
```

功能：向响应 header 添加参数 [HttpHeaders](http_package_classes.md#class-httpheaders) 中的键值对。

参数：

- headers: [HttpHeaders](http_package_classes.md#class-httpheaders) - 传入的 header 对象。

返回值：

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - 当前 [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建 HttpResponseBuilder 并添加 headers
    let headers = HttpHeaders()
    headers.add("X-Custom-Header", "custom-value")
    headers.add("X-Request-Id", "12345")

    let resp = HttpResponseBuilder().status(200).addHeaders(headers).body("OK").build()

    // 验证 headers 已添加
    let respHeaders = resp.headers
    println("X-Custom-Header: ${respHeaders.getFirst("X-Custom-Header")}")
    println("X-Request-Id: ${respHeaders.getFirst("X-Request-Id")}")
}
```

运行结果：

```text
X-Custom-Header: Some(custom-value)
X-Request-Id: Some(12345)
```

### func addTrailers(HttpHeaders)

```cangjie
public func addTrailers(trailers: HttpHeaders): HttpResponseBuilder
```

功能：向响应 trailer 添加参数 [HttpHeaders](http_package_classes.md#class-httpheaders) 中的键值对。

参数：

- trailers: [HttpHeaders](http_package_classes.md#class-httpheaders) - 传入的 trailer 对象。

返回值：

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - 当前 [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建 HttpResponseBuilder 并添加 trailers
    let trailers = HttpHeaders()
    trailers.add("X-Trailer-Info", "end-of-response")

    let resp = HttpResponseBuilder().status(200).addTrailers(trailers).body("OK").build()

    // 验证 trailers 已添加
    let respTrailers = resp.trailers
    println("X-Trailer-Info: ${respTrailers.getFirst("X-Trailer-Info")}")
}
```

运行结果：

```text
X-Trailer-Info: Some(end-of-response)
```

### func body(Array\<UInt8>)

```cangjie
public func body(body: Array<UInt8>): HttpResponseBuilder
```

功能：设置响应 body，如果已经设置过，调用该函数将替换原 body。

参数：

- body: Array\<UInt8> - 字节数组形式的响应体。

返回值：

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - 当前 [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用字节数组设置 body
    let data: Array<UInt8> = [72, 101, 108, 108, 111] // "Hello"

    let resp = HttpResponseBuilder().status(200).body(data).build()

    println("响应 body 大小: ${resp.bodySize}")
}
```

运行结果：

```text
响应 body 大小: Some(5)
```

### func body(InputStream)

```cangjie
public func body(body: InputStream): HttpResponseBuilder
```

功能：设置响应 body，如果已经设置过，调用该函数将替换原 body 调用该函数设置请求 body。

参数：

- body: InputStream - 流形式的响应体。

返回值：

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - 当前 [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import std.io.*
import stdx.net.http.*

main(): Unit {
    // 使用 ByteBuffer 作为 InputStream 设置 body
    let data: Array<UInt8> = [72, 101, 108, 108, 111] // "Hello"
    let buffer = ByteBuffer(data)

    let resp = HttpResponseBuilder().status(200).body(buffer).build()

    println("响应 body 大小: ${resp.bodySize}")
}
```

运行结果：

```text
响应 body 大小: Some(5)
```

### func body(String)

```cangjie
public func body(body: String): HttpResponseBuilder
```

功能：设置响应 body，如果已经设置过，调用该函数将替换原 body 调用该函数设置请求 body。

参数：

- body: String - 字符串形式的响应体。

返回值：

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - 当前 [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用字符串设置 body
    let resp = HttpResponseBuilder().status(200).body("Hello World").build()

    println("响应 body 大小: ${resp.bodySize}")
}
```

运行结果：

```text
响应 body 大小: Some(11)
```

### func build()

```cangjie
public func build(): HttpResponse
```

功能：根据 [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) 实例生成一个 [HttpResponse](http_package_classes.md#class-httpresponse) 实例。

返回值：

- [HttpResponse](http_package_classes.md#class-httpresponse) - 根据当前 [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) 实例构造出来的 [HttpResponse](http_package_classes.md#class-httpresponse) 实例。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用 build() 构建 HttpResponse
    let resp = HttpResponseBuilder().status(200).header("Content-Type", "text/plain").body("OK").build()

    println("响应状态码: ${resp.status}")
    println("Content-Type: ${resp.headers.getFirst("Content-Type")}")
}
```

运行结果：

```text
响应状态码: 200
Content-Type: Some(text/plain)
```

### func header(String, String)

```cangjie
public func header(name: String, value: String): HttpResponseBuilder
```

功能：向响应 header 添加指定键值对，规则同 [HttpHeaders](http_package_classes.md#class-httpheaders) 类的 add 函数。

参数：

- name: String - 响应头的 key。
- value: String - 响应头的 value。

返回值：

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - 当前 [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) 实例的引用。

异常：

- [HttpException](http_package_exceptions.md#class-httpexception) - 如果传入的 name 或 value 包含不合法元素，将抛出此异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用 header() 添加单个 header
    let resp = HttpResponseBuilder()
        .status(200)
        .header("Content-Type", "application/json")
        .header("X-Request-Id", "abc123")
        .body("{}")
        .build()

    let headers = resp.headers
    println("Content-Type: ${headers.getFirst("Content-Type")}")
    println("X-Request-Id: ${headers.getFirst("X-Request-Id")}")
}
```

运行结果：

```text
Content-Type: Some(application/json)
X-Request-Id: Some(abc123)
```

### func request(HttpRequest)

```cangjie
public func request(request: HttpRequest): HttpResponseBuilder
```

功能：设置响应对应的请求。

参数：

- request: [HttpRequest](http_package_classes.md#class-httprequest) - 响应对应的请求。

返回值：

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - 当前 [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建关联的请求
    let req = HttpRequestBuilder().method("GET").url("http://example.com/api").build()

    // 使用 request() 设置响应对应的请求
    let resp = HttpResponseBuilder().status(200).request(req).body("OK").build()

    println("响应状态码：${resp.status}")
    match (resp.request) {
        case Some(r) => println("关联请求方法：${r.method}")
        case None => println("无关联请求")
    }
}
```

运行结果：

```text
响应状态码：200
关联请求方法：GET
```

### func setHeaders(HttpHeaders)

```cangjie
public func setHeaders(headers: HttpHeaders): HttpResponseBuilder
```

功能：设置响应 header，如果已经设置过，调用该函数将替换原 header。

参数：

- headers: [HttpHeaders](http_package_classes.md#class-httpheaders) - 传入的 header 对象。

返回值：

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - 当前 [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建新的 headers 替换原有 headers
    let newHeaders = HttpHeaders()
    newHeaders.add("X-New-Header", "new-value")

    let resp = HttpResponseBuilder()
        .status(200)
        .header("X-Old-Header", "old-value")
        .setHeaders(newHeaders)
        .body("OK")
        .build()

    let headers = resp.headers
    println("X-New-Header: ${headers.getFirst("X-New-Header")}")
    println("X-Old-Header: ${headers.getFirst("X-Old-Header")}")
}
```

运行结果：

```text
X-New-Header: Some(new-value)
X-Old-Header: None
```

### func setTrailers(HttpHeaders)

```cangjie
public func setTrailers(trailers: HttpHeaders): HttpResponseBuilder
```

功能：设置响应 trailer，如果已经设置过，调用该函数将替换原 trailer。

参数：

- trailers: [HttpHeaders](http_package_classes.md#class-httpheaders) - 传入的 trailer 对象。

返回值：

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - 当前 [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建新的 trailers 替换原有 trailers
    let newTrailers = HttpHeaders()
    newTrailers.add("X-New-Trailer", "new-value")

    let resp = HttpResponseBuilder()
        .status(200)
        .trailer("X-Old-Trailer", "old-value")
        .setTrailers(newTrailers)
        .body("OK")
        .build()

    let trailers = resp.trailers
    println("X-New-Trailer: ${trailers.getFirst("X-New-Trailer")}")
    println("X-Old-Trailer: ${trailers.getFirst("X-Old-Trailer")}")
}
```

运行结果：

```text
X-New-Trailer: Some(new-value)
X-Old-Trailer: None
```

### func status(UInt16)

```cangjie
public func status(status: UInt16): HttpResponseBuilder
```

功能：设置 http 响应状态码。

参数：

- status: UInt16 - 传入的状态码的值。

返回值：

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - 当前 [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) 实例的引用。

异常：

- [HttpException](http_package_exceptions.md#class-httpexception) - 如果设置响应状态码不在 100~599 这个区间内，则抛出此异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用 status() 设置状态码
    let resp = HttpResponseBuilder().status(404).body("Not Found").build()

    println("响应状态码：${resp.status}")
}
```

运行结果：

```text
响应状态码：404
```

### func trailer(String, String)

```cangjie
public func trailer(name: String, value: String): HttpResponseBuilder
```

功能：向响应 trailer 添加指定键值对，规则同 [HttpHeaders](http_package_classes.md#class-httpheaders) 类的 add 函数。

参数：

- name: String - 响应头的 key。
- value: String - 响应头的 value。

返回值：

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - 当前 [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) 实例的引用。

异常：

- [HttpException](http_package_exceptions.md#class-httpexception) - 如果传入的 name 或 value 包含不合法元素，将抛出此异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用 trailer() 添加单个 trailer
    let resp = HttpResponseBuilder()
        .status(200)
        .trailer("X-Checksum", "md5:abc123")
        .trailer("X-Timestamp", "1234567890")
        .body("OK")
        .build()

    let trailers = resp.trailers
    println("X-Checksum: ${trailers.getFirst("X-Checksum")}")
    println("X-Timestamp: ${trailers.getFirst("X-Timestamp")}")
}
```

运行结果：

```text
X-Checksum: Some(md5:abc123)
X-Timestamp: Some(1234567890)
```

### func version(Protocol)

```cangjie
public func version(version: Protocol): HttpResponseBuilder
```

功能：设置 http 响应协议版本。

参数：

- version: [Protocol](http_package_enums.md#enum-protocol) - 协议版本。

返回值：

- [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) - 当前 [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) 实例的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用 version() 设置协议版本
    let resp = HttpResponseBuilder().status(200).version(Protocol.HTTP1_1).body("OK").build()

    println("响应协议版本：${resp.version}")
}
```

运行结果：

```text
响应协议版本：HTTP/1.1
```

## class HttpResponsePusher

```cangjie
public class HttpResponsePusher
```

功能：HTTP/2 服务器推送。

> **说明：**
>
> - 如果服务器收到请求后，认为客户端后续还需要某些关联资源，可以将其提前推送到客户端；
> - 服务端推送包括推送请求和推送响应；
> - 启用服务端推送需要先调用 push 函数发送推送请求，并向服务器注册该请求对应的 handler，用以生成推送响应；
> - 客户端可设置拒绝服务端推送；
> - 不允许嵌套推送，即不允许在推送请求对应的 handler 中再次推送。嵌套推送情况下，服务端将不执行推送，并打印日志进行提示。

### static func getPusher(HttpContext)

```cangjie
public static func getPusher(ctx: HttpContext): ?HttpResponsePusher
```

功能：获取 [HttpResponsePusher](http_package_classes.md#class-httpresponsepusher) 实例，如果客户端拒绝推送，将返回 None。

参数：

- ctx: [HttpContext](#class-httpcontext) - Http 请求上下文。

返回值：

- ?[HttpResponsePusher](http_package_classes.md#class-httpresponsepusher) - 获得的 [HttpResponsePusher](http_package_classes.md#class-httpresponsepusher)。

示例：

<!-- verify -->
```cangjie
import std.io.*
import std.fs.*
import std.process.*
import stdx.net.tls.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*
import stdx.net.tls.common.*
import stdx.net.http.*

main(): Unit {
    // OpenSSL 官方标准、无风险的测试命令用来本地生成证书和私钥
    // 生成服务器私钥、证书、证书请求路径
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"
    let serverCsr = "./server.csr"

    // 根证书/私钥路径
    let rootCrt = "./rootCA.crt"
    let rootKey = "./rootCA.key"

    // 客户端私钥、证书、证书请求路径
    let clientKey = "./client.key"
    let clientCrt = "./client.crt"
    let clientCsr = "./client.csr"

    // 生成根CA证书
    let rootCmd = "openssl req -x509 -newkey rsa:4096 -nodes -keyout ${rootKey} -out ${rootCrt} -days 3650 -subj \"/C=CN/ST=Beijing/L=Beijing/O=MyCA/OU=CA/CN=MyRootCA\""
    executeWithOutput("sh", ["-c", rootCmd])

    // 生成服务器私钥+证书请求（CSR） 
    let csrCmd = "openssl req -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCsr} -subj \"/C=CN/ST=Beijing/L=Beijing/O=MyServer/OU=Server/CN=localhost\""
    executeWithOutput("sh", ["-c", csrCmd])

    // 用根CA签发服务器证书
    let signCmd = "openssl x509 -req -in ${serverCsr} -CA ${rootCrt} -CAkey ${rootKey} -CAcreateserial -out ${serverCrt} -days 365 -sha256"
    executeWithOutput("sh", ["-c", signCmd])

    // 生成客户端私钥+证书请求（CSR）
    let clientCsrCmd = "openssl req -newkey rsa:2048 -nodes -keyout ${clientKey} -out ${clientCsr} -subj \"/C=CN/ST=Beijing/L=Beijing/O=MyClient/OU=Client/CN=MyClient\""
    executeWithOutput("sh", ["-c", clientCsrCmd])

    // 用根CA签发客户端证书（和服务端同根CA，服务端会信任）
    let clientSignCmd = "openssl x509 -req -in ${clientCsr} -CA ${rootCrt} -CAkey ${rootKey} -CAcreateserial -out ${clientCrt} -days 365 -sha256"
    executeWithOutput("sh", ["-c", clientSignCmd])

    // 读取根证书PEM
    let pem = String.fromUtf8(File.readFrom(rootCrt))

    // 启动服务器
    spawn {
        =>
            // 对服务器证书以及私钥进行解析 
            let pemString = String.fromUtf8(File.readFrom(serverCrt))
            let keyString = String.fromUtf8(File.readFrom(serverKey))

            let certificate = X509Certificate.decodeFromPem(pemString)
            let privateKey = GeneralPrivateKey.decodeFromPem(keyString)

            // 创建 TLS 服务器配置
            var config = TlsServerConfig(certificate, privateKey)
            // 一定要设置 ALPN 协议为 h2
            config.supportedAlpnProtocols = ["h2"]
            // 开启客户端身份验证，也可以不开启
            config.clientIdentityRequired = Required
            // 设置验证模式
            config.verifyMode = CustomCA(X509Certificate.decodeFromPem(pem).map({c => c}))

            // 构建 Server 实例
            let server = ServerBuilder().addr("127.0.0.1").tlsConfig(config).port(8080).build()
            // 注册 HttpRequestHandler
            server.distributor.register(
                "/index.html",
                {
                    httpContext =>
                        httpContext.responseBuilder.body("index.html 资源").status(200)
                        let pusher = HttpResponsePusher.getPusher(httpContext).getOrThrow()
                        // 推送 index.css 和 index.js
                        pusher.push("/index.css", "GET", HttpHeaders())
                        pusher.push("/index.js", "GET", HttpHeaders())
                }
            )
            server.distributor.register(
                "/index.css",
                {
                    httpContext => httpContext.responseBuilder.body("index.css 资源").status(200)
                }
            )
            server.distributor.register(
                "/index.js",
                {
                    httpContext => httpContext.responseBuilder.body("index.js 资源").status(200)
                }
            )
            // 启动服务
            server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 客户端配置
    var config = TlsClientConfig()
    let clientPem = String.fromUtf8(File.readFrom(clientCrt))
    let clientKeyStr = String.fromUtf8(File.readFrom(clientKey))
    let clientPriKey = GeneralPrivateKey.decodeFromPem(clientKeyStr)
    // 设置客户端证书和私钥
    config.certificate = (X509Certificate.decodeFromPem(clientPem).map({c => c}), clientPriKey)
    // 一定要设置 ALPN 协议为 h2
    config.supportedAlpnProtocols = ["h2"]
    // 设置验证模式
    config.verifyMode = CustomCA(X509Certificate.decodeFromPem(pem).map({c => c}))

    // 创建 Client
    let client = ClientBuilder().tlsConfig(config).build()
    // 发送GET请求
    let resp = client.get("https://127.0.0.1:8080/index.html")
    // 读取响应体
    let bodyBuf = Array<UInt8>(1024, repeat: 0)
    let bytesRead = resp.body.read(bodyBuf)
    println("主请求获得: ${String.fromUtf8(bodyBuf[..bytesRead])}")

    // 处理推送请求
    let pushResponses = resp.getPush().getOrThrow()
    // 遍历推送请求
    for (pushResponse in pushResponses) {
        let bodyBuf = Array<UInt8>(1024, repeat: 0)
        let bytesRead = pushResponse.body.read(bodyBuf)
        println("推送请求获得: ${String.fromUtf8(bodyBuf[..bytesRead])}")
    }
    // 清理生成的文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
    removeIfExists(serverCsr)
    removeIfExists(rootCrt)
    removeIfExists(rootKey)
    removeIfExists(clientKey)
    removeIfExists(clientCrt)
    removeIfExists(clientCsr)
}
```

运行结果：

```text
主请求获得: index.html 资源
推送请求获得: index.css 资源
推送请求获得: index.js 资源
```

### func push(String, String, HttpHeaders)

```cangjie
public func push(path: String, method: String, header: HttpHeaders): Unit
```

功能：向客户端发送推送请求，path 为请求地址，method 为请求方法，header 为请求头。

参数：

- path: String - 推送的请求地址。
- method: String - 推送的请求方法。
- header: [HttpHeaders](#class-httpheaders) - 推送的请求头。

示例：
<!-- associated_example -->
参见 [static func getPusher](#static-func-getpusherhttpcontext) 示例。

## class HttpResponseWriter

```cangjie
public class HttpResponseWriter {
    public HttpResponseWriter(let ctx: HttpContext)
}
```

功能：HTTP response 消息体 Writer，支持用户控制消息体的发送过程。

> **说明：**
>
> - 第一次调用 write 函数时，将立即发送 header 和通过参数传入的 body，此后每次调用 write，发送通过参数传入的 body。
> - 对于 HTTP/1.1，如果设置了 transfer-encoding: chunked，用户每调用一次 write，将发送一个 chunk。
> - 对于 HTTP/2，用户每调用一次 write，将把指定数据封装并发出。

### HttpResponseWriter(HttpContext)

```cangjie
public HttpResponseWriter(let ctx: HttpContext)
```

功能：构造一个 [HttpResponseWriter](http_package_classes.md#class-httpresponsewriter) 实例。

参数：

- ctx: [HttpContext](#class-httpcontext) - Http 请求上下文。

示例：

<!-- verify -->
```cangjie
import std.io.*
import std.fs.*
import std.process.*
import stdx.net.tls.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*
import stdx.net.tls.common.*
import stdx.net.http.*

main(): Unit {
    // OpenSSL 官方标准、无风险的测试命令用来本地生成证书和私钥
    // 生成服务器私钥、证书、证书请求路径
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"
    let serverCsr = "./server.csr"

    // 根证书/私钥路径
    let rootCrt = "./rootCA.crt"
    let rootKey = "./rootCA.key"

    // 客户端私钥、证书、证书请求路径
    let clientKey = "./client.key"
    let clientCrt = "./client.crt"
    let clientCsr = "./client.csr"

    // 生成根CA证书
    let rootCmd = "openssl req -x509 -newkey rsa:4096 -nodes -keyout ${rootKey} -out ${rootCrt} -days 3650 -subj \"/C=CN/ST=Beijing/L=Beijing/O=MyCA/OU=CA/CN=MyRootCA\""
    executeWithOutput("sh", ["-c", rootCmd])

    // 生成服务器私钥+证书请求（CSR） 
    let csrCmd = "openssl req -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCsr} -subj \"/C=CN/ST=Beijing/L=Beijing/O=MyServer/OU=Server/CN=localhost\""
    executeWithOutput("sh", ["-c", csrCmd])

    // 用根CA签发服务器证书
    let signCmd = "openssl x509 -req -in ${serverCsr} -CA ${rootCrt} -CAkey ${rootKey} -CAcreateserial -out ${serverCrt} -days 365 -sha256"
    executeWithOutput("sh", ["-c", signCmd])

    // 生成客户端私钥+证书请求（CSR）
    let clientCsrCmd = "openssl req -newkey rsa:2048 -nodes -keyout ${clientKey} -out ${clientCsr} -subj \"/C=CN/ST=Beijing/L=Beijing/O=MyClient/OU=Client/CN=MyClient\""
    executeWithOutput("sh", ["-c", clientCsrCmd])

    // 用根CA签发客户端证书（和服务端同根CA，服务端会信任）
    let clientSignCmd = "openssl x509 -req -in ${clientCsr} -CA ${rootCrt} -CAkey ${rootKey} -CAcreateserial -out ${clientCrt} -days 365 -sha256"
    executeWithOutput("sh", ["-c", clientSignCmd])

    // 读取根证书PEM
    let pem = String.fromUtf8(File.readFrom(rootCrt))

    // 启动服务器
    spawn {
        =>
            // 对服务器证书以及私钥进行解析 
            let pemString = String.fromUtf8(File.readFrom(serverCrt))
            let keyString = String.fromUtf8(File.readFrom(serverKey))

            let certificate = X509Certificate.decodeFromPem(pemString)
            let privateKey = GeneralPrivateKey.decodeFromPem(keyString)

            // 创建 TLS 服务器配置
            var config = TlsServerConfig(certificate, privateKey)
            // 一定要设置 ALPN 协议为 h2，否则要有 Content-Length 或 transfer-encoding: chunked 头
            config.supportedAlpnProtocols = ["h2"]
            // 开启客户端身份验证，也可以不开启
            config.clientIdentityRequired = Required
            // 设置验证模式
            config.verifyMode = CustomCA(X509Certificate.decodeFromPem(pem).map({c => c}))

            // 构建 Server 实例
            let server = ServerBuilder().addr("127.0.0.1").tlsConfig(config).port(8080).build()
            // 注册 HttpRequestHandler
            server.distributor.register(
                "/index",
                {
                    httpContext =>
                        let writer = HttpResponseWriter(httpContext)
                        // 第一次写入
                        writer.write("Hello, World!".toArray())
                        // 第二次写入
                        writer.write("Cangjie!".toArray())
                }
            )
            // 启动服务
            server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 客户端配置
    var config = TlsClientConfig()
    let clientPem = String.fromUtf8(File.readFrom(clientCrt))
    let clientKeyStr = String.fromUtf8(File.readFrom(clientKey))
    let clientPriKey = GeneralPrivateKey.decodeFromPem(clientKeyStr)
    // 设置客户端证书和私钥
    config.certificate = (X509Certificate.decodeFromPem(clientPem).map({c => c}), clientPriKey)
    // 一定要设置 ALPN 协议为 h2，否则服务器响应要有 Content-Length 或 transfer-encoding: chunked 头
    config.supportedAlpnProtocols = ["h2"]
    // 设置验证模式
    config.verifyMode = CustomCA(X509Certificate.decodeFromPem(pem).map({c => c}))

    // 创建 Client
    let client = ClientBuilder().tlsConfig(config).build()
    // 发送GET请求
    let resp = client.get("https://127.0.0.1:8080/index")

    // 读取响应体
    let bodyBuf = Array<UInt8>(1024, repeat: 0)
    let bytesRead = resp.body.read(bodyBuf)
    println("第一次获得: ${String.fromUtf8(bodyBuf[..bytesRead])}")

    // 读取响应体
    let bodyBuf1 = Array<UInt8>(1024, repeat: 0)
    let bytesRead1 = resp.body.read(bodyBuf1)
    println("第二次获得: ${String.fromUtf8(bodyBuf1[..bytesRead1])}")
    // 清理生成的文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
    removeIfExists(serverCsr)
    removeIfExists(rootCrt)
    removeIfExists(rootKey)
    removeIfExists(clientKey)
    removeIfExists(clientCrt)
    removeIfExists(clientCsr)
}
```

运行结果：

```text
第一次获得: Hello, World!
第二次获得: Cangjie!
```

### func write(Array\<Byte>)

```cangjie
public func write(buf: Array<Byte>): Unit
```

功能：发送数据到客户端。

参数：

- buf: Array\<Byte> - 要发送的数据。

异常：

- [HttpException](http_package_exceptions.md#class-httpexception) - 请求方法为 "HEAD" 或响应状态码为 "1XX\204\304"。
- [HttpException](http_package_exceptions.md#class-httpexception) - 连接关闭。
- [HttpException](http_package_exceptions.md#class-httpexception) - response 协议版本为 HTTP/1.0。
- [HttpException](http_package_exceptions.md#class-httpexception) - 响应连接已升级为 [WebSocket](http_package_classes.md#class-websocket)。

示例：
<!-- associated_example -->
参见 [HttpResponseWriter](#httpresponsewriterhttpcontext) 示例。

## class NotFoundHandler

```cangjie
public class NotFoundHandler <: HttpRequestHandler
```

功能：便捷的 Http 请求处理器，`404 Not Found` 处理器。

父类型：

- [HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler)

### func handle(HttpContext)

```cangjie
public func handle(ctx: HttpContext): Unit
```

功能：处理 Http 请求，回复 404 响应。

参数：

- ctx: [HttpContext](http_package_classes.md#class-httpcontext) - Http 请求上下文。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 启动服务器
    spawn {
        =>
            // 构建 Server 实例
            let server = ServerBuilder().addr("127.0.0.1").port(8080).build()
            // 注册 HttpRequestHandler，也可以直接 register("/index", NotFoundHandler())
            server.distributor.register(
                "/index",
                {
                    httpContext =>
                        let notFoundHandler = NotFoundHandler()
                        notFoundHandler.handle(httpContext)
                }
            )
            // 启动服务
            server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 创建 Client
    let client = ClientBuilder().build()
    // 发送GET请求
    let resp = client.get("http://127.0.0.1:8080/index")

    // 读取响应体
    let bodyBuf = Array<UInt8>(1000, repeat: 0)
    let bytesRead = resp.body.read(bodyBuf)
    println("状态码: ${resp.status}")
    println("响应体: ${String.fromUtf8(bodyBuf[..bytesRead])}")
}
```

运行结果：

```text
状态码: 404
响应体: 404 Not Found
```

## class OptionsHandler

```cangjie
public class OptionsHandler <: HttpRequestHandler
```

功能：便捷的 Http 处理器，用于处理 OPTIONS 请求。固定返回 "Allow: OPTIONS，GET，HEAD，POST，PUT，DELETE" 响应头。

父类型：

- [HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler)

### func handle(HttpContext)

```cangjie
public func handle(ctx: HttpContext): Unit
```

功能：处理 Http OPTIONS 请求。

参数：

- ctx: [HttpContext](http_package_classes.md#class-httpcontext) - Http 请求上下文。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 启动服务器
    spawn {
        =>
            // 构建 Server 实例
            let server = ServerBuilder().addr("127.0.0.1").port(8080).build()
            // 注册 HttpRequestHandler，也可以直接 register("/index", OptionsHandler())
            server.distributor.register(
                "/index",
                {
                    httpContext =>
                        let optionsHandler = OptionsHandler()
                        optionsHandler.handle(httpContext)
                }
            )
            // 启动服务
            server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 创建 Client
    let client = ClientBuilder().build()
    // 发送GET请求
    let resp = client.get("http://127.0.0.1:8080/index")

    // 读取响应体
    let bodyBuf = Array<UInt8>(1000, repeat: 0)
    let bytesRead = resp.body.read(bodyBuf)
    println("状态码: ${resp.status}")
    println("响应体: ${String.fromUtf8(bodyBuf[..bytesRead])}")
    println("响应头: ${resp.headers.getFirst("allow") ?? ""}")
}
```

运行结果：

```text
状态码: 200
响应体: 
响应头: OPTIONS, GET, HEAD, POST, PUT, DELETE
```

## class ProtocolService

```cangjie
public abstract class ProtocolService
```

功能：Http 协议服务实例，为单个客户端连接提供 Http 服务，包括对客户端 request 报文的解析、 request 的分发处理、 response 的发送等。

### prop distributor

```cangjie
protected prop distributor: HttpRequestDistributor
```

功能：获取请求分发器，请求分发器会根据 url 将请求分发给对应的 handler。

类型：[HttpRequestDistributor](http_package_interfaces.md#interface-httprequestdistributor)

示例：
<!-- associated_example -->
参见 [func serve](#func-serve) 示例。

### prop httpKeepAliveTimeout

```cangjie
protected prop httpKeepAliveTimeout: Duration
```

功能：HTTP/1.1 专用，获取服务器设定的保持长连接的超时时间。

类型：Duration

示例：
<!-- associated_example -->
参见 [func serve](#func-serve) 示例。

### prop logger

```cangjie
protected prop logger: Logger
```

功能：获取服务器日志记录器，设置 logger.level 将立即生效，记录器应该是线程安全的。

类型：[Logger](../../../log/log_package_api/log_package_classes.md#class-logger)

示例：
<!-- associated_example -->
参见 [func serve](#func-serve) 示例。

### prop maxRequestBodySize

```cangjie
protected prop maxRequestBodySize: Int64
```

功能：获取服务器设定的读取请求的请求体最大值，仅对于 HTTP/1.1 且未设置 "Transfer-Encoding: chunked" 的请求生效。

类型：Int64

示例：
<!-- associated_example -->
参见 [func serve](#func-serve) 示例。

### prop maxRequestHeaderSize

```cangjie
protected prop maxRequestHeaderSize: Int64
```

功能：获取服务器设定的读取请求的请求头最大值。仅对 HTTP/1.1 生效，HTTP/2 中有专门的配置 maxHeaderListSize。

类型：Int64

示例：
<!-- associated_example -->
参见 [func serve](#func-serve) 示例。

### prop readHeaderTimeout

```cangjie
protected prop readHeaderTimeout: Duration
```

功能：获取服务器设定的读取请求头的超时时间。

类型：Duration

示例：
<!-- associated_example -->
参见 [func serve](#func-serve) 示例。

### prop readTimeout

```cangjie
protected prop readTimeout: Duration
```

功能：获取服务器设定的读取整个请求的超时时间。建议在生产环境中显式配置该项。如果保持默认不超时，服务端连接和资源可能被慢速请求长期占用，增加遭受慢请求类攻击的风险。

类型：Duration

示例：
<!-- associated_example -->
参见 [func serve](#func-serve) 示例。

### prop server

```cangjie
protected open mut prop server: Server
```

功能：返回 [Server](#class-server) 实例，提供默认实现，设置为绑定的 [Server](#class-server) 实例。

类型：Server

示例：
<!-- associated_example -->
参见 [func serve](#func-serve) 示例。

### prop writeTimeout

```cangjie
protected prop writeTimeout: Duration
```

功能：获取服务器设定的写响应的超时时间。建议在生产环境中显式配置该项。如果保持默认不超时，服务端连接和资源可能被慢速读写长期占用，增加遭受慢连接类攻击的风险。

类型：Duration

示例：
<!-- associated_example -->
参见 [func serve](#func-serve) 示例。

### func close()

```cangjie
protected open func close(): Unit
```

功能：强制关闭连接，提供默认实现，无任何行为。

示例：
<!-- associated_example -->
参见 [func serve](#func-serve) 示例。

### func closeGracefully()

```cangjie
protected open func closeGracefully(): Unit
```

功能：优雅关闭连接，提供默认实现，无任何行为。

示例：
<!-- associated_example -->
参见 [func serve](#func-serve) 示例。

### func serve()

```cangjie
protected func serve(): Unit
```

功能：处理来自客户端连接的请求，不提供默认实现。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*
import std.net.*

class MyProtocolServiceFactory <: ProtocolServiceFactory {
    // 此处获得协议类型，socket连接，可以根据需要创建不同的ProtocolService
    public func create(protocol: Protocol, socket: StreamingSocket): ProtocolService {
        println("协议: ${protocol}")
        return MyProtocolService(socket)
    }
}

// 自定义ProtocolService，满足自定义/个性化需求
class MyProtocolService <: ProtocolService {
    let socket: StreamingSocket
    init(socket: StreamingSocket) {
        this.socket = socket
    }
    protected func serve() {
        // 注意：自定义ProtocolService的分发器无法使用
        let _ = this.distributor
        println("保持长连接的超时时间: ${this.httpKeepAliveTimeout}")
        println("日志等级: ${this.logger.level}")
        println("最大请求体大小: ${this.maxRequestBodySize}")
        println("最大请求头大小: ${this.maxRequestHeaderSize}")
        println("读取请求头超时时间: ${this.readHeaderTimeout}")
        println("读取整个请求的超时时间: ${this.readTimeout}")
        println("服务器地址: ${this.server.addr}")
        println("写入超时时间: ${this.writeTimeout}")
        // 无任何实现，可自定义
        this.close()
        // 无任何实现，可自定义
        this.closeGracefully()
        // 写入响应
        socket.write("HTTP/1.1 200 ok\r\ncontent-length: 23\r\n\r\nHello MyProtocolService".toArray())
        this.socket.close()
    }
}

main(): Unit {
    // 启动服务器
    spawn {
        =>
            // 构建 Server 实例
            let server = ServerBuilder()
                .addr("127.0.0.1")
                .port(8080)
                .protocolServiceFactory(MyProtocolServiceFactory())
                .maxRequestBodySize(1024)
                .maxRequestHeaderSize(1024)
                .readHeaderTimeout(Duration.second * 10)
                .httpKeepAliveTimeout(Duration.second * 10)
                .readTimeout(Duration.second * 10)
                .writeTimeout(Duration.second * 10)
                .build()
            // 注册的 HttpRequestHandler 已无法使用
            server.distributor.register("/index", OptionsHandler())
            // 启动服务
            server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 创建 Client
    let client = ClientBuilder().build()
    // 发送GET请求
    let resp = client.get("http://127.0.0.1:8080/index")

    // 读取响应体
    let bodyBuf = Array<UInt8>(1000, repeat: 0)
    let bytesRead = resp.body.read(bodyBuf)
    println("状态码: ${resp.status}")
    println("响应体: ${String.fromUtf8(bodyBuf[..bytesRead])}")
}
```

运行结果：

```text
协议: HTTP/1.1
保持长连接的超时时间: 10s
日志等级: INFO
最大请求体大小: 1024
最大请求头大小: 1024
读取请求头超时时间: 10s
读取整个请求的超时时间: 10s
服务器地址: 127.0.0.1
写入超时时间: 10s
状态码: 200
响应体: Hello MyProtocolService
```

## class RedirectHandler

```cangjie
public class RedirectHandler <: HttpRequestHandler {
    public init(url: String, code: UInt16)
}
```

功能：便捷的 Http 处理器，用于回复重定向响应。

父类型：

- [HttpRequestHandler](http_package_interfaces.md#interface-httprequesthandler)

### init(String, UInt16)

```cangjie
public init(url: String, code: UInt16)
```

功能：[RedirectHandler](http_package_classes.md#class-redirecthandler) 的构造函数。

参数：

- url: String - 重定向响应中 Location 头部的 url。
- code: UInt16 - 重定向响应的响应码。

异常：

- [HttpException](http_package_exceptions.md#class-httpexception) - url 为空或响应码不是除 304 以外的 3XX 状态码时抛出异常。

示例：
<!-- associated_example -->
参见 [func handle](#func-handlehttpcontext-4) 示例。

### func handle(HttpContext)

```cangjie
public func handle(ctx: HttpContext): Unit
```

功能：处理 Http 请求，回复重定向响应。

参数：

- ctx: [HttpContext](http_package_classes.md#class-httpcontext) - Http 请求上下文。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 启动服务器
    spawn {
        =>
            // 构建 Server 实例
            let server = ServerBuilder().addr("127.0.0.1").port(8080).build()
            // 注册 HttpRequestHandler，也可以直接 register("/index", RedirectHandler("/to", 302))
            server.distributor.register(
                "/index",
                {
                    httpContext =>
                        let redirectHandler = RedirectHandler("/toOptions", 302)
                        redirectHandler.handle(httpContext)
                }
            )
            server.distributor.register("/toOptions", OptionsHandler())
            server.distributor.register("/toNotFound", NotFoundHandler())
            // 启动服务
            server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 创建 Client
    let client = ClientBuilder().build()
    // 发送GET请求
    let resp = client.get("http://127.0.0.1:8080/index")

    // 读取响应体
    let bodyBuf = Array<UInt8>(1000, repeat: 0)
    let bytesRead = resp.body.read(bodyBuf)
    println("状态码: ${resp.status}")
    println("响应体: ${String.fromUtf8(bodyBuf[..bytesRead])}")
    println("响应头: ${resp.headers.getFirst("allow") ?? ""}")
}
```

运行结果：

```text
状态码: 200
响应体: 
响应头: OPTIONS, GET, HEAD, POST, PUT, DELETE
```

## class Server

```cangjie
public class Server
```

功能：提供 HTTP 服务的 [Server](http_package_classes.md#class-server) 类。

> **说明：**
>
> - 启动服务，在指定地址及端口等待用户连接、服务用户的 http request；
> - 关闭服务，包括关闭所有已有连接；
> - 提供注册处理 http request 的 handler 的机制，根据注册信息分发 request 到相应的 handler；
> - 提供 tls 证书热机制；
> - 提供 shutdown 回调机制；
> - 通过 [Logger](../../../log/log_package_api/log_package_classes.md#class-logger).level 开启、关闭日志打印，包括按照用户要求打印相应级别的日志；
> - [Server](http_package_classes.md#class-server) 文档中未明确说明支持版本的配置，在 HTTP/1.1 与 HTTP/2 都会生效。

### prop addr

```cangjie
public prop addr: String
```

功能：获取服务端监听地址。

类型：String

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建服务器
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    // 获取服务端监听地址
    println("服务器监听地址：${server.addr}")
}
```

运行结果：

```text
服务器监听地址：127.0.0.1
```

### prop distributor

```cangjie
public prop distributor: HttpRequestDistributor
```

功能：获取请求分发器，请求分发器会根据 url 将请求分发给对应的 handler。

类型：[HttpRequestDistributor](http_package_interfaces.md#interface-httprequestdistributor)

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建服务器
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    // 获取请求分发器
    let distributor = server.distributor
}
```

### prop enableConnectProtocol

```cangjie
public prop enableConnectProtocol: Bool
```

功能：HTTP/2 专用，用来限制对端发送的报文是否支持通过 connect 方法升级协议，true 表示支持。

类型：Bool

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建服务器
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    // 获取是否支持 CONNECT 协议升级
    let enableConnect = server.enableConnectProtocol

    println("CONNECT 协议升级支持：${enableConnect}")
}
```

运行结果：

```text
CONNECT 协议升级支持：false
```

### prop headerTableSize

```cangjie
public prop headerTableSize: UInt32
```

功能：获取服务端 HTTP/2 Hpack 动态表的初始值，默认值为 4096。

类型：UInt32

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建服务器
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    // 获取 HTTP/2 Hpack 动态表大小
    let tableSize = server.headerTableSize

    println("HTTP/2 Hpack 动态表大小：${tableSize}")
}
```

运行结果：

```text
HTTP/2 Hpack 动态表大小：4096
```

### prop httpKeepAliveTimeout

```cangjie
public prop httpKeepAliveTimeout: Duration
```

功能：HTTP/1.1 专用，获取服务器设定的保持长连接的超时时间。

类型：Duration

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建服务器
    let server = ServerBuilder().addr("127.0.0.1").port(8080).httpKeepAliveTimeout(Duration.second * 30).build()

    // 获取 HTTP/1.1 长连接超时时间
    let keepAliveTimeout = server.httpKeepAliveTimeout

    println("HTTP/1.1 长连接超时时间：${keepAliveTimeout}")
}
```

运行结果：

```text
HTTP/1.1 长连接超时时间：30s
```

### prop initialWindowSize

```cangjie
public prop initialWindowSize: UInt32
```

功能：HTTP/2 专用，用来限制对端发送的报文 stream 初始流量窗口大小。默认值为 65535 ，取值范围为 0 至 2^31 - 1。

类型：UInt32

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建服务器
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    // 获取 HTTP/2 初始流量窗口大小
    let windowSize = server.initialWindowSize

    println("HTTP/2 初始流量窗口大小：${windowSize}")
}
```

运行结果：

```text
HTTP/2 初始流量窗口大小：65535
```

### prop listener

```cangjie
public prop listener: ServerSocket
```

功能：获取服务器绑定 socket。

类型：ServerSocket

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建服务器
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    // 获取服务器绑定 socket
    let listener = server.listener

    println("服务器绑定地址长度：${listener.localAddress.size}")
}
```

运行结果：

```text
服务器绑定地址长度：16
```

### prop logger

```cangjie
public prop logger: Logger
```

功能：获取服务器日志记录器，设置 logger.level 将立即生效，记录器应该是线程安全的。

类型：[Logger](../../../log/log_package_api/log_package_classes.md#class-logger)

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*
import stdx.logger.*
import std.env.*

main(): Unit {
    // 构建 Server 实例并设置 logger
    let server = ServerBuilder().addr("127.0.0.1").port(8080).logger(SimpleLogger(getStdOut())).build()

    println("日志等级: ${server.logger.level}")
}
```

运行结果：

```text
日志等级: INFO
```

### prop maxConcurrentStreams

```cangjie
public prop maxConcurrentStreams: UInt32
```

功能：HTTP/2 专用，用来限制连接同时处理的最大请求数量。

类型：UInt32

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建服务器
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    // 获取 HTTP/2 最大并发流数量
    let maxStreams = server.maxConcurrentStreams

    println("HTTP/2 最大并发流数量：${maxStreams}")
}
```

运行结果：

```text
HTTP/2 最大并发流数量：100
```

### prop maxFrameSize

```cangjie
public prop maxFrameSize: UInt32
```

功能：HTTP/2 专用，用来限制对端发送的报文一个帧的最大长度。默认值为 16384. 取值范围为 2^14 至 2^24 - 1。

类型：UInt32

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建服务器
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    // 获取 HTTP/2 最大帧大小
    let maxFrameSize = server.maxFrameSize

    println("HTTP/2 最大帧大小：${maxFrameSize}")
}
```

运行结果：

```text
HTTP/2 最大帧大小：16384
```

### prop maxHeaderListSize

```cangjie
public prop maxHeaderListSize: UInt32
```

功能：获取客户端支持的 HTTP/2 最大头部（Header）大小。这个大小指的是响应头部中所有头部字段（Header Field）的最大允许长度之和，其中包括所有字段名称（name）的长度、字段值（value）的长度以及每个字段自动添加的伪头开销（通常每个字段会有 32 字节的开销，这包括了 HTTP/2 协议本身为头部字段添加的伪头部信息）。默认情况下，这个最大长度被设置为 UInt32.Max。

类型：UInt32

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建服务器
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    // 获取 HTTP/2 最大头部列表大小
    let maxHeaderListSize = server.maxHeaderListSize

    println("HTTP/2 最大头部列表大小：${maxHeaderListSize}")
}
```

运行结果：

```text
HTTP/2 最大头部列表大小：8192
```

### prop maxRequestBodySize

```cangjie
public prop maxRequestBodySize: Int64
```

功能：获取服务器设定的读取请求的请求体最大值，仅对于 HTTP/1.1 且未设置 "Transfer-Encoding: chunked" 的请求生效。

类型：Int64

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建服务器
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    // 获取最大请求体大小
    let maxBodySize = server.maxRequestBodySize

    println("最大请求体大小：${maxBodySize}")
}
```

运行结果：

```text
最大请求体大小：2097152
```

### prop maxRequestHeaderSize

```cangjie
public prop maxRequestHeaderSize: Int64
```

功能：获取服务器设定的读取请求的请求头最大值。仅对 HTTP/1.1 生效，HTTP/2 中有专门的配置 maxHeaderListSize。

类型：Int64

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建服务器
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    // 获取最大请求头大小
    let maxHeaderSize = server.maxRequestHeaderSize

    println("最大请求头大小：${maxHeaderSize}")
}
```

运行结果：

```text
最大请求头大小：8192
```

### prop port

```cangjie
public prop port: UInt16
```

功能：获取服务端监听端口。

类型：UInt16

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建服务器
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    // 获取服务端监听端口
    let port = server.port

    println("服务器监听端口：${port}")
}
```

运行结果：

```text
服务器监听端口：8080
```

### prop protocolServiceFactory

```cangjie
public prop protocolServiceFactory: ProtocolServiceFactory
```

功能：获取协议服务工厂，服务协议工厂会生成每个协议所需的服务实例。

类型：[ProtocolServiceFactory](http_package_interfaces.md#interface-protocolservicefactory)

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建服务器
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    // 获取协议服务工厂
    let _ = server.protocolServiceFactory
}
```

### prop readHeaderTimeout

```cangjie
public prop readHeaderTimeout: Duration
```

功能：获取服务器设定的读取请求头的超时时间。

类型：Duration

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 设置读取 header 超时时间为 10 秒
    let server = ServerBuilder().addr("127.0.0.1").port(8080).readHeaderTimeout(Duration.second * 10).build()

    println("读取 header 超时时间：${server.readHeaderTimeout}")
}
```

运行结果：

```text
读取 header 超时时间：10s
```

### prop readTimeout

```cangjie
public prop readTimeout: Duration
```

功能：获取服务器设定的读取整个请求的超时时间。

类型：Duration

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 设置读取超时时间为 30 秒
    let server = ServerBuilder().addr("127.0.0.1").port(8080).readTimeout(Duration.second * 30).build()

    println("读取超时时间：${server.readTimeout}")
}
```

运行结果：

```text
读取超时时间：30s
```

### prop servicePoolConfig

```cangjie
public prop servicePoolConfig: ServicePoolConfig
```

功能：获取协程池配置实例。

类型：[ServicePoolConfig](http_package_structs.md#struct-servicepoolconfig)

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建协程池配置
    var poolCfg = ServicePoolConfig(capacity: 100, queueCapacity: 200, preheat: 10)

    // 使用 servicePoolConfig 设置协程池配置
    let server = ServerBuilder().addr("127.0.0.1").port(8080).servicePoolConfig(poolCfg).build()

    println("协程池容量：${server.servicePoolConfig.capacity}")
    println("队列容量：${server.servicePoolConfig.queueCapacity}")
    println("预热数量：${server.servicePoolConfig.preheat}")
}
```

运行结果：

```text
协程池容量：100
队列容量：200
预热数量：10
```

### prop transportConfig

```cangjie
public prop transportConfig: TransportConfig
```

功能：获取服务器设定的传输层配置。

类型：[TransportConfig](http_package_structs.md#struct-transportconfig)

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建传输层配置
    var transportCfg = TransportConfig()
    transportCfg.readBufferSize = 8192

    // 使用 transportConfig 设置传输层配置
    let server = ServerBuilder().addr("127.0.0.1").port(8080).transportConfig(transportCfg).build()

    println("读取缓冲区大小：${server.transportConfig.readBufferSize}")
}
```

运行结果：

```text
读取缓冲区大小：Some(8192)
```

### prop writeTimeout

```cangjie
public prop writeTimeout: Duration
```

功能：获取服务器设定的写响应的超时时间。

类型：Duration

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 设置写入超时时间为 30 秒
    let server = ServerBuilder().addr("127.0.0.1").port(8080).writeTimeout(Duration.second * 30).build()

    println("写入超时时间：${server.writeTimeout}")
}
```

运行结果：

```text
写入超时时间：30s
```

### func afterBind(() -> Unit)

```cangjie
public func afterBind(f: () -> Unit): Unit
```

功能：注册服务器启动时的回调函数，服务内部 ServerSocket 实例 bind 之后，accept 之前将调用该函数。重复调用将覆盖之前注册的函数。

参数：

- f: () -> Unit - 回调函数，入参为空，返回值为 Unit 类型。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    spawn {
        // 启动时触发回调函数
        let server = ServerBuilder().addr("127.0.0.1").port(8080).afterBind({
            => println("服务器已启动")
        }).build()
        server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)
}
```

运行结果：

```text
服务器已启动
```

### func close()

```cangjie
public func close(): Unit
```

功能：关闭服务器，服务器关闭后将不再对请求进行读取与处理，重复关闭将只有第一次生效（包括 close 和 closeGracefully）。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main(): Unit {
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    spawn {
        server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 关闭服务器
    server.close()
}
```

### func closeGracefully()

```cangjie
public func closeGracefully(): Unit
```

功能：关闭服务器，服务器关闭后将不再对请求进行读取，当前正在进行处理的服务器待处理结束后进行关闭。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main(): Unit {
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    spawn {
        server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 优雅关闭服务器
    server.closeGracefully()
}
```

### func getTlsConfig()

```cangjie
public func getTlsConfig(): ?TlsConfig
```

功能：获取服务器设定的 TLS 层配置。

返回值：

- ?[TlsConfig](../../tls/common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconfig) - 服务端设定的 TLS 层配置，如果没有设置则返回 None。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建服务器（未配置 TLS）
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    // 获取 TLS 配置
    let tlsConfig = server.getTlsConfig()

    match (tlsConfig) {
        case Some(config) => println("TLS 配置已设置")
        case None => println("未配置 TLS")
    }
}
```

运行结果：

```text
未配置 TLS
```

### func onShutdown(() -> Unit)

```cangjie
public func onShutdown(f: () -> Unit): Unit
```

功能：注册服务器关闭时的回调函数，服务器关闭时将调用该回调函数，重复调用将覆盖之前注册的函数。

参数：

- f: () -> Unit - 回调函数，入参为空，返回值为 Unit 类型。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    let server = ServerBuilder().addr("127.0.0.1").port(8080).onShutdown({
        => println("服务器已关闭")
    }).build()

    spawn {
        // 启动服务器
        server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 关闭服务器
    server.close()
}
```

运行结果：

```text
服务器已关闭
```

### func serve()

```cangjie
public func serve(): Unit
```

功能：启动服务端进程，不支持重复启动。

h1 request 检查和处理：

- request-line 不符合 RFC 9112 中 request-line = method SP request-target SP HTTP-version 的规则，将会返回 400 响应；
- method 由 tokens 组成，且大小写敏感；request-target 为能够被解析的 url；HTTP-version 为 HTTP/1.0 或 HTTP/1.1 ，否则将会返回 400 响应；
- headers name 和 value 需符合特定规则，详见 [HttpHeaders](http_package_classes.md#class-httpheaders) 类说明，否则返回 400 响应；
- 当 headers 的大小超出 server 设定的 maxRequestHeaderSize 时将自动返回 431 响应；
- headers 中必须包含 "host" 请求头，且值唯一，否则返回 400 响应 headers 中不允许同时存在 "content-length" 与 "transfer-encoding" 请求头，否则返回 400 响应；
- 请求头 "transfer-encoding" 的 value 经过 "," 分割后最后一个 value 必须为 "chunked"，且之前的 value 不允许存在 "chunked"，否则返回 400 响应；
- 请求头 "content-length" 其 value 必须能解析为 Int64 类型，且不能为负值，否则返回 400 响应，当其 value 值超出 server 设定 maxRequestBodySize，将返回 413 响应；
- headers 中若不存在 "content-length" 和 "transfer-encoding: chunked" 时默认不存在 body；
- 请求头 "trailer" 中，value 不允许存在 "transfer-encoding"，"trailer"，"content-length"；
- 请求头 "expect" 中，value 中存在非 "100-continue" 的值，将会返回 417 响应；
- HTTP/1.0 默认短连接，若想保持长连接需要包含请求头 "connection: keep-alive" 与 "keep-alive: timeout = XX, max = XX"，将会自动保持 timeout 时长的连接。HTTP/1.1 默认长连接，当解析 request 失败则关闭连接；
- 仅允许在 chunked 模式下存在 trailer，且 trailer 中条目的 name 必须被包含在 "trailer" 请求头中，否则将自动删除。

h1 response 检查和处理：

- 若用户不对 response 进行配置，将会自动返回 200 响应；
- 若接收到的 request 包含请求头 "connection: close" 而配置 response 未添加响应头 "connection" 或响应头 "connection" 的 value 不包含 "close"，将自动添加 "connection: close"，若接收到的 request 不包含请求头 "connection: close" 且响应头不存在 "connection: keep-alive"，将会自动添加；
- 如果 headers 包含逐跳响应头："proxy-connection"，"keep-alive"，"te"，"transfer-encoding"，"upgrade"，将会在响应头 "connection" 自动添加这些头作为 value；
- 将自动添加 "date" 响应头，用户提供的 "date" 将被忽略；
- 若请求方法为 "HEAD" 或响应状态码为 "1XX\204\304"，body 将配置为空；
- 若已知提供 body 的长度时，将会与响应头 "content-length" 进行比较，若不存在响应头 "content-length"，将自动添加此响应头，其 value 值为 body 长度。若响应头 "content-length" 长度大于 body 长度，将会在 handler 中抛出 [HttpException](http_package_exceptions.md#class-httpexception)，若小于 body 长度，将对 body 进行截断处理，发送的 body 长度将为 "content-length" 的值；
- response 中 "set-cookie" header 将分条发送，其他 headers 同名条目将合成一条发送；
- 在处理包含请求头："expect: 100-continue" 的 request 时，在调用 request 的 body.read() 时将会自动发送状态码为 100 的响应给客户端。不允许用户主动发送状态码为 100 的 response，若进行发送则被认定为服务器异常。

启用 h2 服务：tlsConfig 中 supportedAlpnProtocols 需包含 "h2"，此后如果 tls 层 alpn 协商结果为 h2，则启用 h2 服务。

h2 request 检查和处理：

- headers name 和 value 需符合特定规则，详见 [HttpHeaders](http_package_classes.md#class-httpheaders) 类说明，此外 name 不能包含大写字符，否则发送 RST 帧关闭流，即无法保证返回响应；
- trailers name 和 value 需符合同样规则，否则关闭流；
- headers 不能包含 "connection"，"transfer-encoding"，"keep-alive"，"upgrade"，"proxy-connection"，否则关闭流；
- 如果有 "te" header，其值只能为 "trailers"，否则关闭流；
- 如果有 "host" header 和 ":authority" pseudo header，"host" 值必须与 ":authority" 一致，否则关闭流；
- 如果有 "content-length" header，需符合 "content-length" 每个值都能解析为 Int64 类型，且如果有多个值，必须相等，否则关闭流；
- 如果有 "content-length" header，且有 body 大小，则 content-length 值与 body 大小必须相等，否则关闭流；
- 如果有 "trailer" header，其值不能包含 "transfer-encoding"，"trailer"，"content-length"，否则关闭流；
- 仅在升级 [WebSocket](http_package_classes.md#class-websocket) 场景下支持 CONNECT 方法，否则关闭流；
- pseudo headers 中，必须包含 ":method"、":scheme"、":path"，其中 ":method" 值必须由 tokens 字符组成，":scheme" 值必须为 "https"，":path" 不能为空，否则关闭流；
- trailer 中条目的 name 必须被包含在 "trailer" 头中，否则将自动删除；
- request headers 大小不能超过 maxHeaderListSize，否则关闭连接。

h2 response 检查和处理：

- 如果 HEAD 请求的响应包含 body，将自动删除；
- 将自动添加 "date" field，用户提供的 "date" 将被忽略；
- 如果 headers 包含 "connection"，"transfer-encoding"，"keep-alive"，"upgrade"，"proxy-connection"，将自动删除；
- response 中 "set-cookie" header 将分条发送，其他 headers 同名条目将合成一条发送；
- 如果 headers 包含 "content-length"，且 method 不为 "HEAD"，"content-length" 将被删除；
- 如果 method 为 "HEAD"，则：
    - headers 包含 "content-length"，但 "content-length" 不合法（无法被解析为 Int64 值，或包含多个不同值），如果用户调用 [HttpResponseWriter](http_package_classes.md#class-httpresponsewriter) 类的 write 函数，将抛出 [HttpException](http_package_exceptions.md#class-httpexception)，如果用户 handler 已经结束，将打印日志；
    - headers 包含 "content-length"，同时 response.body.length 不为 -1，"content-length" 值与 body.length 不符，同 6.1 处理；
    - headers 包含 "content-length"，同时 response.body.length 为 -1，或 body.length 与 "content-length" 值一致，则保留 "content-length" header；
- trailer 中条目必须被包含在 "trailer" 头中，否则将自动删除；
- 如果 handler 中抛出异常，且用户未调用 write 发送部分响应，将返回 500 响应。如果用户已经调用 write 发送部分响应，将发送 RST 帧关闭 stream。

h2 server 发完 response 之后，如果 stream 状态不是 CLOSED，会发送带 NO_ERROR 错误码的 RST 帧关闭 stream，避免已经处理完毕的 stream 继续占用服务器资源。

h2 流量控制：

- connection 流量窗口初始值为 65535，每次收到 DATA 帧将返回一个 connection 层面的 WINDOW-UPDATE，发送 DATA 时，如果 connection 流量窗口值为负数，将阻塞至其变为正数；
- stream 流量窗口初始值可由用户设置，默认值为 65535，每次收到 DATA 帧将返回一个 stream 层面的 WINDOW-UPDATE，发送 DATA 时，如果 stream 流量窗口值为负数，将阻塞至其变为正数。

h2 请求优先级：

- 支持按 urgency 处理请求，h2 服务默认并发处理请求，当并发资源不足时，请求将按 urgency 处理，优先级高的请求优先处理。

默认 [ProtocolServiceFactory](http_package_interfaces.md#interface-protocolservicefactory) 协议选择：

- 如果连接是 tcp，使用 HTTP/1.1 server；
- 如果连接是 tls，根据 alpn 协商结果确定 http 协议版本，如果协商结果为 "http/1.0"，"http/1.1" 或 ""，使用 HTTP/1.1 server，如果协商结果为 "h2"，使用 HTTP/2 server，否则不处理此次请求，打印日志关连接。

异常：

- SocketException - 当端口监听失败时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    spawn {
        // 启动服务器（会阻塞直到服务器关闭）
        server.serve()
    }

    // 等待服务启动
    sleep(Duration.second)
    println("服务器已启动")

    // 关闭服务器
    server.close()
}
```

运行结果：

```text
服务器已启动
```

### func updateCA(Array\<Certificate>)

```cangjie
public func updateCA(newCa: Array<Certificate>): Unit
```

功能：对 CA 证书进行热更新。

参数：

- newCa: Array\<[Certificate](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-certificate)> - CA 证书。

异常：

- IllegalArgumentException - 参数包含空字符时抛出异常。
- [HttpException](http_package_exceptions.md#class-httpexception) - 服务端未配置 tlsConfig 时抛出异常。

示例：

<!-- verify -->
```cangjie
import std.io.*
import std.fs.*
import std.process.*
import stdx.net.tls.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*
import stdx.net.tls.common.*
import stdx.net.http.*
import stdx.crypto.kit.*
import stdx.log.*

main(): Unit {
    // OpenSSL 官方标准、无风险的测试命令用来本地生成证书和私钥
    // 生成服务器私钥、证书、证书请求路径
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"
    let serverCsr = "./server.csr"

    // 根证书/私钥路径
    let rootCrt = "./rootCA.crt"
    let rootKey = "./rootCA.key"

    // 客户端私钥、证书、证书请求路径
    let clientKey = "./client.key"
    let clientCrt = "./client.crt"
    let clientCsr = "./client.csr"

    // 生成根CA证书
    let rootCmd = "openssl req -x509 -newkey rsa:4096 -nodes -keyout ${rootKey} -out ${rootCrt} -days 3650 -subj \"/C=CN/ST=Beijing/L=Beijing/O=MyCA/OU=CA/CN=MyRootCA\""
    executeWithOutput("sh", ["-c", rootCmd])

    // 生成服务器私钥+证书请求（CSR） 
    let csrCmd = "openssl req -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCsr} -subj \"/C=CN/ST=Beijing/L=Beijing/O=MyServer/OU=Server/CN=localhost\""
    executeWithOutput("sh", ["-c", csrCmd])

    // 用根CA签发服务器证书
    let signCmd = "openssl x509 -req -in ${serverCsr} -CA ${rootCrt} -CAkey ${rootKey} -CAcreateserial -out ${serverCrt} -days 365 -sha256"
    executeWithOutput("sh", ["-c", signCmd])

    // 生成客户端私钥+证书请求（CSR）
    let clientCsrCmd = "openssl req -newkey rsa:2048 -nodes -keyout ${clientKey} -out ${clientCsr} -subj \"/C=CN/ST=Beijing/L=Beijing/O=MyClient/OU=Client/CN=MyClient\""
    executeWithOutput("sh", ["-c", clientCsrCmd])

    // 用根CA签发客户端证书（和服务端同根CA，服务端会信任）
    let clientSignCmd = "openssl x509 -req -in ${clientCsr} -CA ${rootCrt} -CAkey ${rootKey} -CAcreateserial -out ${clientCrt} -days 365 -sha256"
    executeWithOutput("sh", ["-c", clientSignCmd])

    // 读取根证书PEM
    let pem = String.fromUtf8(File.readFrom(rootCrt))

    // 对服务器证书以及私钥进行解析 
    let pemString = String.fromUtf8(File.readFrom(serverCrt))
    let keyString = String.fromUtf8(File.readFrom(serverKey))

    let certificate = X509Certificate.decodeFromPem(pemString)
    let privateKey = GeneralPrivateKey.decodeFromPem(keyString)

    // 创建 TLS 服务器配置
    var serverConfig = TlsServerConfig(certificate, privateKey)

    serverConfig.clientIdentityRequired = Required
    serverConfig.verifyMode = CustomCA(X509Certificate.decodeFromPem(pem).map({c => c}))

    // 构建带 TLS 配置的 Server 实例
    let server = ServerBuilder().addr("127.0.0.1").tlsConfig(serverConfig).port(8080).build()
    server.logger.level = LogLevel.OFF

    // 启动服务器
    spawn {
        =>
            // 注册 HttpRequestHandler
            server.distributor.register("/index", {
                httpContext => println("Hello 客户端，你的证书数量是${httpContext.clientCertificate?.size ?? 0}")
            })
            // 启动服务
            server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 第一步：使用旧根证书进行验证（预期成功）
    println("=== 第一步：使用旧根证书验证 ===")
    var config1 = TlsClientConfig()
    let clientPem1 = String.fromUtf8(File.readFrom(clientCrt))
    let clientKeyStr1 = String.fromUtf8(File.readFrom(clientKey))
    let clientPriKey1 = GeneralPrivateKey.decodeFromPem(clientKeyStr1)

    // 设置客户端证书和私钥（旧根证书签发）
    config1.certificate = (X509Certificate.decodeFromPem(clientPem1).map({c => c}), clientPriKey1)
    // 设置验证模式使用旧根证书
    config1.verifyMode = CustomCA(X509Certificate.decodeFromPem(pem).map({c => c}))

    // 创建带 TLS 配置的 Client 实例
    let client1 = ClientBuilder().tlsConfig(config1).build()

    // 发送https GET请求
    try {
        let resp1 = client1.get("https://127.0.0.1:8080/index")
        println("旧根证书验证成功，响应状态：${resp1.status}")
    } catch (e: Exception) {
        println("旧根证书验证失败：${e.message}")
    }

    // 第二步：创建新的根CA证书并更新服务器
    println("\n=== 第二步：更换服务器根证书 ===")
    let newRootCrt = "./newRootCA.crt"
    let newRootKey = "./newRootCA.key"
    let newRootCmd = "openssl req -x509 -newkey rsa:4096 -nodes -keyout ${newRootKey} -out ${newRootCrt} -days 3650 -subj \"/C=CN/ST=Beijing/L=Beijing/O=NewCA/OU=CA/CN=NewRootCA\""
    executeWithOutput("sh", ["-c", newRootCmd])
    println("新根证书已创建")

    // 更新服务器 CA 证书（热更新）- 使用新的根证书
    // 方式1：使用文件路径方式
    server.updateCA(newRootCrt)
    // 方式2：使用证书数组方式（与上面等效，二选一即可）
    // let newRootPem = String.fromUtf8(File.readFrom(newRootCrt))
    // server.updateCA(X509Certificate.decodeFromPem(newRootPem).map({c => c}))
    println("服务器 CA 证书已更新为新根证书")

    // 第三步：再次使用旧根证书进行验证（预期失败）
    println("\n=== 第三步：再次使用旧根证书验证（预期失败）===")
    // 创建新的客户端实例（强制新建连接）
    let client2 = ClientBuilder().tlsConfig(config1).build()
    try {
        let resp2 = client2.get("https://127.0.0.1:8080/index")
        println("旧根证书验证成功（意外），响应状态：${resp2.status}")
    } catch (e: Exception) {
        println("旧根证书验证失败（预期）：客户端证书不再被新根证书信任")
    }

    // 删除生成的文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
    removeIfExists(serverCsr)
    removeIfExists(clientKey)
    removeIfExists(clientCrt)
    removeIfExists(clientCsr)
    removeIfExists(rootKey)
    removeIfExists(rootCrt)
    removeIfExists(newRootKey)
    removeIfExists(newRootCrt)
}
```

运行结果：

```text
=== 第一步：使用旧根证书验证 ===
Hello 客户端，你的证书数量是2
旧根证书验证成功，响应状态：200

=== 第二步：更换服务器根证书 ===
新根证书已创建
服务器 CA 证书已更新为新根证书

=== 第三步：再次使用旧根证书验证（预期失败）===
旧根证书验证失败（预期）：客户端证书不再被新根证书信任
```

### func updateCA(String)

```cangjie
public func updateCA(newCaFile: String): Unit
```

功能：对 CA 证书进行热更新。

参数：

- newCaFile: String - CA 证书文件路径。

异常：

- IllegalArgumentException - 参数包含空字符时抛出异常。
- [HttpException](http_package_exceptions.md#class-httpexception) - 服务端未配置 tlsConfig 时抛出异常。

示例：
<!-- associated_example -->
参见 [func updateCA](#func-updatecaarraycertificate) 示例。

### func updateCert(Array\<Certificate>, PrivateKey)

```cangjie
public func updateCert(certChain: Array<Certificate>, certKey: PrivateKey): Unit
```

功能：对 TLS 证书进行热更新。

参数：

- certChain: Array\<[Certificate](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-certificate)> - 证书链。
- certKey: [PrivateKey](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey) - 证书匹配的私钥。

异常：

- [HttpException](http_package_exceptions.md#class-httpexception) - 服务端未配置 tlsConfig 时抛出异常。

示例：

<!-- verify -->
```cangjie
import std.io.*
import std.fs.*
import std.process.*
import stdx.net.tls.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*
import stdx.net.tls.common.*
import stdx.net.http.*
import stdx.crypto.kit.*

main(): Unit {
    // OpenSSL 官方标准、无风险的测试命令用来本地生成证书和私钥
    // 生成服务器私钥、证书、证书请求路径
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"
    let serverCsr = "./server.csr"

    // 根证书/私钥路径
    let rootCrt = "./rootCA.crt"
    let rootKey = "./rootCA.key"

    // 客户端私钥、证书、证书请求路径
    let clientKey = "./client.key"
    let clientCrt = "./client.crt"
    let clientCsr = "./client.csr"

    // 生成根CA证书
    let rootCmd = "openssl req -x509 -newkey rsa:4096 -nodes -keyout ${rootKey} -out ${rootCrt} -days 3650 -subj \"/C=CN/ST=Beijing/L=Beijing/O=MyCA/OU=CA/CN=MyRootCA\""
    executeWithOutput("sh", ["-c", rootCmd])

    // 生成服务器私钥+证书请求（CSR） 
    let csrCmd = "openssl req -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCsr} -subj \"/C=CN/ST=Beijing/L=Beijing/O=MyServer/OU=Server/CN=localhost\""
    executeWithOutput("sh", ["-c", csrCmd])

    // 用根CA签发服务器证书
    let signCmd = "openssl x509 -req -in ${serverCsr} -CA ${rootCrt} -CAkey ${rootKey} -CAcreateserial -out ${serverCrt} -days 365 -sha256"
    executeWithOutput("sh", ["-c", signCmd])

    // 生成客户端私钥+证书请求（CSR）
    let clientCsrCmd = "openssl req -newkey rsa:2048 -nodes -keyout ${clientKey} -out ${clientCsr} -subj \"/C=CN/ST=Beijing/L=Beijing/O=MyClient/OU=Client/CN=MyClient\""
    executeWithOutput("sh", ["-c", clientCsrCmd])

    // 用根CA签发客户端证书（和服务端同根CA，服务端会信任）
    let clientSignCmd = "openssl x509 -req -in ${clientCsr} -CA ${rootCrt} -CAkey ${rootKey} -CAcreateserial -out ${clientCrt} -days 365 -sha256"
    executeWithOutput("sh", ["-c", clientSignCmd])

    // 读取根证书PEM
    let pem = String.fromUtf8(File.readFrom(rootCrt))

    // 对服务器证书以及私钥进行解析 
    let pemString = String.fromUtf8(File.readFrom(serverCrt))
    let keyString = String.fromUtf8(File.readFrom(serverKey))

    let certificate = X509Certificate.decodeFromPem(pemString)
    let privateKey = GeneralPrivateKey.decodeFromPem(keyString)

    // 创建 TLS 服务器配置
    var serverConfig = TlsServerConfig(certificate, privateKey)

    serverConfig.clientIdentityRequired = Required
    serverConfig.verifyMode = CustomCA(X509Certificate.decodeFromPem(pem).map({c => c}))

    // 构建带 TLS 配置的 Server 实例
    let server = ServerBuilder().addr("127.0.0.1").tlsConfig(serverConfig).port(8080).build()

    // 启动服务器
    spawn {
        =>
            // 注册 HttpRequestHandler
            server.distributor.register("/index", {
                httpContext => println("Hello 客户端，你的证书数量是${httpContext.clientCertificate?.size ?? 0}")
            })
            // 启动服务
            server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 第一步：使用旧服务器证书进行连接（预期成功）
    println("=== 第一步：使用旧服务器证书连接 ===")
    var config1 = TlsClientConfig()
    let clientPem1 = String.fromUtf8(File.readFrom(clientCrt))
    let clientKeyStr1 = String.fromUtf8(File.readFrom(clientKey))
    let clientPriKey1 = GeneralPrivateKey.decodeFromPem(clientKeyStr1)

    // 设置客户端证书和私钥
    config1.certificate = (X509Certificate.decodeFromPem(clientPem1).map({c => c}), clientPriKey1)
    // 设置验证模式使用根证书验证服务器
    config1.verifyMode = CustomCA(X509Certificate.decodeFromPem(pem).map({c => c}))

    // 创建带 TLS 配置的 Client 实例
    let client1 = ClientBuilder().tlsConfig(config1).build()

    // 发送https GET请求
    try {
        let resp1 = client1.get("https://127.0.0.1:8080/index")
        println("旧服务器证书连接成功，响应状态：${resp1.status}")
    } catch (e: Exception) {
        println("旧服务器证书连接失败：${e.message}")
    }

    // 第二步：创建新的服务器证书并更新
    println("\n=== 第二步：更换服务器TLS证书 ===")
    let newServerKey = "./newServer.key"
    let newServerCrt = "./newServer.crt"
    let newServerCsr = "./newServer.csr"

    // 生成新服务器私钥+证书请求（CSR）
    let newCsrCmd = "openssl req -newkey rsa:2048 -nodes -keyout ${newServerKey} -out ${newServerCsr} -subj \"/C=CN/ST=Beijing/L=Beijing/O=NewServer/OU=Server/CN=localhost\""
    executeWithOutput("sh", ["-c", newCsrCmd])

    // 用原根CA签发新服务器证书
    let newSignCmd = "openssl x509 -req -in ${newServerCsr} -CA ${rootCrt} -CAkey ${rootKey} -CAcreateserial -out ${newServerCrt} -days 365 -sha256"
    executeWithOutput("sh", ["-c", newSignCmd])
    println("新服务器证书已创建")

    // 更新服务器 TLS 证书（热更新）
    // 方式1：使用文件路径方式（推荐，更简单）
    server.updateCert(newServerCrt, newServerKey)
    // 方式2：使用证书对象和私钥对象方式（与上面等效，二选一即可）
    // let newServerPem = String.fromUtf8(File.readFrom(newServerCrt))
    // let newServerKeyStr = String.fromUtf8(File.readFrom(newServerKey))
    // let newServerCert = X509Certificate.decodeFromPem(newServerPem)
    // let newServerPrivateKey = GeneralPrivateKey.decodeFromPem(newServerKeyStr)
    // server.updateCert(newServerCert.map({c => c}), newServerPrivateKey)
    println("服务器 TLS 证书已更新为新证书")

    // 第三步：再次连接（使用新服务器证书，预期成功，因为同属于一个根证书）
    println("\n=== 第三步：使用新服务器证书连接 ===")
    // 创建新的客户端实例（强制新建连接）
    let client2 = ClientBuilder().tlsConfig(config1).build()
    try {
        let resp2 = client2.get("https://127.0.0.1:8080/index")
        println("新服务器证书连接成功，响应状态：${resp2.status}")
    } catch (e: Exception) {
        println("新服务器证书连接失败：${e.message}")
    }

    // 删除生成的文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
    removeIfExists(serverCsr)
    removeIfExists(clientKey)
    removeIfExists(clientCrt)
    removeIfExists(clientCsr)
    removeIfExists(rootKey)
    removeIfExists(rootCrt)
    removeIfExists(newServerKey)
    removeIfExists(newServerCrt)
    removeIfExists(newServerCsr)
}
```

运行结果：

```text
=== 第一步：使用旧服务器证书连接 ===
Hello 客户端，你的证书数量是2
旧服务器证书连接成功，响应状态：200

=== 第二步：更换服务器TLS证书 ===
新服务器证书已创建
服务器 TLS 证书已更新为新证书

=== 第三步：使用新服务器证书连接 ===
Hello 客户端，你的证书数量是2
新服务器证书连接成功，响应状态：200
```

### func updateCert(String, String)

```cangjie
public func updateCert(certificateChainFile: String, privateKeyFile: String): Unit
```

功能：对 TLS 证书进行热更新。

参数：

- certificateChainFile: String - 证书链文件路径。
- privateKeyFile: String - 证书匹配的私钥文件。

异常：

- IllegalArgumentException - 参数包含空字符时抛出异常。
- [HttpException](http_package_exceptions.md#class-httpexception) - 服务端未配置 tlsConfig 时抛出异常。

示例：
<!-- associated_example -->
参见 [func updateCert](#func-updatecertarraycertificate-privatekey) 示例。

## class ServerBuilder

```cangjie
public class ServerBuilder {
    public init()
}
```

功能：提供 [Server](http_package_classes.md#class-server) 实例构建器。

支持通过如下参数构造一个 Http [Server](http_package_classes.md#class-server)：

- 地址、端口；
- 线程安全的 logger；
- [HttpRequestDistributor](http_package_interfaces.md#interface-httprequestdistributor)，用于注册 handler、分发 request；
- HTTP/2 的 settings；
- shutdown 回调；
- transport：listener、连接及其配置；
- protocol service：http 协议解析服务；

除地址端口、shutdown 回调外，均提供默认实现，用户在构造 server 过程中可不指定其他构建参数。
[ServerBuilder](http_package_classes.md#class-serverbuilder) 文档中未明确说明支持版本的配置，在 HTTP/1.1 与 HTTP/2 都会生效。

> **说明：**
>
> 该类提供了一系列配置参数的函数，配置完成后调用 [build](./http_package_classes.md#func-build-3) 函数构造出 [Server](./http_package_classes.md#class-server) 实例。配置函数中说明了参数的取值范围，但配置函数本身不做参数合法性校验，[build](./http_package_classes.md#func-build-3) 时统一进行校验。

### init()

```cangjie
public init()
```

功能：创建 [ServerBuilder](http_package_classes.md#class-serverbuilder) 实例。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main(): Unit {
    let _ = ServerBuilder()
}
```

### func addr(String)

```cangjie
public func addr(addr: String): ServerBuilder
```

功能：设置服务端监听地址，若 listener 被设定，此值被忽略。

格式需符合 IPAddress 中相关规定。

参数：

- addr: String - 地址值。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建 ServerBuilder 并设置监听地址
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    println("服务器监听地址：${server.addr}")
}
```

运行结果：

```text
服务器监听地址：127.0.0.1
```

### func afterBind(() -> Unit)

```cangjie
public func afterBind(f: () -> Unit): ServerBuilder
```

功能：注册服务器启动时的回调函数，服务内部 ServerSocket 实例 bind 之后，accept 之前将调用该函数。重复调用将覆盖之前注册的函数。

参数：

- f: () -> Unit - 回调函数，入参为空，返回值为 Unit 类型。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    spawn {
        // 启动时触发回调函数
        let server = ServerBuilder().addr("127.0.0.1").port(8080).afterBind({
            => println("服务器已启动")
        }).build()
        server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)
}
```

运行结果：

```text
服务器已启动
```

### func build()

```cangjie
public func build(): Server
```

功能：根据设置的参数构建 [Server](http_package_classes.md#class-server) 实例。

此处会对各参数的值进行检查，如果取值非法，将抛出异常。各参数的取值范围详见设置参数相关的函数。

返回值：

- [Server](http_package_classes.md#class-server) - 生成的 [Server](http_package_classes.md#class-server) 实例。

异常：

- IllegalArgumentException - 当设置的参数非法时，抛出异常。
- IllegalFormatException 格式错误时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用 build() 构建 Server 实例
    let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

    println("监听地址：${server.addr}")
    println("监听端口：${server.port}")
}
```

运行结果：

```text
监听地址：127.0.0.1
监听端口：8080
```

### func distributor(HttpRequestDistributor)

```cangjie
public func distributor(distributor: HttpRequestDistributor): ServerBuilder
```

功能：设置请求分发器，请求分发器会根据 url 将请求分发给对应的 handler。不设置时使用默认请求分发器。

参数：

- distributor: [HttpRequestDistributor](http_package_interfaces.md#interface-httprequestdistributor) - 自定义请求分发器实例。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import std.collection.*
import stdx.net.http.*

// 自定义简易 HttpRequestDistributor 以演示注册和分发请求
class MyDistributor <: HttpRequestDistributor {
    var handlers: HashMap<String, HttpRequestHandler> = HashMap<String, HttpRequestHandler>()
    public func register(path: String, handler: HttpRequestHandler): Unit {
        println("注册路径: ${path}")
        handlers[path] = handler
    }

    public func distribute(path: String): HttpRequestHandler {
        return handlers.get(path).getOrThrow()
    }
}

main(): Unit {
    spawn {
        let server = ServerBuilder().addr("127.0.0.1").port(8080).distributor(MyDistributor()).build()
        server.distributor.register("/index", OptionsHandler())
        server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 创建 Client
    let client = ClientBuilder().build()
    // 发送GET请求
    let resp = client.get("http://127.0.0.1:8080/index")
    // 打印响应状态码
    println("响应状态码: ${resp.status}")
}
```

运行结果：

```text
注册路径: /index
响应状态码: 200
```

### func enableConnectProtocol(Bool)

```cangjie
public func enableConnectProtocol(flag: Bool): ServerBuilder
```

功能：HTTP/2 专用，设置本端是否接收 CONNECT 请求，默认 false。

参数：

- flag: Bool - 本端是否接收 CONNECT 请求。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 使用 build() 构建 Server 实例
    let server = ServerBuilder().addr("127.0.0.1").port(8080).enableConnectProtocol(true).build()

    println("enableConnectProtocol: ${server.enableConnectProtocol}")
}
```

运行结果：

```text
enableConnectProtocol: true
```

### func headerTableSize(UInt32)

```cangjie
public func headerTableSize(size: UInt32): ServerBuilder
```

功能：设置服务端 HTTP/2 Hpack 动态表的初始值，默认值为 4096。

参数：

- size: UInt32 - 本端对响应头编码时使用的最大 `table size`

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 设置 HTTP/2 Hpack 动态表大小
    let server = ServerBuilder().addr("127.0.0.1").port(8080).headerTableSize(8192).build()

    println("headerTableSize: ${server.headerTableSize}")
}
```

运行结果：

```text
headerTableSize: 8192
```

### func httpKeepAliveTimeout(Duration)

```cangjie
public func httpKeepAliveTimeout(timeout: Duration): ServerBuilder
```

功能：HTTP/1.1 专用，设定服务端连接保活时长，该时长内客户端未再次发送请求，服务端将关闭长连接，默认不进行限制。

参数：

- timeout: Duration - 设定保持长连接的超时时间，如果传入负的 Duration 将被替换为 Duration.Zero。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 设置 HTTP/1.1 连接保活超时为 30 秒
    let server = ServerBuilder().addr("127.0.0.1").port(8080).httpKeepAliveTimeout(Duration.second * 30).build()

    println("httpKeepAliveTimeout: ${server.httpKeepAliveTimeout}")
}
```

运行结果：

```text
httpKeepAliveTimeout: 30s
```

### func initialWindowSize(UInt32)

```cangjie
public func initialWindowSize(size: UInt32): ServerBuilder
```

功能：HTTP/2 专用，设置当前服务器上每个流的接收报文的初始流量窗口大小，默认值为 65535。取值范围为 0 至 2^31 - 1。

参数：

- size: UInt32 - 本端一个 stream 上接收报文的初始流量窗口大小。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 设置 HTTP/2 初始窗口大小
    let server = ServerBuilder().addr("127.0.0.1").port(8080).initialWindowSize(65535).build()

    println("初始流量窗口大小：${server.initialWindowSize}")
}
```

运行结果：

```text
初始流量窗口大小：65535
```

### func listener(ServerSocket)

```cangjie
public func listener(listener: ServerSocket): ServerBuilder
```

功能：服务端调用此函数对指定 socket 进行绑定监听。

参数：

- listener: ServerSocket - 所绑定的 socket。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import std.net.*
import stdx.net.http.*

main(): Unit {
    // 直接注入一个已经指定 bind 地址/端口的 ServerSocket
    let socket = TcpServerSocket(bindAt: IPSocketAddress("127.0.0.1", 8080))

    // 构建 Server 实例
    let server = ServerBuilder().addr("127.0.0.1").port(8080).listener(socket).build()

    println("listener: ${server.listener}")
}
```

运行结果：

```text
listener: TcpServerSocket(unconnected, unbound)
```

### func logger(Logger)

```cangjie
public func logger(logger: Logger): ServerBuilder
```

功能：设定服务器的 logger，默认 logger 级别为 INFO，logger 内容将写入 Console.stdout。

参数：

- logger: [Logger](../../../log/log_package_api/log_package_classes.md#class-logger) - 需要是线程安全的，默认使用内置线程安全 logger。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import std.env.*
import stdx.net.http.*
import stdx.logger.*

main(): Unit {
    // 构建 Server 实例
    let server = ServerBuilder().addr("127.0.0.1").port(8080).logger(SimpleLogger(getStdOut())).build()

    println("日志等级: ${server.logger.level}")
}
```

运行结果：

```text
日志等级: INFO
```

### func maxConcurrentStreams(UInt32)

```cangjie
public func maxConcurrentStreams(size: UInt32): ServerBuilder
```

功能：HTTP/2 专用，设置本端同时处理的最大请求数量，限制对端并发发送请求的数量，默认值为 100。

参数：

- size: UInt32 - 本端同时处理的最大请求数量。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 设置最大并发流数
    let server = ServerBuilder().addr("127.0.0.1").port(8080).maxConcurrentStreams(100).build()

    println("maxConcurrentStreams: ${server.maxConcurrentStreams}")
}
```

运行结果：

```text
maxConcurrentStreams: 100
```

### func maxFrameSize(UInt32)

```cangjie
public func maxFrameSize(size: UInt32): ServerBuilder
```

功能：HTTP/2 专用，设置本端接收的一个帧的最大长度，用来限制对端发送帧的长度，默认值为 16384. 取值范围为 2^14 至 2^24 - 1。

参数：

- size: UInt32 - 本端接收的一个帧的最大长度。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 设置最大帧大小
    let server = ServerBuilder().addr("127.0.0.1").port(8080).maxFrameSize(16384).build()

    println("最大帧大小: ${server.maxFrameSize}")
}
```

运行结果：

```text
最大帧大小: 16384
```

### func maxHeaderListSize(UInt32)

```cangjie
public func maxHeaderListSize(size: UInt32): ServerBuilder
```

功能：获取客户端支持的 HTTP/2 最大头部（Header）大小。这个大小指的是响应头部中所有头部字段（Header Field）的最大允许长度之和，其中包括所有字段名称（name）的长度、字段值（value）的长度以及每个字段自动添加的伪头开销（通常每个字段会有 32 字节的开销，这包括了 HTTP/2 协议本身为头部字段添加的伪头部信息）。默认情况下，这个最大长度被设置为 UInt32.Max。

参数：

- size: UInt32 - 本端接收的报文头最大长度。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 设置最大 header 列表大小
    let server = ServerBuilder().addr("127.0.0.1").port(8080).maxHeaderListSize(8192).build()

    println("报文头最大长度: ${server.maxHeaderListSize}")
}
```

运行结果：

```text
报文头最大长度: 8192
```

### func maxRequestBodySize(Int64)

```cangjie
public func maxRequestBodySize(size: Int64): ServerBuilder
```

功能：设置服务端允许客户端发送单个请求的请求体最大长度，请求体长度超过该值时，将返回状态码为 413 的响应。默认值为 2M。仅对于 HTTP/1.1 且未设置 "Transfer-Encoding: chunked" 的请求生效。

参数：

- size: Int64 - 设定允许接收请求的请求体大小最大值，值为 0 代表不作限制。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

异常：

- IllegalArgumentException - 当入参 size < 0 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 设置最大请求 body 大小
    let server = ServerBuilder().addr("127.0.0.1").port(8080).maxRequestBodySize(1024).build()

    println("最大请求体大小: ${server.maxRequestBodySize}")
}
```

运行结果：

```text
最大请求体大小: 1024
```

### func maxRequestHeaderSize(Int64)

```cangjie
public func maxRequestHeaderSize(size: Int64): ServerBuilder
```

功能：设定服务端允许客户端发送单个请求的请求头最大长度，请求头长度超过该值时，将返回状态码为 431 的响应；仅对 HTTP/1.1 生效，HTTP/2 中有专门的配置 maxHeaderListSize。

参数：

- size: Int64 - 设定允许接收请求的请求头大小最大值，值为 0 代表不作限制。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

异常：

- IllegalArgumentException - 当入参 size < 0 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 设置最大请求 header 大小
    let server = ServerBuilder().addr("127.0.0.1").port(8080).maxRequestHeaderSize(8192).build()

    println("最大请求 header 大小: ${server.maxRequestHeaderSize}")
}
```

运行结果：

```text
最大请求 header 大小: 8192
```

### func onShutdown(() -> Unit)

```cangjie
public func onShutdown(f: () -> Unit): ServerBuilder
```

功能：注册服务器关闭时的回调函数，服务器关闭时将调用该回调函数，重复调用将覆盖之前注册的函数。

参数：

- f: () ->Unit - 回调函数，入参为空，返回值为 Unit 类型。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    let server = ServerBuilder().addr("127.0.0.1").port(8080).onShutdown({
        => println("服务器已关闭")
    }).build()
    spawn {
        // 启动服务器
        server.serve()
    }
    // 等待服务启动
    sleep(Duration.second)

    // 关闭服务器
    server.close()
}
```

运行结果：

```text
服务器已关闭
```

### func port(UInt16)

```cangjie
public func port(port: UInt16): ServerBuilder
```

功能：设置服务端监听端口，若 listener 被设定，此值被忽略。

参数：

- port: UInt16 - 端口值。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 设置监听端口
    let server = ServerBuilder().addr("127.0.0.1").port(9090).build()

    println("port 设置成功：${server.port}")
}
```

运行结果：

```text
port 设置成功：9090
```

### func protocolServiceFactory(ProtocolServiceFactory)

```cangjie
public func protocolServiceFactory(factory: ProtocolServiceFactory): ServerBuilder
```

功能：设置协议服务工厂，服务协议工厂会生成每个协议所需的服务实例，不设置时使用默认工厂。

参数：

- factory: [ProtocolServiceFactory](http_package_interfaces.md#interface-protocolservicefactory) - 自定义工厂实例。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：
<!-- associated_example -->
参见 [func serve](#func-serve) 示例。

### func readHeaderTimeout(Duration)

```cangjie
public func readHeaderTimeout(timeout: Duration): ServerBuilder
```

功能：设定服务端读取客户端发送一个请求的请求头最大时长，超过该时长将不再进行读取并关闭连接，默认不进行限制。

参数：

- timeout: Duration - 设定的读请求头超时时间，如果传入负的 Duration 将被替换为 Duration.Zero。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 设置读取 header 超时时间为 10 秒
    let server = ServerBuilder().addr("127.0.0.1").port(8080).readHeaderTimeout(Duration.second * 10).build()

    println("读取 header 超时时间：${server.readHeaderTimeout}")
}
```

运行结果：

```text
读取 header 超时时间：10s
```

### func readTimeout(Duration)

```cangjie
public func readTimeout(timeout: Duration): ServerBuilder
```

功能：设定服务端读取一个请求的最大时长，超过该时长将不再进行读取并关闭连接，默认不进行限制。建议在生产环境中显式设置该值。若不配置，服务端可能因慢速请求长期占用连接和资源，增加遭受慢请求类攻击的风险。

参数：

- timeout: Duration - 设定读请求的超时时间，如果传入时间为负值将被替换为 Duration.Zero。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 设置读取超时时间为 30 秒
    let server = ServerBuilder().addr("127.0.0.1").port(8080).readTimeout(Duration.second * 30).build()

    println("读取超时时间：${server.readTimeout}")
}
```

运行结果：

```text
读取超时时间：30s
```

### func servicePoolConfig(ServicePoolConfig)

```cangjie
public func servicePoolConfig(cfg: ServicePoolConfig): ServerBuilder
```

功能：服务过程中使用的协程池相关设置，具体说明见 [ServicePoolConfig](http_package_structs.md#struct-servicepoolconfig) 结构体。

参数：

- cfg: [ServicePoolConfig](http_package_structs.md#struct-servicepoolconfig) - 协程池相关设置。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建协程池配置
    var poolCfg = ServicePoolConfig(capacity: 100, queueCapacity: 200, preheat: 10)

    // 使用 servicePoolConfig 设置协程池配置
    let server = ServerBuilder().addr("127.0.0.1").port(8080).servicePoolConfig(poolCfg).build()

    println("协程池容量：${server.servicePoolConfig.capacity}")
    println("队列容量：${server.servicePoolConfig.queueCapacity}")
    println("预热数量：${server.servicePoolConfig.preheat}")
}
```

运行结果：

```text
协程池容量：100
队列容量：200
预热数量：10
```

### func tlsConfig(TlsConfig)

```cangjie
public func tlsConfig(config: TlsConfig): ServerBuilder
```

功能：设置 TLS 层配置，默认不对其进行设置。

参数：

- config: [TlsConfig](../../tls/common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconfig) - 设定支持 tls 服务所需要的配置信息。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：
<!-- associated_example -->
参见 [prop clientCertificate](#prop-clientcertificate) 示例。

### func transportConfig(TransportConfig)

```cangjie
public func transportConfig(config: TransportConfig): ServerBuilder
```

功能：设置传输层配置，默认配置详见 [TransportConfig](http_package_structs.md#struct-transportconfig) 结构体说明。

参数：

- config: [TransportConfig](http_package_structs.md#struct-transportconfig) - 设定的传输层配置信息。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 创建传输层配置
    var transportCfg = TransportConfig()
    transportCfg.readBufferSize = 8192

    // 使用 transportConfig 设置传输层配置
    let server = ServerBuilder().addr("127.0.0.1").port(8080).transportConfig(transportCfg).build()

    println("读取缓冲区大小：${server.transportConfig.readBufferSize}")
}
```

运行结果：

```text
读取缓冲区大小：Some(8192)
```

### func writeTimeout(Duration)

```cangjie
public func writeTimeout(timeout: Duration): ServerBuilder
```

功能：设定服务端发送一个响应的最大时长，超过该时长将不再进行写入并关闭连接，默认不进行限制。建议在生产环境中显式设置该值。若不配置，服务端可能因慢速读写长期占用连接和资源，增加遭受慢连接类攻击的风险。

参数：

- timeout: Duration - 设定写响应的超时时间，如果传入时间为负值将被替换为 Duration.Zero。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*

main(): Unit {
    // 设置写入超时时间为 30 秒
    let server = ServerBuilder().addr("127.0.0.1").port(8080).writeTimeout(Duration.second * 30).build()

    println("写入超时时间：${server.writeTimeout}")
}
```

运行结果：

```text
写入超时时间：30s
```

## class WebSocket

```cangjie
public class WebSocket
```

功能：提供 [WebSocket](http_package_classes.md#class-websocket) 服务的相关类，支持 [WebSocket](http_package_classes.md#class-websocket) 连接的读、写、关闭等操作。用户通过 upgradeFrom 函数获取 [WebSocket](http_package_classes.md#class-websocket) 连接。

- 调用 `read()` 读取一个 [WebSocketFrame](http_package_classes.md#class-websocketframe)，用户可通过 [WebSocketFrame](http_package_classes.md#class-websocketframe).frameType 来知晓帧的类型，通过 [WebSocketFrame](http_package_classes.md#class-websocketframe).fin 来知晓是否是分段帧。
- 调用 `write(frameType: WebSocketFrameType, byteArray: Array<UInt8>)`，传入消息类型和消息内容（字节数组）来发送 [WebSocket](http_package_classes.md#class-websocket) 数据。控制帧不会被分段发送，数据帧（Text、Binary）则会按底层 buffer 大小分段（分成多个 fragment）发送。

详细说明见下文接口说明，接口行为以 RFC 6455 为准。

### prop logger

```cangjie
public prop logger: Logger
```

功能：日志记录器。

类型：[Logger](../../../log/log_package_api/log_package_classes.md#class-logger)

示例：
<!-- associated_example -->
参见 [static func upgradeFromClient](#static-func-upgradefromclientclient-url-protocol-arrayliststring-httpheaders) 示例。

### prop subProtocol

```cangjie
public prop subProtocol: String
```

功能：获取与对端协商到的 subProtocol，协商时，客户端提供一个按偏好排名的 subProtocols 列表，服务器从中选取一个或零个子协议。

类型：String

示例：
<!-- associated_example -->
参见 [static func upgradeFromClient](#static-func-upgradefromclientclient-url-protocol-arrayliststring-httpheaders) 示例。

### static func upgradeFromClient(Client, URL, Protocol, ArrayList\<String>, HttpHeaders)

```cangjie
public static func upgradeFromClient(client: Client, url: URL, version!: Protocol = HTTP1_1,
        subProtocols!: ArrayList<String> = ArrayList<String>(), headers!: HttpHeaders = HttpHeaders()): (WebSocket,
        HttpHeaders)
```

功能：提供客户端升级到 [WebSocket](http_package_classes.md#class-websocket) 协议的函数。

> **说明：**
>
> 客户端升级流程：传入 client 和 url 对象构建升级请求，发送给服务器并验证响应。握手成功后返回 [WebSocket](http_package_classes.md#class-websocket) 对象用于通讯，同时返回 101 响应头的 [HttpHeaders](http_package_classes.md#class-httpheaders) 对象。暂不支持 extensions。若子协议协商成功，可通过返回的 [WebSocket](http_package_classes.md#class-websocket) 的 subProtocol 属性查看。

参数：

- client: [Client](http_package_classes.md#class-client) - 用于请求的 client 对象。
- url: [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) - 用于请求的 url 对象，[WebSocket](http_package_classes.md#class-websocket) 升级时要注意 url 的 scheme 为 ws 或 wss。
- version!: [Protocol](http_package_enums.md#enum-protocol) - 创建 socket 使用的 HTTP 版本，只支持  [HTTP1_1](./http_package_enums.md#enum-protocol) 和  [HTTP2_0](./http_package_enums.md#enum-protocol) 向 [WebSocket](http_package_classes.md#class-websocket) 升级。
- subProtocols!: ArrayList\<String> - 用户配置的子协议列表，按偏好排名，默认为空。若用户配置了，则会随着升级请求发送给服务器。
- headers!: [HttpHeaders](http_package_classes.md#class-httpheaders) - 需要随着升级请求一同发送的非升级必要头，如 cookie 等。

返回值：

- ([WebSocket](http_package_classes.md#class-websocket), HttpHeaders) - 升级成功时，返回用于通讯的 [WebSocket](http_package_classes.md#class-websocket) 对象以及 101 响应头。

异常：

- SocketException - 底层连接错误时抛出异常。
- [HttpException](http_package_exceptions.md#class-httpexception) - 握手时 HTTP 请求过程中出现错误时抛出异常。
- [WebSocketException](http_package_exceptions.md#class-websocketexception) - 升级失败，升级响应验证不通过时抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*
import stdx.encoding.url.*
import std.collection.*
import stdx.log.*
import stdx.crypto.kit.*

let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

main(): Unit {
    // 启动服务端
    spawn {
        =>
            // 注册 WebSocket 处理器到指定路径
            server.distributor.register("/webSocket", WebSocketHandler)
            server.logger.level = LogLevel.OFF
            server.serve()
    }
    // 等待服务端启动完成
    sleep(Duration.second)

    // ===== 客户端流程 =====
    let client = ClientBuilder().build()
    let url = URL.parse("ws://127.0.0.1:8080/webSocket")

    // 设置自定义请求头，服务端可在响应中回显
    let headers = HttpHeaders()
    headers.add("X-Client-Id", "demo-client")

    // 设置 Origin 请求头，服务端可用于验证来源
    headers.add("Origin", "http://127.0.0.1:8080")

    // 执行 WebSocket 握手升级。客户端提供支持的子协议列表
    // 服务端从中选择第一个匹配的（此处为 "chat"）
    let (clientWs, respHeaders) = WebSocket.upgradeFromClient(
        client,
        url,
        subProtocols: ArrayList<String>(["chat", "json"]),
        headers: headers
    )
    clientWs.logger.level = LogLevel.OFF
    client.close()

    // 打印握手结果：协商成功的子协议和服务端返回的响应头
    println("协商的子协议: ${clientWs.subProtocol}")
    println("服务端响应头: ${respHeaders.getFirst("X-Server-Id") ?? ""}")

    // 发送文本消息，服务端会回显一个更大的消息（测试分片传输）
    clientWs.write(TextWebFrame, "hello".toArray())
    let echoData = readWebSocketMessage(clientWs)
    println("接收数据大小: ${echoData.size}")

    // 发送 Close 帧并等待服务端响应，完成优雅关闭
    clientWs.writeCloseFrame(status: 1000)
    let closeFrame = clientWs.read()
    if (closeFrame.frameType == CloseWebFrame) {
        println("收到服务端 Close 帧，连接正常关闭")
        clientWs.closeConn()
    } else {
        println("警告：预期收到 Close 帧，但收到 ${closeFrame.frameType}")
        clientWs.closeConn()
    }
    server.close()
}

// 服务端 WebSocket 处理器
func WebSocketHandler(ctx: HttpContext): Unit {
    // 从 HTTP 升级请求升级为 WebSocket 连接
    // subProtocols: 服务端支持的子协议列表，按优先级排列
    // userFunc: 自定义处理函数，可读取请求头并设置响应头
    let serverWs = WebSocket.upgradeFromServer(
        ctx,
        origins: ArrayList<String>(["http://127.0.0.1:8080"]),
        subProtocols: ArrayList<String>(["chat", "json", "xml"]),
        userFunc: {
            req =>
                let headers = HttpHeaders()
                // 将客户端传来的 X-Client-Id 回显到响应头 X-Server-Id
                headers.add("X-Server-Id", req.headers.getFirst("X-Client-Id") ?? "unknown")
                headers
        }
    )

    // 读取客户端发送的完整消息（自动处理分片帧的拼接）
    let msg = readWebSocketMessage(serverWs)
    println("收到: ${String.fromUtf8(msg.toArray())}")

    // 发送一个大消息（4097 字节 > 默认分片大小 4096），
    // 客户端的 readWebSocketMessage 需要能正确处理分片帧
    serverWs.write(TextWebFrame, Array<UInt8>(4097, repeat: 97))

    // 等待客户端关闭并响应
    let closeFrame = serverWs.read()
    // 验证收到的是 Close 帧，然后完成双向关闭握手
    if (closeFrame.frameType == CloseWebFrame) {
        serverWs.write(CloseWebFrame, closeFrame.payload)
        serverWs.closeConn()
    } else {
        println("警告：预期收到 Close 帧，但收到 ${closeFrame.frameType}")
        serverWs.closeConn()
    }
}

// 读取完整 WebSocket 消息的简易函数（处理分片帧）
func readWebSocketMessage(ws: WebSocket): ArrayList<UInt8> {
    let data = ArrayList<UInt8>()
    var frame = ws.read()
    while (true) {
        match (frame.frameType) {
            // 延续帧：追加 payload，fin=true 表示这是最后一个分片
            case ContinuationWebFrame =>
                data.add(all: frame.payload)
                if (frame.fin) {
                    return data
                }
            // 首帧（文本或二进制）：必须是消息的第一个帧
            case TextWebFrame | BinaryWebFrame =>
                // 如果 data 不为空，说明收到了乱序的帧，抛出异常
                if (!data.isEmpty()) {
                    throw Exception("invalid frame sequence.")
                }
                data.add(all: frame.payload)
                if (frame.fin) {
                    return data
                }
            case CloseWebFrame =>
                ws.write(CloseWebFrame, frame.payload)
                return data
            // Ping 帧：自动回复 Pong 帧，继续读取
            case PingWebFrame => ws.writePongFrame(frame.payload)
            case _ => println("unexpected frame: ${frame.frameType}")
        }
        frame = ws.read()
    }
    data
}
```

运行结果：

```text
协商的子协议: chat
服务端响应头: demo-client
收到: hello
接收数据大小: 4097
收到服务端 Close 帧，连接正常关闭
```

### static func upgradeFromServer(HttpContext, ArrayList\<String>, ArrayList\<String>, (HttpRequest) -> HttpHeaders)

```cangjie
public static func upgradeFromServer(ctx: HttpContext, subProtocols!: ArrayList<String> = ArrayList<String>(),
        origins!: ArrayList<String> = ArrayList<String>(),
        userFunc!: (HttpRequest) -> HttpHeaders = {_: HttpRequest => HttpHeaders()}): WebSocket
```

功能：提供服务端升级到 [WebSocket](http_package_classes.md#class-websocket) 协议的函数，通常在 handler 中使用。

服务端升级的流程为：收到客户端发来的升级请求，验证请求，如果验证通过，则回复 101 响应并返回 [WebSocket](http_package_classes.md#class-websocket) 对象用于 [WebSocket](http_package_classes.md#class-websocket) 通讯。

- 用户通过 subProtocols，origins 参数来配置其支持的 subprotocol 和 origin 白名单，subProtocols 如果不设置，则表示不支持子协议，origins 如果不设置，则表示接受所有 origin 的握手请求；
- 用户通过 userFunc 来自定义处理升级请求的行为，如处理 cookie 等，传入的 userFunc 要求返回一个 [HttpHeaders](http_package_classes.md#class-httpheaders) 对象，其会通过 101 响应回给客户端（升级失败的请求则不会）；
- 暂不支持 [WebSocket](http_package_classes.md#class-websocket) 的 extensions，因此如果握手过程中出现 extensions 协商则会抛 [WebSocketException](http_package_exceptions.md#class-websocketexception)；
- 只支持 HTTP1_1 和 HTTP2_0 向 [WebSocket](http_package_classes.md#class-websocket) 升级。

参数：

- ctx: [HttpContext](http_package_classes.md#class-httpcontext) - Http 请求上下文，将传入给 handler 的直接传给 upgradeFromServer 即可。
- subProtocols!: ArrayList\<String> - 用户配置的子协议列表，默认值为空，表示不支持。如果用户配置了，则会选取升级请求中最靠前的作为升级后的 [WebSocket](http_package_classes.md#class-websocket) 的子协议，用户可通过调用返回的 [WebSocket](http_package_classes.md#class-websocket) 的 subProtocol 查看子协议。
- origins!: ArrayList\<String> - 用户配置的同意握手的 origin 的白名单，如果不配置，则同意来自所有 origin 的握手，如果配置了，则只接受来自配置 origin 的握手。
- userFunc!: ([HttpRequest](http_package_classes.md#class-httprequest)) ->[HttpHeaders](http_package_classes.md#class-httpheaders) - 用户配置的自定义处理升级请求的函数，该函数返回一个 [HttpHeaders](http_package_classes.md#class-httpheaders)。

返回值：

- [WebSocket](http_package_classes.md#class-websocket) - 升级得到的 [WebSocket](http_package_classes.md#class-websocket) 实例。

示例：
<!-- associated_example -->
参见 [static func upgradeFromClient](#static-func-upgradefromclientclient-url-protocol-arrayliststring-httpheaders) 示例。

### func closeConn()

```cangjie
public func closeConn(): Unit
```

功能：提供关闭底层 [WebSocket](http_package_classes.md#class-websocket) 连接的函数。

> **说明：**
>
> 直接关闭底层连接。正常的关闭流程需要遵循协议规定的握手流程，即先发送 Close 帧给对端，并等待对端回应的 Close 帧。握手流程结束后方可关闭底层连接。

示例：
<!-- associated_example -->
参见 [static func upgradeFromClient](#static-func-upgradefromclientclient-url-protocol-arrayliststring-httpheaders) 示例。

### func read()

```cangjie
public func read(): WebSocketFrame
```

功能：从连接中读取一个帧，如果连接上数据未就绪会阻塞，非线程安全（即对同一个 [WebSocket](http_package_classes.md#class-websocket) 对象不支持多线程读）。

read 函数返回一个 [WebSocketFrame](http_package_classes.md#class-websocketframe) 对象。用户可通过 [WebSocketFrame](http_package_classes.md#class-websocketframe) 的 frameType 和 fin 属性确定帧类型以及是否为分段帧，通过 payload 函数获取原始二进制数据（Array\<UInt8>）。

- 首帧：fin == false，frameType 为 TextWebFrame 或 BinaryWebFrame
- 中间帧：fin == false，frameType 为 ContinuationWebFrame
- 尾帧：fin == true，frameType 为 ContinuationWebFrame
- 非分段帧：fin == true，frameType 不为 ContinuationWebFrame

> **注意：**
>
> - 数据帧（Text，Binary）可以分段。用户需多次调用 read 读取所有分段帧（收到 fin == true 时表示消息完整），然后将各分段帧的 payload 按顺序拼接。Text 帧的 payload 为 UTF-8 编码，可调用 String.fromUtf8 转为字符串；Binary 帧的 payload 含义由应用定义，直接传给上层处理；
> - 控制帧（Close，Ping，Pong）不可分段；
> - 控制帧本身不可分段，但其可以穿插在分段的数据帧之间。分段的数据帧之间不可出现其他数据帧，如果用户收到穿插的分段数据帧，则需要当作错误处理；
> - 客户端收到 masked 帧，服务器收到 unmasked 帧，断开底层连接并抛出异常；
> - rsv1、rsv2、rsv3 位被设置（暂不支持 extensions，因此 rsv 位必须为 0），断开底层连接并抛出异常；
> - 收到无法理解的帧类型（只支持 Continuation，Text，Binary，Close，Ping，Pong），断开底层连接并抛出异常；
> - 收到分段或 payload 长度大于 125 bytes 的控制帧（Close，Ping，Pong），断开底层连接并抛出异常；
> - 收到 payload 长度大于 20M 的帧，断开底层连接并抛出异常；
> - WebSocket 没有分段帧聚合消息大小限制，即由多个分段帧组成的完整消息的总大小没有限制；
> - closeConn 关闭连接后继续调用读，抛出异常。

返回值：

- [WebSocketFrame](http_package_classes.md#class-websocketframe) - 读到的 [WebSocketFrame](http_package_classes.md#class-websocketframe) 对象。

异常：

- SocketException - 底层连接错误。
- [WebSocketException](http_package_exceptions.md#class-websocketexception) - 收到不符合协议规定的帧，此时会给对端发送 Close 帧说明错误信息，并断开底层连接。
- [ConnectionException](http_package_exceptions.md#class-connectionexception) - 从连接中读数据时对端已关闭连接抛此异常。

示例：
<!-- associated_example -->
参见 [static func upgradeFromClient](#static-func-upgradefromclientclient-url-protocol-arrayliststring-httpheaders) 示例。

### func write(WebSocketFrameType, Array\<UInt8>, Int64)

```cangjie
public func write(frameType: WebSocketFrameType, byteArray: Array<UInt8>, frameSize!: Int64 = 4096): Unit
```

功能：发送数据，非线程安全（即对同一个 [WebSocket](http_package_classes.md#class-websocket) 对象不支持多线程写）。

> **注意：**
>
> write 函数将数据以 [WebSocket](http_package_classes.md#class-websocket) 帧的形式发送给对端；
>
> - 发送数据帧（Text，Binary）时，若 byteArray 大于 frameSize（默认 4 * 1024 bytes），会将其切分为不超过 frameSize 的 payload 并以分段帧形式发送；否则不分段；
> - 如果发送控制帧（Close，Ping，Pong），传入的 byteArray 的大小需要小于等于 125 bytes，Close 帧的前两个字节为状态码，可用的状态码见 RFC 6455 7.4. Status Codes 协议规定，Close 帧发送之后，禁止再发送数据帧，如果发送则会抛出异常；
> - 用户需要自己保证其传入的 byteArray 符合协议，如 Text 帧的 payload 需要是 UTF-8 编码，如果数据帧设置了 frameSize，那么需要大于 0，否则抛出异常；
> - 发送数据帧时，frameSize 小于等于 0，抛出异常；
> - 用户发送控制帧时，传入的数据大于 125 bytes，抛出异常；
> - 用户传入非 Text，Binary，Close，Ping，Pong 类型的帧类型，抛出异常；
> - 发送 Close 帧时传入非法的状态码，或 reason 数据超过 123 bytes，抛出异常；
> - 发送完 Close 帧后继续发送数据帧，抛出异常；
> - closeConn 关闭连接后调用写，抛出异常。

参数：

- frameType: [WebSocketFrameType](http_package_enums.md#enum-websocketframetype) - 所需发送的帧的类型。
- byteArray: Array\<UInt8> - 所需发送的帧的 payload（二进制形式）。
- frameSize!: Int64 - 分段帧的大小，默认为 4 * 1024 bytes，frameSize 不会对控制帧生效（控制帧设置了无效）。

异常：

- SocketException - 底层连接错误时抛出异常。
- [WebSocketException](http_package_exceptions.md#class-websocketexception) - 传入非法的帧类型，或者数据时抛出异常。

示例：
<!-- associated_example -->
参见 [static func upgradeFromClient](#static-func-upgradefromclientclient-url-protocol-arrayliststring-httpheaders) 示例。

### func writeCloseFrame(?UInt16, String)

```cangjie
public func writeCloseFrame(status!: ?UInt16 = None, reason!: String = ""): Unit
```

功能：发送 Close 帧。

> **注意：**
>
> 协议规定：发送 Close 帧后禁止再发送数据帧。若未设置 status，则 reason 也不会发送（有 reason 必有 status）。控制帧 payload 不超过 125 bytes，其中 Close 帧前 2 bytes 为 status，因此 reason 不能超过 123 bytes。另外，closeConn 关闭连接后再调用写操作会抛出异常。

参数：

- status!: ?UInt16 - 发送的 Close 帧的状态码，默认为 None，表示不发送状态码和 reason。
- reason!: String - 关闭连接的说明，默认为空字符串，发送时会转成 UTF-8，不保证可读，debug 用。

异常：

- [WebSocketException](http_package_exceptions.md#class-websocketexception) - 传入非法的状态码，或 reason 数据超过 123 bytes 时抛出异常。

示例：
<!-- associated_example -->
参见 [static func upgradeFromClient](#static-func-upgradefromclientclient-url-protocol-arrayliststring-httpheaders) 示例。

### func writePingFrame(Array\<UInt8>)

```cangjie
public func writePingFrame(byteArray: Array<UInt8>): Unit
```

功能：提供发送 Ping 帧的快捷函数，closeConn 关闭连接后调用写，抛出异常。

参数：

- byteArray: Array\<UInt8> - 所需发送的帧的 payload（二进制形式）。

异常：

- SocketException - 底层连接错误时抛出异常。
- [WebSocketException](http_package_exceptions.md#class-websocketexception) - 传入的数据大于 125 bytes，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*
import stdx.encoding.url.*
import stdx.log.*
import std.collection.*
import stdx.crypto.kit.*

let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

main(): Unit {
    // 启动服务端
    spawn {
        =>
            server.distributor.register("/ping", PingHandler)
            server.logger.level = LogLevel.OFF
            server.serve()
    }
    // 等待服务端启动完成
    sleep(Duration.second)

    // 客户端连接
    let client = ClientBuilder().build()
    let url = URL.parse("ws://127.0.0.1:8080/ping")
    let headers = HttpHeaders()
    headers.add("Origin", "http://127.0.0.1:8080")
    let (ws, _) = WebSocket.upgradeFromClient(client, url, headers: headers)
    client.close()

    // 发送 Ping 帧
    println("客户端发送 Ping 帧")
    ws.writePingFrame("hello".toArray())

    // 读取服务端回复的 Pong 帧
    let frame = ws.read()
    if (frame.frameType == PongWebFrame) {
        println("客户端收到 Pong 帧: ${String.fromUtf8(frame.payload)}")
    }

    // 关闭连接
    ws.writeCloseFrame(status: 1000)
    ws.closeConn()
    server.close()
}

// 服务端处理器：收到 Ping 后回复 Pong
func PingHandler(ctx: HttpContext): Unit {
    // 配置 origins 白名单，接受来自 http://127.0.0.1:8080 的连接
    let serverWs = WebSocket.upgradeFromServer(ctx, origins: ArrayList<String>(["http://127.0.0.1:8080"]))

    // 读取 Ping 帧
    let frame = serverWs.read()
    if (frame.frameType == PingWebFrame) {
        println("服务端收到 Ping: ${String.fromUtf8(frame.payload)}")
        // 回复 Pong 帧（payload 原样返回）
        serverWs.writePongFrame(frame.payload)
        println("服务端回复 Pong 帧")
    }

    // 等待客户端关闭
    let closeFrame = serverWs.read()
    if (closeFrame.frameType == CloseWebFrame) {
        serverWs.closeConn()
    }
}
```

运行结果：

```text
客户端发送 Ping 帧
服务端收到 Ping: hello
服务端回复 Pong 帧
客户端收到 Pong 帧: hello
```

### func writePongFrame(Array\<UInt8>)

```cangjie
public func writePongFrame(byteArray: Array<UInt8>): Unit
```

功能：提供发送 Pong 帧的快捷函数，closeConn 关闭连接后调用写，抛出异常。

参数：

- byteArray: Array\<UInt8> - 所需发送的帧的 payload（二进制形式）。

异常：

- SocketException - 底层连接错误时抛出异常。
- [WebSocketException](http_package_exceptions.md#class-websocketexception) - 传入的数据大于 125 bytes，抛出异常。

示例：
<!-- associated_example -->
参见 [func writePingFrame](#func-writepingframearrayuint8) 示例。

## class WebSocketFrame

```cangjie
public class WebSocketFrame
```

功能：[WebSocket](http_package_classes.md#class-websocket) 用于读的基本单元。

[WebSocketFrame](http_package_classes.md#class-websocketframe) 提供了三个属性，其中 fin 和 frameType 共同说明了帧是否分段和帧的类型。payload 为帧的载荷。

- 分段帧的首帧为 fin == false，frameType == TextWebFrame 或 BinaryWebFrame；
- 中间帧 fin == false，frameType == ContinuationWebFrame；
- 尾帧 fin == true， frameType == ContinuationWebFrame；
- 非分段帧为     fin == true， frameType != ContinuationWebFrame；
- 用户仅能通过 [WebSocket](http_package_classes.md#class-websocket) 对象的 read 函数得到 [WebSocketFrame](http_package_classes.md#class-websocketframe)。数据帧可分段，如果用户收到分段帧，则需要多次调用 read 函数直到收到完整的 message，并将所有分段的 payload 按接收顺序拼接。

> **注意：**
>
> 由于控制帧可以穿插在分段帧之间，用户在拼接分段帧的 payload 时需要单独处理控制帧。分段帧之间仅可穿插控制帧，如果用户在分段帧之间接收到其他数据帧，则需要当作错误处理。

### prop fin

```cangjie
public prop fin: Bool
```

功能：获取 [WebSocketFrame](http_package_classes.md#class-websocketframe) 的 fin 属性，fin 与 frameType 共同说明了帧是否分段和帧的类型。

类型：Bool

示例：
<!-- associated_example -->
参见 [static func upgradeFromClient](#static-func-upgradefromclientclient-url-protocol-arrayliststring-httpheaders) 示例。

### prop frameType

```cangjie
public prop frameType: WebSocketFrameType
```

功能：获取 [WebSocketFrame](http_package_classes.md#class-websocketframe) 的帧类型，fin 与 frameType 共同说明了帧是否分段和帧的类型。

类型：[WebSocketFrameType](http_package_enums.md#enum-websocketframetype)

示例：
<!-- associated_example -->
参见 [static func upgradeFromClient](#static-func-upgradefromclientclient-url-protocol-arrayliststring-httpheaders) 示例。

### prop payload

```cangjie
public prop payload: Array<UInt8>
```

功能：获取 [WebSocketFrame](http_package_classes.md#class-websocketframe) 的帧载荷。如果是分段数据帧，用户需要在接收到完整的 message 后，将所有分段的 payload 按接收序拼接。

类型：Array\<UInt8>

示例：
<!-- associated_example -->
参见 [static func upgradeFromClient](#static-func-upgradefromclientclient-url-protocol-arrayliststring-httpheaders) 示例。
