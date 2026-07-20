# 结构体

## struct CipherSuite

```cangjie
public struct CipherSuite <: ToString & Equatable<CipherSuite>
```

功能：TLS 中的密码套件。

父类型：

- ToString
- Equatable\<[CipherSuite](#struct-ciphersuite)>

### static prop allSupported

```cangjie
public static prop allSupported: Array<CipherSuite>
```

功能：返回所有支持的密码套件。

类型：Array\<[CipherSuite](tls_package_structs.md#struct-ciphersuite)>

示例：

<!-- verify -->
```cangjie
import stdx.net.tls.*

main() {
    let allSuites = CipherSuite.allSupported
    println("支持的密码套件数量: ${allSuites.size}")
    return 0
}
```

运行结果：

```text
支持的密码套件数量: 60
```

### func toString()

```cangjie
public func toString(): String
```

功能：返回密码套件名称。

返回值：

- String - 密码套件名称。

示例：

<!-- verify -->
```cangjie
import stdx.net.tls.*

main() {
    let suite = CipherSuite.allSupported[0]
    let name = suite.toString()
    println("密码套件名称: ${name}")
    return 0
}
```

运行结果：

```text
密码套件名称: TLS_AES_256_GCM_SHA384
```

### operator func !=(CipherSuite)

```cangjie
public operator func !=(that: CipherSuite): Bool
```

功能：判断两个密码套件是否不等。

参数：

- that: [CipherSuite](tls_package_structs.md#struct-ciphersuite) - 被比较的密码套件对象。

返回值：

- Bool - 若不等，则返回 `true`；反之，返回 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.net.tls.*

main() {
    let suite1 = CipherSuite.allSupported[0]
    let suite2 = CipherSuite.allSupported[1]
    let isNotEqual = suite1 != suite2
    println("两个密码套件是否不等: ${isNotEqual}")
    return 0
}
```

运行结果：

```text
两个密码套件是否不等: true
```

### operator func ==(CipherSuite)

```cangjie
public operator func ==(that: CipherSuite): Bool
```

功能：判断两个密码套件是否相等。

参数：

- that: [CipherSuite](tls_package_structs.md#struct-ciphersuite) - 被比较的密码套件对象。

返回值：

- Bool - 若相等，则返回 `true`；反之，返回 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.net.tls.*

main() {
    let suite1 = CipherSuite.allSupported[0]
    let suite2 = CipherSuite.allSupported[0] // 相同索引
    let isEqual = suite1 == suite2
    println("两个密码套件是否相等: ${isEqual}")
    return 0
}
```

运行结果：

```text
两个密码套件是否相等: true
```

## struct TlsClientConfig

```cangjie
public struct TlsClientConfig <: TlsConfig {
    public var keylogCallback: ?(TlsSocket, String) -> Unit = None
    public init()
}
```

功能：客户端配置。

父类型：

- [TlsConfig](./../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconfig)

### var keylogCallback

```cangjie
public var keylogCallback: ?(TlsSocket, String) -> Unit = None
```

功能：握手过程的回调函数，提供 TLS 初始秘钥数据，用于调试和解密记录使用。

> **注意：**
>
> 严禁在生产环境中使用此回调：传入的字符串参数属于敏感数据，泄露其内容会严重危及连接安全。

类型：?([TlsSocket](tls_package_classes.md#class-tlssocket), String) -> Unit

示例：

<!-- run -->
```cangjie
import std.io.*
import std.fs.*
import std.net.*
import std.process.*
import stdx.net.tls.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*
import stdx.net.tls.common.*

main(): Unit {
    // 定义证书和私钥文件路径
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // 启动服务器
    spawn {
        // OpenSSL 官方标准、无风险的测试命令用来本地生成证书和私钥
        let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
        executeWithOutput("sh", ["-c", cmdStr])
        // 对证书以及私钥进行解析
        let pemString = String.fromUtf8(File.readFrom(serverCrt))
        let keyString = String.fromUtf8(File.readFrom(serverKey))

        let certificate = X509Certificate.decodeFromPem(pemString)
        let privateKey = GeneralPrivateKey.decodeFromPem(keyString)

        let config = TlsServerConfig(certificate, privateKey)

        // 启动 TCP 服务器
        try (server = TcpServerSocket(bindAt: 8443)) {
            // 绑定并监听
            server.bind()
            // 接受客户端连接，如果需要多次连接，可以使用循环，参考模块下示例教程
            try (clientSocket = server.accept()) {
                // 创建 TLS 套接字并进行握手
                try (tls = TlsSocket.server(clientSocket, serverConfig: config, session: None)) {
                    // 握手成功就会触发回调
                    tls.handshake()
                }
            }
        }
    }
    // 等待服务器启动
    sleep(Duration.second)

    // 客户端配置
    var config = TlsClientConfig()
    config.verifyMode = TrustAll

    // 握手过程的回调函数设置，禁止在生产环境中使用
    config.keylogCallback = {
        _, String => println("秘钥数据: ${String}")
    }

    // 连接服务器
    try (socket = TcpSocket("127.0.0.1", 8443)) {
        // 首先进行 TCP 连接
        socket.connect()
        // 创建 TLS 套接字并进行握手
        try (tls = TlsSocket.client(socket, clientConfig: config, session: None)) {
            // 握手成功就会触发回调
            let _ = tls.handshake()
        }
    } catch (e: Exception) {
        println("客户端连接失败: ${e.message}")
    }
    // 删除生成的证书和私钥文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
}
```

可能的运行结果：

```text
秘钥数据: SERVER_HANDSHAKE_TRAFFIC_SECRET XXX XXX
秘钥数据: EXPORTER_SECRET XXX XXX
秘钥数据: SERVER_TRAFFIC_SECRET_0 XXX XXX
秘钥数据: CLIENT_HANDSHAKE_TRAFFIC_SECRET XXX XXX
秘钥数据: CLIENT_TRAFFIC_SECRET_0 XXX XXX
```

### prop certificate

```cangjie
public mut prop certificate: ?(Array<Certificate>, PrivateKey)
```

功能：设置或获取客户端证书和对应的私钥文件。其中证书必须为 [X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate) 类型。

类型：?(Array\<[Certificate](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-certificate)>, [PrivateKey](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey))

异常：

- [TlsException](../common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - 设置的客户端证书不是 [X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate) 类型时，抛出异常。

示例：

<!-- verify -->
```cangjie
import std.io.*
import std.fs.*
import std.net.*
import std.process.*
import stdx.net.tls.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*
import stdx.net.tls.common.*

let port: UInt16 = 8443

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
        // 对服务器证书以及私钥进行解析 
        let pemString = String.fromUtf8(File.readFrom(serverCrt))
        let keyString = String.fromUtf8(File.readFrom(serverKey))

        let certificate = X509Certificate.decodeFromPem(pemString)
        let privateKey = GeneralPrivateKey.decodeFromPem(keyString)

        var config = TlsServerConfig(certificate, privateKey)

        // 设置服务端身份验证模式为校验
        config.clientIdentityRequired = Required
        config.verifyMode = CustomCA(X509Certificate.decodeFromPem(pem).map({c => c}))

        // 启动 TCP 服务器 
        try (server = TcpServerSocket(bindAt: port)) {
            // 绑定并监听 
            server.bind()
            // 接受客户端连接，如果需要多次连接，可以使用循环，参考模块下示例教程
            try (clientSocket = server.accept()) {
                // 创建 TLS 套接字并进行握手 
                try (tls = TlsSocket.server(clientSocket, serverConfig: config, session: None)) {
                    // 仅进行握手
                    tls.handshake()
                    let peerCertificate = tls.handshakeResult.getOrThrow().peerCertificate
                    // 只有开启客户端身份验证模式为校验，这里才能获取到对端证书
                    println("对端证书数量: ${peerCertificate.size}")
                    let certClient = (peerCertificate[0] as X509Certificate).getOrThrow()
                    let certRoot = (peerCertificate[1] as X509Certificate).getOrThrow()
                    println("证书链第1个-客户端终端证书 自身通用名称: ${certClient.subject.commonName ?? ""}")
                    println("证书链第2个-根CA证书 自身通用名称: ${certRoot.subject.commonName ?? ""}")
                }
            }
        }
    }
    // 等待服务器启动 
    sleep(Duration.second)

    // 客户端配置 
    var config = TlsClientConfig()
    let clientPem = String.fromUtf8(File.readFrom(clientCrt))
    let clientKeyStr = String.fromUtf8(File.readFrom(clientKey))
    let clientPriKey = GeneralPrivateKey.decodeFromPem(clientKeyStr)
    // 设置客户端证书和私钥
    config.certificate = (X509Certificate.decodeFromPem(clientPem).map({c => c}), clientPriKey)
    config.verifyMode = TrustAll

    // 连接服务器 
    try (socket = TcpSocket("127.0.0.1", port)) {
        // 首先进行 TCP 连接
        socket.connect()
        // 创建 TLS 套接字并进行握手 
        try (tls = TlsSocket.client(socket, clientConfig: config, session: None)) {
            // 仅进行握手
            let _ = tls.handshake()
        }
    } catch (e: Exception) {
        println("客户端连接失败: ${e.message}")
    }

    // 删除生成的证书和私钥文件
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
对端证书数量: 2
证书链第1个-客户端终端证书 自身通用名称: MyClient
证书链第2个-根CA证书 自身通用名称: MyRootCA
```

### prop securityLevel

```cangjie
public mut prop securityLevel: Int32
```

功能：指定客户端的安全级别，默认值为 2，可选参数值在 0-5 内，参数值含义参见 openssl 的 SSL_CTX_set_security_level 说明。

类型：Int32

示例：

<!-- verify -->
```cangjie
import stdx.net.tls.*

main() {
    // 创建一个TlsClientConfig实例
    var config = TlsClientConfig()

    // 设置安全级别
    config.securityLevel = 3

    println("安全级别设置为: ${config.securityLevel}")
}
```

运行结果：

```text
安全级别设置为: 3
```

### prop serverName

```cangjie
public mut prop serverName: ?String
```

功能：TLS 客户端的服务器名称指示（SNI，Server Name Indication）配置，属于 TLS 握手扩展字段。客户端在 TLS 握手时，向服务端声明想要访问的主机域名，让服务端返回对应域名的证书。服务端可通过握手结果获取该扩展字段。设置为 None 时，握手时不向服务端传递 SNI 扩展字段，服务端将使用当前 IP 的默认证书响应。

类型：?String

异常：

- IllegalArgumentException - 参数有 '\0' 字符时，抛出异常。

示例：

<!-- verify -->
```cangjie
import std.io.*
import std.fs.*
import std.net.*
import std.process.*
import stdx.net.tls.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*
import stdx.net.tls.common.*

main(): Unit {
    // 定义证书和私钥文件路径
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // 启动服务器
    spawn {
        // OpenSSL 官方标准、无风险的测试命令用来本地生成证书和私钥
        let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
        executeWithOutput("sh", ["-c", cmdStr])
        // 对证书以及私钥进行解析
        let pemString = String.fromUtf8(File.readFrom(serverCrt))
        let keyString = String.fromUtf8(File.readFrom(serverKey))

        let certificate = X509Certificate.decodeFromPem(pemString)
        let privateKey = GeneralPrivateKey.decodeFromPem(keyString)

        var config = TlsServerConfig(certificate, privateKey)

        // 启动 TCP 服务器
        try (server = TcpServerSocket(bindAt: 8443)) {
            // 绑定并监听
            server.bind()
            // 接受客户端连接，如果需要多次连接，可以使用循环，参考模块下示例教程
            try (clientSocket = server.accept()) {
                // 创建 TLS 套接字并进行握手
                try (tls = TlsSocket.server(clientSocket, serverConfig: config, session: None)) {
                    // 仅握手行为
                    tls.handshake()
                    println("服务端获取到客户端想要访问的主机域名是: ${tls.handshakeResult.getOrThrow().serverName}")
                }
            }
        }
    }
    // 等待服务器启动
    sleep(Duration.second)

    // 客户端配置
    var config = TlsClientConfig()
    config.verifyMode = TrustAll

    // 设置服务器名称指示，告诉服务器客户端希望访问的主机域名
    config.serverName = "localhost"
    println("客户端已设置的希望访问的主机域名是: ${config.serverName}")

    // 连接服务器
    try (socket = TcpSocket("127.0.0.1", 8443)) {
        // 首先进行 TCP 连接
        socket.connect()
        // 创建 TLS 套接字并进行握手
        try (tls = TlsSocket.client(socket, clientConfig: config, session: None)) {
            // 仅握手行为
            let _ = tls.handshake()
        }
    } catch (e: Exception) {
        println("客户端连接失败: ${e.message}")
    }
    // 删除生成的证书和私钥文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
}
```

运行结果：

```text
客户端已设置的希望访问的主机域名是: Some(localhost)
服务端获取到客户端想要访问的主机域名是: localhost
```

### prop signatureAlgorithms

```cangjie
public mut prop signatureAlgorithms: ?Array<SignatureAlgorithm>
```

功能：指定保序的签名和哈希算法。在值为 `None` 或者列表为空时，客户端会使用默认的列表。指定列表后，客户端可能不会发送不合适的签名算法。
参见 [RFC5246 7.4.1.4.1 (TLS 1.2)](https://www.rfc-editor.org/rfc/rfc5246.html#section-7.4.1.4.1) 章节， [RFC8446 4.2.3. (TLS 1.3)](https://www.rfc-editor.org/rfc/rfc8446.html#section-4.2.3) 章节。

类型：?Array\<[SignatureAlgorithm](tls_package_enums.md#enum-signaturealgorithm)>

示例：

<!-- verify -->
```cangjie
import stdx.net.tls.*

main() {
    // 创建一个TlsClientConfig实例
    var config = TlsClientConfig()

    config.signatureAlgorithms = [SignatureScheme(RSA_PSS_RSAE_SHA384)]
    println("签名算法设置为: ${config.signatureAlgorithms}")
}
```

运行结果：

```text
签名算法设置为: Some([rsa_pss_rsae_sha384])
```

### prop supportedAlpnProtocols

```cangjie
public mut prop supportedAlpnProtocols: Array<String>
```

功能：应用层协商协议，若列表为空，则客户端将不协商应用层协议。

类型：Array\<String>

异常：

- IllegalArgumentException - 列表元素有 '\0' 字符时，抛出异常。

示例：

<!-- verify -->
```cangjie
import std.io.*
import std.fs.*
import std.net.*
import std.process.*
import stdx.net.tls.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*
import stdx.net.tls.common.*

main(): Unit {
    // 定义证书和私钥文件路径
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // 启动服务器
    spawn {
        // OpenSSL 官方标准、无风险的测试命令用来本地生成证书和私钥
        let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
        executeWithOutput("sh", ["-c", cmdStr])
        // 对证书以及私钥进行解析
        let pemString = String.fromUtf8(File.readFrom(serverCrt))
        let keyString = String.fromUtf8(File.readFrom(serverKey))

        let certificate = X509Certificate.decodeFromPem(pemString)
        let privateKey = GeneralPrivateKey.decodeFromPem(keyString)

        var config = TlsServerConfig(certificate, privateKey)

        // 设置支持的ALPN协议
        config.supportedAlpnProtocols = ["h2", "http/1.1"]

        // 启动 TCP 服务器
        try (server = TcpServerSocket(bindAt: 8445)) {
            // 绑定并监听
            server.bind()
            // 接受客户端连接，如果需要多次连接，可以使用循环，参考模块下示例教程
            try (clientSocket = server.accept()) {
                // 创建 TLS 套接字并进行握手
                try (tls = TlsSocket.server(clientSocket, serverConfig: config, session: None)) {
                    // 仅握手行为
                    tls.handshake()
                    println("握手结果中的应用层协议: ${tls.handshakeResult.getOrThrow().alpnProtocol}")
                }
            }
        }
    }
    // 等待服务器启动
    sleep(Duration.second)

    // 客户端配置
    var config = TlsClientConfig()
    config.verifyMode = TrustAll

    // 设置支持的ALPN协议
    config.supportedAlpnProtocols = ["h2", "http/1.1"]

    // 连接服务器
    try (socket = TcpSocket("127.0.0.1", 8445)) {
        // 首先进行 TCP 连接
        socket.connect()
        // 创建 TLS 套接字并进行握手
        try (tls = TlsSocket.client(socket, clientConfig: config, session: None)) {
            // 仅握手行为
            let _ = tls.handshake()
        }
    } catch (e: Exception) {
        println("客户端连接失败: ${e.message}")
    }
    // 删除生成的证书和私钥文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
}
```

运行结果：

```text
握手结果中的应用层协议: h2
```

### prop supportedCipherSuites

```cangjie
public mut prop supportedCipherSuites: Map<TlsVersion, Array<String>>
```

功能：设置或获取每个 TLS 版本对应的密码套件。

类型：Map\<[TlsVersion](../common/tls_common_package_api/tls_common_package_enums.md#enum-tlsversion), Array\<String>>

异常：

- IllegalArgumentException - 通过传入 `Map` 设置密码套件时，某个 TLS 版本对应的密码套件字符串中包含空字符 `\0`，则抛出异常。

示例：

<!-- verify -->
```cangjie
import std.io.*
import std.fs.*
import std.net.*
import std.process.*
import stdx.net.tls.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*
import stdx.net.tls.common.*

main(): Unit {
    // 定义证书和私钥文件路径
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // 启动服务器
    spawn {
        // OpenSSL 官方标准、无风险的测试命令用来本地生成证书和私钥
        let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
        executeWithOutput("sh", ["-c", cmdStr])
        // 对证书以及私钥进行解析
        let pemString = String.fromUtf8(File.readFrom(serverCrt))
        let keyString = String.fromUtf8(File.readFrom(serverKey))

        let certificate = X509Certificate.decodeFromPem(pemString)
        let privateKey = GeneralPrivateKey.decodeFromPem(keyString)

        var config = TlsServerConfig(certificate, privateKey)

        // 设置支持的 TLS 版本
        config.supportedVersions = [V1_3]

        // 启动 TCP 服务器
        try (server = TcpServerSocket(bindAt: 8448)) {
            // 绑定并监听
            server.bind()
            // 接受客户端连接，如果需要多次连接，可以使用循环，参考模块下示例教程
            try (clientSocket = server.accept()) {
                // 创建 TLS 套接字并进行握手
                try (tls = TlsSocket.server(clientSocket, serverConfig: config, session: None)) {
                    // 仅握手行为
                    tls.handshake()
                    println("握手结果中的密码套件: ${tls.handshakeResult.getOrThrow().cipherSuite}")
                }
            }
        }
    }
    // 等待服务器启动
    sleep(Duration.second)

    // 客户端配置
    var config = TlsClientConfig()
    config.verifyMode = TrustAll

    // 设置支持的 TLS 版本
    config.supportedVersions = [V1_2, V1_3]
    config.supportedCipherSuites[V1_2] = ["ECDHE-RSA-AES128-GCM-SHA256"]
    config.supportedCipherSuites[V1_3] = ["TLS_AES_256_GCM_SHA384"]

    // 连接服务器
    try (socket = TcpSocket("127.0.0.1", 8448)) {
        // 首先进行 TCP 连接
        socket.connect()
        // 创建 TLS 套接字并进行握手
        try (tls = TlsSocket.client(socket, clientConfig: config, session: None)) {
            // 仅握手行为
            let _ = tls.handshake()
        }
    } catch (e: Exception) {
        println("客户端连接失败: ${e.message}")
    }
    // 删除生成的证书和私钥文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
}
```

运行结果：

```text
握手结果中的密码套件: TLS_AES_256_GCM_SHA384
```

### prop supportedVersions

```cangjie
public mut prop supportedVersions: Array<TlsVersion>
```

功能：设置或获取支持的 TLS 版本。

类型：Array\<[TlsVersion](../common/tls_common_package_api/tls_common_package_enums.md#enum-tlsversion)>

示例：
<!-- associated_example -->
参见 [prop supportedCipherSuites](#prop-supportedciphersuites) 示例。

### prop verifyMode

```cangjie
public mut prop verifyMode: CertificateVerifyMode
```

功能：设置或获取认证模式，默认值为 [CertificateVerifyMode](../common/tls_common_package_api/tls_common_package_enums.md#enum-certificateverifymode).Default，即认证系统证书。

类型：[CertificateVerifyMode](../common/tls_common_package_api/tls_common_package_enums.md#enum-certificateverifymode)

示例：

<!-- run -->
```cangjie
import std.io.*
import std.fs.*
import std.net.*
import std.process.*
import stdx.net.tls.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*
import stdx.net.tls.common.*

let port: UInt16 = 8443

main(): Unit {
    // OpenSSL 官方标准、无风险的测试命令用来本地生成证书和私钥
    // 生成服务器私钥、证书、证书请求路径
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"
    let serverCsr = "./server.csr"

    // 根证书/私钥路径
    let rootCrt = "./rootCA.crt"
    let rootKey = "./rootCA.key"

    // 生成根CA证书
    let rootCmd = "openssl req -x509 -newkey rsa:4096 -nodes -keyout ${rootKey} -out ${rootCrt} -days 3650 -subj \"/C=CN/ST=Beijing/L=Beijing/O=MyCA/OU=CA/CN=MyRootCA\""
    executeWithOutput("sh", ["-c", rootCmd])

    // 生成服务器私钥+证书请求（CSR） 
    let csrCmd = "openssl req -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCsr} -subj \"/C=CN/ST=Beijing/L=Beijing/O=MyServer/OU=Server/CN=localhost\""
    executeWithOutput("sh", ["-c", csrCmd])

    // 用根CA签发服务器证书
    let signCmd = "openssl x509 -req -in ${serverCsr} -CA ${rootCrt} -CAkey ${rootKey} -CAcreateserial -out ${serverCrt} -days 365 -sha256"
    executeWithOutput("sh", ["-c", signCmd])

    // 读取根证书PEM
    let pem = String.fromUtf8(File.readFrom(rootCrt))

    // 启动服务器 
    spawn {
        // 对服务器证书以及私钥进行解析 
        let pemString = String.fromUtf8(File.readFrom(serverCrt))
        let keyString = String.fromUtf8(File.readFrom(serverKey))

        let certificate = X509Certificate.decodeFromPem(pemString)
        let privateKey = GeneralPrivateKey.decodeFromPem(keyString)

        var config = TlsServerConfig(certificate, privateKey)

        // 启动 TCP 服务器 
        try (server = TcpServerSocket(bindAt: port)) {
            // 绑定并监听 
            server.bind()
            // 接受客户端连接，如果需要多次连接，可以使用循环，参考模块下示例教程
            try (clientSocket = server.accept()) {
                // 创建 TLS 套接字并进行握手 
                try (tls = TlsSocket.server(clientSocket, serverConfig: config, session: None)) {
                    // 仅进行握手
                    tls.handshake()
                }
            }
        }
    }
    // 等待服务器启动 
    sleep(Duration.second)

    // 客户端配置 
    var config = TlsClientConfig()

    // 设置认证模式：根据提供的 CA 列表与系统 CA 验证服务端的证书
    config.verifyMode = CustomCA(X509Certificate.decodeFromPem(pem).map({c => c}))

    // 连接服务器 
    try (socket = TcpSocket("127.0.0.1", port)) {
        // 首先进行 TCP 连接
        socket.connect()
        // 创建 TLS 套接字并进行握手 
        try (tls = TlsSocket.client(socket, clientConfig: config, session: None)) {
            // 仅进行握手
            let _ = tls.handshake()
        }
    } catch (e: Exception) {
        println("客户端连接失败: ${e.message}")
    }

    // 删除生成的证书和私钥文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
    removeIfExists(serverCsr)
    removeIfExists(rootCrt)
    removeIfExists(rootKey)
}
```

### init()

```cangjie
public init()
```

功能：构造 [TlsClientConfig](tls_package_structs.md#struct-tlsclientconfig)。

示例：

<!-- run -->
```cangjie
import stdx.net.tls.*
import stdx.net.tls.common.*

main() {
    // 客户端配置
    var config = TlsClientConfig()
    config.verifyMode = TrustAll
    return 0
}
```

## struct TlsServerConfig

```cangjie
public struct TlsServerConfig <: TlsConfig {
    public var keylogCallback: ?(TlsSocket, String) -> Unit = None
    public init(certChain: Array<X509Certificate>, certKey: PrivateKey)
}
```

父类型：

- [TlsConfig](../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconfig)

功能：服务端配置。

### var keylogCallback

```cangjie
public var keylogCallback: ?(TlsSocket, String) -> Unit = None
```

功能：握手过程的回调函数，提供 TLS 初始秘钥数据，用于调试和解密记录使用。

> **注意：**
>
> 严禁在生产环境中使用此回调：传入的字符串参数属于敏感数据，泄露其内容会严重危及连接安全。

类型：?([TlsSocket](tls_package_classes.md#class-tlssocket), String) -> Unit

示例：

<!-- run -->
```cangjie
import std.io.*
import std.fs.*
import std.net.*
import std.process.*
import stdx.net.tls.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*
import stdx.net.tls.common.*

main(): Unit {
    // 定义证书和私钥文件路径
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // 启动服务器
    spawn {
        // OpenSSL 官方标准、无风险的测试命令用来本地生成证书和私钥
        let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
        executeWithOutput("sh", ["-c", cmdStr])
        // 对证书以及私钥进行解析
        let pemString = String.fromUtf8(File.readFrom(serverCrt))
        let keyString = String.fromUtf8(File.readFrom(serverKey))

        let certificate = X509Certificate.decodeFromPem(pemString)
        let privateKey = GeneralPrivateKey.decodeFromPem(keyString)

        var config = TlsServerConfig(certificate, privateKey)

        // 设置握手过程的回调函数
        config.keylogCallback = {
            _, secret => println("服务端秘钥数据: ${secret}")
        }

        // 启动 TCP 服务器
        try (server = TcpServerSocket(bindAt: 8443)) {
            // 绑定并监听
            server.bind()
            // 接受客户端连接
            try (clientSocket = server.accept()) {
                // 创建 TLS 套接字并进行握手
                try (tls = TlsSocket.server(clientSocket, serverConfig: config, session: None)) {
                    // 握手成功就会触发回调
                    tls.handshake()
                }
            }
        }
    }
    // 等待服务器启动
    sleep(Duration.second)

    // 客户端配置
    var config = TlsClientConfig()
    config.verifyMode = TrustAll

    // 连接服务器
    try (socket = TcpSocket("127.0.0.1", 8443)) {
        // 首先进行 TCP 连接
        socket.connect()
        // 创建 TLS 套接字并进行握手
        try (tls = TlsSocket.client(socket, clientConfig: config, session: None)) {
            // 仅握手
            let _ = tls.handshake()
        }
    } catch (e: Exception) {
        println("客户端连接失败: ${e.message}")
    }
    // 删除生成的证书和私钥文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
}
```

可能的运行结果：

```text
服务端秘钥数据: SERVER_HANDSHAKE_TRAFFIC_SECRET XXX XXX
服务端秘钥数据: CLIENT_HANDSHAKE_TRAFFIC_SECRET XXX XXX
服务端秘钥数据: EXPORTER_SECRET XXX XXX
服务端秘钥数据: SERVER_TRAFFIC_SECRET_0 XXX XXX
服务端秘钥数据: CLIENT_TRAFFIC_SECRET_0 XXX XXX
```

### prop certificate

```cangjie
public mut prop certificate: ?(Array<Certificate>, PrivateKey)
```

功能：设置或获取服务端证书和对应的私钥文件。其中证书必须为 [X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate) 类型。不可设置为 None。

类型：?(Array\<[Certificate](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-certificate)>, [PrivateKey](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey))

异常：

- [TlsException](../common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - 设置的服务端证书不是 [X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate) 类型时，抛出异常；设置服务端证书和对应的私钥文件为 None 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import std.io.*
import std.fs.*
import std.process.*
import stdx.net.tls.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main(): Unit {
    // 定义证书和私钥文件路径
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // OpenSSL 官方标准、无风险的测试命令用来本地生成证书和私钥
    let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
    executeWithOutput("sh", ["-c", cmdStr])

    // 对证书以及私钥进行解析
    let pemString = String.fromUtf8(File.readFrom(serverCrt))
    let keyString = String.fromUtf8(File.readFrom(serverKey))
    let certificate = X509Certificate.decodeFromPem(pemString)
    let privateKey = GeneralPrivateKey.decodeFromPem(keyString)

    // 创建 TLS 服务器配置
    var config = TlsServerConfig(certificate, privateKey)

    // 获取配置中的证书并进行比较
    let x509Cert = (config.certificate.getOrThrow()[0][0] as X509Certificate).getOrThrow()
    println("是否和初始化时的证书是同一个? ${x509Cert == certificate[0]}")

    // 删除生成的证书和私钥文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
}
```

运行结果：

```text
是否和初始化时的证书是同一个? true
```

### prop clientIdentityRequired

```cangjie
public mut prop clientIdentityRequired: TlsClientIdentificationMode
```

功能：设置或获取服务端要求客户端的认证模式，默认值为 [TlsClientIdentificationMode](tls_package_enums.md#enum-tlsclientidentificationmode).Disable，即不要求客户端认证服务端证书，也不要求客户端发送本端证书。

类型：[TlsClientIdentificationMode](tls_package_enums.md#enum-tlsclientidentificationmode)

示例：
<!-- associated_example -->
参见 [prop certificate](#prop-certificate) 示例。

### prop dhParameters

```cangjie
public mut prop dhParameters: ?DHParameters
```

功能：指定服务端的 DH 密钥参数，默认为 `None`， 默认情况下使用 openssl 自动生成的参数值。

类型：?[DHParameters](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-dhparameters)

示例：

<!-- verify -->
```cangjie
import std.io.*
import std.fs.*
import std.process.*
import stdx.net.tls.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main(): Unit {
    // 定义证书和私钥文件路径
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // OpenSSL 官方标准、无风险的测试命令用来本地生成证书和私钥
    let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
    executeWithOutput("sh", ["-c", cmdStr])

    // 对证书以及私钥进行解析
    let pemString = String.fromUtf8(File.readFrom(serverCrt))
    let keyString = String.fromUtf8(File.readFrom(serverKey))
    let certificate = X509Certificate.decodeFromPem(pemString)
    let privateKey = GeneralPrivateKey.decodeFromPem(keyString)

    var config = TlsServerConfig(certificate, privateKey)

    // 获取当前的 dhParameters 值
    let currentDhParams = config.dhParameters
    println("当前 DH 参数值: ${currentDhParams}")

    // 删除生成的证书和私钥文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
}
```

运行结果：

```text
当前 DH 参数值: None
```

### prop securityLevel

```cangjie
public mut prop securityLevel: Int32
```

功能：指定服务端的安全级别，默认值为 2，可选参数值在 [0,5] 内，参数值含义参见 [openssl-SSL_CTX_set_security_level](https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_security_level/) 说明。

类型：Int32

异常：

- IllegalArgumentException - 当配置值不在 0-5 范围内时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.net.tls.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*
import std.fs.*
import std.process.*
import std.io.*

main() {
    // 创建一个TlsServerConfig实例（需要证书和私钥参数）
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // 生成测试用的证书和私钥
    let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
    executeWithOutput("sh", ["-c", cmdStr])

    // 读取证书和私钥
    let pemString = String.fromUtf8(File.readFrom(serverCrt))
    let keyString = String.fromUtf8(File.readFrom(serverKey))
    let certificate = X509Certificate.decodeFromPem(pemString)
    let privateKey = GeneralPrivateKey.decodeFromPem(keyString)

    // 创建服务器配置
    var config = TlsServerConfig(certificate, privateKey)

    // 设置安全级别
    config.securityLevel = 3
    println("服务端安全级别设置为: ${config.securityLevel}")

    // 清理临时文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
    return 0
}
```

运行结果：

```text
服务端安全级别设置为: 3
```

### prop supportedAlpnProtocols

```cangjie
public mut prop supportedAlpnProtocols: Array<String>
```

功能：应用层协商协议，若客户端尝试协商该协议，服务端将与选取其中相交的协议名称。若客户端未尝试协商协议，则该配置将被忽略。

类型：Array\<String>

异常：

- IllegalArgumentException - 列表元素有 '\0' 字符时，抛出异常。

示例：
<!-- associated_example -->
参见 [prop supportedAlpnProtocols](#prop-supportedalpnprotocols) 示例。

### prop supportedCipherSuites

```cangjie
public mut prop supportedCipherSuites: Map<TlsVersion, Array<String>>
```

功能：设置或获取每个 TLS 版本对应的密码套件。

类型：Map\<[TlsVersion](../common/tls_common_package_api/tls_common_package_enums.md#enum-tlsversion), Array\<String>>

异常：

- IllegalArgumentException - 通过传入 `Map` 设置密码套件时，某个 TLS 版本对应的密码套件字符串中包含空字符 `\0`，则抛出异常。

示例：

<!-- verify -->
```cangjie
import std.io.*
import std.fs.*
import std.net.*
import std.process.*
import stdx.net.tls.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*
import stdx.net.tls.common.*

main(): Unit {
    // 定义证书和私钥文件路径
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // 启动服务器
    spawn {
        // OpenSSL 官方标准、无风险的测试命令用来本地生成证书和私钥
        let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
        executeWithOutput("sh", ["-c", cmdStr])
        // 对证书以及私钥进行解析
        let pemString = String.fromUtf8(File.readFrom(serverCrt))
        let keyString = String.fromUtf8(File.readFrom(serverKey))

        let certificate = X509Certificate.decodeFromPem(pemString)
        let privateKey = GeneralPrivateKey.decodeFromPem(keyString)

        var config = TlsServerConfig(certificate, privateKey)

        // 设置支持的密码套件
        config.supportedVersions = [TlsVersion.V1_2, TlsVersion.V1_3]
        config.supportedCipherSuites[TlsVersion.V1_2] = ["ECDHE-RSA-AES128-GCM-SHA256"]
        config.supportedCipherSuites[TlsVersion.V1_3] = ["TLS_AES_256_GCM_SHA384"]
        println("服务端支持的 TLS 1.2 密码套件: ${config.supportedCipherSuites[TlsVersion.V1_2]}")
        println("服务端支持的 TLS 1.3 密码套件: ${config.supportedCipherSuites[TlsVersion.V1_3]}")

        // 启动 TCP 服务器
        try (server = TcpServerSocket(bindAt: 8449)) {
            // 绑定并监听
            server.bind()
            // 接受客户端连接
            try (clientSocket = server.accept()) {
                // 创建 TLS 套接字并进行握手
                try (tls = TlsSocket.server(clientSocket, serverConfig: config, session: None)) {
                    // 仅握手行为
                    tls.handshake()
                    println("握手结果中的密码套件: ${tls.handshakeResult.getOrThrow().cipherSuite}")
                }
            }
        }
    }
    // 等待服务器启动
    sleep(Duration.second)

    // 客户端配置
    var config = TlsClientConfig()
    config.verifyMode = TrustAll

    // 设置支持的密码套件
    config.supportedVersions = [TlsVersion.V1_2, TlsVersion.V1_3]
    config.supportedCipherSuites[TlsVersion.V1_2] = ["ECDHE-RSA-AES128-GCM-SHA256"]
    config.supportedCipherSuites[TlsVersion.V1_3] = ["TLS_AES_256_GCM_SHA384"]

    // 连接服务器
    try (socket = TcpSocket("127.0.0.1", 8449)) {
        // 首先进行 TCP 连接
        socket.connect()
        // 创建 TLS 套接字并进行握手
        try (tls = TlsSocket.client(socket, clientConfig: config, session: None)) {
            // 仅握手行为
            let _ = tls.handshake()
        }
    } catch (e: Exception) {
        println("客户端连接失败: ${e.message}")
    }
    // 删除生成的证书和私钥文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
}
```

运行结果：

```text
服务端支持的 TLS 1.2 密码套件: [ECDHE-RSA-AES128-GCM-SHA256]
服务端支持的 TLS 1.3 密码套件: [TLS_AES_256_GCM_SHA384]
握手结果中的密码套件: TLS_AES_256_GCM_SHA384
```

### prop supportedVersions

```cangjie
public mut prop supportedVersions: Array<TlsVersion>
```

功能：设置或获取支持的 TLS 版本。

类型：Array\<[TlsVersion](../common/tls_common_package_api/tls_common_package_enums.md#enum-tlsversion)>

示例：
<!-- associated_example -->
参见 [prop supportedCipherSuites](#prop-supportedversions-1) 示例。

### prop verifyMode

```cangjie
public mut prop verifyMode: CertificateVerifyMode
```

功能：设置或获取认证模式，默认值为 [CertificateVerifyMode](../common/tls_common_package_api/tls_common_package_enums.md#enum-certificateverifymode).Default，即认证系统证书。

类型：[CertificateVerifyMode](../common/tls_common_package_api/tls_common_package_enums.md#enum-certificateverifymode)

示例：
<!-- associated_example -->
参见 [prop certificate](#prop-certificate) 示例。

### init(Array\<X509Certificate>, PrivateKey)

```cangjie
public init(certChain: Array<X509Certificate>, certKey: PrivateKey)
```

功能：构造 [TlsServerConfig](tls_package_structs.md#struct-tlsserverconfig) 对象。

参数：

- certChain: Array\<[X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate)> - 证书对象。
- certKey: [PrivateKey](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey) - 私钥对象。

示例：

<!-- run -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*
import stdx.net.tls.*

main() {
    // 定义证书和私钥文件
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // OpenSSL 官方标准、无风险的测试用命令
    let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
    executeWithOutput("sh", ["-c", cmdStr])

    // 获取证书和私钥内容
    let serverCrtContent = String.fromUtf8(File.readFrom(serverCrt))
    let serverCertificate = X509Certificate.decodeFromPem(serverCrtContent)

    let serverKeyContent = String.fromUtf8(File.readFrom(serverKey))
    let serverPrivateKey = GeneralPrivateKey.decodeFromPem(serverKeyContent)

    // 创建 TLS 服务器配置
    let _ = TlsServerConfig(serverCertificate, serverPrivateKey)

    // 删除证书和私钥文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
    return 0
}
```
