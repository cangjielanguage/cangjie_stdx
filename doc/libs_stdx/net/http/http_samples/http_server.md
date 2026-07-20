# server

## Hello 仓颉

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

    // 构建客户端并发送请求
    let client = ClientBuilder().build()
    let response = client.get("http://127.0.0.1:${server.port}/index")
    println("响应状态: ${response.status}")

    // 读取响应内容
    let buf = Array<UInt8>(100, repeat: 0)
    let len = response.body.read(buf)
    println("响应内容: ${String.fromUtf8(buf[..len])}")

    // 关闭客户端和服务器
    client.close()
    server.close()
}

func startServer(): Unit {
    server.distributor.register("/index", {
        httpContext => httpContext.responseBuilder.body("Hello 仓颉!")
    })
    server.logger.level = LogLevel.OFF
    server.serve()
}
```

运行结果：

```text
响应状态: 200
响应内容: Hello 仓颉!
```

## 通过 request distributor 注册处理器

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

    // 请求不同的路径，服务器自动分发到对应的处理器
    let resp1 = client.get("http://127.0.0.1:${server.port}/index")
    let resp2 = client.get("http://127.0.0.1:${server.port}/id")
    let resp3 = client.get("http://127.0.0.1:${server.port}/help")

    println("/index 响应: ${readBody(resp1)}")
    println("/id 响应: ${readBody(resp2)}")
    println("/help 响应: ${readBody(resp3)}")

    // 关闭客户端和服务器
    client.close()
    server.close()
}

func startServer(): Unit {
    var indexHandler: HttpRequestHandler = FuncHandler({
        httpContext => httpContext.responseBuilder.body("index")
    })
    var idHandler: HttpRequestHandler = FuncHandler({
        httpContext => httpContext.responseBuilder.body("id")
    })
    var helpHandler: HttpRequestHandler = FuncHandler({
        httpContext => httpContext.responseBuilder.body("help")
    })
    server.distributor.register("/index", indexHandler)
    server.distributor.register("/id", idHandler)
    server.distributor.register("/help", helpHandler)
    server.logger.level = LogLevel.OFF
    server.serve()
}

func readBody(response: HttpResponse): String {
    let buf = Array<UInt8>(100, repeat: 0)
    let len = response.body.read(buf)
    String.fromUtf8(buf[..len])
}
```

运行结果：

```text
/index 响应: index
/id 响应: id
/help 响应: help
```

## 自定义 request distributor 与处理器

示例：

<!-- verify -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.collection.HashMap

// 自定义请求分发器
class NaiveDistributor <: HttpRequestDistributor {
    let map = HashMap<String, HttpRequestHandler>()
    public func register(path: String, handler: HttpRequestHandler): Unit {
        map.add(path, handler)
    }

    public func distribute(path: String): HttpRequestHandler {
        if (path == "/index" || path == "/index.html") {
            return PageHandler()
        }
        return NotFoundHandler()
    }
}

// 返回一个简单的 HTML 页面
class PageHandler <: HttpRequestHandler {
    public func handle(httpContext: HttpContext): Unit {
        httpContext.responseBuilder.body("<html><body>Hello</body></html>")
    }
}

let server = ServerBuilder().addr("127.0.0.1").port(0).distributor(NaiveDistributor()).build()

main() {
    // 启动服务器
    spawn {
        server.logger.level = LogLevel.OFF
        server.serve()
    }
    sleep(Duration.second) // 等待服务器启动

    // 构建客户端并发送请求
    let client = ClientBuilder().build()

    let resp1 = client.get("http://127.0.0.1:${server.port}/index")
    println("/index 响应状态: ${resp1.status}")

    let resp2 = client.get("http://127.0.0.1:${server.port}/unknown")
    println("/unknown 响应状态: ${resp2.status}")

    // 关闭客户端和服务器
    client.close()
    server.close()
}
```

运行结果：

```text
/index 响应状态: 200
/unknown 响应状态: 404
```

## 自定义 server 网络配置

示例：

<!-- compile -->
```cangjie
import std.io.*
import std.fs.*
import stdx.net.tls.*
import stdx.crypto.x509.X509Certificate
import stdx.crypto.keys.GeneralPrivateKey
import stdx.net.http.*

main() {
    // 自定义传输层配置
    // 配置 TCP 参数，设置读缓冲区大小
    var transportCfg = TransportConfig()
    transportCfg.readBufferSize = 8192
    // 配置 TLS 参数，需要提供证书和私钥文件路径（用户需自行提供有效文件）
    let certContent = String.fromUtf8(File.readFrom("/certPath"))
    let keyContent = String.fromUtf8(File.readFrom("/keyPath"))
    var tlsConfig = TlsServerConfig(X509Certificate.decodeFromPem(certContent),
        GeneralPrivateKey.decodeFromPem(keyContent))
    tlsConfig.supportedAlpnProtocols = ["h2"]
    // 构建服务器实例，应用自定义配置
    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(8080)
        .transportConfig(transportCfg)
        .tlsConfig(tlsConfig)
        .headerTableSize(10 * 1024)
        .maxRequestHeaderSize(1024 * 1024)
        .build()
    // 注册请求处理器
    server.distributor.register("/index", {
        httpContext => httpContext.responseBuilder.body("Hello 仓颉!")
    })
    // 启动服务器
    server.serve()
}
```

## response 中的 chunked 与 trailer

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

    // 构建客户端并发送请求
    let client = ClientBuilder().build()
    let response = client.get("http://127.0.0.1:${server.port}/chunked")

    // 循环调用直到返回 0，trailers 才会被填充
    let buf = Array<UInt8>(100, repeat: 0)
    var total = 0
    while (true) {
        let len = response.body.read(buf[total..])
        if (len == 0) {
            break
        }
        total += len
    }
    println("响应体: ${String.fromUtf8(buf[..total])}")

    // 读取 trailer
    let trailers = response.trailers
    println("Trailer: ${trailers.getFirst("X-Checksum") ?? "无"}")

    // 关闭客户端和服务器
    client.close()
    server.close()
}

func startServer(): Unit {
    server.distributor.register("/chunked", {
        httpContext => httpContext
            .responseBuilder
            .header("Transfer-Encoding", "chunked")
            .header("Trailer", "X-Checksum")
            .body("Hello Chunked!")
            .trailer("X-Checksum", "abc123")
    })
    server.logger.level = LogLevel.OFF
    server.serve()
}
```

运行结果：

```text
响应体: Hello Chunked!
Trailer: abc123
```

## 处理重定向 request

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

    // 构建客户端并发送请求
    let client = ClientBuilder().build()

    // 请求 /redirect，服务器会重定向到 /target
    let response = client.get("http://127.0.0.1:${server.port}/redirect")

    // 读取重定向后的响应
    let buf = Array<UInt8>(100, repeat: 0)
    let len = response.body.read(buf)
    println("最终响应: ${String.fromUtf8(buf[..len])}")

    // 关闭客户端和服务器
    client.close()
    server.close()
}

func startServer(): Unit {
    // 重定向处理器：/redirect -> /target
    server.distributor.register("/redirect", RedirectHandler("/target", 302))
    // 目标处理器
    server.distributor.register("/target", {
        httpContext => httpContext.responseBuilder.body("Target Page")
    })
    server.logger.level = LogLevel.OFF
    server.serve()
}
```

运行结果：

```text
最终响应: Target Page
```

## tls 证书热加载

更详细使用参见 [func updateCA](./../http_package_api/http_package_classes.md#func-updatecaarraycertificate)

示例：

<!-- compile -->
```cangjie
import std.io.*
import std.fs.*
import stdx.net.tls.*
import stdx.net.tls.common.*
import stdx.crypto.x509.X509Certificate
import stdx.crypto.keys.GeneralPrivateKey
import stdx.net.http.*

main() {
    // 配置 TLS，需用户提供有效的证书和私钥文件
    let certContent = String.fromUtf8(File.readFrom("/certPath"))
    let keyContent = String.fromUtf8(File.readFrom("/keyPath"))
    var tlsConfig = TlsServerConfig(X509Certificate.decodeFromPem(certContent),
        GeneralPrivateKey.decodeFromPem(keyContent))
    tlsConfig.supportedAlpnProtocols = ["http/1.1"]
    // 配置 CA 证书用于双向认证
    let rootCertContent = String.fromUtf8(File.readFrom("/rootCerPath"))
    tlsConfig.verifyMode = CustomCA(X509Certificate.decodeFromPem(rootCertContent).map({certificate => certificate}))
    // 构建服务器实例并启动服务
    let server = ServerBuilder().addr("127.0.0.1").port(8080).tlsConfig(tlsConfig).build()
    spawn {
        server.serve()
    }
    // 热更新 TLS 证书和私钥
    server.updateCert("/newCerPath", "/newKeyPath")
    // 热更新 CA 证书（用于双向认证）
    server.updateCA("/newRootCerPath")
}
```

## server push

仅用于 HTTP/2

更详细使用参见 [static func getPusher](./../http_package_api/http_package_classes.md#static-func-getpusherhttpcontext)

示例：

<!-- compile -->
```cangjie
import std.io.*
import std.fs.*
import stdx.net.tls.*
import stdx.net.tls.common.*
import stdx.crypto.x509.X509Certificate
import stdx.crypto.keys.*
import stdx.net.http.*

let server = ServerBuilder().addr("127.0.0.1").port(8080).build()

main() {
    spawn {
        // 配置服务器端 TLS
        let certContent = String.fromUtf8(File.readFrom("/certPath"))
        let keyContent = String.fromUtf8(File.readFrom("/keyPath"))
        var tlsConfig = TlsServerConfig(X509Certificate.decodeFromPem(certContent),
            GeneralPrivateKey.decodeFromPem(keyContent))
        tlsConfig.supportedAlpnProtocols = ["h2"]

        server.distributor.register(
            "/index.html",
            {
                httpContext =>
                    let pusher = HttpResponsePusher.getPusher(httpContext)
                    match (pusher) {
                        case Some(pusher) => pusher.push("/picture.png", "GET", httpContext.request.headers)
                        case None => ()
                    }
            }
        )
        server.distributor.register("/picture.png", {
            httpContext => httpContext.responseBuilder.body("picture.png")
        })
        server.serve()
    }

    // 客户端
    var tlsConfig = TlsClientConfig()
    let rootCertContent = String.fromUtf8(File.readFrom("/rootCerPath"))
    tlsConfig.verifyMode = CustomCA(X509Certificate.decodeFromPem(rootCertContent).map({certificate => certificate}))
    tlsConfig.supportedAlpnProtocols = ["h2"]

    let client = ClientBuilder().tlsConfig(tlsConfig).build()
    let response = client.get("https://127.0.0.1:8080/index.html")
    let pushResponses = response.getPush()
    client.close()
    server.close()
}
```
