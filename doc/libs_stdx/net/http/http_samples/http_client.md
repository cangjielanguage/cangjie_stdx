# client

> **注意：**
>
> 以下示例仅用于展示客户端写法，可通过编译但无法运行成功。如需查看运行效果，需用户自行提供服务端配合运行。部分用例需用户自行提供有效证书文件。

## Hello World

示例：

<!-- compile -->
```cangjie
import stdx.net.http.*

main() {
    // 构建客户端实例
    let client = ClientBuilder().build()
    // 发送 GET 请求并获取响应（URL 可根据实际情况修改）
    let response = client.get("http://example.com/hello")
    // 打印响应信息
    println(response)
    // 关闭客户端连接
    client.close()
}
```

## 自定义 client 网络配置

示例：

<!-- compile -->
```cangjie
import std.net.{TcpSocket, SocketAddress}
import std.fs.*
import stdx.net.tls.*
import stdx.net.tls.common.*
import stdx.crypto.x509.X509Certificate
import stdx.net.http.*
import std.io.*

main() {
    // 自定义配置
    // 配置 TLS，需用户提供有效的 CA 证书文件
    var tlsConfig = TlsClientConfig()
    let rootCertContent = String.fromUtf8(File.readFrom("/rootCerPath"))
    tlsConfig.verifyMode = CustomCA(X509Certificate.decodeFromPem(rootCertContent).map({certificate => certificate}))
    tlsConfig.supportedAlpnProtocols = ["h2"]
    // 配置自定义 TCP 连接器
    let customConnector = {
        sa: SocketAddress =>
            let socket = TcpSocket(sa)
            socket.connect()
            return socket
    }
    // 构建客户端实例，应用自定义配置
    let client = ClientBuilder().tlsConfig(tlsConfig).enablePush(false).connector(customConnector).build()
    // 发送请求（URL 可根据实际情况修改）
    let response = client.get("https://example.com/hello")
    // 读取并打印响应体
    let buffer = Array<UInt8>(1024, repeat: 0)
    let bytesRead = response.body.read(buffer)
    println(String.fromUtf8(buffer.slice(0, bytesRead)))
    // 关闭客户端连接
    client.close()
}
```

## 响应中的 trailer 读取

客户端读取服务端响应中的 trailer 示例：

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
    sleep(Duration.second)

    // 构建客户端实例
    let client = ClientBuilder().build()

    // 发送请求
    let response = client.get("http://127.0.0.1:${server.port}/data")

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

    client.close()
    server.close()
}

func startServer(): Unit {
    server.distributor.register("/data", {
        httpContext => httpContext
            .responseBuilder
            .header("Transfer-Encoding", "chunked")
            .header("Trailer", "X-Checksum")
            .body("Hello Client!")
            .trailer("X-Checksum", "abc123")
    })
    server.logger.level = LogLevel.OFF
    server.serve()
}
```

运行结果：

```text
响应体: Hello Client!
Trailer: abc123
```

## 配置代理

示例：

<!-- compile -->
```cangjie
import stdx.net.http.*

main() {
    // 构建客户端实例，配置 HTTP 代理
    let client = ClientBuilder().httpProxy("http://127.0.0.1:8080").build()
    // 发送请求，所有请求都会通过代理服务器转发（代理配置和 URL 可根据实际情况修改）
    let response = client.get("http://example.com/hello")
    // 打印响应信息
    println(response)
    // 关闭客户端连接
    client.close()
}
```
