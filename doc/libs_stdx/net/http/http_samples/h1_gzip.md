# h1_gzip

服务端使用 gzip 压缩报文示例

示例：

<!-- verify -->
```cangjie
import stdx.compress.zlib.*
import stdx.net.http.*
import stdx.log.*
import std.io.*
import std.collection.*

let server = ServerBuilder().addr("127.0.0.1").port(0).build()

main() {
    // 启动服务器
    spawn {
        startServer()
    }
    sleep(Duration.second) // 等待服务器启动

    // 构建 HTTP 请求，声明客户端支持 gzip 压缩
    let request = HttpRequestBuilder()
        .get()
        .url("http://127.0.0.1:${server.port}/hello")
        .header("Accept-Encoding", "gzip")
        .build()

    // 发送请求并获取响应
    let client = ClientBuilder().build()
    let response = client.send(request)

    // 使用 gzip 解压响应体
    let decompressedBody = DecompressInputStream(response.body, wrap: GzipFormat)
    println("Rsp body: ${StringReader(decompressedBody).readToEnd()}")

    client.close()
    server.close()
}

func startServer(): Unit {
    server.distributor.register("/hello") {
        ctx =>
            // 设置响应头，声明使用 chunked 传输编码和 gzip 内容编码
            ctx.responseBuilder.header("Transfer-Encoding", "chunked")
            ctx.responseBuilder.header("Content-Encoding", "gzip")

            // 准备原始响应体数据
            let rawBody = ByteBuffer()
            "hello gzip".toArray() |> rawBody.write

            // 使用 gzip 压缩输入流作为响应体
            let compressedBody = CompressInputStream(rawBody, wrap: GzipFormat)
            ctx.responseBuilder.body(compressedBody)
    }
    server.logger.level = LogLevel.OFF
    server.serve()
}
```

运行结果：

```text
Rsp body: hello gzip
```
