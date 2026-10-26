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

### prop connector

```cangjie
public prop connector: (SocketAddress) -> StreamingSocket
```

功能：客户端调用此函数获取到服务器的连接。

类型：(SocketAddress) -> StreamingSocket

### prop cookieJar

```cangjie
public prop cookieJar: ?CookieJar
```

功能：用于存储客户端所有 [Cookie](http_package_classes.md#class-cookie)，如果配置为 None，则不会启用 [Cookie](http_package_classes.md#class-cookie)。

类型：?[CookieJar](http_package_interfaces.md#interface-cookiejar)

### prop enablePush

```cangjie
public prop enablePush: Bool
```

功能：客户端 HTTP/2 是否支持服务器推送，默认值为 true。

类型：Bool

### prop headerTableSize

```cangjie
public prop headerTableSize: UInt32
```

功能：获取客户端 HTTP/2 Hpack 动态表的初始值，默认值为 4096。

类型：UInt32

### prop httpProxy

```cangjie
public prop httpProxy: String
```

功能：获取客户端 http 代理，默认使用系统环境变量 http_proxy 的值，用字符串表示，格式为：`"http://host:port"`，例如：`"http://192.168.1.1:80"`。

类型：String

### prop httpsProxy

```cangjie
public prop httpsProxy: String
```

功能：获取客户端 https 代理，默认使用系统环境变量 https_proxy 的值，用字符串表示，格式为：`"http://host:port"`，例如：`"http://192.168.1.1:443"`。

类型：String

### prop initialWindowSize

```cangjie
public prop initialWindowSize: UInt32
```

功能：获取客户端 HTTP/2 流控窗口初始值，默认值为 65535 ，取值范围为 0 至 2^31 - 1。

类型：UInt32

### prop logger

```cangjie
public prop logger: Logger
```

功能：获取客户端日志记录器，设置 logger.level 将立即生效，记录器应该是线程安全的。

类型：[Logger](../../../log/log_package_api/log_package_classes.md#class-logger)

### prop maxConcurrentStreams

```cangjie
public prop maxConcurrentStreams: UInt32
```

功能：获取客户端 HTTP/2 初始最大并发流数量，默认值为 2^31 - 1。

类型：UInt32

### prop maxFrameSize

```cangjie
public prop maxFrameSize: UInt32
```

功能：获取客户端 HTTP/2 初始最大帧大小。默认值为 16384. 取值范围为 2^14 至 2^24 - 1。

类型：UInt32

### prop maxHeaderListSize

```cangjie
public prop maxHeaderListSize: UInt32
```

功能：获取客户端支持的 HTTP/2 最大头部（Header）大小。这个大小指的是响应头部中所有头部字段（Header Field）的最大允许长度之和，其中包括所有字段名称（name）的长度、字段值（value）的长度以及每个字段自动添加的伪头开销（通常每个字段会有 32 字节的开销，这包括了 HTTP/2 协议本身为头部字段添加的伪头部信息）。默认情况下，这个最大长度被设置为 UInt32.Max。

类型：UInt32

### prop poolSize

```cangjie
public prop poolSize: Int64
```

功能：配置 HTTP/1.1 客户端使用的连接池的大小，亦可表示对同一个主机（host:port）同时存在的连接数的最大值。

类型：Int64

### prop readTimeout

```cangjie
public prop readTimeout: Duration
```

功能：获取客户端设定的读取整个响应的超时时间，默认值为 15 秒。

类型：Duration

### prop writeTimeout

```cangjie
public prop writeTimeout: Duration
```

功能：获取客户端设定的写请求的超时时间，默认值为 15 秒。

类型：Duration

### func close()

```cangjie
public func close(): Unit
```

功能：关闭客户端建立的所有连接，调用后不能继续发送请求。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let client = ClientBuilder().build()

    // 调用 func close() 关闭客户端
    client.close()
    println("closed")
}
```

运行结果：

```text
closed
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

<!-- run -->
```cangjie
import stdx.net.http.*
import std.net.*
import std.sync.*

main() {
    // 1) 启动一个最简 "代理"：只要收到 CONNECT，就回 200 并保持连接可读。
    let ss = TcpServerSocket(bindAt: 0)
    ss.bind()
    let done = SyncCounter(1)

    spawn {
        =>
            let s = ss.accept()
            println("[server] CONNECT received")
            let buf = Array<UInt8>(2048, repeat: 0)
            let _ = s.read(buf)
            // CONNECT 成功：2xx
            s.write("HTTP/1.1 200 Connection Established\r\n\r\n".toArray())
            // 等 client 关闭
            s.close()
            done.dec()
    }

    let port = (ss.localAddress as IPSocketAddress)?.port ?? throw Exception("Port not found")

    let client = ClientBuilder().build()
    // 2) func connect：与服务端建立隧道，返回 (HttpResponse, ?StreamingSocket)
    let (resp, sockOpt) = client.connect("http://127.0.0.1:${port}")
    println("status = ${resp.status}")
    println("hasSocket = ${sockOpt.isSome()}")

    // 3) 关闭返回的 socket（由用户负责），再关闭 client。
    match (sockOpt) {
        case Some(s) => s.close()
        case None => ()
    }
    client.close()

    done.waitUntilZero()
    ss.close()
}
```

运行结果：

```text
[server] CONNECT received
status = 200
hasSocket = true
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

<!-- run -->
```cangjie
import stdx.net.http.*
import std.net.*
import std.sync.*

main() {
    let ss = TcpServerSocket(bindAt: 0)
    ss.bind()
    let done = SyncCounter(1)

    spawn {
        =>
            let s = ss.accept()
            let buf = Array<UInt8>(1024, repeat: 0)
            let n = s.read(buf)
            let firstLine = (String.fromUtf8(buf[..n]).split("\r\n"))[0]
            println("[server] ${firstLine}")
            s.write("HTTP/1.1 204 No Content\r\nConnection: close\r\n\r\n".toArray())
            s.close()
            done.dec()
    }

    let port = (ss.localAddress as IPSocketAddress)?.port ?? throw Exception("Port not found")

    let client = ClientBuilder().build()
    let resp = client.delete("http://127.0.0.1:${port}/d")
    println("status = ${resp.status}")

    client.close()
    done.waitUntilZero()
    ss.close()
}
```

运行结果：

```text
[server] DELETE /d HTTP/1.1
status = 204
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

<!-- run -->
```cangjie
import stdx.net.http.*
import std.net.*
import std.sync.*

main() {
    let ss = TcpServerSocket(bindAt: 0)
    ss.bind()
    let done = SyncCounter(1)

    spawn {
        =>
            let s = ss.accept()
            let buf = Array<UInt8>(1024, repeat: 0)
            let n = s.read(buf)
            let firstLine = (String.fromUtf8(buf[..n]).split("\r\n"))[0]
            println("[server] ${firstLine}")
            s.write("HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nOK".toArray())
            s.close()
            done.dec()
    }

    let port = (ss.localAddress as IPSocketAddress)?.port ?? throw Exception("Port not found")

    let client = ClientBuilder().build()

    // func get(String)
    let resp = client.get("http://127.0.0.1:${port}/hello")
    println("status = ${resp.status}")
    let bodyBuf = Array<UInt8>(16, repeat: 0)
    let m = resp.body.read(bodyBuf)
    println("body = ${String.fromUtf8(bodyBuf[..m])}")

    client.close()
    done.waitUntilZero()
    ss.close()
}
```

运行结果：

```text
[server] GET /hello HTTP/1.1
status = 200
body = OK
```

### func getTlsConfig()

```cangjie
public func getTlsConfig(): ?TlsConfig
```

功能：获取客户端设定的 TLS 层配置。

返回值：

- ?[TlsConfig](../../tls/common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconfig) - 客户端设定的 TLS 层配置，如果没有设置则返回 None。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    // 未配置 tlsConfig 时，getTlsConfig() 预期返回 None
    let client = ClientBuilder().build()
    let tls = client.getTlsConfig()
    println("tlsConfig.isSome = ${tls.isSome()}")
    client.close()
}
```

运行结果：

```text
tlsConfig.isSome = false
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

<!-- run -->
```cangjie
import stdx.net.http.*
import std.net.*
import std.sync.*

main() {
    let ss = TcpServerSocket(bindAt: 0)
    ss.bind()
    let done = SyncCounter(1)

    spawn {
        =>
            let s = ss.accept()
            let buf = Array<UInt8>(1024, repeat: 0)
            let n = s.read(buf)
            let firstLine = (String.fromUtf8(buf[..n]).split("\r\n"))[0]
            println("[server] ${firstLine}")
            // HEAD 响应可以带 Content-Length，但不返回 body
            s.write("HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\n".toArray())
            s.close()
            done.dec()
    }

    let port = (ss.localAddress as IPSocketAddress)?.port ?? throw Exception("Port not found")

    let client = ClientBuilder().build()
    let resp = client.head("http://127.0.0.1:${port}/h")
    println("status = ${resp.status}")
    println("bodySize = ${resp.bodySize}")

    // 读 body：预期读到 0
    let buf = Array<UInt8>(8, repeat: 0)
    let n = resp.body.read(buf)
    println("body.read = ${n}")

    client.close()
    done.waitUntilZero()
    ss.close()
}
```

运行结果：

```text
[server] HEAD /h HTTP/1.1
status = 200
bodySize = Some(0)
body.read = 0
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

<!-- run -->
```cangjie
import stdx.net.http.*
import std.net.*
import std.sync.*

main() {
    let ss = TcpServerSocket(bindAt: 0)
    ss.bind()
    let done = SyncCounter(1)

    spawn {
        =>
            let s = ss.accept()
            let buf = Array<UInt8>(1024, repeat: 0)
            let n = s.read(buf)
            let firstLine = (String.fromUtf8(buf[..n]).split("\r\n"))[0]
            println("[server] ${firstLine}")
            // 返回 Allow 头，表示支持的方法
            s.write("HTTP/1.1 204 No Content\r\nAllow: GET, POST, OPTIONS\r\nConnection: close\r\n\r\n".toArray())
            s.close()
            done.dec()
    }

    let port = (ss.localAddress as IPSocketAddress)?.port ?? throw Exception("Port not found")

    let client = ClientBuilder().build()
    let resp = client.options("http://127.0.0.1:${port}/")
    println("status = ${resp.status}")
    println("allow = ${resp.headers.getFirst("allow") ?? ""}")

    client.close()
    done.waitUntilZero()
    ss.close()
}
```

运行结果：

```text
[server] OPTIONS / HTTP/1.1
status = 204
allow = GET, POST, OPTIONS
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

<!-- run -->
```cangjie
import stdx.net.http.*
import std.net.*
import std.sync.*

main() {
    let ss = TcpServerSocket(bindAt: 0)
    ss.bind()
    let done = SyncCounter(1)

    spawn {
        =>
            let s = ss.accept()
            let buf = Array<UInt8>(4096, repeat: 0)
            var total = s.read(buf)
            var reqStr = String.fromUtf8(buf[..total])
            if (!reqStr.contains("\r\n\r\nabc")) {
                total += s.read(buf[total..])
                reqStr = String.fromUtf8(buf[..total])
            }
            let firstLine = (reqStr.split("\r\n"))[0]
            println("[server] ${firstLine}")
            let parts = reqStr.split("\r\n\r\n")
            if (parts.size > 1) {
                println("[server] body = ${parts[1]}")
            }
            s.write("HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nOK".toArray())
            s.close()
            done.dec()
    }

    let port = (ss.localAddress as IPSocketAddress)?.port ?? throw Exception("Port not found")

    let client = ClientBuilder().build()
    let resp = client.post("http://127.0.0.1:${port}/p", [97, 98, 99]) // func post(String, Array<UInt8>)

    let out = Array<UInt8>(8, repeat: 0)
    let m = resp.body.read(out)
    println("status = ${resp.status}")
    println("body = ${String.fromUtf8(out[..m])}")

    client.close()
    done.waitUntilZero()
    ss.close()
}
```

运行结果：

```text
[server] POST /p HTTP/1.1
[server] body = abc
status = 200
body = OK
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

<!-- run -->
```cangjie
import stdx.net.http.*
import std.io.*
import std.net.*
import std.sync.*

// 一个最简可 seek 的 InputStream：提供 length，满足 http 库对 bodySize 的要求。
public class ByteArrayInputStream <: InputStream & Seekable {
    let bytes: Array<Byte>
    var start: Int64
    var remain: Int64

    public init(str: String) {
        this.bytes = unsafe { str.rawData() }
        this.start = 0
        this.remain = bytes.size
    }

    public prop length: Int64 {
        get() {
            bytes.size
        }
    }

    public func read(buf: Array<Byte>): Int64 {
        if (remain == 0) {
            return 0
        }
        let size = min(buf.size, remain)
        bytes.copyTo(buf, start, 0, size)
        start += size
        remain -= size
        return size
    }

    public func seek(_: SeekPosition): Int64 {
        // 示例中不做真正 seek，仅满足接口要求。
        0
    }
}

main() {
    let ss = TcpServerSocket(bindAt: 0)
    ss.bind()
    let done = SyncCounter(1)

    spawn {
        =>
            let s = ss.accept()
            let buf = Array<UInt8>(4096, repeat: 0)
            var total = s.read(buf)
            var reqStr = String.fromUtf8(buf[..total])
            if (!reqStr.contains("\r\n\r\nhi")) {
                total += s.read(buf[total..])
                reqStr = String.fromUtf8(buf[..total])
            }
            let firstLine = (reqStr.split("\r\n"))[0]
            println("[server] ${firstLine}")
            let parts = reqStr.split("\r\n\r\n")
            if (parts.size > 1) {
                println("[server] body = ${parts[1]}")
            }
            s.write("HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nOK".toArray())
            s.close()
            done.dec()
    }

    let port = (ss.localAddress as IPSocketAddress)?.port ?? throw Exception("Port not found")

    // func post(String, InputStream)
    let body: InputStream = ByteArrayInputStream("hi")

    let client = ClientBuilder().build()
    let resp = client.post("http://127.0.0.1:${port}/p", body)

    let out = Array<UInt8>(8, repeat: 0)
    let m = resp.body.read(out)
    println("status = ${resp.status}")
    println("body = ${String.fromUtf8(out[..m])}")

    client.close()
    done.waitUntilZero()
    ss.close()
}
```

运行结果：

```text
[server] POST /p HTTP/1.1
[server] body = hi
status = 200
body = OK
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

<!-- run -->
```cangjie
import stdx.net.http.*
import std.net.*
import std.sync.*

main() {
    let ss = TcpServerSocket(bindAt: 0)
    ss.bind()
    let done = SyncCounter(1)

    spawn {
        =>
            let s = ss.accept()
            let buf = Array<UInt8>(4096, repeat: 0)
            var total = 0

            // 先读一段（通常包含完整 header，可能也包含 body）
            total += s.read(buf)
            var reqStr = String.fromUtf8(buf[..total])

            // 如果 body 还没读到（TCP 分包），继续读一段补齐。
            if (!reqStr.contains("\r\n\r\nhi")) {
                total += s.read(buf[total..])
                reqStr = String.fromUtf8(buf[..total])
            }
            let firstLine = (reqStr.split("\r\n"))[0]
            println("[server] ${firstLine}")
            let parts = reqStr.split("\r\n\r\n")
            if (parts.size > 1) {
                println("[server] body = ${parts[1]}")
            }
            let body = match (reqStr.indexOf("\r\n\r\n")) {
                case Some(idx) => reqStr[(idx + 4)..]
                case None => ""
            }

            let respBody = "echo:${body}"
            s.write(
                "HTTP/1.1 200 OK\r\nContent-Length: ${respBody.size}\r\nConnection: close\r\n\r\n${respBody}".toArray())
            s.close()
            done.dec()
    }

    let port = (ss.localAddress as IPSocketAddress)?.port ?? throw Exception("Port not found")

    let client = ClientBuilder().build()
    let resp = client.post("http://127.0.0.1:${port}/p", "hi") // func post(String, String)

    let out = Array<UInt8>(64, repeat: 0)
    let m = resp.body.read(out)
    println("status = ${resp.status}")
    println("body = ${String.fromUtf8(out[..m])}")

    client.close()
    done.waitUntilZero()
    ss.close()
}
```

运行结果：

```text
[server] POST /p HTTP/1.1
[server] body = hi
status = 200
body = echo:hi
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

<!-- run -->
```cangjie
import stdx.net.http.*
import std.net.*
import std.sync.*

main() {
    let ss = TcpServerSocket(bindAt: 0)
    ss.bind()
    let done = SyncCounter(1)

    spawn {
        =>
            let s = ss.accept()
            let buf = Array<UInt8>(4096, repeat: 0)
            var total = s.read(buf)
            var reqStr = String.fromUtf8(buf[..total])
            // 如果 body 未读全，补一段（这里 body 就是 "abc"）
            if (!reqStr.contains("\r\n\r\nabc")) {
                total += s.read(buf[total..])
                reqStr = String.fromUtf8(buf[..total])
            }
            let firstLine = (reqStr.split("\r\n"))[0]
            println("[server] ${firstLine}")
            let parts = reqStr.split("\r\n\r\n")
            if (parts.size > 1) {
                println("[server] body = ${parts[1]}")
            }
            s.write("HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nOK".toArray())
            s.close()
            done.dec()
    }

    let port = (ss.localAddress as IPSocketAddress)?.port ?? throw Exception("Port not found")

    let client = ClientBuilder().build()
    let resp = client.put("http://127.0.0.1:${port}/u", [97, 98, 99]) // func put(String, Array<UInt8>)

    let out = Array<UInt8>(8, repeat: 0)
    let m = resp.body.read(out)
    println("status = ${resp.status}")
    println("body = ${String.fromUtf8(out[..m])}")

    client.close()
    done.waitUntilZero()
    ss.close()
}
```

运行结果：

```text
[server] PUT /u HTTP/1.1
[server] body = abc
status = 200
body = OK
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

<!-- run -->
```cangjie
import stdx.net.http.*
import std.io.*
import std.net.*
import std.sync.*

public class ByteArrayInputStream <: InputStream & Seekable {
    let bytes: Array<Byte>
    var start: Int64
    var remain: Int64

    public init(str: String) {
        this.bytes = unsafe { str.rawData() }
        this.start = 0
        this.remain = bytes.size
    }

    public prop length: Int64 {
        get() {
            bytes.size
        }
    }

    public func read(buf: Array<Byte>): Int64 {
        if (remain == 0) {
            return 0
        }
        let size = min(buf.size, remain)
        bytes.copyTo(buf, start, 0, size)
        start += size
        remain -= size
        return size
    }

    public func seek(_: SeekPosition): Int64 {
        0
    }
}

main() {
    let ss = TcpServerSocket(bindAt: 0)
    ss.bind()
    let done = SyncCounter(1)

    spawn {
        =>
            let s = ss.accept()
            let buf = Array<UInt8>(4096, repeat: 0)
            var total = s.read(buf)
            var reqStr = String.fromUtf8(buf[..total])
            if (!reqStr.contains("\r\n\r\nhi")) {
                total += s.read(buf[total..])
                reqStr = String.fromUtf8(buf[..total])
            }
            let firstLine = (reqStr.split("\r\n"))[0]
            println("[server] ${firstLine}")
            let parts = reqStr.split("\r\n\r\n")
            if (parts.size > 1) {
                println("[server] body = ${parts[1]}")
            }
            s.write("HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nOK".toArray())
            s.close()
            done.dec()
    }

    let port = (ss.localAddress as IPSocketAddress)?.port ?? throw Exception("Port not found")

    let body: InputStream = ByteArrayInputStream("hi")

    let client = ClientBuilder().build()
    let resp = client.put("http://127.0.0.1:${port}/u", body) // func put(String, InputStream)

    let out = Array<UInt8>(8, repeat: 0)
    let m = resp.body.read(out)
    println("status = ${resp.status}")
    println("body = ${String.fromUtf8(out[..m])}")

    client.close()
    done.waitUntilZero()
    ss.close()
}
```

运行结果：

```text
[server] PUT /u HTTP/1.1
[server] body = hi
status = 200
body = OK
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

<!-- run -->
```cangjie
import stdx.net.http.*
import std.net.*
import std.sync.*

main() {
    let ss = TcpServerSocket(bindAt: 0)
    ss.bind()
    let done = SyncCounter(1)

    spawn {
        =>
            let s = ss.accept()
            let buf = Array<UInt8>(4096, repeat: 0)
            var total = s.read(buf)
            var reqStr = String.fromUtf8(buf[..total])
            if (!reqStr.contains("\r\n\r\nhi")) {
                total += s.read(buf[total..])
                reqStr = String.fromUtf8(buf[..total])
            }
            let firstLine = (reqStr.split("\r\n"))[0]
            println("[server] ${firstLine}")
            let parts = reqStr.split("\r\n\r\n")
            if (parts.size > 1) {
                println("[server] body = ${parts[1]}")
            }
            s.write("HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nOK".toArray())
            s.close()
            done.dec()
    }

    let port = (ss.localAddress as IPSocketAddress)?.port ?? throw Exception("Port not found")

    let client = ClientBuilder().build()
    let resp = client.put("http://127.0.0.1:${port}/u", "hi") // func put(String, String)

    let out = Array<UInt8>(8, repeat: 0)
    let m = resp.body.read(out)
    println("status = ${resp.status}")
    println("body = ${String.fromUtf8(out[..m])}")

    client.close()
    done.waitUntilZero()
    ss.close()
}
```

运行结果：

```text
[server] PUT /u HTTP/1.1
[server] body = hi
status = 200
body = OK
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.encoding.url.*
import std.net.*
import std.sync.*

main() {
    // server: 回 204 并关闭
    let ss = TcpServerSocket(bindAt: 0)
    ss.bind()
    let done = SyncCounter(1)
    spawn {
        =>
            let s = ss.accept()
            let buf = Array<UInt8>(1024, repeat: 0)
            let n = s.read(buf)
            let firstLine = (String.fromUtf8(buf[..n]).split("\r\n"))[0]
            println("[server] ${firstLine}")
            s.write("HTTP/1.1 204 No Content\r\nConnection: close\r\n\r\n".toArray())
            s.close()
            done.dec()
    }

    let port = (ss.localAddress as IPSocketAddress)?.port ?? throw Exception("Port not found")

    let client = ClientBuilder().build()

    // func send(HttpRequest): 通过 HttpRequestBuilder 构建请求
    let u = URL.parse("http://127.0.0.1:${port}/send")
    let req = HttpRequestBuilder().url(u).method("GET").build()
    let resp = client.send(req)
    println("status = ${resp.status}")

    client.close()
    done.waitUntilZero()
    ss.close()
}
```

运行结果：

```text
[server] GET /send HTTP/1.1
status = 204
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.encoding.url.*
import std.net.*
import std.sync.*

main() {
    let ss = TcpServerSocket(bindAt: 0)
    ss.bind()
    let done = SyncCounter(1)

    spawn {
        =>
            let s = ss.accept()
            let buf = Array<UInt8>(2048, repeat: 0)
            let n = s.read(buf)
            let reqStr = String.fromUtf8(buf[..n])
            // 打印方法（避免随机端口）
            println("method = ${reqStr.split(" ")[0]}")

            // 按协议回 101 Switching Protocols
            s.write("HTTP/1.1 101 Switching Protocols\r\nUpgrade: test/1\r\nConnection: Upgrade\r\n\r\n".toArray())
            // 等 client 关闭
            s.close()
            done.dec()
    }

    let port = (ss.localAddress as IPSocketAddress)?.port ?? throw Exception("Port not found")

    let client = ClientBuilder().build()

    // func upgrade(HttpRequest)
    let headers = HttpHeaders()
    headers.add("Upgrade", "test/1")
    let req = HttpRequestBuilder().url(URL.parse("http://127.0.0.1:${port}/up")).get().setHeaders(headers).build()

    let (resp, sockOpt) = client.upgrade(req)
    println("status = ${resp.status}")
    println("hasSocket = ${sockOpt.isSome()}")

    match (sockOpt) {
        case Some(s) => s.close()
        case None => ()
    }
    client.close()

    done.waitUntilZero()
    ss.close()
}
```

运行结果：

```text
method = GET
status = 101
hasSocket = true
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

main() {
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    // 配置 ClientBuilder.autoRedirect，并验证 Client.autoRedirect
    let client = ClientBuilder().autoRedirect(false).build()
    println("autoRedirect = ${client.autoRedirect}")
    client.close()
}
```

运行结果：

```text
autoRedirect = false
```

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

main() {
    // build() 构建出 Client 实例
    let client = ClientBuilder().build()
    println("poolSize = ${client.poolSize}")
    client.close()
}
```

运行结果：

```text
poolSize = 10
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

<!-- run -->
```cangjie
import stdx.net.http.*
import std.net.*
import std.sync.*

main() {
    // 用 connector 注入自定义建连逻辑
    let ss = TcpServerSocket(bindAt: 0)
    ss.bind()
    let done = SyncCounter(1)

    spawn {
        =>
            let s = ss.accept()
            let buf = Array<UInt8>(1024, repeat: 0)
            let n = s.read(buf)
            println((String.fromUtf8(buf[..n]).split("\r\n"))[0])
            s.write("HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nOK".toArray())
            s.close()
            done.dec()
    }

    let port = (ss.localAddress as IPSocketAddress)?.port ?? throw Exception("Port not found")

    let myConnector: (SocketAddress) -> StreamingSocket = {
        addr =>
            println("connector called")
            let socket = TcpSocket(addr)
            socket.connect()
            socket
    }

    let client = ClientBuilder().connector(myConnector).build()
    let resp = client.get("http://127.0.0.1:${port}/")
    println("status = ${resp.status}")

    client.close()
    done.waitUntilZero()
    ss.close()
}
```

运行结果：

```text
connector called
GET / HTTP/1.1
status = 200
```

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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    // 将 cookieJar 设为 None：禁用 Cookie
    let client = ClientBuilder().cookieJar(None).build()
    println("cookieJar.isSome = ${client.cookieJar.isSome()}")
    client.close()
}
```

运行结果：

```text
cookieJar.isSome = false
```

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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let client = ClientBuilder().enablePush(false).build()
    println("enablePush = ${client.enablePush}")
    client.close()
}
```

运行结果：

```text
enablePush = false
```

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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let client = ClientBuilder().headerTableSize(1024).build()
    println("headerTableSize = ${client.headerTableSize}")
    client.close()
}
```

运行结果：

```text
headerTableSize = 1024
```

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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    // 设置 http 代理（字符串形式）
    let client = ClientBuilder().httpProxy("http://proxy.example:8080").build()
    println("httpProxy = ${client.httpProxy}")
    client.close()
}
```

运行结果：

```text
httpProxy = http://proxy.example:8080
```

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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    // 设置 https 代理（注意：格式仍是 http://host:port）
    let client = ClientBuilder().httpsProxy("http://proxy.example:443").build()
    println("httpsProxy = ${client.httpsProxy}")
    client.close()
}
```

运行结果：

```text
httpsProxy = http://proxy.example:443
```

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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let client = ClientBuilder().initialWindowSize(65535).build()
    println("initialWindowSize = ${client.initialWindowSize}")
    client.close()
}
```

运行结果：

```text
initialWindowSize = 65535
```

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
import stdx.log.*

main() {
    // 使用 NoopLogger 注入 logger
    let logger = NoopLogger()
    logger.level = LogLevel.INFO

    let client = ClientBuilder().logger(logger).build()
    println("client.logger.level = ${client.logger.level}")
    client.close()
}
```

运行结果：

```text
client.logger.level = OFF
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let client = ClientBuilder().maxConcurrentStreams(100).build()
    println("maxConcurrentStreams = ${client.maxConcurrentStreams}")
    client.close()
}
```

运行结果：

```text
maxConcurrentStreams = 100
```

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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let client = ClientBuilder().maxFrameSize(16384).build()
    println("maxFrameSize = ${client.maxFrameSize}")
    client.close()
}
```

运行结果：

```text
maxFrameSize = 16384
```

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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let client = ClientBuilder().maxHeaderListSize(1024).build()
    println("maxHeaderListSize = ${client.maxHeaderListSize}")
    client.close()
}
```

运行结果：

```text
maxHeaderListSize = 1024
```

### func noProxy()

```cangjie
public func noProxy(): ClientBuilder
```

功能：调用此函数后，客户端不使用任何代理。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    // noProxy() 清空代理
    let client = ClientBuilder().noProxy().build()
    println("httpProxy = '${client.httpProxy}'")
    println("httpsProxy = '${client.httpsProxy}'")
    client.close()
}
```

运行结果：

```text
httpProxy = ''
httpsProxy = ''
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let client = ClientBuilder().poolSize(5).build()
    println("poolSize = ${client.poolSize}")
    client.close()
}
```

运行结果：

```text
poolSize = 5
```

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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let client = ClientBuilder().readTimeout(Duration.second * 1).build()
    println("readTimeout = ${client.readTimeout}")
    client.close()
}
```

运行结果：

```text
readTimeout = 1s
```

### func tlsConfig(TlsConfig)

```cangjie
public func tlsConfig(config: TlsConfig): ClientBuilder
```

功能：设置 TLS 层配置，默认不对其进行设置。当 TLS 客户端配置未指定 serverName 时，客户端将使用请求 URL 中的主机名作为 SNI 并校验服务器证书；主机名为空时 TLS 握手失败。

参数：

- config: [TlsConfig](../../tls/common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconfig) - 设定支持 tls 客户端需要的配置信息。

返回值：

- [ClientBuilder](http_package_classes.md#class-clientbuilder) - 当前 [ClientBuilder](http_package_classes.md#class-clientbuilder) 实例的引用。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.net.tls.*

main() {
    // 配置 ClientBuilder.tlsConfig，并通过 Client.getTlsConfig() 验证已生效。
    var tls = TlsClientConfig()
    tls.supportedAlpnProtocols = ["h2"]

    let client = ClientBuilder().tlsConfig(tls).build()
    println("tlsConfig.isSome = ${client.getTlsConfig().isSome()}")
    client.close()
}
```

运行结果：

```text
tlsConfig.isSome = true
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let client = ClientBuilder().writeTimeout(Duration.second * 2).build()
    println("writeTimeout = ${client.writeTimeout}")
    client.close()
}
```

运行结果：

```text
writeTimeout = 2s
```

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

### prop cookieValue

```cangjie
public prop cookieValue: String
```

功能：获取 [Cookie](http_package_classes.md#class-cookie) 对象的 cookie-value 值。

类型：String

### prop domain

```cangjie
public prop domain: String
```

功能：获取 [Cookie](http_package_classes.md#class-cookie) 对象的 domain-av 值。

类型：String

### prop expires

```cangjie
public prop expires: ?DateTime
```

功能：获取 [Cookie](http_package_classes.md#class-cookie) 对象的 expires-av 值。

类型：?DateTime

### prop httpOnly

```cangjie
public prop httpOnly: Bool
```

功能：获取 [Cookie](http_package_classes.md#class-cookie) 对象的 httpOnly-av 值。

类型：Bool

### prop maxAge

```cangjie
public prop maxAge: ?Int64
```

功能：获取 [Cookie](http_package_classes.md#class-cookie) 对象的 max-age-av 值。

类型：?Int64

### prop others

```cangjie
public prop others: ArrayList<String>
```

功能：获取未被解析的属性。

类型：ArrayList\<String>

### prop path

```cangjie
public prop path: String
```

功能：获取 [Cookie](http_package_classes.md#class-cookie) 对象的 path-av 值。

类型：String

### prop secure

```cangjie
public prop secure: Bool
```

功能：获取 [Cookie](http_package_classes.md#class-cookie) 对象的 secure-av 值。

类型：Bool

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
- maxAge!: ?Int64 - [Cookie](http_package_classes.md#class-cookie) 的最大生命周期，默认为 None，如果 [Cookie](http_package_classes.md#class-cookie) 既有 expires 属性，也有 maxAge，则表示该 [Cookie](http_package_classes.md#class-cookie) 只维护到会话结束（维护到 [Client](http_package_classes.md#class-client) 关闭之前，[Client](http_package_classes.md#class-client) 关闭之后设置了过期的 [Cookie](http_package_classes.md#class-cookie) 也不再维护）。

    ```text
    max-age-av     = "Max-Age=" non-zero-digit *DIGIT
    non-zero-digit = %x31-39
                    ; digits 1 through 9
    DIGIT          = %x30-39
                    ; digits 0 through 9
    ```

- domain!: String - 默认为空字符串，表示该收到该 [Cookie](http_package_classes.md#class-cookie) 的客户端只会发送该 [Cookie](http_package_classes.md#class-cookie) 给原始服务器。如果设置了合法的 domain，则收到该 [Cookie](http_package_classes.md#class-cookie) 的客户端只会发送该 [Cookie](http_package_classes.md#class-cookie) 给所有该 domain 的子域（且满足其他属性条件要求才会发）。

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

- path!: String - 默认为空字符串，客户端会根据 url 计算出默认的 path 属性，见 RFC 6265 5.1.4.。 收到该 [Cookie](http_package_classes.md#class-cookie) 的客户端只会发送该 [Cookie](http_package_classes.md#class-cookie) 给所有该 path 的子目录（且满足其他属性条件要求才会发）。

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

<!-- run -->
```cangjie
import stdx.net.http.*
import std.time.*

main() {
    let cookie = Cookie("sid", "abc", expires: DateTime.of(year: 2099, month: 1, dayOfMonth: 1, timeZone: TimeZone.UTC),
        maxAge: 3600, domain: "example.com", path: "/", secure: true, httpOnly: true)
    // 当前属性：secure
    println("secure = ${cookie.secure}")
}
```

运行结果：

```text
secure = true
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

<!-- run -->
```cangjie
import stdx.net.http.*
import std.time.*

main() {
    // func toSetCookieString(): 将 Cookie 转成 Set-Cookie header 的 value
    let cookie = Cookie(
        "sid",
        "abc",
        expires: DateTime.of(year: 2099, month: 1, dayOfMonth: 1, timeZone: TimeZone.UTC),
        maxAge: 3600,
        domain: ".example.com", // 以 '.' 开头也会被规范化
        path: "/",
        secure: true,
        httpOnly: true
    )

    let setCookieValue = cookie.toSetCookieString()
    println(setCookieValue)
}
```

运行结果：

```text
sid=abc; Expires=Thu, 01 Jan 2099 00:00:00 UTC; Max-Age=3600; Domain=example.com; Path=/; Secure; HttpOnly
```

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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let filePath: String = "./http_filehandler_download.txt"
    FileHandler(filePath)
    return 0
}
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let dirPath: String = "/tmp"
    FileHandler(dirPath, validator: {fileName: String => fileName.contains(".txt")})
    return 0
}
```

### func handle(HttpContext)

```cangjie
public func handle(ctx: HttpContext): Unit
```

功能：根据请求对响应数据进行处理。

参数：

- ctx: [HttpContext](http_package_classes.md#class-httpcontext) - Http 请求上下文。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.fs.*
import std.io.*
import std.sync.*

main() {
    // 创建一个临时文件，供 FileHandler 下载
    let filePath: Path = Path("./http_filehandler_download.txt")
    if (exists(filePath)) {
        remove(filePath)
    }
    let f = File(filePath, Write)
    f.write("file-content".toArray())
    f.close()

    // 启动服务并注册 FileHandler
    let sc = SyncCounter(1)
    let server = ServerBuilder().addr("127.0.0.1").port(18090).afterBind({=> sc.dec()}).build()
    server.distributor.register("/file", FileHandler(filePath.toString()))
    server.logger.level = LogLevel.ERROR

    spawn {server.serve()}
    sc.waitUntilZero()

    // 访问 /file，触发 FileHandler.handle(ctx)
    let client = ClientBuilder().build()
    let resp = client.get("http://127.0.0.1:18090/file")

    var buf = Array<UInt8>(1024, repeat: 0)
    var body = ""
    while (true) {
        let n = resp.body.read(buf)
        if (n <= 0) {
            break
        }
        body = body + String.fromUtf8(buf[..n])
    }
    resp.close()

    // 输出稳定内容（不打印随机端口等信息）
    println("status = ${resp.status}")
    println("body = ${body}")

    client.close()
    server.closeGracefully()
    remove(filePath)
}
```

运行结果：

```text
status = 200
body = file-content
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.fs.*
import std.io.*
import std.sync.*

main() {
    // 准备一个临时文件，让 handler 返回该文件内容（稳定输出）
    let filePath: Path = Path("./http_funchandler_resp.txt")
    if (exists(filePath)) {
        remove(filePath)
    }
    let f = File(filePath, Write)
    f.write("hello".toArray())
    f.close()

    // 使用 FuncHandler 注册一个处理函数
    let handler = FuncHandler({
        ctx =>
        // 当前函数：handle(ctx) 会触发这里的逻辑
        ctx.responseBuilder.status(200).header("content-type", "text/plain").body(File(filePath, Read))
    })

    let sc = SyncCounter(1)
    let server = ServerBuilder().addr("127.0.0.1").port(18091).afterBind({=> sc.dec()}).build()
    server.distributor.register("/hi", handler)
    server.logger.level = LogLevel.ERROR

    spawn {server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().build()
    let resp = client.get("http://127.0.0.1:18091/hi")

    var buf = Array<UInt8>(1024, repeat: 0)
    var body = ""
    while (true) {
        let n = resp.body.read(buf)
        if (n <= 0) {
            break
        }
        body = body + String.fromUtf8(buf[..n])
    }
    resp.close()

    println("status = ${resp.status}")
    println("body = ${body}")

    client.close()
    server.closeGracefully()
    remove(filePath)
}
```

运行结果：

```text
status = 200
body = hello
```

### func handle(HttpContext)

```cangjie
public func handle(ctx: HttpContext): Unit
```

功能：处理 Http 请求。

参数：

- ctx: [HttpContext](http_package_classes.md#class-httpcontext) - Http 请求上下文。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.fs.*
import std.io.*
import std.sync.*

main() {
    // 准备一个临时文件，让 handler 返回该文件内容（稳定输出）
    let filePath: Path = Path("./http_funchandler_resp.txt")
    if (exists(filePath)) {
        remove(filePath)
    }
    let f = File(filePath, Write)
    f.write("hello".toArray())
    f.close()

    // 使用 FuncHandler 注册一个处理函数
    let handler = FuncHandler({
        ctx =>
        // 当前函数：handle(ctx) 会触发这里的逻辑
        ctx.responseBuilder.status(200).header("content-type", "text/plain").body(File(filePath, Read))
    })

    let sc = SyncCounter(1)
    let server = ServerBuilder().addr("127.0.0.1").port(18091).afterBind({=> sc.dec()}).build()
    server.distributor.register("/hi", handler)
    server.logger.level = LogLevel.ERROR

    spawn {server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().build()
    let resp = client.get("http://127.0.0.1:18091/hi")

    var buf = Array<UInt8>(1024, repeat: 0)
    var body = ""
    while (true) {
        let n = resp.body.read(buf)
        if (n <= 0) {
            break
        }
        body = body + String.fromUtf8(buf[..n])
    }
    resp.close()

    println("status = ${resp.status}")
    println("body = ${body}")

    client.close()
    server.closeGracefully()
    remove(filePath)
}
```

运行结果：

```text
status = 200
body = hello
```

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

### prop request

```cangjie
public prop request: HttpRequest
```

功能：获取 Http 请求。

类型：[HttpRequest](http_package_classes.md#class-httprequest)

### prop responseBuilder

```cangjie
public prop responseBuilder: HttpResponseBuilder
```

功能：获取 Http 响应构建器。

类型：[HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder)

### func isClosed()

```cangjie
public func isClosed(): Bool
```

功能：使用 HTTP/1.1 协议时，判断 socket 是否已关闭；使用 HTTP/2 协议时，判断 HTTP/2 流是否已关闭。

返回值：

- Bool - 如果 HTTP/1.1 的 socket 或 HTTP/2 的流已关闭，返回 true，否则返回 false。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.sync.*

main() {
    let sc = SyncCounter(1)
    let server = ServerBuilder().addr("127.0.0.1").port(18095).afterBind({=> sc.dec()}).build()
    server.logger.level = LogLevel.ERROR

    server.distributor.register(
        "/t",
        FuncHandler(
            {
                ctx =>
                    // 当前函数：isClosed()
                    println("isClosed = ${ctx.isClosed()}")
                    ctx.responseBuilder.status(200).body("ok")
            }
        )
    )

    spawn {server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().build()
    let resp = client.get("http://127.0.0.1:18095/t")
    resp.close()
    client.close()
    server.closeGracefully()
}
```

运行结果：

```text
isClosed = false
```

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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let headers = HttpHeaders()
    // 当前函数：add(name, value)
    headers.add("x-a", "1")
    headers.add("x-a", "2")

    println("x-a.first = ${headers.getFirst("X-A") ?? ""}")
    println("x-a.size = ${headers.get("x-a").size}")
}
```

运行结果：

```text
x-a.first = 1
x-a.size = 2
```

### func del(String)

```cangjie
public func del(name: String): Unit
```

功能：删除指定 name 对应的键值对。

参数：

- name: String - 删除的字段名称。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let headers = HttpHeaders()
    headers.add("x-a", "1")

    // 当前函数：del(name)
    headers.del("x-a")
    println("isEmpty = ${headers.isEmpty()}")
}
```

运行结果：

```text
isEmpty = true
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let headers = HttpHeaders()
    headers.add("x-a", "1")
    headers.add("x-a", "2")

    // 当前函数：get(name)
    let values = headers.get("x-a")
    println("x-a.size = ${values.size}")
}
```

运行结果：

```text
x-a.size = 2
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let headers = HttpHeaders()
    headers.add("x-a", "1")
    headers.add("x-a", "2")

    // 当前函数：getFirst(name)
    println("x-a.first = ${headers.getFirst("x-a") ?? ""}")
}
```

运行结果：

```text
x-a.first = 1
```

### func isEmpty()

```cangjie
public func isEmpty(): Bool
```

功能：判断当前实例是否为空，即没有任何键值对。

返回值：

- Bool - 如果当前实例为空，返回 true，否则返回 false。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let headers = HttpHeaders()
    println("empty0 = ${headers.isEmpty()}")

    headers.add("x-a", "1")
    // 当前函数：isEmpty()
    println("empty1 = ${headers.isEmpty()}")
}
```

运行结果：

```text
empty0 = true
empty1 = false
```

### func iterator()

```cangjie
public func iterator(): Iterator<(String, Collection<String>)>
```

功能：获取迭代器，可用于遍历所有键值对。

返回值：

- Iterator\<(String, Collection\<String>)> - 该键值集的迭代器。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let headers = HttpHeaders()
    headers.add("x-a", "1")
    headers.add("x-b", "2")

    // 当前函数：iterator()（遍历 header 键值）
    let it = headers.iterator()
    while (true) {
        match (it.next()) {
            case Some((k, v)) =>
                // k 已被规范化为小写
                println("${k} = ${v.size}")
            case None => break
        }
    }
}
```

运行结果：

```text
x-a = 1
x-b = 1
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let headers = HttpHeaders()
    headers.add("x-a", "1")
    // 当前函数：set(name, value) 会覆盖同名 header
    headers.set("x-a", "100")

    println("x-a.first = ${headers.getFirst("x-a") ?? ""}")
    println("x-a.size = ${headers.get("x-a").size}")
}
```

运行结果：

```text
x-a.first = 100
x-a.size = 1
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

### prop bodySize

```cangjie
public prop bodySize: Option<Int64>
```

功能：获取请求 body 长度。

- 如果未设置 body，则 bodySize 为 Some(0)；
- 如果 body 长度已知，即通过 Array\<UInt8> 或 String 传入 body，或传入的 InputStream 有确定的 length (length >= 0)，则 bodySize 为 Some(Int64)；
- 如果 body 长度未知，即通过用户自定义的 InputStream 实例传入 body 且 InputStream 实例没有确定的 length (length < 0)，则 bodySize 为 None。

类型：Option\<Int64>

### prop form

```cangjie
public prop form: Form
```

功能：获取请求中的表单信息。

- 如果请求方法为 POST，PUT，PATCH，且 content-type 包含 application/x-www-form-urlencoded，获取请求 body 部分，用 form 格式解析；
- 如果请求方法不为 POST，PUT，PATCH，获取请求 url 中 query 部分。

> **注意：**
>
> - 如果用该接口读取了 body，body 已被消费完，后续将无法通过 body.read 读取 body；
> - 如果 form 不符合 [Form](../../../encoding/url/url_package_api/url_package_classes.md#class-form) 格式，抛 [UrlSyntaxException](../../../encoding/url/url_package_api/url_package_exceptions.md#class-urlsyntaxexception) 异常。

类型：[Form](../../../encoding/url/url_package_api/url_package_classes.md#class-form)

### prop headers

```cangjie
public prop headers: HttpHeaders
```

功能：获取 headers，headers 详述见 [HttpHeaders](http_package_classes.md#class-httpheaders) 类，获取后，可通过调用 [HttpHeaders](http_package_classes.md#class-httpheaders) 实例成员函数，修改该请求的 headers。

类型：[HttpHeaders](http_package_classes.md#class-httpheaders)

### prop isPersistent

```cangjie
public prop isPersistent: Bool
```

功能：表示该请求是否为长连接，即请求 header 是否不包含 `Connection: close`。包含 `Connection: close` 为 false，否则为 true。

- 对于服务端，isPersistent 为 false 表示处理完该请求应该关闭连接。
- 对于客户端，isPersistent 为 false 表示如果收到响应后服务端未关闭连接，客户端应主动关闭连接。

类型：Bool

### prop method

```cangjie
public prop method: String
```

功能：获取 method，如 "GET", "POST"，request 实例的 method 无法修改。

类型：String

### prop readTimeout

```cangjie
public prop readTimeout: ?Duration
```

功能：表示该请求的请求级读超时时间。None 表示没有设置；Some(Duration) 表示设置了读超时时间。

类型：?Duration

### prop remoteAddr

```cangjie
public prop remoteAddr: String
```

功能：用于服务端，获取对端地址，即客户端地址，格式为 ip: port，用户无法设置，自定义的 request 对象调用该属性返回 ""，服务端 handler 中调用该属性返回客户端地址。

类型：String

### prop trailers

```cangjie
public prop trailers: HttpHeaders
```

功能：获取 trailers，trailers 详述见 [HttpHeaders](http_package_classes.md#class-httpheaders) 类，获取后，可通过调用 [HttpHeaders](http_package_classes.md#class-httpheaders) 实例成员函数，修改该请求的 trailers。

类型：[HttpHeaders](http_package_classes.md#class-httpheaders)

### prop url

```cangjie
public prop url: URL
```

功能：获取 url，表示客户端访问的 url。

类型：[URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url)

### prop version

```cangjie
public prop version: Protocol
```

功能：获取 http 版本，如 HTTP1_1 和 HTTP2_0，request 实例的 version 无法修改。

类型：[Protocol](http_package_enums.md#enum-protocol)

### prop writeTimeout

```cangjie
public prop writeTimeout: ?Duration
```

功能：表示该请求的请求级写超时时间，None 表示没有设置；Some(Duration) 表示设置了写超时时间。

类型：?Duration

### func toString()

```cangjie
public override func toString(): String
```

功能：把请求转换为字符串，包括 start line，headers，body size，trailers。
例如：`"GET /path HTTP/1.1\r\nhost: www.example.com\r\n\r\nbody size: 5\r\nbar: foo\r\n"`。

返回值：

- String - 请求的字符串表示。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder()
        .method("GET")
        .url("http://example.com/hello")
        .header("x-test", "1")
        .body("abc")
        .build()

    // 当前函数：toString()
    println(req.toString())
}
```

运行结果：

```text
GET /hello HTTP/1.1
x-test: 1

body size: 3
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

main() {
    let _ = HttpRequestBuilder()
}
```

### init(HttpRequest)

```cangjie
public init(request: HttpRequest)
```

功能： 通过 request 构造一个具有 request 属性的 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder)。由于 body 成员是一个 InputStream，对原始的 request 的 body 的操作会影响到复制得到的 [HttpRequest](http_package_classes.md#class-httprequest) 的 body。[HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 的 headers 和 trailers 是入参 request 的深拷贝。其余元素都是入参 request 的浅拷贝（因为是不可变对象，无需深拷贝）。

参数：

- request: [HttpRequest](http_package_classes.md#class-httprequest) - 传入的 [HttpRequest](http_package_classes.md#class-httprequest) 对象。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let extra = HttpHeaders()
    extra.add("x-a", "1")
    extra.add("x-b", "2")

    let req = HttpRequestBuilder().url("http://example.com/hello").addHeaders(extra).build()
    let a = req.headers.getFirst("x-a") ?? ""
    let b = req.headers.getFirst("x-b") ?? ""
    println("x-a = ${a}")
    println("x-b = ${b}")
}
```

运行结果：

```text
x-a = 1
x-b = 2
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let extra = HttpHeaders()
    extra.add("x-t", "1")

    let req = HttpRequestBuilder().url("http://example.com/hello").addTrailers(extra).build()
    let t = req.trailers.getFirst("x-t") ?? ""
    println("x-t = ${t}")
}
```

运行结果：

```text
x-t = 1
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().url("http://example.com/hello").body("abc".toArray()).build()
    let buf = Array<UInt8>(16, repeat: 0)
    let n = req.body.read(buf)
    let s = if (n > 0) {
        String.fromUtf8(buf[..n])
    } else {
        ""
    }
    println("body = ${s}")
    println("bodySize = ${req.bodySize.getOrThrow()}")
}
```

运行结果：

```text
body = abc
bodySize = 3
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

<!-- run -->
```cangjie
import stdx.net.http.*
import std.io.*

class MyBody <: InputStream {
    let data: Array<UInt8>
    var pos: Int64 = 0

    init(s: String) {
        data = s.toArray()
    }

    public func read(buf: Array<Byte>): Int64 {
        if (pos >= data.size) {
            return 0
        }
        let n = min(buf.size, data.size - pos)
        data.copyTo(buf, pos, 0, n)
        pos += n
        return n
    }
}

main() {
    let input: InputStream = MyBody("abc")
    let req = HttpRequestBuilder().url("http://example.com/hello").body(input).build()

    // 自定义 InputStream 不一定实现 Seekable，因此 bodySize 可能为 None
    println("bodySize.isSome = ${req.bodySize.isSome()}")
    let buf = Array<UInt8>(16, repeat: 0)
    let n = req.body.read(buf)
    let s = if (n > 0) {
        String.fromUtf8(buf[..n])
    } else {
        ""
    }
    println("body = ${s}")
}
```

运行结果：

```text
bodySize.isSome = false
body = abc
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().url("http://example.com/hello").body("abc").build()
    let buf = Array<UInt8>(16, repeat: 0)
    let n = req.body.read(buf)
    let s = if (n > 0) {
        String.fromUtf8(buf[..n])
    } else {
        ""
    }
    println("body = ${s}")
}
```

运行结果：

```text
body = abc
```

### func build()

```cangjie
public func build(): HttpRequest
```

功能：根据 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例生成一个 [HttpRequest](http_package_classes.md#class-httprequest) 实例。

返回值：

- [HttpRequest](http_package_classes.md#class-httprequest) - 根据当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例构造出来的 [HttpRequest](http_package_classes.md#class-httprequest) 实例。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().method("GET").url("http://example.com/hello").build()
    println("method = ${req.method}")
    println("path = ${req.url.path}")
}
```

运行结果：

```text
method = GET
path = /hello
```

### func connect()

```cangjie
public func connect(): HttpRequestBuilder
```

功能：构造 method 为 "CONNECT" 的请求的便捷函数。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().connect().url("http://example.com/hello").build()
    println(req.toString())
}
```

运行结果：

```text
CONNECT example.com HTTP/1.1
```

### func delete()

```cangjie
public func delete(): HttpRequestBuilder
```

功能：构造 method 为 "DELETE" 的请求的便捷函数。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().delete().url("http://example.com/hello").build()
    println(req.toString())
}
```

运行结果：

```text
DELETE /hello HTTP/1.1
```

### func get()

```cangjie
public func get(): HttpRequestBuilder
```

功能：构造 method 为 "GET" 的请求的便捷函数。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().get().url("http://example.com/hello").build()
    println(req.toString())
}
```

运行结果：

```text
GET /hello HTTP/1.1
```

### func head()

```cangjie
public func head(): HttpRequestBuilder
```

功能：构造 method 为 "HEAD" 的请求的便捷函数。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().head().url("http://example.com/hello").build()
    println(req.toString())
}
```

运行结果：

```text
HEAD /hello HTTP/1.1
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().url("http://example.com/hello").header("x-a", "1").build()
    let v = req.headers.getFirst("x-a") ?? ""
    println("x-a = ${v}")
}
```

运行结果：

```text
x-a = 1
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().method("PATCH").url("http://example.com/hello").build()
    println(req.toString())
}
```

运行结果：

```text
PATCH /hello HTTP/1.1
```

### func options()

```cangjie
public func options(): HttpRequestBuilder
```

功能：构造 method 为 "OPTIONS" 的请求的便捷函数。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().options().url("http://example.com/hello").build()
    println(req.toString())
}
```

运行结果：

```text
OPTIONS /hello HTTP/1.1
```

### func post()

```cangjie
public func post(): HttpRequestBuilder
```

功能：构造 method 为 "POST" 的请求的便捷函数。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().post().url("http://example.com/hello").body("x").build()
    println(req.toString())
}
```

运行结果：

```text
POST /hello HTTP/1.1

body size: 1
```

### func priority(Int64, Bool)

```cangjie
public func priority(urg: Int64, inc: Bool): HttpRequestBuilder
```

功能：设置 priority 头的便捷函数，调用此函数后，将生成 priority 头，形如："priority: urgency=x, i"。如果通过设置请求头的函数设置了 priority 字段，调用此函数无效。如果多次调用此函数，以最后一次为准。

参数：

- urg: Int64 - 表示请求优先级，取值范围为 [0, 7]，0 表示最高优先级。
- inc: Bool - 表示请求是否需要增量处理，为 true 表示希望服务器并发处理与之同 urg 同 inc 的请求，为 false 表示不希望服务器并发处理。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

异常：

- [HttpException](./http_package_exceptions.md#class-httpexception) - 当参数 urg 取值非法，即不在 [0, 7] 范围内时，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().url("http://example.com/hello").priority(3, true).build()
    let p = req.headers.getFirst("priority") ?? ""
    println("priority = ${p}")
}
```

运行结果：

```text
priority = u=3, i
```

### func put()

```cangjie
public func put(): HttpRequestBuilder
```

功能：构造 method 为 "PUT" 的请求的便捷函数。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().put().url("http://example.com/hello").body("x").build()
    println(req.toString())
}
```

运行结果：

```text
PUT /hello HTTP/1.1

body size: 1
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().url("http://example.com/hello").readTimeout(Duration.second).build()
    println("readTimeout.isSome = ${req.readTimeout.isSome()}")
}
```

运行结果：

```text
readTimeout.isSome = true
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let h = HttpHeaders()
    h.add("x-a", "1")
    let req = HttpRequestBuilder().url("http://example.com/hello").setHeaders(h).build()
    let v = req.headers.getFirst("x-a") ?? ""
    println("x-a = ${v}")
}
```

运行结果：

```text
x-a = 1
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let t = HttpHeaders()
    t.add("x-t", "1")
    let req = HttpRequestBuilder().url("http://example.com/hello").setTrailers(t).build()
    let v = req.trailers.getFirst("x-t") ?? ""
    println("x-t = ${v}")
}
```

运行结果：

```text
x-t = 1
```

### func trace()

```cangjie
public func trace(): HttpRequestBuilder
```

功能：构造 method 为 "TRACE" 的请求的便捷函数。

返回值：

- [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) - 当前 [HttpRequestBuilder](http_package_classes.md#class-httprequestbuilder) 实例的引用。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().trace().url("http://example.com/hello").build()
    println(req.toString())
}
```

运行结果：

```text
TRACE /hello HTTP/1.1
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().url("http://example.com/hello").trailer("x-t", "1").build()
    let v = req.trailers.getFirst("x-t") ?? ""
    println("x-t = ${v}")
}
```

运行结果：

```text
x-t = 1
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().url("http://example.com/hello").build()
    println("path = ${req.url.path}")
}
```

运行结果：

```text
path = /hello
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.encoding.url.*

main() {
    let u = URL.parse("http://example.com/hello")
    let req = HttpRequestBuilder().url(u).build()
    println("path = ${req.url.path}")
}
```

运行结果：

```text
path = /hello
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().url("http://example.com/hello").version(HTTP1_1).build()
    println("version = ${req.version.toString()}")
}
```

运行结果：

```text
version = HTTP/1.1
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().url("http://example.com/hello").writeTimeout(Duration.second).build()
    println("writeTimeout.isSome = ${req.writeTimeout.isSome()}")
}
```

运行结果：

```text
writeTimeout.isSome = true
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

### prop bodySize

```cangjie
public prop bodySize: Option<Int64>
```

功能：获取响应 body 长度。

> - 如果未设置 body，则 bodySize 为 Some(0)；
> - 如果 body 长度已知，即通过 Array\<UInt8> 或 String 传入 body，或传入的 InputStream 有确定的 length (length >= 0)，则 bodySize 为 Some(Int64)；
> - 如果 body 长度未知，即通过用户自定义的 InputStream 实例传入 body 且 InputStream 实例没有确定的 length (length < 0)，则 bodySize 为 None。

类型：Option\<Int64>

### prop headers

```cangjie
public prop headers: HttpHeaders
```

功能：获取 headers，headers 详述见 [HttpHeaders](http_package_classes.md#class-httpheaders) 类，获取后，可通过调用 [HttpHeaders](http_package_classes.md#class-httpheaders) 实例成员函数，修改该请求的 headers。

类型：[HttpHeaders](http_package_classes.md#class-httpheaders)

### prop isPersistent

```cangjie
public prop isPersistent: Bool
```

功能：表示该响应是否为长连接，即响应 header 是否不包含 `Connection: close`。包含 `Connection: close` 为 false，否则为 true。

对于服务端，isPersistent 为 false 表示处理完该请求应关闭连接；

对于客户端，isPersistent 为 false 表示读完响应体后客户端应主动关闭连接。

类型：Bool

### prop request

```cangjie
public prop request: Option<HttpRequest>
```

功能：获取该响应对应的请求，默认为 None。

类型：Option\<[HttpRequest](http_package_classes.md#class-httprequest)>

### prop status

```cangjie
public prop status: UInt16
```

功能：获取响应的状态码，默认值为 200。状态码由 100~599 的三位数字组成，状态码所反映的具体信息可参考 [RFC 9110](https://httpwg.org/specs/rfc9110.html#status.codes)。

类型：UInt16

### prop trailers

```cangjie
public prop trailers: HttpHeaders
```

功能：获取 trailers，trailers 详述见 [HttpHeaders](http_package_classes.md#class-httpheaders) 类，获取后，可通过调用 [HttpHeaders](http_package_classes.md#class-httpheaders) 实例成员函数，修改该请求的 trailers。

类型：[HttpHeaders](http_package_classes.md#class-httpheaders)

### prop version

```cangjie
public prop version: Protocol
```

功能：获取响应的协议版本，默认值为 [HTTP1_1](./http_package_enums.md#enum-protocol)。

类型：[Protocol](http_package_enums.md#enum-protocol)

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

main() {
    let resp = HttpResponseBuilder().body("abc").build()
    // 当前函数：close()
    resp.close()
    println("closed")
}
```

运行结果：

```text
closed
```

### func toString()

```cangjie
public override func toString(): String
```

功能：把响应转换为字符串，包括 status-line，headers，body size， trailers。

例如：HTTP/1.1 200 OK\r\ncontent-length: 5\r\n\r\nbody size: 5\r\nbar: foo\r\n。

返回值：

- String - 响应的字符串表示。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let resp = HttpResponseBuilder().body("abc").build()
    println(resp)
}
```

运行结果：

```text
HTTP/1.1 200 OK

body size: 3

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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let resp = HttpResponseBuilder().status(404).build()
    // 当前函数：toString()
    println(resp.toString().split("\n")[0])
}
```

运行结果：

```text
HTTP/1.1 404 Not Found
```

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

main() {
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let h = HttpHeaders()
    h.add("x-a", "1")
    let resp = HttpResponseBuilder().addHeaders(h).build()
    let v = resp.headers.getFirst("x-a") ?? ""
    println("x-a = ${v}")
}
```

运行结果：

```text
x-a = 1
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let t = HttpHeaders()
    t.add("x-t", "1")
    let resp = HttpResponseBuilder().addTrailers(t).build()
    let v = resp.trailers.getFirst("x-t") ?? ""
    println("x-t = ${v}")
}
```

运行结果：

```text
x-t = 1
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let resp = HttpResponseBuilder().body("abc".toArray()).build()
    let buf = Array<UInt8>(16, repeat: 0)
    let n = resp.body.read(buf)
    let s = if (n > 0) {
        String.fromUtf8(buf[..n])
    } else {
        ""
    }
    println("body = ${s}")
    println("bodySize = ${resp.bodySize.getOrThrow()}")
}
```

运行结果：

```text
body = abc
bodySize = 3
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

<!-- run -->
```cangjie
import stdx.net.http.*
import std.io.*

class MyBody <: InputStream {
    let data: Array<UInt8>
    var pos: Int64 = 0

    init(s: String) {
        data = s.toArray()
    }

    public func read(buf: Array<Byte>): Int64 {
        if (pos >= data.size) {
            return 0
        }
        let n = min(buf.size, data.size - pos)
        data.copyTo(buf, pos, 0, n)
        pos += n
        return n
    }
}

main() {
    let input: InputStream = MyBody("abc")
    let resp = HttpResponseBuilder().body(input).build()
    println("bodySize.isSome = ${resp.bodySize.isSome()}")
    let buf = Array<UInt8>(16, repeat: 0)
    let n = resp.body.read(buf)
    let s = if (n > 0) {
        String.fromUtf8(buf[..n])
    } else {
        ""
    }
    println("body = ${s}")
}
```

运行结果：

```text
bodySize.isSome = false
body = abc
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let resp = HttpResponseBuilder().body("abc").build()
    let buf = Array<UInt8>(16, repeat: 0)
    let n = resp.body.read(buf)
    let s = if (n > 0) {
        String.fromUtf8(buf[..n])
    } else {
        ""
    }
    println("body = ${s}")
}
```

运行结果：

```text
body = abc
```

### func build()

```cangjie
public func build(): HttpResponse
```

功能：根据 [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) 实例生成一个 [HttpResponse](http_package_classes.md#class-httpresponse) 实例。

返回值：

- [HttpResponse](http_package_classes.md#class-httpresponse) - 根据当前 [HttpResponseBuilder](http_package_classes.md#class-httpresponsebuilder) 实例构造出来的 [HttpResponse](http_package_classes.md#class-httpresponse) 实例。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let resp = HttpResponseBuilder().status(200).body("ok").build()
    println("status = ${resp.status}")
    let buf = Array<UInt8>(8, repeat: 0)
    let n = resp.body.read(buf)
    println("body = ${String.fromUtf8(buf[..n])}")
}
```

运行结果：

```text
status = 200
body = ok
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let resp = HttpResponseBuilder().header("x-a", "1").build()
    let v = resp.headers.getFirst("x-a") ?? ""
    println("x-a = ${v}")
}
```

运行结果：

```text
x-a = 1
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let req = HttpRequestBuilder().url("http://example.com/hello").build()
    let resp = HttpResponseBuilder().request(req).build()
    println("request.isSome = ${resp.request.isSome()}")
}
```

运行结果：

```text
request.isSome = true
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let h = HttpHeaders()
    h.add("x-a", "1")
    let resp = HttpResponseBuilder().setHeaders(h).build()
    let v = resp.headers.getFirst("x-a") ?? ""
    println("x-a = ${v}")
}
```

运行结果：

```text
x-a = 1
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let t = HttpHeaders()
    t.add("x-t", "1")
    let resp = HttpResponseBuilder().setTrailers(t).build()
    let v = resp.trailers.getFirst("x-t") ?? ""
    println("x-t = ${v}")
}
```

运行结果：

```text
x-t = 1
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let resp = HttpResponseBuilder().status(201).build()
    println("status = ${resp.status}")
}
```

运行结果：

```text
status = 201
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let resp = HttpResponseBuilder().trailer("x-t", "1").build()
    let v = resp.trailers.getFirst("x-t") ?? ""
    println("x-t = ${v}")
}
```

运行结果：

```text
x-t = 1
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

<!-- run -->
```cangjie
import stdx.net.http.*

main() {
    let resp = HttpResponseBuilder().version(HTTP1_1).build()
    println("version = ${resp.version.toString()}")
}
```

运行结果：

```text
version = HTTP/1.1
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.sync.*

main() {
    let sc = SyncCounter(1)
    let logger = NoopLogger()

    let server = ServerBuilder().addr("127.0.0.1").port(18100).logger(logger).afterBind({=> sc.dec()}).build()

    server.distributor.register(
        "/p",
        FuncHandler(
            {
                ctx =>
                    // 当前函数：getPusher(ctx)
                    let p = HttpResponsePusher.getPusher(ctx)
                    println("pusher.isSome = ${p.isSome()}")
                    ctx.responseBuilder.status(200).body("ok")
            }
        )
    )

    spawn {server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().build()
    let resp = client.get("http://127.0.0.1:18100/p")
    resp.close()
    client.close()
    server.closeGracefully()
}
```

运行结果：

```text
pusher.isSome = false
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.sync.*

main() {
    let sc = SyncCounter(1)
    let logger = NoopLogger()

    let server = ServerBuilder().addr("127.0.0.1").port(18101).logger(logger).afterBind({=> sc.dec()}).build()

    server.distributor.register(
        "/p",
        FuncHandler(
            {
                ctx =>
                    // 当前函数：push(path, method, header)
                    let p = HttpResponsePusher.getPusher(ctx)
                    match (p) {
                        case Some(v) =>
                            v.push("/asset", "GET", HttpHeaders())
                            println("push called")
                        case None =>
                            // HTTP/1.1 下无法获取 pusher，这里演示如何安全跳过 push
                            println("push skipped (no pusher)")
                    }
                    ctx.responseBuilder.status(200).body("ok")
            }
        )
    )

    server.distributor.register("/asset", FuncHandler({
        ctx => ctx.responseBuilder.status(200).body("asset")
    }))

    spawn {server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().build()
    let resp = client.get("http://127.0.0.1:18101/p")
    resp.close()
    client.close()
    server.closeGracefully()
}
```

运行结果：

```text
push skipped (no pusher)
```

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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.sync.*

main() {
    let sc = SyncCounter(1)
    let logger = NoopLogger()

    let server = ServerBuilder().addr("127.0.0.1").port(18102).logger(logger).afterBind({=> sc.dec()}).build()

    server.distributor.register(
        "/w",
        FuncHandler(
            {
                ctx =>
                    ctx.responseBuilder.status(200).header("transfer-encoding", "chunked")

                    // 构造 writer 后，通过 write 控制 body 的发送过程
                    let w = HttpResponseWriter(ctx)
                    w.write("hi".toArray())
                    w.write("!".toArray())
            }
        )
    )

    spawn {server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().build()
    let resp = client.get("http://127.0.0.1:18102/w")

    var buf = Array<UInt8>(64, repeat: 0)
    var body = ""
    while (true) {
        let n = resp.body.read(buf)
        if (n <= 0) {
            break
        }
        body = body + String.fromUtf8(buf[..n])
    }
    resp.close()

    println("status = ${resp.status}")
    println("body = ${body}")

    client.close()
    server.closeGracefully()
}
```

运行结果：

```text
status = 200
body = hi!
```

### func write(Array\<Byte>)

```cangjie
public func write(buf: Array<Byte>): Unit
```

功能：发送 buf 中数据到客户端。

参数：

- buf: Array\<Byte> - 要发送的数据。

异常：

- [HttpException](http_package_exceptions.md#class-httpexception) - 请求方法为 "HEAD" 或响应状态码为 "1XX\204\304"。
- [HttpException](http_package_exceptions.md#class-httpexception) - 连接关闭。
- [HttpException](http_package_exceptions.md#class-httpexception) - response 协议版本为 HTTP/1.0。
- [HttpException](http_package_exceptions.md#class-httpexception) - 响应连接已升级为 [WebSocket](http_package_classes.md#class-websocket)。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.sync.*

main() {
    let sc = SyncCounter(1)
    let logger = NoopLogger()

    let server = ServerBuilder().addr("127.0.0.1").port(18102).logger(logger).afterBind({=> sc.dec()}).build()

    server.distributor.register(
        "/w",
        FuncHandler(
            {
                ctx =>
                    ctx.responseBuilder.status(200).header("transfer-encoding", "chunked")

                    // 当前函数：write(buf)
                    let w = HttpResponseWriter(ctx)
                    w.write("hi".toArray())
                    w.write("!".toArray())
            }
        )
    )

    spawn {server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().build()
    let resp = client.get("http://127.0.0.1:18102/w")

    var buf = Array<UInt8>(64, repeat: 0)
    var body = ""
    while (true) {
        let n = resp.body.read(buf)
        if (n <= 0) {
            break
        }
        body = body + String.fromUtf8(buf[..n])
    }
    resp.close()

    println("status = ${resp.status}")
    println("body = ${body}")

    client.close()
    server.closeGracefully()
}
```

运行结果：

```text
status = 200
body = hi!
```

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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.sync.*

main() {
    let sc = SyncCounter(1)
    let logger = NoopLogger()

    let server = ServerBuilder().addr("127.0.0.1").port(18103).logger(logger).afterBind({=> sc.dec()}).build()

    // 当前函数：NotFoundHandler.handle(ctx)
    server.distributor.register("/nf", NotFoundHandler())

    spawn {server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().build()
    let resp = client.get("http://127.0.0.1:18103/nf")

    var buf = Array<UInt8>(64, repeat: 0)
    let n = resp.body.read(buf)
    let body = if (n > 0) {
        String.fromUtf8(buf[..n])
    } else {
        ""
    }
    resp.close()

    println("status = ${resp.status}")
    println("body = ${body}")

    client.close()
    server.closeGracefully()
}
```

运行结果：

```text
status = 404
body = 404 Not Found
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.sync.*

main() {
    let sc = SyncCounter(1)
    let logger = NoopLogger()

    let server = ServerBuilder().addr("127.0.0.1").port(18104).logger(logger).afterBind({=> sc.dec()}).build()

    // 当前函数：OptionsHandler.handle(ctx)
    server.distributor.register("/opt", OptionsHandler())

    spawn {server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().build()
    let req = HttpRequestBuilder().url("http://127.0.0.1:18104/opt").method("OPTIONS").build()
    let resp = client.send(req)

    println("status = ${resp.status}")
    println("allow = ${resp.headers.getFirst("allow") ?? ""}")

    resp.close()
    client.close()
    server.closeGracefully()
}
```

运行结果：

```text
status = 200
allow = OPTIONS, GET, HEAD, POST, PUT, DELETE
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

### prop httpKeepAliveTimeout

```cangjie
protected prop httpKeepAliveTimeout: Duration
```

功能：HTTP/1.1 专用，获取服务器设定的保持长连接的超时时间。

类型：Duration

### prop logger

```cangjie
protected prop logger: Logger
```

功能：获取服务器日志记录器，设置 logger.level 将立即生效，记录器应该是线程安全的。

类型：[Logger](../../../log/log_package_api/log_package_classes.md#class-logger)

### prop maxRequestBodySize

```cangjie
protected prop maxRequestBodySize: Int64
```

功能：获取服务器设定的读取请求的请求体最大值，仅对于 HTTP/1.1 且未设置 "Transfer-Encoding: chunked" 的请求生效。

类型：Int64

### prop maxRequestHeaderSize

```cangjie
protected prop maxRequestHeaderSize: Int64
```

功能：获取服务器设定的读取请求的请求头最大值。仅对 HTTP/1.1 生效，HTTP/2 中有专门的配置 maxHeaderListSize。

类型：Int64

### prop readHeaderTimeout

```cangjie
protected prop readHeaderTimeout: Duration
```

功能：获取服务器设定的读取请求头的超时时间。

类型：Duration

### prop readTimeout

```cangjie
protected prop readTimeout: Duration
```

功能：获取服务器设定的读取整个请求的超时时间。建议在生产环境中显式配置该项。如果保持默认不超时，服务端连接和资源可能被慢速请求长期占用，增加遭受慢请求类攻击的风险。

类型：Duration

### prop server

```cangjie
protected open mut prop server: Server
```

功能：返回 [Server](#class-server) 实例，提供默认实现，设置为绑定的 [Server](#class-server) 实例。

类型：Server

### prop writeTimeout

```cangjie
protected prop writeTimeout: Duration
```

功能：获取服务器设定的写响应的超时时间。建议在生产环境中显式配置该项。如果保持默认不超时，服务端连接和资源可能被慢速读写长期占用，增加遭受慢连接类攻击的风险。

类型：Duration

### func close()

```cangjie
protected open func close(): Unit
```

功能：强制关闭连接，提供默认实现，无任何行为。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.net.*
import std.sync.*

class MyFactory <: ProtocolServiceFactory {
    public func create(p: Protocol, s: StreamingSocket): ProtocolService {
        // 固定响应（避免依赖内部协议解析）
        let _ = p
        s.write("HTTP/1.1 200 OK\r\ncontent-length: 2\r\nconnection: close\r\n\r\nOK".toArray())
        return MyService()
    }
}

class MyService <: ProtocolService {
    let running = AtomicBool(true)

    protected func serve(): Unit {
        while (running.load()) {
            sleep(Duration.millisecond * 10)
        }
    }

    protected override func close(): Unit {
        running.store(false)
        println("close called")
    }

    protected override func closeGracefully(): Unit {
        running.store(false)
        println("closeGracefully called")
    }
}

main() {
    let sc = SyncCounter(1)

    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18119)
        .logger(NoopLogger())
        .enableConnectProtocol(true)
        .maxRequestHeaderSize(123)
        .maxRequestBodySize(456)
        .readTimeout(Duration.second)
        .writeTimeout(Duration.second)
        .readHeaderTimeout(Duration.second)
        .httpKeepAliveTimeout(Duration.second)
        .protocolServiceFactory(MyFactory())
        .afterBind({=> sc.dec()})
        .build()

    spawn {=> server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().build()
    let rsp = client.get("http://127.0.0.1:18119/")
    rsp.close()
    client.close()

    server.close()
}
```

运行结果：

```text
close called
```

### func closeGracefully()

```cangjie
protected open func closeGracefully(): Unit
```

功能：优雅关闭连接，提供默认实现，无任何行为。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.net.*
import std.sync.*

class MyFactory <: ProtocolServiceFactory {
    public func create(p: Protocol, s: StreamingSocket): ProtocolService {
        // 固定响应（避免依赖内部协议解析）
        let _ = p
        s.write("HTTP/1.1 200 OK\r\ncontent-length: 2\r\nconnection: close\r\n\r\nOK".toArray())
        return MyService()
    }
}

class MyService <: ProtocolService {
    let running = AtomicBool(true)

    protected func serve(): Unit {
        while (running.load()) {
            sleep(Duration.millisecond * 10)
        }
    }

    protected override func close(): Unit {
        running.store(false)
        println("close called")
    }

    protected override func closeGracefully(): Unit {
        running.store(false)
        println("closeGracefully called")
    }
}

main() {
    let sc = SyncCounter(1)

    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18120)
        .logger(NoopLogger())
        .enableConnectProtocol(true)
        .maxRequestHeaderSize(123)
        .maxRequestBodySize(456)
        .readTimeout(Duration.second)
        .writeTimeout(Duration.second)
        .readHeaderTimeout(Duration.second)
        .httpKeepAliveTimeout(Duration.second)
        .protocolServiceFactory(MyFactory())
        .afterBind({=> sc.dec()})
        .build()

    spawn {=> server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().build()
    let rsp = client.get("http://127.0.0.1:18120/")
    rsp.close()
    client.close()

    server.closeGracefully()
}
```

运行结果：

```text
closeGracefully called
```

### func serve()

```cangjie
protected func serve(): Unit
```

功能：处理来自客户端连接的请求，不提供默认实现。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.net.*
import std.sync.*

class MyFactory <: ProtocolServiceFactory {
    public func create(p: Protocol, s: StreamingSocket): ProtocolService {
        // 固定响应（避免依赖内部协议解析）
        let _ = p
        s.write("HTTP/1.1 200 OK\r\ncontent-length: 2\r\nconnection: close\r\n\r\nOK".toArray())
        return MyService()
    }
}

class MyService <: ProtocolService {
    let running = AtomicBool(true)

    protected func serve(): Unit {
        println("serve called")
        sleep(Duration.millisecond * 10)
    }
}

main() {
    let sc = SyncCounter(1)

    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18121)
        .logger(NoopLogger())
        .enableConnectProtocol(true)
        .maxRequestHeaderSize(123)
        .maxRequestBodySize(456)
        .readTimeout(Duration.second)
        .writeTimeout(Duration.second)
        .readHeaderTimeout(Duration.second)
        .httpKeepAliveTimeout(Duration.second)
        .protocolServiceFactory(MyFactory())
        .afterBind({=> sc.dec()})
        .build()

    spawn {=> server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().build()
    let rsp = client.get("http://127.0.0.1:18121/")
    rsp.close()
    client.close()

    server.closeGracefully()
}
```

运行结果：

```text
serve called
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.sync.*

main() {
    let _ = RedirectHandler("/to", 302)
}
```

### func handle(HttpContext)

```cangjie
public func handle(ctx: HttpContext): Unit
```

功能：处理 Http 请求，回复重定向响应。

参数：

- ctx: [HttpContext](http_package_classes.md#class-httpcontext) - Http 请求上下文。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.sync.*

main() {
    let sc = SyncCounter(1)
    let logger = NoopLogger()

    let server = ServerBuilder().addr("127.0.0.1").port(18105).logger(logger).afterBind({=> sc.dec()}).build()

    // 当前函数：RedirectHandler.handle(ctx)
    server.distributor.register("/from", RedirectHandler("/to", 302))

    spawn {server.serve()}
    sc.waitUntilZero()

    // 关闭自动重定向，以便直接读取 302 与 Location
    let client = ClientBuilder().autoRedirect(false).build()
    let resp = client.get("http://127.0.0.1:18105/from")

    var buf = Array<UInt8>(128, repeat: 0)
    let n = resp.body.read(buf)
    let body = if (n > 0) {
        String.fromUtf8(buf[..n])
    } else {
        ""
    }

    println("status = ${resp.status}")
    println("location = ${resp.headers.getFirst("location") ?? ""}")
    println("body = ${body}")

    resp.close()
    client.close()
    server.closeGracefully()
}
```

运行结果：

```text
status = 302
location = /to
body = <a href="/to">Found</a>
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

### prop distributor

```cangjie
public prop distributor: HttpRequestDistributor
```

功能：获取请求分发器，请求分发器会根据 url 将请求分发给对应的 handler。

类型：[HttpRequestDistributor](http_package_interfaces.md#interface-httprequestdistributor)

### prop enableConnectProtocol

```cangjie
public prop enableConnectProtocol: Bool
```

功能：HTTP/2 专用，用来限制对端发送的报文是否支持通过 connect 方法升级协议，true 表示支持。

类型：Bool

### prop headerTableSize

```cangjie
public prop headerTableSize: UInt32
```

功能：获取服务端 HTTP/2 Hpack 动态表的初始值，默认值为 4096。

类型：UInt32

### prop httpKeepAliveTimeout

```cangjie
public prop httpKeepAliveTimeout: Duration
```

功能：HTTP/1.1 专用，获取服务器设定的保持长连接的超时时间。

类型：Duration

### prop initialWindowSize

```cangjie
public prop initialWindowSize: UInt32
```

功能：HTTP/2 专用，用来限制对端发送的报文 stream 初始流量窗口大小。默认值为 65535 ，取值范围为 0 至 2^31 - 1。

类型：UInt32

### prop listener

```cangjie
public prop listener: ServerSocket
```

功能：获取服务器绑定 socket。

类型：ServerSocket

### prop logger

```cangjie
public prop logger: Logger
```

功能：获取服务器日志记录器，设置 logger.level 将立即生效，记录器应该是线程安全的。

类型：[Logger](../../../log/log_package_api/log_package_classes.md#class-logger)

### prop maxConcurrentStreams

```cangjie
public prop maxConcurrentStreams: UInt32
```

功能：HTTP/2 专用，用来限制连接同时处理的最大请求数量。

类型：UInt32

### prop maxFrameSize

```cangjie
public prop maxFrameSize: UInt32
```

功能：HTTP/2 专用，用来限制对端发送的报文一个帧的最大长度。默认值为 16384. 取值范围为 2^14 至 2^24 - 1。

类型：UInt32

### prop maxHeaderListSize

```cangjie
public prop maxHeaderListSize: UInt32
```

功能：获取客户端支持的 HTTP/2 最大头部（Header）大小。这个大小指的是响应头部中所有头部字段（Header Field）的最大允许长度之和，其中包括所有字段名称（name）的长度、字段值（value）的长度以及每个字段自动添加的伪头开销（通常每个字段会有 32 字节的开销，这包括了 HTTP/2 协议本身为头部字段添加的伪头部信息）。默认情况下，这个最大长度被设置为 UInt32.Max。

类型：UInt32

### prop maxRequestBodySize

```cangjie
public prop maxRequestBodySize: Int64
```

功能：获取服务器设定的读取请求的请求体最大值，仅对于 HTTP/1.1 且未设置 "Transfer-Encoding: chunked" 的请求生效。

类型：Int64

### prop maxRequestHeaderSize

```cangjie
public prop maxRequestHeaderSize: Int64
```

功能：获取服务器设定的读取请求的请求头最大值。仅对 HTTP/1.1 生效，HTTP/2 中有专门的配置 maxHeaderListSize。

类型：Int64

### prop port

```cangjie
public prop port: UInt16
```

功能：获取服务端监听端口。

类型：UInt16

### prop protocolServiceFactory

```cangjie
public prop protocolServiceFactory: ProtocolServiceFactory
```

功能：获取协议服务工厂，服务协议工厂会生成每个协议所需的服务实例。

类型：[ProtocolServiceFactory](http_package_interfaces.md#interface-protocolservicefactory)

### prop readHeaderTimeout

```cangjie
public prop readHeaderTimeout: Duration
```

功能：获取服务器设定的读取请求头的超时时间。

类型：Duration

### prop readTimeout

```cangjie
public prop readTimeout: Duration
```

功能：获取服务器设定的读取整个请求的超时时间。

类型：Duration

### prop servicePoolConfig

```cangjie
public prop servicePoolConfig: ServicePoolConfig
```

功能：获取协程池配置实例。

类型：[ServicePoolConfig](http_package_structs.md#struct-servicepoolconfig)

### prop transportConfig

```cangjie
public prop transportConfig: TransportConfig
```

功能：获取服务器设定的传输层配置。

类型：[TransportConfig](http_package_structs.md#struct-transportconfig)

### prop writeTimeout

```cangjie
public prop writeTimeout: Duration
```

功能：获取服务器设定的写响应的超时时间。

类型：Duration

### func afterBind(() -> Unit)

```cangjie
public func afterBind(f: ()-> Unit): Unit
```

功能：注册服务器启动时的回调函数，服务内部 ServerSocket 实例 bind 之后，accept 之前将调用该函数。重复调用将覆盖之前注册的函数。

参数：

- f: () -> Unit - 回调函数，入参为空，返回值为 Unit 类型。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.sync.*
import stdx.crypto.keys.RSAPrivateKey

// 用于稳定获取响应 body（避免依赖 readToEnd/readAll 等 API）
func readAllBytes(resp: HttpResponse): String {
    let buf = Array<UInt8>(1024, repeat: 0)
    var body = ""
    while (true) {
        let n = resp.body.read(buf)
        if (n <= 0) {
            break
        }
        body += String.fromUtf8(buf[..n])
    }
    return body
}

main() {
    let sc = SyncCounter(1)

    let server = ServerBuilder().addr("127.0.0.1").port(18126).logger(NoopLogger()).build()

    // func afterBind(): 注册 bind 后回调（此处用它做“就绪信号”）
    server.afterBind(
        {
            =>
                println("afterBind set by Server.afterBind")
                sc.dec()
        }
    )

    // 注册一个最简 handler，便于 serve() 可测
    server.distributor.register("/ping", {
        httpContext => httpContext.responseBuilder.body("pong")
    })

    spawn {server.serve()}
    sc.waitUntilZero()

    // func serve(): 发起一次请求，证明服务正常
    let client = ClientBuilder().noProxy().build()
    let resp = client.get("http://127.0.0.1:18126/ping")
    let body = readAllBytes(resp)
    println("status = ${resp.status}")
    println("body = ${body}")
    resp.close()

    // func getTlsConfig(): 未设置 TLS，返回 None
    println("tlsConfig.isSome = ${server.getTlsConfig().isSome()}")

    // func onShutdown(): close/closeGracefully 时回调
    server.onShutdown({=> println("onShutdown set by Server.onShutdown")})

    client.close()

    // func closeGracefully(): 触发回调并关闭
    server.closeGracefully()

    // func updateCA / updateCert(): 未配置 TLS，调用会抛 HttpException
    try {
        server.updateCA([])
    } catch (e: HttpException) {
        println("updateCA(Array) HttpException: ${e.message}")
    }
    try {
        server.updateCA("/tmp/not-exist.pem")
    } catch (e: HttpException) {
        println("updateCA(String) HttpException: ${e.message}")
    }
    // 不引入证书/私钥文件依赖：仅展示未配置 TLS 时的异常行为
    try {
        server.updateCert([], RSAPrivateKey(1024))
    } catch (e: HttpException) {
        println("updateCert(Array,Key) HttpException: ${e.message}")
    }
    try {
        server.updateCert("/tmp/a.pem", "/tmp/b.pem")
    } catch (e: HttpException) {
        println("updateCert(String,String) HttpException: ${e.message}")
    }
}
```

运行结果：

```text
afterBind set by Server.afterBind
status = 200
body = pong
tlsConfig.isSome = false
onShutdown set by Server.onShutdown
updateCA(Array) HttpException: The TLS certificate is not configured.
updateCA(String) HttpException: The TLS certificate is not configured.
updateCert(Array,Key) HttpException: The TLS certificate is not configured.
updateCert(String,String) HttpException: The TLS certificate is not configured.
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
import stdx.log.*

main() {
    let server = ServerBuilder().addr("127.0.0.1").port(18127).logger(NoopLogger()).build()

    // func close(): 关闭服务（可重复调用）
    server.close()
    println("closed once")

    server.close()
    println("closed twice")
}
```

运行结果：

```text
closed once
closed twice
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
import stdx.log.*
import std.sync.*
import stdx.crypto.keys.RSAPrivateKey

// 用于稳定获取响应 body（避免依赖 readToEnd/readAll 等 API）
func readAllBytes(resp: HttpResponse): String {
    let buf = Array<UInt8>(1024, repeat: 0)
    var body = ""
    while (true) {
        let n = resp.body.read(buf)
        if (n <= 0) {
            break
        }
        body += String.fromUtf8(buf[..n])
    }
    return body
}

main() {
    let sc = SyncCounter(1)

    let server = ServerBuilder().addr("127.0.0.1").port(18126).logger(NoopLogger()).build()

    // func afterBind(): 注册 bind 后回调（此处用它做“就绪信号”）
    server.afterBind(
        {
            =>
                println("afterBind set by Server.afterBind")
                sc.dec()
        }
    )

    // 注册一个最简 handler，便于 serve() 可测
    server.distributor.register("/ping", {
        httpContext => httpContext.responseBuilder.body("pong")
    })

    spawn {server.serve()}
    sc.waitUntilZero()

    // func serve(): 发起一次请求，证明服务正常
    let client = ClientBuilder().noProxy().build()
    let resp = client.get("http://127.0.0.1:18126/ping")
    let body = readAllBytes(resp)
    println("status = ${resp.status}")
    println("body = ${body}")
    resp.close()

    // func getTlsConfig(): 未设置 TLS，返回 None
    println("tlsConfig.isSome = ${server.getTlsConfig().isSome()}")

    // func onShutdown(): close/closeGracefully 时回调
    server.onShutdown({=> println("onShutdown set by Server.onShutdown")})

    client.close()

    // func closeGracefully(): 触发回调并关闭
    server.closeGracefully()

    // func updateCA / updateCert(): 未配置 TLS，调用会抛 HttpException
    try {
        server.updateCA([])
    } catch (e: HttpException) {
        println("updateCA(Array) HttpException: ${e.message}")
    }
    try {
        server.updateCA("/tmp/not-exist.pem")
    } catch (e: HttpException) {
        println("updateCA(String) HttpException: ${e.message}")
    }
    // 不引入证书/私钥文件依赖：仅展示未配置 TLS 时的异常行为
    try {
        server.updateCert([], RSAPrivateKey(1024))
    } catch (e: HttpException) {
        println("updateCert(Array,Key) HttpException: ${e.message}")
    }
    try {
        server.updateCert("/tmp/a.pem", "/tmp/b.pem")
    } catch (e: HttpException) {
        println("updateCert(String,String) HttpException: ${e.message}")
    }
}
```

运行结果：

```text
afterBind set by Server.afterBind
status = 200
body = pong
tlsConfig.isSome = false
onShutdown set by Server.onShutdown
updateCA(Array) HttpException: The TLS certificate is not configured.
updateCA(String) HttpException: The TLS certificate is not configured.
updateCert(Array,Key) HttpException: The TLS certificate is not configured.
updateCert(String,String) HttpException: The TLS certificate is not configured.
```

### func getTlsConfig()

```cangjie
public func getTlsConfig(): ?TlsConfig
```

功能：获取服务器设定的 TLS 层配置。

返回值：

- ?[TlsConfig](../../tls/common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconfig) - 服务端设定的 TLS 层配置，如果没有设置则返回 None。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.sync.*
import stdx.crypto.keys.RSAPrivateKey

// 用于稳定获取响应 body（避免依赖 readToEnd/readAll 等 API）
func readAllBytes(resp: HttpResponse): String {
    let buf = Array<UInt8>(1024, repeat: 0)
    var body = ""
    while (true) {
        let n = resp.body.read(buf)
        if (n <= 0) {
            break
        }
        body += String.fromUtf8(buf[..n])
    }
    return body
}

main() {
    let sc = SyncCounter(1)

    let server = ServerBuilder().addr("127.0.0.1").port(18126).logger(NoopLogger()).build()

    // func afterBind(): 注册 bind 后回调（此处用它做“就绪信号”）
    server.afterBind(
        {
            =>
                println("afterBind set by Server.afterBind")
                sc.dec()
        }
    )

    // 注册一个最简 handler，便于 serve() 可测
    server.distributor.register("/ping", {
        httpContext => httpContext.responseBuilder.body("pong")
    })

    spawn {server.serve()}
    sc.waitUntilZero()

    // func serve(): 发起一次请求，证明服务正常
    let client = ClientBuilder().noProxy().build()
    let resp = client.get("http://127.0.0.1:18126/ping")
    let body = readAllBytes(resp)
    println("status = ${resp.status}")
    println("body = ${body}")
    resp.close()

    // func getTlsConfig(): 未设置 TLS，返回 None
    println("tlsConfig.isSome = ${server.getTlsConfig().isSome()}")

    // func onShutdown(): close/closeGracefully 时回调
    server.onShutdown({=> println("onShutdown set by Server.onShutdown")})

    client.close()

    // func closeGracefully(): 触发回调并关闭
    server.closeGracefully()

    // func updateCA / updateCert(): 未配置 TLS，调用会抛 HttpException
    try {
        server.updateCA([])
    } catch (e: HttpException) {
        println("updateCA(Array) HttpException: ${e.message}")
    }
    try {
        server.updateCA("/tmp/not-exist.pem")
    } catch (e: HttpException) {
        println("updateCA(String) HttpException: ${e.message}")
    }
    // 不引入证书/私钥文件依赖：仅展示未配置 TLS 时的异常行为
    try {
        server.updateCert([], RSAPrivateKey(1024))
    } catch (e: HttpException) {
        println("updateCert(Array,Key) HttpException: ${e.message}")
    }
    try {
        server.updateCert("/tmp/a.pem", "/tmp/b.pem")
    } catch (e: HttpException) {
        println("updateCert(String,String) HttpException: ${e.message}")
    }
}
```

运行结果：

```text
afterBind set by Server.afterBind
status = 200
body = pong
tlsConfig.isSome = false
onShutdown set by Server.onShutdown
updateCA(Array) HttpException: The TLS certificate is not configured.
updateCA(String) HttpException: The TLS certificate is not configured.
updateCert(Array,Key) HttpException: The TLS certificate is not configured.
updateCert(String,String) HttpException: The TLS certificate is not configured.
```

### func onShutdown(() -> Unit)

```cangjie
public func onShutdown(f: () -> Unit): Unit
```

功能：注册服务器关闭时的回调函数，服务器关闭时将调用该回调函数，重复调用将覆盖之前注册的函数。

参数：

- f: () -> Unit - 回调函数，入参为空，返回值为 Unit 类型。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.sync.*
import stdx.crypto.keys.RSAPrivateKey

// 用于稳定获取响应 body（避免依赖 readToEnd/readAll 等 API）
func readAllBytes(resp: HttpResponse): String {
    let buf = Array<UInt8>(1024, repeat: 0)
    var body = ""
    while (true) {
        let n = resp.body.read(buf)
        if (n <= 0) {
            break
        }
        body += String.fromUtf8(buf[..n])
    }
    return body
}

main() {
    let sc = SyncCounter(1)

    let server = ServerBuilder().addr("127.0.0.1").port(18126).logger(NoopLogger()).build()

    // func afterBind(): 注册 bind 后回调（此处用它做“就绪信号”）
    server.afterBind(
        {
            =>
                println("afterBind set by Server.afterBind")
                sc.dec()
        }
    )

    // 注册一个最简 handler，便于 serve() 可测
    server.distributor.register("/ping", {
        httpContext => httpContext.responseBuilder.body("pong")
    })

    spawn {server.serve()}
    sc.waitUntilZero()

    // func serve(): 发起一次请求，证明服务正常
    let client = ClientBuilder().noProxy().build()
    let resp = client.get("http://127.0.0.1:18126/ping")
    let body = readAllBytes(resp)
    println("status = ${resp.status}")
    println("body = ${body}")
    resp.close()

    // func getTlsConfig(): 未设置 TLS，返回 None
    println("tlsConfig.isSome = ${server.getTlsConfig().isSome()}")

    // func onShutdown(): close/closeGracefully 时回调
    server.onShutdown({=> println("onShutdown set by Server.onShutdown")})

    client.close()

    // func closeGracefully(): 触发回调并关闭
    server.closeGracefully()

    // func updateCA / updateCert(): 未配置 TLS，调用会抛 HttpException
    try {
        server.updateCA([])
    } catch (e: HttpException) {
        println("updateCA(Array) HttpException: ${e.message}")
    }
    try {
        server.updateCA("/tmp/not-exist.pem")
    } catch (e: HttpException) {
        println("updateCA(String) HttpException: ${e.message}")
    }
    // 不引入证书/私钥文件依赖：仅展示未配置 TLS 时的异常行为
    try {
        server.updateCert([], RSAPrivateKey(1024))
    } catch (e: HttpException) {
        println("updateCert(Array,Key) HttpException: ${e.message}")
    }
    try {
        server.updateCert("/tmp/a.pem", "/tmp/b.pem")
    } catch (e: HttpException) {
        println("updateCert(String,String) HttpException: ${e.message}")
    }
}
```

运行结果：

```text
afterBind set by Server.afterBind
status = 200
body = pong
tlsConfig.isSome = false
onShutdown set by Server.onShutdown
updateCA(Array) HttpException: The TLS certificate is not configured.
updateCA(String) HttpException: The TLS certificate is not configured.
updateCert(Array,Key) HttpException: The TLS certificate is not configured.
updateCert(String,String) HttpException: The TLS certificate is not configured.
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.sync.*
import stdx.crypto.keys.RSAPrivateKey

// 用于稳定获取响应 body（避免依赖 readToEnd/readAll 等 API）
func readAllBytes(resp: HttpResponse): String {
    let buf = Array<UInt8>(1024, repeat: 0)
    var body = ""
    while (true) {
        let n = resp.body.read(buf)
        if (n <= 0) {
            break
        }
        body += String.fromUtf8(buf[..n])
    }
    return body
}

main() {
    let sc = SyncCounter(1)

    let server = ServerBuilder().addr("127.0.0.1").port(18126).logger(NoopLogger()).build()

    // func afterBind(): 注册 bind 后回调（此处用它做“就绪信号”）
    server.afterBind(
        {
            =>
                println("afterBind set by Server.afterBind")
                sc.dec()
        }
    )

    // 注册一个最简 handler，便于 serve() 可测
    server.distributor.register("/ping", {
        httpContext => httpContext.responseBuilder.body("pong")
    })

    spawn {server.serve()}
    sc.waitUntilZero()

    // func serve(): 发起一次请求，证明服务正常
    let client = ClientBuilder().noProxy().build()
    let resp = client.get("http://127.0.0.1:18126/ping")
    let body = readAllBytes(resp)
    println("status = ${resp.status}")
    println("body = ${body}")
    resp.close()

    // func getTlsConfig(): 未设置 TLS，返回 None
    println("tlsConfig.isSome = ${server.getTlsConfig().isSome()}")

    // func onShutdown(): close/closeGracefully 时回调
    server.onShutdown({=> println("onShutdown set by Server.onShutdown")})

    client.close()

    // func closeGracefully(): 触发回调并关闭
    server.closeGracefully()

    // func updateCA / updateCert(): 未配置 TLS，调用会抛 HttpException
    try {
        server.updateCA([])
    } catch (e: HttpException) {
        println("updateCA(Array) HttpException: ${e.message}")
    }
    try {
        server.updateCA("/tmp/not-exist.pem")
    } catch (e: HttpException) {
        println("updateCA(String) HttpException: ${e.message}")
    }
    // 不引入证书/私钥文件依赖：仅展示未配置 TLS 时的异常行为
    try {
        server.updateCert([], RSAPrivateKey(1024))
    } catch (e: HttpException) {
        println("updateCert(Array,Key) HttpException: ${e.message}")
    }
    try {
        server.updateCert("/tmp/a.pem", "/tmp/b.pem")
    } catch (e: HttpException) {
        println("updateCert(String,String) HttpException: ${e.message}")
    }
}
```

运行结果：

```text
afterBind set by Server.afterBind
status = 200
body = pong
tlsConfig.isSome = false
onShutdown set by Server.onShutdown
updateCA(Array) HttpException: The TLS certificate is not configured.
updateCA(String) HttpException: The TLS certificate is not configured.
updateCert(Array,Key) HttpException: The TLS certificate is not configured.
updateCert(String,String) HttpException: The TLS certificate is not configured.
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.sync.*
import stdx.crypto.keys.RSAPrivateKey

// 用于稳定获取响应 body（避免依赖 readToEnd/readAll 等 API）
func readAllBytes(resp: HttpResponse): String {
    let buf = Array<UInt8>(1024, repeat: 0)
    var body = ""
    while (true) {
        let n = resp.body.read(buf)
        if (n <= 0) {
            break
        }
        body += String.fromUtf8(buf[..n])
    }
    return body
}

main() {
    let sc = SyncCounter(1)

    let server = ServerBuilder().addr("127.0.0.1").port(18126).logger(NoopLogger()).build()

    // func afterBind(): 注册 bind 后回调（此处用它做“就绪信号”）
    server.afterBind(
        {
            =>
                println("afterBind set by Server.afterBind")
                sc.dec()
        }
    )

    // 注册一个最简 handler，便于 serve() 可测
    server.distributor.register("/ping", {
        httpContext => httpContext.responseBuilder.body("pong")
    })

    spawn {server.serve()}
    sc.waitUntilZero()

    // func serve(): 发起一次请求，证明服务正常
    let client = ClientBuilder().noProxy().build()
    let resp = client.get("http://127.0.0.1:18126/ping")
    let body = readAllBytes(resp)
    println("status = ${resp.status}")
    println("body = ${body}")
    resp.close()

    // func getTlsConfig(): 未设置 TLS，返回 None
    println("tlsConfig.isSome = ${server.getTlsConfig().isSome()}")

    // func onShutdown(): close/closeGracefully 时回调
    server.onShutdown({=> println("onShutdown set by Server.onShutdown")})

    client.close()

    // func closeGracefully(): 触发回调并关闭
    server.closeGracefully()

    // func updateCA / updateCert(): 未配置 TLS，调用会抛 HttpException
    try {
        server.updateCA([])
    } catch (e: HttpException) {
        println("updateCA(Array) HttpException: ${e.message}")
    }
    try {
        server.updateCA("/tmp/not-exist.pem")
    } catch (e: HttpException) {
        println("updateCA(String) HttpException: ${e.message}")
    }
    // 不引入证书/私钥文件依赖：仅展示未配置 TLS 时的异常行为
    try {
        server.updateCert([], RSAPrivateKey(1024))
    } catch (e: HttpException) {
        println("updateCert(Array,Key) HttpException: ${e.message}")
    }
    try {
        server.updateCert("/tmp/a.pem", "/tmp/b.pem")
    } catch (e: HttpException) {
        println("updateCert(String,String) HttpException: ${e.message}")
    }
}
```

运行结果：

```text
afterBind set by Server.afterBind
status = 200
body = pong
tlsConfig.isSome = false
onShutdown set by Server.onShutdown
updateCA(Array) HttpException: The TLS certificate is not configured.
updateCA(String) HttpException: The TLS certificate is not configured.
updateCert(Array,Key) HttpException: The TLS certificate is not configured.
updateCert(String,String) HttpException: The TLS certificate is not configured.
```

### func updateCA(String)

```cangjie
public func updateCA(newCaFile: String): Unit
```

功能：对 CA 证书进行热更新。

参数：

- newCaFile: String - CA 证书文件。

异常：

- IllegalArgumentException - 参数包含空字符时抛出异常。
- [HttpException](http_package_exceptions.md#class-httpexception) - 服务端未配置 tlsConfig 时抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.sync.*
import stdx.crypto.keys.RSAPrivateKey

// 用于稳定获取响应 body（避免依赖 readToEnd/readAll 等 API）
func readAllBytes(resp: HttpResponse): String {
    let buf = Array<UInt8>(1024, repeat: 0)
    var body = ""
    while (true) {
        let n = resp.body.read(buf)
        if (n <= 0) {
            break
        }
        body += String.fromUtf8(buf[..n])
    }
    return body
}

main() {
    let sc = SyncCounter(1)

    let server = ServerBuilder().addr("127.0.0.1").port(18126).logger(NoopLogger()).build()

    // func afterBind(): 注册 bind 后回调（此处用它做“就绪信号”）
    server.afterBind(
        {
            =>
                println("afterBind set by Server.afterBind")
                sc.dec()
        }
    )

    // 注册一个最简 handler，便于 serve() 可测
    server.distributor.register("/ping", {
        httpContext => httpContext.responseBuilder.body("pong")
    })

    spawn {server.serve()}
    sc.waitUntilZero()

    // func serve(): 发起一次请求，证明服务正常
    let client = ClientBuilder().noProxy().build()
    let resp = client.get("http://127.0.0.1:18126/ping")
    let body = readAllBytes(resp)
    println("status = ${resp.status}")
    println("body = ${body}")
    resp.close()

    // func getTlsConfig(): 未设置 TLS，返回 None
    println("tlsConfig.isSome = ${server.getTlsConfig().isSome()}")

    // func onShutdown(): close/closeGracefully 时回调
    server.onShutdown({=> println("onShutdown set by Server.onShutdown")})

    client.close()

    // func closeGracefully(): 触发回调并关闭
    server.closeGracefully()

    // func updateCA / updateCert(): 未配置 TLS，调用会抛 HttpException
    try {
        server.updateCA([])
    } catch (e: HttpException) {
        println("updateCA(Array) HttpException: ${e.message}")
    }
    try {
        server.updateCA("/tmp/not-exist.pem")
    } catch (e: HttpException) {
        println("updateCA(String) HttpException: ${e.message}")
    }
    // 不引入证书/私钥文件依赖：仅展示未配置 TLS 时的异常行为
    try {
        server.updateCert([], RSAPrivateKey(1024))
    } catch (e: HttpException) {
        println("updateCert(Array,Key) HttpException: ${e.message}")
    }
    try {
        server.updateCert("/tmp/a.pem", "/tmp/b.pem")
    } catch (e: HttpException) {
        println("updateCert(String,String) HttpException: ${e.message}")
    }
}
```

运行结果：

```text
afterBind set by Server.afterBind
status = 200
body = pong
tlsConfig.isSome = false
onShutdown set by Server.onShutdown
updateCA(Array) HttpException: The TLS certificate is not configured.
updateCA(String) HttpException: The TLS certificate is not configured.
updateCert(Array,Key) HttpException: The TLS certificate is not configured.
updateCert(String,String) HttpException: The TLS certificate is not configured.
```

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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.sync.*
import stdx.crypto.keys.RSAPrivateKey

// 用于稳定获取响应 body（避免依赖 readToEnd/readAll 等 API）
func readAllBytes(resp: HttpResponse): String {
    let buf = Array<UInt8>(1024, repeat: 0)
    var body = ""
    while (true) {
        let n = resp.body.read(buf)
        if (n <= 0) {
            break
        }
        body += String.fromUtf8(buf[..n])
    }
    return body
}

main() {
    let sc = SyncCounter(1)

    let server = ServerBuilder().addr("127.0.0.1").port(18126).logger(NoopLogger()).build()

    // func afterBind(): 注册 bind 后回调（此处用它做“就绪信号”）
    server.afterBind(
        {
            =>
                println("afterBind set by Server.afterBind")
                sc.dec()
        }
    )

    // 注册一个最简 handler，便于 serve() 可测
    server.distributor.register("/ping", {
        httpContext => httpContext.responseBuilder.body("pong")
    })

    spawn {server.serve()}
    sc.waitUntilZero()

    // func serve(): 发起一次请求，证明服务正常
    let client = ClientBuilder().noProxy().build()
    let resp = client.get("http://127.0.0.1:18126/ping")
    let body = readAllBytes(resp)
    println("status = ${resp.status}")
    println("body = ${body}")
    resp.close()

    // func getTlsConfig(): 未设置 TLS，返回 None
    println("tlsConfig.isSome = ${server.getTlsConfig().isSome()}")

    // func onShutdown(): close/closeGracefully 时回调
    server.onShutdown({=> println("onShutdown set by Server.onShutdown")})

    client.close()

    // func closeGracefully(): 触发回调并关闭
    server.closeGracefully()

    // func updateCA / updateCert(): 未配置 TLS，调用会抛 HttpException
    try {
        server.updateCA([])
    } catch (e: HttpException) {
        println("updateCA(Array) HttpException: ${e.message}")
    }
    try {
        server.updateCA("/tmp/not-exist.pem")
    } catch (e: HttpException) {
        println("updateCA(String) HttpException: ${e.message}")
    }
    // 不引入证书/私钥文件依赖：仅展示未配置 TLS 时的异常行为
    try {
        server.updateCert([], RSAPrivateKey(1024))
    } catch (e: HttpException) {
        println("updateCert(Array,Key) HttpException: ${e.message}")
    }
    try {
        server.updateCert("/tmp/a.pem", "/tmp/b.pem")
    } catch (e: HttpException) {
        println("updateCert(String,String) HttpException: ${e.message}")
    }
}
```

运行结果：

```text
afterBind set by Server.afterBind
status = 200
body = pong
tlsConfig.isSome = false
onShutdown set by Server.onShutdown
updateCA(Array) HttpException: The TLS certificate is not configured.
updateCA(String) HttpException: The TLS certificate is not configured.
updateCert(Array,Key) HttpException: The TLS certificate is not configured.
updateCert(String,String) HttpException: The TLS certificate is not configured.
```

### func updateCert(String, String)

```cangjie
public func updateCert(certificateChainFile: String, privateKeyFile: String): Unit
```

功能：对 TLS 证书进行热更新。

参数：

- certificateChainFile: String - 证书链文件。
- privateKeyFile: String - 证书匹配的私钥文件。

异常：

- IllegalArgumentException - 参数包含空字符时抛出异常。
- [HttpException](http_package_exceptions.md#class-httpexception) - 服务端未配置 tlsConfig 时抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.sync.*
import stdx.crypto.keys.RSAPrivateKey

// 用于稳定获取响应 body（避免依赖 readToEnd/readAll 等 API）
func readAllBytes(resp: HttpResponse): String {
    let buf = Array<UInt8>(1024, repeat: 0)
    var body = ""
    while (true) {
        let n = resp.body.read(buf)
        if (n <= 0) {
            break
        }
        body += String.fromUtf8(buf[..n])
    }
    return body
}

main() {
    let sc = SyncCounter(1)

    let server = ServerBuilder().addr("127.0.0.1").port(18126).logger(NoopLogger()).build()

    // func afterBind(): 注册 bind 后回调（此处用它做“就绪信号”）
    server.afterBind(
        {
            =>
                println("afterBind set by Server.afterBind")
                sc.dec()
        }
    )

    // 注册一个最简 handler，便于 serve() 可测
    server.distributor.register("/ping", {
        httpContext => httpContext.responseBuilder.body("pong")
    })

    spawn {server.serve()}
    sc.waitUntilZero()

    // func serve(): 发起一次请求，证明服务正常
    let client = ClientBuilder().noProxy().build()
    let resp = client.get("http://127.0.0.1:18126/ping")
    let body = readAllBytes(resp)
    println("status = ${resp.status}")
    println("body = ${body}")
    resp.close()

    // func getTlsConfig(): 未设置 TLS，返回 None
    println("tlsConfig.isSome = ${server.getTlsConfig().isSome()}")

    // func onShutdown(): close/closeGracefully 时回调
    server.onShutdown({=> println("onShutdown set by Server.onShutdown")})

    client.close()

    // func closeGracefully(): 触发回调并关闭
    server.closeGracefully()

    // func updateCA / updateCert(): 未配置 TLS，调用会抛 HttpException
    try {
        server.updateCA([])
    } catch (e: HttpException) {
        println("updateCA(Array) HttpException: ${e.message}")
    }
    try {
        server.updateCA("/tmp/not-exist.pem")
    } catch (e: HttpException) {
        println("updateCA(String) HttpException: ${e.message}")
    }
    // 不引入证书/私钥文件依赖：仅展示未配置 TLS 时的异常行为
    try {
        server.updateCert([], RSAPrivateKey(1024))
    } catch (e: HttpException) {
        println("updateCert(Array,Key) HttpException: ${e.message}")
    }
    try {
        server.updateCert("/tmp/a.pem", "/tmp/b.pem")
    } catch (e: HttpException) {
        println("updateCert(String,String) HttpException: ${e.message}")
    }
}
```

运行结果：

```text
afterBind set by Server.afterBind
status = 200
body = pong
tlsConfig.isSome = false
onShutdown set by Server.onShutdown
updateCA(Array) HttpException: The TLS certificate is not configured.
updateCA(String) HttpException: The TLS certificate is not configured.
updateCert(Array,Key) HttpException: The TLS certificate is not configured.
updateCert(String,String) HttpException: The TLS certificate is not configured.
```

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
import stdx.log.*

main() {
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    // addr(): 设置监听地址（只是配置，真正 bind 在 serve() 时发生）
    let server = ServerBuilder().addr("127.0.0.1").port(18110).logger(NoopLogger()).build()

    // 关注点：读取 Server.addr
    println("addr = ${server.addr}")
    server.closeGracefully()
}
```

运行结果：

```text
addr = 127.0.0.1
```

### func afterBind(()->Unit)

```cangjie
public func afterBind(f: ()->Unit): ServerBuilder
```

功能：注册服务器启动时的回调函数，服务内部 ServerSocket 实例 bind 之后，accept 之前将调用该函数。重复调用将覆盖之前注册的函数。

参数：

- f: () ->Unit - 回调函数，入参为空，返回值为 Unit 类型。

返回值：

- [ServerBuilder](http_package_classes.md#class-serverbuilder) - 当前 [ServerBuilder](http_package_classes.md#class-serverbuilder) 的引用。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.sync.*

main() {
    let sc = SyncCounter(1)

    // afterBind(): bind() 完成后会回调
    let server = ServerBuilder().addr("127.0.0.1").port(18112).logger(NoopLogger()).afterBind(
        {
            =>
                println("afterBind called")
                sc.dec()
        }
    ).build()

    spawn {server.serve()}
    sc.waitUntilZero()

    server.closeGracefully()
}
```

运行结果：

```text
afterBind called
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    // build(): 根据 builder 的配置生成 Server 实例
    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18124)
        .logger(NoopLogger())
        .readTimeout(Duration.second)
        .writeTimeout(Duration.second * 2)
        .readHeaderTimeout(Duration.millisecond * 300)
        .httpKeepAliveTimeout(Duration.second * 3)
        .maxRequestHeaderSize(1024)
        .maxRequestBodySize(2048)
        .headerTableSize(1024)
        .maxConcurrentStreams(123)
        .initialWindowSize(65535)
        .maxFrameSize(16384)
        .maxHeaderListSize(4096)
        .enableConnectProtocol(true)
        .servicePoolConfig(ServicePoolConfig(capacity: 8, queueCapacity: 16, preheat: 2))
        .build()

    // 关注点：读取 Server 上的配置结果
    println("addr = ${server.addr}")
    println("port = ${server.port}")
    println("logger.level = ${server.logger.level}")
    println("readTimeout = ${server.readTimeout}")
    println("writeTimeout = ${server.writeTimeout}")
    println("readHeaderTimeout = ${server.readHeaderTimeout}")
    println("httpKeepAliveTimeout = ${server.httpKeepAliveTimeout}")
    println("maxRequestHeaderSize = ${server.maxRequestHeaderSize}")
    println("maxRequestBodySize = ${server.maxRequestBodySize}")
    println("headerTableSize = ${server.headerTableSize}")
    println("maxConcurrentStreams = ${server.maxConcurrentStreams}")
    println("initialWindowSize = ${server.initialWindowSize}")
    println("maxFrameSize = ${server.maxFrameSize}")
    println("maxHeaderListSize = ${server.maxHeaderListSize}")
    println("enableConnectProtocol = ${server.enableConnectProtocol}")
    println(
        "servicePoolConfig = (capacity=${server.servicePoolConfig.capacity}, queueCapacity=${server.servicePoolConfig.queueCapacity}, preheat=${server.servicePoolConfig.preheat})")

    server.closeGracefully()
}
```

运行结果：

```text
addr = 127.0.0.1
port = 18124
logger.level = OFF
readTimeout = 1s
writeTimeout = 2s
readHeaderTimeout = 300ms
httpKeepAliveTimeout = 3s
maxRequestHeaderSize = 1024
maxRequestBodySize = 2048
headerTableSize = 1024
maxConcurrentStreams = 123
initialWindowSize = 65535
maxFrameSize = 16384
maxHeaderListSize = 4096
enableConnectProtocol = true
servicePoolConfig = (capacity=8, queueCapacity=16, preheat=2)
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

// 自定义 distributor，用来证明 builder.distributor() 生效
class MyDistributor <: HttpRequestDistributor {
    public func register(path: String, handler: HttpRequestHandler): Unit {
        let _ = path
        let _ = handler
    }

    public func distribute(path: String): HttpRequestHandler {
        let _ = path
        return NotFoundHandler()
    }
}

main() {
    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18113)
        .logger(NoopLogger())
        .distributor(MyDistributor())
        .build()

    // 关注点：检查 Server.distributor 的动态类型
    let d = server.distributor as MyDistributor
    println("is MyDistributor: ${d.isSome()}")

    server.closeGracefully()
}
```

运行结果：

```text
is MyDistributor: true
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18118)
        .logger(NoopLogger())
        // HTTP/2 settings
        .headerTableSize(1024)
        .maxConcurrentStreams(123)
        .initialWindowSize(65535)
        .maxFrameSize(16384)
        .maxHeaderListSize(4096)
        .enableConnectProtocol(true)
        .build()

    println("headerTableSize = ${server.headerTableSize}")
    println("maxConcurrentStreams = ${server.maxConcurrentStreams}")
    println("initialWindowSize = ${server.initialWindowSize}")
    println("maxFrameSize = ${server.maxFrameSize}")
    println("maxHeaderListSize = ${server.maxHeaderListSize}")
    println("enableConnectProtocol = ${server.enableConnectProtocol}")

    server.closeGracefully()
}
```

运行结果：

```text
headerTableSize = 1024
maxConcurrentStreams = 123
initialWindowSize = 65535
maxFrameSize = 16384
maxHeaderListSize = 4096
enableConnectProtocol = true
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18118)
        .logger(NoopLogger())
        // HTTP/2 settings
        .headerTableSize(1024)
        .maxConcurrentStreams(123)
        .initialWindowSize(65535)
        .maxFrameSize(16384)
        .maxHeaderListSize(4096)
        .enableConnectProtocol(true)
        .build()

    println("headerTableSize = ${server.headerTableSize}")
    println("maxConcurrentStreams = ${server.maxConcurrentStreams}")
    println("initialWindowSize = ${server.initialWindowSize}")
    println("maxFrameSize = ${server.maxFrameSize}")
    println("maxHeaderListSize = ${server.maxHeaderListSize}")
    println("enableConnectProtocol = ${server.enableConnectProtocol}")

    server.closeGracefully()
}
```

运行结果：

```text
headerTableSize = 1024
maxConcurrentStreams = 123
initialWindowSize = 65535
maxFrameSize = 16384
maxHeaderListSize = 4096
enableConnectProtocol = true
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18117)
        .logger(NoopLogger())
        // 关注点：这些配置最终体现在 Server 的 prop 上
        .readTimeout(Duration.second)
        .writeTimeout(Duration.second * 2)
        .readHeaderTimeout(Duration.millisecond * 300)
        .httpKeepAliveTimeout(Duration.second * 3)
        .build()

    println("readTimeout = ${server.readTimeout}")
    println("writeTimeout = ${server.writeTimeout}")
    println("readHeaderTimeout = ${server.readHeaderTimeout}")
    println("httpKeepAliveTimeout = ${server.httpKeepAliveTimeout}")

    server.closeGracefully()
}
```

运行结果：

```text
readTimeout = 1s
writeTimeout = 2s
readHeaderTimeout = 300ms
httpKeepAliveTimeout = 3s
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18118)
        .logger(NoopLogger())
        // HTTP/2 settings
        .headerTableSize(1024)
        .maxConcurrentStreams(123)
        .initialWindowSize(65535)
        .maxFrameSize(16384)
        .maxHeaderListSize(4096)
        .enableConnectProtocol(true)
        .build()

    println("headerTableSize = ${server.headerTableSize}")
    println("maxConcurrentStreams = ${server.maxConcurrentStreams}")
    println("initialWindowSize = ${server.initialWindowSize}")
    println("maxFrameSize = ${server.maxFrameSize}")
    println("maxHeaderListSize = ${server.maxHeaderListSize}")
    println("enableConnectProtocol = ${server.enableConnectProtocol}")

    server.closeGracefully()
}
```

运行结果：

```text
headerTableSize = 1024
maxConcurrentStreams = 123
initialWindowSize = 65535
maxFrameSize = 16384
maxHeaderListSize = 4096
enableConnectProtocol = true
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.net.*

main() {
    // listener(): 直接注入一个已经指定 bind 地址/端口的 ServerSocket
    let socket = TcpServerSocket(bindAt: IPSocketAddress("127.0.0.1", 18122))

    let server = ServerBuilder().listener(socket).logger(NoopLogger()).build()

    println("addr = ${server.addr}")
    println("port = ${server.port}")

    server.closeGracefully()
}
```

运行结果：

```text
addr = 127.0.0.1
port = 18122
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    // logger(): 设定 Server 的 logger
    let server = ServerBuilder().addr("127.0.0.1").port(18114).logger(NoopLogger()).build()

    // 关注点：NoopLogger.level 恒为 OFF
    println("logger.level = ${server.logger.level}")

    server.closeGracefully()
}
```

运行结果：

```text
logger.level = OFF
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18118)
        .logger(NoopLogger())
        // HTTP/2 settings
        .headerTableSize(1024)
        .maxConcurrentStreams(123)
        .initialWindowSize(65535)
        .maxFrameSize(16384)
        .maxHeaderListSize(4096)
        .enableConnectProtocol(true)
        .build()

    println("headerTableSize = ${server.headerTableSize}")
    println("maxConcurrentStreams = ${server.maxConcurrentStreams}")
    println("initialWindowSize = ${server.initialWindowSize}")
    println("maxFrameSize = ${server.maxFrameSize}")
    println("maxHeaderListSize = ${server.maxHeaderListSize}")
    println("enableConnectProtocol = ${server.enableConnectProtocol}")

    server.closeGracefully()
}
```

运行结果：

```text
headerTableSize = 1024
maxConcurrentStreams = 123
initialWindowSize = 65535
maxFrameSize = 16384
maxHeaderListSize = 4096
enableConnectProtocol = true
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18118)
        .logger(NoopLogger())
        // HTTP/2 settings
        .headerTableSize(1024)
        .maxConcurrentStreams(123)
        .initialWindowSize(65535)
        .maxFrameSize(16384)
        .maxHeaderListSize(4096)
        .enableConnectProtocol(true)
        .build()

    println("headerTableSize = ${server.headerTableSize}")
    println("maxConcurrentStreams = ${server.maxConcurrentStreams}")
    println("initialWindowSize = ${server.initialWindowSize}")
    println("maxFrameSize = ${server.maxFrameSize}")
    println("maxHeaderListSize = ${server.maxHeaderListSize}")
    println("enableConnectProtocol = ${server.enableConnectProtocol}")

    server.closeGracefully()
}
```

运行结果：

```text
headerTableSize = 1024
maxConcurrentStreams = 123
initialWindowSize = 65535
maxFrameSize = 16384
maxHeaderListSize = 4096
enableConnectProtocol = true
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18118)
        .logger(NoopLogger())
        // HTTP/2 settings
        .headerTableSize(1024)
        .maxConcurrentStreams(123)
        .initialWindowSize(65535)
        .maxFrameSize(16384)
        .maxHeaderListSize(4096)
        .enableConnectProtocol(true)
        .build()

    println("headerTableSize = ${server.headerTableSize}")
    println("maxConcurrentStreams = ${server.maxConcurrentStreams}")
    println("initialWindowSize = ${server.initialWindowSize}")
    println("maxFrameSize = ${server.maxFrameSize}")
    println("maxHeaderListSize = ${server.maxHeaderListSize}")
    println("enableConnectProtocol = ${server.enableConnectProtocol}")

    server.closeGracefully()
}
```

运行结果：

```text
headerTableSize = 1024
maxConcurrentStreams = 123
initialWindowSize = 65535
maxFrameSize = 16384
maxHeaderListSize = 4096
enableConnectProtocol = true
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18119)
        .logger(NoopLogger())
        .maxRequestHeaderSize(1024)
        .maxRequestBodySize(2048)
        .build()

    println("maxRequestHeaderSize = ${server.maxRequestHeaderSize}")
    println("maxRequestBodySize = ${server.maxRequestBodySize}")

    server.closeGracefully()
}
```

运行结果：

```text
maxRequestHeaderSize = 1024
maxRequestBodySize = 2048
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18119)
        .logger(NoopLogger())
        .maxRequestHeaderSize(1024)
        .maxRequestBodySize(2048)
        .build()

    println("maxRequestHeaderSize = ${server.maxRequestHeaderSize}")
    println("maxRequestBodySize = ${server.maxRequestBodySize}")

    server.closeGracefully()
}
```

运行结果：

```text
maxRequestHeaderSize = 1024
maxRequestBodySize = 2048
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    // onShutdown(): close/closeGracefully 时会触发回调
    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18123)
        .logger(NoopLogger())
        .onShutdown({=> println("onShutdown called")})
        .build()

    server.closeGracefully()
}
```

运行结果：

```text
onShutdown called
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    // port(): 设置监听端口
    let server = ServerBuilder().addr("127.0.0.1").port(18111).logger(NoopLogger()).build()

    println("port = ${server.port}")
    server.closeGracefully()
}
```

运行结果：

```text
port = 18111
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import std.net.*

// 自定义 ProtocolService：不做真实 HTTP 解析，只打印并回一个固定响应
class MyProtocolService <: ProtocolService {
    let conn: StreamingSocket

    public init(conn: StreamingSocket) {
        this.conn = conn
    }

    protected override func serve(): Unit {
        println("MyProtocolService.serve")
        conn.write("HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nOK".toArray())
        conn.close()
    }

    protected override func closeGracefully(): Unit {
        conn.close()
    }

    protected override func close(): Unit {
        conn.close()
    }
}

class MyFactory <: ProtocolServiceFactory {
    public func create(protocol: Protocol, socket: StreamingSocket): ProtocolService {
        let _ = protocol
        return MyProtocolService(socket)
    }
}

main() {
    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18121)
        .logger(NoopLogger())
        .protocolServiceFactory(MyFactory())
        .build()

    // 关注点：Server.protocolServiceFactory 的动态类型
    let f = server.protocolServiceFactory as MyFactory
    println("protocolServiceFactory is MyFactory: ${f.isSome()}")

    server.closeGracefully()
}
```

运行结果：

```text
protocolServiceFactory is MyFactory: true
```

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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18117)
        .logger(NoopLogger())
        // 关注点：这些配置最终体现在 Server 的 prop 上
        .readTimeout(Duration.second)
        .writeTimeout(Duration.second * 2)
        .readHeaderTimeout(Duration.millisecond * 300)
        .httpKeepAliveTimeout(Duration.second * 3)
        .build()

    println("readTimeout = ${server.readTimeout}")
    println("writeTimeout = ${server.writeTimeout}")
    println("readHeaderTimeout = ${server.readHeaderTimeout}")
    println("httpKeepAliveTimeout = ${server.httpKeepAliveTimeout}")

    server.closeGracefully()
}
```

运行结果：

```text
readTimeout = 1s
writeTimeout = 2s
readHeaderTimeout = 300ms
httpKeepAliveTimeout = 3s
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18117)
        .logger(NoopLogger())
        // 关注点：这些配置最终体现在 Server 的 prop 上
        .readTimeout(Duration.second)
        .writeTimeout(Duration.second * 2)
        .readHeaderTimeout(Duration.millisecond * 300)
        .httpKeepAliveTimeout(Duration.second * 3)
        .build()

    println("readTimeout = ${server.readTimeout}")
    println("writeTimeout = ${server.writeTimeout}")
    println("readHeaderTimeout = ${server.readHeaderTimeout}")
    println("httpKeepAliveTimeout = ${server.httpKeepAliveTimeout}")

    server.closeGracefully()
}
```

运行结果：

```text
readTimeout = 1s
writeTimeout = 2s
readHeaderTimeout = 300ms
httpKeepAliveTimeout = 3s
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    let poolCfg = ServicePoolConfig(capacity: 8, queueCapacity: 16, preheat: 2)

    let server = ServerBuilder().addr("127.0.0.1").port(18120).logger(NoopLogger()).servicePoolConfig(poolCfg).build()

    let c = server.servicePoolConfig.capacity
    let q = server.servicePoolConfig.queueCapacity
    let p = server.servicePoolConfig.preheat
    println("servicePoolConfig = (capacity=${c}, queueCapacity=${q}, preheat=${p})")

    server.closeGracefully()
}
```

运行结果：

```text
servicePoolConfig = (capacity=8, queueCapacity=16, preheat=2)
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    // 默认不配置 TLS
    let server = ServerBuilder().addr("127.0.0.1").port(18116).logger(NoopLogger()).build()

    println("tlsConfig.isSome = ${server.getTlsConfig().isSome()}")

    server.closeGracefully()
}
```

运行结果：

```text
tlsConfig.isSome = false
```

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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    var cfg = TransportConfig()
    cfg.readBufferSize = 8192

    let server = ServerBuilder().addr("127.0.0.1").port(18115).logger(NoopLogger()).transportConfig(cfg).build()

    let rb = server.transportConfig.readBufferSize ?? 0
    println("transport.readBufferSize = ${rb}")

    server.closeGracefully()
}
```

运行结果：

```text
transport.readBufferSize = 8192
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*

main() {
    let server = ServerBuilder()
        .addr("127.0.0.1")
        .port(18117)
        .logger(NoopLogger())
        // 关注点：这些配置最终体现在 Server 的 prop 上
        .readTimeout(Duration.second)
        .writeTimeout(Duration.second * 2)
        .readHeaderTimeout(Duration.millisecond * 300)
        .httpKeepAliveTimeout(Duration.second * 3)
        .build()

    println("readTimeout = ${server.readTimeout}")
    println("writeTimeout = ${server.writeTimeout}")
    println("readHeaderTimeout = ${server.readHeaderTimeout}")
    println("httpKeepAliveTimeout = ${server.httpKeepAliveTimeout}")

    server.closeGracefully()
}
```

运行结果：

```text
readTimeout = 1s
writeTimeout = 2s
readHeaderTimeout = 300ms
httpKeepAliveTimeout = 3s
```

## class WebSocket

```cangjie
public class WebSocket
```

功能：提供 [WebSocket](http_package_classes.md#class-websocket) 服务的相关类，提供 [WebSocket](http_package_classes.md#class-websocket) 连接的读、写、关闭等函数。用户通过 upgradeFrom 函数以获取 [WebSocket](http_package_classes.md#class-websocket) 连接。

- 调用 `read()` 读取一个 [WebSocketFrame](http_package_classes.md#class-websocketframe)，用户可通过 [WebSocketFrame](http_package_classes.md#class-websocketframe).frameType 来知晓帧的类型，通过 [WebSocketFrame](http_package_classes.md#class-websocketframe).fin 来知晓是否是分段帧。
- 调用 `write(frameType: WebSocketFrameType, byteArray: Array<UInt8>)`，传入 message 的类型和 message 的 byte 来发送 [WebSocket](http_package_classes.md#class-websocket) 信息，如果写的是控制帧，则不会分段发送，如果写的是数据帧（Text、Binary），则会将 message 按底层 buffer 的大小分段（分成多个 fragment）发送。

详细说明见下文接口说明，接口行为以 RFC 6455 为准。

### prop logger

```cangjie
public prop logger: Logger
```

功能：日志记录器。

类型：[Logger](../../../log/log_package_api/log_package_classes.md#class-logger)

### prop subProtocol

```cangjie
public prop subProtocol: String
```

功能：获取与对端协商到的 subProtocol，协商时，客户端提供一个按偏好排名的 subProtocols 列表，服务器从中选取一个或零个子协议。

类型：String

### static func upgradeFromClient(Client, URL, Protocol, ArrayList\<String>, HttpHeaders)

```cangjie
public static func upgradeFromClient(client: Client, url: URL,
 version!: Protocol = HTTP1_1,
 subProtocols!: ArrayList<String> = ArrayList<String>(),
 headers!: HttpHeaders = HttpHeaders()): (WebSocket, HttpHeaders)
```

功能：提供客户端升级到 [WebSocket](http_package_classes.md#class-websocket) 协议的函数。

> **说明：**
>
> 客户端的升级流程为：传入 client 对象，url 对象，构建升级请求，请求服务器后验证其响应，如果握手成功，则返回 [WebSocket](http_package_classes.md#class-websocket) 对象用于 [WebSocket](http_package_classes.md#class-websocket) 通讯，并返回 101 响应头的 [HttpHeaders](http_package_classes.md#class-httpheaders) 对象给用户。暂不支持 extensions。如果子协议协商成功，用户可通过调用返回的 [WebSocket](http_package_classes.md#class-websocket) 的 subProtocol 查看子协议。

参数：

- client: [Client](http_package_classes.md#class-client) - 用于请求的 client 对象。
- url: [URL](../../../encoding/url/url_package_api/url_package_classes.md#class-url) - 用于请求的 url 对象，[WebSocket](http_package_classes.md#class-websocket) 升级时要注意 url 的 scheme 为 ws 或 wss。
- version!: [Protocol](http_package_enums.md#enum-protocol) - 创建 socket 使用的 HTTP 版本，只支持  [HTTP1_1](./http_package_enums.md#enum-protocol) 和  [HTTP2_0](./http_package_enums.md#enum-protocol) 向 [WebSocket](http_package_classes.md#class-websocket) 升级。
- subProtocols!: ArrayList\<String> - 用户配置的子协议列表，按偏好排名，默认为空。若用户配置了，则会随着升级请求发送给服务器。
- headers!: [HttpHeaders](http_package_classes.md#class-httpheaders) - 需要随着升级请求一同发送的非升级必要头，如 cookie 等。

返回值：

- ([WebSocket](http_package_classes.md#class-websocket), HttpHeaders) - 升级成功，则返回 [WebSocket](http_package_classes.md#class-websocket) 对象用于通讯和 101 响应的头。

异常：

- SocketException - 底层连接错误时抛出异常。
- [HttpException](http_package_exceptions.md#class-httpexception) - 握手时 HTTP 请求过程中出现错误时抛出异常。
- [WebSocketException](http_package_exceptions.md#class-websocketexception) - 升级失败，升级响应验证不通过时抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import stdx.encoding.url.URL
import std.sync.*
import stdx.crypto.kit.DefaultCryptoKit

main() {
    let _ = DefaultCryptoKit()
    let sc = SyncCounter(1)
    let logger = NoopLogger()

    let server = ServerBuilder().addr("127.0.0.1").port(18170).logger(logger).afterBind({=> sc.dec()}).build()
    server.distributor.register(
        "/ws",
        FuncHandler(
            {
                ctx: HttpContext =>
                    let ws = WebSocket.upgradeFromServer(ctx)
                    // 当前属性：WebSocket.logger（可动态调整 level）
                    ws.logger.level = LogLevel.ERROR
                    println("ws.logger.level = ${ws.logger.level}")
                    ws.writeCloseFrame(status: 1000, reason: "bye")
                    ws.closeConn()
            }
        )
    )

    spawn {server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().logger(logger).build()
    let (ws, hdr) = WebSocket.upgradeFromClient(client, URL.parse("ws://127.0.0.1:18170/ws"))
    let _ = hdr

    let _ = ws.read() // Close

    ws.closeConn()
    client.close()
    server.closeGracefully()
}
```

运行结果：

```text
ws.logger.level = ERROR
```

### static func upgradeFromServer(HttpContext, ArrayList\<String>, ArrayList\<String>, (HttpRequest) -> HttpHeaders)

```cangjie
public static func upgradeFromServer(ctx: HttpContext, subProtocols!: ArrayList<String> = ArrayList<String>(), 
                                        origins!: ArrayList<String> = ArrayList<String>(), 
                                        userFunc!:(HttpRequest) -> HttpHeaders = {_: HttpRequest => HttpHeaders()}): WebSocket
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import stdx.encoding.url.URL
import std.sync.*
import stdx.crypto.kit.DefaultCryptoKit

main() {
    let _ = DefaultCryptoKit()
    let sc = SyncCounter(1)
    let logger = NoopLogger()

    let server = ServerBuilder().addr("127.0.0.1").port(18170).logger(logger).afterBind({=> sc.dec()}).build()
    server.distributor.register(
        "/ws",
        FuncHandler(
            {
                ctx: HttpContext =>
                    let ws = WebSocket.upgradeFromServer(ctx)
                    // 当前属性：WebSocket.logger（可动态调整 level）
                    ws.logger.level = LogLevel.ERROR
                    println("ws.logger.level = ${ws.logger.level}")
                    ws.writeCloseFrame(status: 1000, reason: "bye")
                    ws.closeConn()
            }
        )
    )

    spawn {server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().logger(logger).build()
    let (ws, hdr) = WebSocket.upgradeFromClient(client, URL.parse("ws://127.0.0.1:18170/ws"))
    let _ = hdr

    let _ = ws.read() // Close

    ws.closeConn()
    client.close()
    server.closeGracefully()
}
```

运行结果：

```text
ws.logger.level = ERROR
```

### func closeConn()

```cangjie
public func closeConn(): Unit
```

功能：提供关闭底层 [WebSocket](http_package_classes.md#class-websocket) 连接的函数。

> **说明：**
>
> 直接关闭底层连接。正常的关闭流程需要遵循协议规定的握手流程，即先发送 Close 帧给对端，并等待对端回应的 Close 帧。握手流程结束后方可关闭底层连接。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import stdx.encoding.url.URL
import std.sync.*
import stdx.crypto.kit.DefaultCryptoKit

main() {
    // 触发 DefaultCryptoKit.static init（设置全局 crypto kit），供 WebSocket 握手生成随机 key/sha1 使用
    let _ = DefaultCryptoKit()

    let sc = SyncCounter(1)
    let logger = NoopLogger()

    let server = ServerBuilder().addr("127.0.0.1").port(18172).logger(logger).afterBind({=> sc.dec()}).build()

    server.distributor.register(
        "/ws",
        FuncHandler(
            {
                ctx: HttpContext =>
                    let ws = WebSocket.upgradeFromServer(ctx)
                    ws.writeCloseFrame(status: 1000, reason: "bye")
                    ws.closeConn()
                    println("server closed")
            }
        )
    )

    spawn {server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().logger(logger).build()
    let (ws, hdr) = WebSocket.upgradeFromClient(client, URL.parse("ws://127.0.0.1:18172/ws"))
    let _ = hdr

    println("client before close")
    let _ = ws.read()
    ws.closeConn()
    println("client closed")
    client.close();
    server.closeGracefully();
    return ws.closeConn()
    client.close()
    server.closeGracefully()
}
```

运行结果：

```text
server closed
client before close
client closed
```

### func read()

```cangjie
public func read(): WebSocketFrame
```

功能：从连接中读取一个帧，如果连接上数据未就绪会阻塞，非线程安全（即对同一个 [WebSocket](http_package_classes.md#class-websocket) 对象不支持多线程读）。

read 函数返回一个 [WebSocketFrame](http_package_classes.md#class-websocketframe) 对象，用户可以调用 [WebSocketFrame](http_package_classes.md#class-websocketframe) 的 frameType，fin 属性确定其帧类型和是否是分段帧调用。通过 [WebSocketFrame](http_package_classes.md#class-websocketframe) 的 payload 函数得到原始二进制数据数组：Array\<UInt8>

- 分段帧的首帧为 fin == false，frameType == TextWebFrame 或 BinaryWebFrame 中间帧 fin == false，frameType == ContinuationWebFrame 尾帧 fin == true， frameType == ContinuationWebFrame；
- 非分段帧为     fin == true， frameType != ContinuationWebFrame。

> **注意：**
>
> - 数据帧（Text，Binary）可以分段，用户需要多次调用 read 将所有分段帧读完（以下称为接收到完整的 message），再将分段帧的 payload 按接收序拼接 Text 帧的 payload 为 UTF-8 编码，用户在接收到完整的 message 后，调用 String.fromUtf8 函数将拼接后的 payload 转成字符串 Binary 帧的 payload 的意义由使用其的应用确定，用户在接收到完整的 message 后，将拼接后的 payload 传给上层应用；
> - 控制帧（Close，Ping，Pong）不可分段；
> - 控制帧本身不可分段，但其可以穿插在分段的数据帧之间。分段的数据帧之间不可出现其他数据帧，如果用户收到穿插的分段数据帧，则需要当作错误处理；
> - 客户端收到 masked 帧，服务器收到 unmasked 帧，断开底层连接并抛出异常；
> - rsv1、rsv2、rsv3 位被设置（暂不支持 extensions，因此 rsv 位必须为 0），断开底层连接并抛出异常；
> - 收到无法理解的帧类型（只支持 Continuation，Text，Binary，Close，Ping，Pong），断开底层连接并抛出异常；
> - 收到分段或 payload 长度大于 125 bytes 的控制帧（Close，Ping，Pong），断开底层连接并抛出异常；
> - 收到 payload 长度大于 20M 的帧，断开底层连接并抛出异常；
> - WebSocket 没有跨续帧聚合消息大小限制，即由多个分段帧组成的完整消息的总大小没有限制；
> - closeConn 关闭连接后继续调用读，抛出异常。

返回值：

- [WebSocketFrame](http_package_classes.md#class-websocketframe) - 读到的 [WebSocketFrame](http_package_classes.md#class-websocketframe) 对象。

异常：

- SocketException - 底层连接错误。
- [WebSocketException](http_package_exceptions.md#class-websocketexception) - 收到不符合协议规定的帧，此时会给对端发送 Close 帧说明错误信息，并断开底层连接。
- [ConnectionException](http_package_exceptions.md#class-connectionexception) - 从连接中读数据时对端已关闭连接抛此异常。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import stdx.encoding.url.URL
import std.sync.*
import stdx.crypto.kit.DefaultCryptoKit

main() {
    // 触发 DefaultCryptoKit.static init（设置全局 crypto kit），供 WebSocket 握手生成随机 key/sha1 使用
    let _ = DefaultCryptoKit()

    let sc = SyncCounter(1)
    let logger = NoopLogger()

    let server = ServerBuilder().addr("127.0.0.1").port(18173).logger(logger).afterBind({=> sc.dec()}).build()

    server.distributor.register(
        "/ws",
        FuncHandler(
            {
                ctx: HttpContext =>
                    let ws = WebSocket.upgradeFromServer(ctx)
                    ws.write(TextWebFrame, "pong".toArray())
                    ws.writeCloseFrame(status: 1000, reason: "bye")
            }
        )
    )

    spawn {server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().logger(logger).build()
    let (ws, hdr) = WebSocket.upgradeFromClient(client, URL.parse("ws://127.0.0.1:18173/ws"))
    let _ = hdr

    let f1 = ws.read()
    // 当前函数：WebSocket.read()
    println("read type=${f1.frameType}, payload=${String.fromUtf8(f1.payload)}")
    let _ = ws.read()

    ws.closeConn()
    client.close()
    server.closeGracefully()
}
```

运行结果：

```text
read type=TextWebFrame, payload=pong
```

### func write(WebSocketFrameType, Array\<UInt8>, Int64)

```cangjie
public func write(frameType: WebSocketFrameType, byteArray: Array<UInt8>, frameSize!: Int64 = 4096): Unit
```

功能：发送数据，非线程安全（即对同一个 [WebSocket](http_package_classes.md#class-websocket) 对象不支持多线程写）。

> **注意：**
>
> write 函数将数据以 [WebSocket](http_package_classes.md#class-websocket) 帧的形式发送给对端；
>
> - 如果发送数据帧（Text，Binary），传入的 byteArray 如果大于 frameSize （默认 4 * 1024 bytes)，我们会将其分成小于等于 frameSize 的 payload 以分段帧的形式发送，否则不分段；
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import stdx.encoding.url.URL
import std.sync.*
import stdx.crypto.kit.DefaultCryptoKit

main() {
    // 触发 DefaultCryptoKit.static init（设置全局 crypto kit），供 WebSocket 握手生成随机 key/sha1 使用
    let _ = DefaultCryptoKit()

    let sc = SyncCounter(1)
    let logger = NoopLogger()

    let server = ServerBuilder().addr("127.0.0.1").port(18174).logger(logger).afterBind({=> sc.dec()}).build()

    server.distributor.register(
        "/ws",
        FuncHandler(
            {
                ctx: HttpContext =>
                    let ws = WebSocket.upgradeFromServer(ctx)
                    let f = ws.read()
                    // 当前函数：WebSocket.write(...)
                    println("server got ${String.fromUtf8(f.payload)}")
                    ws.write(TextWebFrame, "ack".toArray())
                    ws.writeCloseFrame(status: 1000, reason: "bye")
            }
        )
    )

    spawn {server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().logger(logger).build()
    let (ws, hdr) = WebSocket.upgradeFromClient(client, URL.parse("ws://127.0.0.1:18174/ws"))
    let _ = hdr

    ws.write(TextWebFrame, "hello".toArray())
    let f1 = ws.read()
    println("client got ${String.fromUtf8(f1.payload)}")
    let _ = ws.read()

    ws.closeConn()
    client.close()
    server.closeGracefully()
}
```

运行结果：

```text
server got hello
client got ack
```

### func writeCloseFrame(?UInt16, String)

```cangjie
public func writeCloseFrame(status!: ?UInt16 = None, reason!: String = ""): Unit
```

功能：发送 Close 帧。

> **注意：**
>
> 协议规定，Close 帧发送之后，禁止再发送数据帧。如果用户不设置 status，那么 reason 不会被发送（即有 reason 必有 status）；控制帧的 payload 不超过 125 bytes，Close 帧的前两个 bytes 为 status，因此 reason 不能超过 123 bytes，closeConn 关闭连接后调用写，抛出异常。

参数：

- status!: ?UInt16 - 发送的 Close 帧的状态码，默认为 None，表示不发送状态码和 reason。
- reason!: String - 关闭连接的说明，默认为空字符串，发送时会转成 UTF-8，不保证可读，debug 用。

异常：

- [WebSocketException](http_package_exceptions.md#class-websocketexception) - 传入非法的状态码，或 reason 数据超过 123 bytes 时抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import stdx.encoding.url.URL
import std.sync.*
import stdx.crypto.kit.DefaultCryptoKit

main() {
    // 触发 DefaultCryptoKit.static init（设置全局 crypto kit），供 WebSocket 握手生成随机 key/sha1 使用
    let _ = DefaultCryptoKit()

    let sc = SyncCounter(1)
    let logger = NoopLogger()

    let server = ServerBuilder().addr("127.0.0.1").port(18175).logger(logger).afterBind({=> sc.dec()}).build()

    server.distributor.register(
        "/ws",
        FuncHandler(
            {
                ctx: HttpContext =>
                    let ws = WebSocket.upgradeFromServer(ctx)
                    ws.writeCloseFrame(status: 1000, reason: "bye")
            }
        )
    )

    spawn {server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().logger(logger).build()
    let (ws, hdr) = WebSocket.upgradeFromClient(client, URL.parse("ws://127.0.0.1:18175/ws"))
    let _ = hdr

    let f = ws.read()
    // 当前函数：WebSocket.writeCloseFrame(status, reason)
    println("close frameType=${f.frameType}")

    ws.closeConn()
    client.close()
    server.closeGracefully()
}
```

运行结果：

```text
close frameType=CloseWebFrame
```

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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import stdx.encoding.url.URL
import std.sync.*
import stdx.crypto.kit.DefaultCryptoKit

main() {
    // 触发 DefaultCryptoKit.static init（设置全局 crypto kit），供 WebSocket 握手生成随机 key/sha1 使用
    let _ = DefaultCryptoKit()

    let sc = SyncCounter(1)
    let logger = NoopLogger()

    let server = ServerBuilder().addr("127.0.0.1").port(18176).logger(logger).afterBind({=> sc.dec()}).build()

    server.distributor.register(
        "/ws",
        FuncHandler(
            {
                ctx: HttpContext =>
                    let ws = WebSocket.upgradeFromServer(ctx)
                    let f = ws.read()
                    println("server got ping payload=${String.fromUtf8(f.payload)}")
                    ws.writePongFrame("pong".toArray())
                    ws.writeCloseFrame(status: 1000, reason: "bye")
            }
        )
    )

    spawn {server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().logger(logger).build()
    let (ws, hdr) = WebSocket.upgradeFromClient(client, URL.parse("ws://127.0.0.1:18176/ws"))
    let _ = hdr

    ws.writePingFrame("ping".toArray())
    let f1 = ws.read()
    println("client got ${f1.frameType}")
    let _ = ws.read()

    ws.closeConn()
    client.close()
    server.closeGracefully()
}
```

运行结果：

```text
server got ping payload=ping
client got PongWebFrame
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

<!-- run -->
```cangjie
import stdx.net.http.*
import stdx.log.*
import stdx.encoding.url.URL
import std.sync.*
import stdx.crypto.kit.DefaultCryptoKit

main() {
    // 触发 DefaultCryptoKit.static init（设置全局 crypto kit），供 WebSocket 握手生成随机 key/sha1 使用
    let _ = DefaultCryptoKit()

    let sc = SyncCounter(1)
    let logger = NoopLogger()

    let server = ServerBuilder().addr("127.0.0.1").port(18177).logger(logger).afterBind({=> sc.dec()}).build()

    server.distributor.register(
        "/ws",
        FuncHandler(
            {
                ctx: HttpContext =>
                    let ws = WebSocket.upgradeFromServer(ctx)
                    let f = ws.read()
                    println("server got ${f.frameType}")
                    ws.writePongFrame("pong".toArray())
                    ws.writeCloseFrame(status: 1000, reason: "bye")
            }
        )
    )

    spawn {server.serve()}
    sc.waitUntilZero()

    let client = ClientBuilder().logger(logger).build()
    let (ws, hdr) = WebSocket.upgradeFromClient(client, URL.parse("ws://127.0.0.1:18177/ws"))
    let _ = hdr

    ws.writePingFrame("ping".toArray())
    let f1 = ws.read()
    // 当前函数：WebSocket.writePongFrame(...)
    println("client got pong payload=${String.fromUtf8(f1.payload)}")
    let _ = ws.read()

    ws.closeConn()
    client.close()
    server.closeGracefully()
}
```

运行结果：

```text
server got PingWebFrame
client got pong payload=pong
```

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

### prop frameType

```cangjie
public prop frameType: WebSocketFrameType
```

功能：获取 [WebSocketFrame](http_package_classes.md#class-websocketframe) 的帧类型，fin 与 frameType 共同说明了帧是否分段和帧的类型。

类型：[WebSocketFrameType](http_package_enums.md#enum-websocketframetype)

### prop payload

```cangjie
public prop payload: Array<UInt8>
```

功能：获取 [WebSocketFrame](http_package_classes.md#class-websocketframe) 的帧载荷。如果是分段数据帧，用户需要在接收到完整的 message 后，将所有分段的 payload 按接收序拼接。

类型：Array\<UInt8>
