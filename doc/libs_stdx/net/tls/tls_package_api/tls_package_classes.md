# 类

## class DefaultTlsKit

```cangjie
public class DefaultTlsKit <: TlsKit
```

功能：[TlsKit](../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlskit) 的默认实现。用于获取 TLS 服务端、客户端连接和服务端会话。

父类型：

- [TlsKit](../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlskit)

### func getTlsClient(StreamingSocket, TlsConfig, ?TlsSession)

```cangjie
public func getTlsClient(socket: StreamingSocket, config: TlsConfig, session!: ?TlsSession): TlsConnection
```

功能：根据传入的 StreamingSocket 实例创建客户端 TLS 连接，该连接可用于 TLS 握手。

参数：

- socket: StreamingSocket - TCP 连接建立完成后得到的 socket。
- config: [TlsConfig](../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconfig) - 客户端 TLS 配置。
- session!: ?[TlsSession](../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlssession) - TLS 会话。若存在可用的 TLS 会话，则可通过该会话恢复，省去 TLS 建立连接时间。

返回值：

- [TlsConnection](../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconnection) - 构造出的客户端 TLS 连接。

示例：

<!-- verify -->
```cangjie
import std.net.*
import stdx.net.tls.*
import stdx.net.tls.common.*

main() {
    // 创建默认 TLS 套件
    let tlsKit = DefaultTlsKit()

    // 创建 TCP 连接
    let tcpSocket = TcpSocket("127.0.0.1", 8443)

    // 创建 TLS 配置
    var config = TlsClientConfig()
    config.verifyMode = CertificateVerifyMode.TrustAll

    // 获取 TLS 客户端连接
    let tlsConnection = tlsKit.getTlsClient(tcpSocket, config, session: None)
    let handshakeResult = tlsConnection.handshakeResult

    println("已获取客户端 TLS 连接，握手结果: ${handshakeResult?.alpnProtocol ?? "未连接"}")
    return 0
}
```

运行结果：

```text
已获取客户端 TLS 连接，握手结果: 未连接
```

### func getTlsServer(StreamingSocket, TlsConfig, ?TlsSession)

```cangjie
public func getTlsServer(socket: StreamingSocket, config: TlsConfig, session!: ?TlsSession): TlsConnection
```

功能：根据传入的 StreamingSocket 实例创建服务端 TLS 连接，该连接可用于 TLS 握手。

参数：

- socket: StreamingSocket - TCP 连接建立完成后得到的 socket。
- config: [TlsConfig](../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconfig) - 服务端 TLS 配置。
- session!: ?[TlsSession](../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlssession) - TLS 会话。若存在可用的 TLS 会话，则可通过该会话恢复，省去 TLS 建立连接时间。

返回值：

- [TlsConnection](../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconnection) - 构造出的服务端 TLS 连接。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*
import stdx.net.tls.*
import std.net.*

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
    let config = TlsServerConfig(serverCertificate, serverPrivateKey)

    // 创建默认 TLS 套件
    let tlsKit = DefaultTlsKit()

    // 创建 TCP 套接字
    let tcpSocket = TcpSocket("127.0.0.1", 8443)

    // 获取 TLS 服务端连接
    let tlsConnection = tlsKit.getTlsServer(tcpSocket, config, session: None)
    let handshakeResult = tlsConnection.handshakeResult

    println("已获取服务端 TLS 连接，握手结果: ${handshakeResult?.alpnProtocol ?? "未连接"}")

    // 删除证书和私钥文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
    return 0
}
```

运行结果：

```text
已获取服务端 TLS 连接，握手结果: 未连接
```

### func getTlsServerSession(String)

```cangjie
public func getTlsServerSession(name: String): TlsSession
```

功能：通过名称创建 [TlsSession](../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlssession) 实例，该名称用于区分 TLS 服务器。

参数：

- name: String - 会话名称。

返回值：

- [TlsSession](../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlssession) - 创建的 [TlsSession](../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlssession) 实例。

示例：

<!-- verify -->
```cangjie
import stdx.net.tls.*

main() {
    // 创建默认 TLS 套件
    let tlsKit = DefaultTlsKit()

    // 获取 TLS 服务端会话
    let tlsSession = tlsKit.getTlsServerSession("test_server_session")

    // 转换为 TlsServerSession 方便打印
    let tlsServerSession = tlsSession as TlsServerSession
    println("已获取服务端 TLS 会话，会话名称: ${tlsServerSession?.toString() ?? ""}")
    return 0
}
```

运行结果：

```text
已获取服务端 TLS 会话，会话名称: TlsServerSession(test_server_session)
```

## class KeylessTlsServerConfig

```cangjie
public class KeylessTlsServerConfig <: TlsConfig {
    public init(certChain: Array<X509Certificate>, signCallback: KeylessSignFunc, decryptCallback!: ?KeylessDecryptFunc = None<KeylessDecryptFunc>)
}
```

功能：提供无私钥握手的服务端配置。

> **注意：**
>
> 暂只支持 ECDHE-RSA-AES256-GCM-SHA384, TLS_AES_256_GCM_SHA384, TLS_CHACHA20_POLY1305_SHA256 三种算法套，其余算法套不保证可用性。

父类型：

- [TlsConfig](../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconfig)

### var keylogCallback

```cangjie
public var keylogCallback: ?(TlsSocket, String) -> Unit = None
```

功能：握手过程的回调函数，提供 TLS 初始秘钥数据，用于调试和解密记录使用。

类型：?([TlsSocket](tls_package_classes.md#class-tlssocket), String) -> Unit

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.x509.*
import stdx.net.tls.*

main() {
    // 定义证书和私钥文件
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // OpenSSL 官方标准、无风险的测试用命令
    let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
    executeWithOutput("sh", ["-c", cmdStr])

    // 获取证书
    let serverCrtContent = String.fromUtf8(File.readFrom(serverCrt))
    let serverCertificate = X509Certificate.decodeFromPem(serverCrtContent)

    let config = KeylessTlsServerConfig(serverCertificate, keylessSignFunc)
    config.keylogCallback = myKeylogCallback
    println("发生在TLS握手的回调: ${config.keylogCallback.isSome()}")

    // 删除证书和私钥文件
    removeIfExists(serverCrt)
    removeIfExists(serverKey)
    return 0
}

public func keylessSignFunc(data: Array<Byte>): Array<Byte> {
    println("此处模拟调用外部密钥服务器完成签名操作")
    return data
}

func myKeylogCallback(_: TlsSocket, keyLog: String) {
    // 仅打印核心的密钥日志（忽略socket）
    println(keyLog)
}
```

运行结果：

```text
发生在TLS握手的回调: true
```

### prop certificate

```cangjie
public mut prop certificate: ?(Array<Certificate>, PrivateKey)
```

功能：设置或获取服务端证书和对应的私钥文件。其中证书必须为 [X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate) 类型。不可设置为 None。

> **注意：**
>
> 该属性返回的 `PrivateKey` 是一个无意义的 dummy key，与 `Array<Certifiace>` 无关。

类型：?(Array\<[Certificate](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-certificate)>, [PrivateKey](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey))

异常：

- [TlsException](../common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - 设置的服务端证书不是 [X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate) 类型时，抛出异常；设置服务端证书和对应的私钥文件为 None 时，抛出异常。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.x509.*
import stdx.net.tls.*

main() {
    // 定义证书和私钥文件
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // OpenSSL 官方标准、无风险的测试用命令
    let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
    executeWithOutput("sh", ["-c", cmdStr])

    // 获取证书
    let serverCrtContent = String.fromUtf8(File.readFrom(serverCrt))
    let serverCertificate = X509Certificate.decodeFromPem(serverCrtContent)

    let config = KeylessTlsServerConfig(serverCertificate, keylessSignFunc)

    if (let Some(certificate) <- config.certificate) {
        // 获取证书并转换为 X509Certificate 类型
        let cert = (certificate[0][0] as X509Certificate).getOrThrow()
        println("X509证书实体的通用名称: ${cert.issuer.commonName ?? ""}")
    }

    // 删除证书和私钥文件
    removeIfExists(serverCrt)
    removeIfExists(serverKey)
    return 0
}

public func keylessSignFunc(data: Array<Byte>): Array<Byte> {
    println("此处模拟调用外部密钥服务器完成签名操作")
    return data
}
```

运行结果：

```text
X509证书实体的通用名称: localhost
```

### prop clientIdentityRequired

```cangjie
public mut prop clientIdentityRequired: TlsClientIdentificationMode
```

功能：设置或获取服务端要求客户端的认证模式，默认值为 [TlsClientIdentificationMode](tls_package_enums.md#enum-tlsclientidentificationmode).Disable，即不要求客户端认证服务端证书，也不要求客户端发送本端证书。

类型：[TlsClientIdentificationMode](tls_package_enums.md#enum-tlsclientidentificationmode)

示例：

<!-- run -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.x509.*
import stdx.net.tls.*

main() {
    // 定义证书和私钥文件
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // OpenSSL 官方标准、无风险的测试用命令
    let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
    executeWithOutput("sh", ["-c", cmdStr])

    // 获取证书
    let serverCrtContent = String.fromUtf8(File.readFrom(serverCrt))
    let serverCertificate = X509Certificate.decodeFromPem(serverCrtContent)

    let config = KeylessTlsServerConfig(serverCertificate, keylessSignFunc)

    // 设置双向认证模式
    config.clientIdentityRequired = TlsClientIdentificationMode.Required

    // 删除证书和私钥文件
    removeIfExists(serverCrt)
    removeIfExists(serverKey)
    return 0
}

public func keylessSignFunc(data: Array<Byte>): Array<Byte> {
    return data
}
```

### prop dhParameters

```cangjie
public mut prop dhParameters: ?DHParameters
```

功能：指定服务端的 DH 密钥参数，默认为 `None`， 默认情况下使用 openssl 自动生成的参数值。

类型：?[DHParameters](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-dhparameters)

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.x509.*
import stdx.net.tls.*

main() {
    // 定义证书和私钥文件
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // OpenSSL 官方标准、无风险的测试用命令
    let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
    executeWithOutput("sh", ["-c", cmdStr])

    // 获取证书
    let serverCrtContent = String.fromUtf8(File.readFrom(serverCrt))
    let serverCertificate = X509Certificate.decodeFromPem(serverCrtContent)

    let config = KeylessTlsServerConfig(serverCertificate, keylessSignFunc)

    // 默认情况下使用 openssl 自动生成的参数值
    println("服务端的 DH 密钥参数: ${config.dhParameters}")

    // 删除证书和私钥文件
    removeIfExists(serverCrt)
    removeIfExists(serverKey)
    return 0
}

public func keylessSignFunc(data: Array<Byte>): Array<Byte> {
    return data
}
```

运行结果：

```text
服务端的 DH 密钥参数: None
```

### prop securityLevel

```cangjie
public mut prop securityLevel: Int32
```

功能：指定服务端的安全级别，默认值为 2，可选参数值在 [0,5] 内，参数值含义参见 [openssl-SSL_CTX_set_security_level](https://www.openssl.org/docs/man1.1.1/man3/SSL_CTX_set_security_level.html) 说明。

类型：Int32

异常：

- IllegalArgumentException - 当配置值不在 0-5 范围内时，抛出异常。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.x509.*
import stdx.net.tls.*

main() {
    // 定义证书和私钥文件
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // OpenSSL 官方标准、无风险的测试用命令
    let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
    executeWithOutput("sh", ["-c", cmdStr])

    // 获取证书
    let serverCrtContent = String.fromUtf8(File.readFrom(serverCrt))
    let serverCertificate = X509Certificate.decodeFromPem(serverCrtContent)

    let config = KeylessTlsServerConfig(serverCertificate, keylessSignFunc)
    config.securityLevel = 2 // 设置安全级别为默认值

    println("安全级别已设置为: ${config.securityLevel}")

    // 删除证书和私钥文件
    removeIfExists(serverCrt)
    removeIfExists(serverKey)
    return 0
}

public func keylessSignFunc(data: Array<Byte>): Array<Byte> {
    return data
}
```

运行结果：

```text
安全级别已设置为: 2
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

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.x509.*
import stdx.net.tls.*

main() {
    // 定义证书和私钥文件
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // OpenSSL 官方标准、无风险的测试用命令
    let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
    executeWithOutput("sh", ["-c", cmdStr])

    // 获取证书
    let serverCrtContent = String.fromUtf8(File.readFrom(serverCrt))
    let serverCertificate = X509Certificate.decodeFromPem(serverCrtContent)

    let config = KeylessTlsServerConfig(serverCertificate, keylessSignFunc)
    config.supportedAlpnProtocols = ["http/1.1", "h2"] // 设置支持的 ALPN 协议

    println("支持的 ALPN 协议: ${config.supportedAlpnProtocols}")

    // 删除证书和私钥文件
    removeIfExists(serverCrt)
    removeIfExists(serverKey)
    return 0
}

public func keylessSignFunc(data: Array<Byte>): Array<Byte> {
    return data
}
```

运行结果：

```text
支持的 ALPN 协议: [http/1.1, h2]
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

<!-- run -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import std.collection.*
import stdx.crypto.x509.*
import stdx.net.tls.*
import stdx.net.tls.common.*

main() {
    // 定义证书和私钥文件
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // OpenSSL 官方标准、无风险的测试用命令
    let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
    executeWithOutput("sh", ["-c", cmdStr])

    // 获取证书
    let serverCrtContent = String.fromUtf8(File.readFrom(serverCrt))
    let serverCertificate = X509Certificate.decodeFromPem(serverCrtContent)

    let config = KeylessTlsServerConfig(serverCertificate, keylessSignFunc)

    // 设置 TLS 1.2 和 1.3 支持的密码套件
    var cipherSuites = HashMap<TlsVersion, Array<String>>()
    cipherSuites[TlsVersion.V1_2] = ["TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"]
    cipherSuites[TlsVersion.V1_3] = ["TLS_AES_256_GCM_SHA384"]
    config.supportedCipherSuites = cipherSuites

    // 删除证书和私钥文件
    removeIfExists(serverCrt)
    removeIfExists(serverKey)
    return 0
}

public func keylessSignFunc(data: Array<Byte>): Array<Byte> {
    return data
}
```

### prop supportedVersions

```cangjie
public mut prop supportedVersions: Array<TlsVersion>
```

功能：设置或获取支持的 TLS 版本。

类型：Array\<[TlsVersion](../common/tls_common_package_api/tls_common_package_enums.md#enum-tlsversion)>

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.x509.*
import stdx.net.tls.*
import stdx.net.tls.common.*

main() {
    // 定义证书和私钥文件
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // OpenSSL 官方标准、无风险的测试用命令
    let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
    executeWithOutput("sh", ["-c", cmdStr])

    // 获取证书
    let serverCrtContent = String.fromUtf8(File.readFrom(serverCrt))
    let serverCertificate = X509Certificate.decodeFromPem(serverCrtContent)

    let config = KeylessTlsServerConfig(serverCertificate, keylessSignFunc)
    config.supportedVersions = [TlsVersion.V1_2, TlsVersion.V1_3] // 支持 TLS 1.2 和 1.3 版本

    println("支持的 TLS 版本数量: ${config.supportedVersions.size}")

    // 删除证书和私钥文件
    removeIfExists(serverCrt)
    removeIfExists(serverKey)
    return 0
}

public func keylessSignFunc(data: Array<Byte>): Array<Byte> {
    return data
}
```

运行结果：

```text
支持的 TLS 版本数量: 2
```

### prop verifyMode

```cangjie
public mut prop verifyMode: CertificateVerifyMode
```

功能：设置或获取认证模式，默认值为 [CertificateVerifyMode](../common/tls_common_package_api/tls_common_package_enums.md#enum-certificateverifymode).Default，即认证系统证书。

类型：[CertificateVerifyMode](../common/tls_common_package_api/tls_common_package_enums.md#enum-certificateverifymode)

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.x509.*
import stdx.net.tls.*
import stdx.net.tls.common.*

main() {
    // 定义证书和私钥文件
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // OpenSSL 官方标准、无风险的测试用命令
    let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
    executeWithOutput("sh", ["-c", cmdStr])

    // 获取证书
    let serverCrtContent = String.fromUtf8(File.readFrom(serverCrt))
    let serverCertificate = X509Certificate.decodeFromPem(serverCrtContent)

    let config = KeylessTlsServerConfig(serverCertificate, keylessSignFunc)
    config.verifyMode = CertificateVerifyMode.TrustAll // 设置为信任所有证书

    println("证书验证模式已设置为: TrustAll")

    // 删除证书和私钥文件
    removeIfExists(serverCrt)
    removeIfExists(serverKey)
    return 0
}

public func keylessSignFunc(data: Array<Byte>): Array<Byte> {
    return data
}
```

运行结果：

```text
证书验证模式已设置为: TrustAll
```

### init(Array\<X509Certificate>, KeylessSignFunc, ?KeylessDecryptFunc)

```cangjie
public init(certChain: Array<X509Certificate>, signCallback: KeylessSignFunc, decryptCallback!: ?KeylessDecryptFunc = None<KeylessDecryptFunc>)
```

功能：构造 [KeylessTlsServerConfig](./tls_package_classes.md#class-keylesstlsserverconfig) 对象。

参数：

- certChain: Array\<[X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate)> - 证书对象。
- signCallback: [KeylessSignFunc](./tls_package_type.md#type-keylesssignfunc) - 签名回调函数。
- decryptCallback!: ?[KeylessDecryptFunc](./tls_package_type.md#type-keylessdecryptfunc) - 解密回调函数，默认为 None\<[KeylessDecryptFunc](./tls_package_type.md#type-keylessdecryptfunc)>。

异常：

- IllegalArgumentException - 当 `certChain` 为空时，抛出异常。

示例：

<!-- run -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.x509.*
import stdx.net.tls.*

main() {
    // 定义证书和私钥文件
    let serverKey = "./server.key"
    let serverCrt = "./server.crt"

    // OpenSSL 官方标准、无风险的测试用命令
    let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
    executeWithOutput("sh", ["-c", cmdStr])

    // 获取证书
    let serverCrtContent = String.fromUtf8(File.readFrom(serverCrt))
    let serverCertificate = X509Certificate.decodeFromPem(serverCrtContent)

    let config = KeylessTlsServerConfig(serverCertificate, keylessSignFunc)

    // 删除证书和私钥文件
    removeIfExists(serverCrt)
    removeIfExists(serverKey)
    return 0
}

public func keylessSignFunc(data: Array<Byte>): Array<Byte> {
    println("此处模拟调用外部密钥服务器完成签名操作")
    return data
}
```

## class TlsClientSession

```cangjie
public class TlsClientSession <: TlsSession & Equatable<TlsClientSession> & ToString & Hashable
```

功能：此结构体表示已建立的客户端会话。此结构体实例用户不可创建，其内部结构对用户不可见。

当客户端 TLS 握手成功后，将会生成一个会话，当连接因一些原因丢失后，客户端可以通过这个会话 id 复用此次会话，省略握手流程。

父类型：

- [TlsSession](../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlssession)
- Equatable\<[TlsClientSession](#class-tlsclientsession)>
- ToString
- Hashable

### func hashCode()

```cangjie
public override func hashCode(): Int64
```

功能：生成会话 id 哈希值。

返回值：

- Int64 - 会话 id 哈希值。

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

main() {
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
                    // 此处握手之后就关闭链接
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

    // 用于恢复会话
    var lastSession: ?TlsClientSession = None

    // 连接服务器
    try (socket = TcpSocket("127.0.0.1", 8443)) {
        // 首先进行 TCP 连接
        socket.connect()
        // 创建 TLS 套接字并进行握手
        try (tls = TlsSocket.client(socket, clientConfig: config, session: lastSession)) {
            try {
                let result = tls.handshake()
                // 读取数据时，关闭了链接
                tls.read(Array<Byte>(3, repeat: 0))

                // 成功协商下一次重新连接，将记住会话
                lastSession = match (result.session) {
                    case Some(r) => r as TlsClientSession
                    case None => None
                }
            } catch (e: Exception) {
                // 如果协商失败，将删除会话
                lastSession = None
                throw e
            }
            // 发送数据
            tls.write("这是一个由客户端发送的消息".toArray())
        }
    } catch (e: Exception) {
        println("客户端连接失败: ${e.message}")
    }
    // 删除生成的证书和私钥文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)

    println("会话 id 哈希值: ${lastSession?.hashCode() ?? 0}")
    println("会话 id 字符串: ${lastSession?.toString() ?? ""}")
    println("会话 id 相等: ${lastSession == lastSession}")
    println("会话 id 不相等: ${lastSession != lastSession}")
}
```

可能的运行结果：

```text
会话 id 哈希值: 139444231039951559
会话 id 字符串: TlsClientSession(fbb54e2e0145dcfae89600faf24da3136a68fb1a3af3da6ecb56e2ee239bf083)
会话 id 相等: true
会话 id 不相等: false
```

### func toString()

```cangjie
public override func toString(): String
```

功能：生成会话 id 字符串。

返回值：

- String - [TlsClientSession](tls_package_classes.md#class-tlsclientsession)(会话 id 字符串)。

示例：
<!-- associated_example -->
参见 [func hashCode](#func-hashcode) 示例。

### operator func !=(TlsClientSession)

```cangjie
public override operator func !=(other: TlsClientSession): Bool
```

功能：判断会话 id 是否不同。

参数：

- other: [TlsClientSession](tls_package_classes.md#class-tlsclientsession) - 被比较的会话对象。

返回值：

- Bool - 若会话对象不同，返回 `true`；否则，返回 `false`。

示例：
<!-- associated_example -->
参见 [func hashCode](#func-hashcode) 示例。

### operator func ==(TlsClientSession)

```cangjie
public override operator func ==(other: TlsClientSession): Bool
```

功能：判断会话 id 是否相同。

参数：

- other: [TlsClientSession](tls_package_classes.md#class-tlsclientsession) - 被比较的会话对象。

返回值：

- Bool - 若会话对象相同，返回 `true`；否则，返回 `false`。

示例：
<!-- associated_example -->
参见 [func hashCode](#func-hashcode) 示例。

## class TlsServerSession

```cangjie
public class TlsServerSession <: TlsSession & Equatable<TlsServerSession> & ToString
```

功能：该类表示 TLS 会话上下文，给客户端提供信息，确保客户端所连接的服务端仍为相同实例，用于连接复用时，验证客户端合法性。

> **说明：**
>
> 当客户端尝试恢复会话时，双方都必须确保他们正在恢复与合法对端的会话。

父类型：

- [TlsSession](./../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlssession)
- Equatable\<[TlsServerSession](#class-tlsserversession)>
- ToString

### static func fromName(String)

```cangjie
public static func fromName(name: String): TlsServerSession
```

功能：通过名称创建 [TlsServerSession](tls_package_classes.md#class-tlsserversession) 实例。

通过 [TlsServerSession](tls_package_classes.md#class-tlsserversession) 保存的名称获取 [TlsServerSession](tls_package_classes.md#class-tlsserversession) 对象。该名称用于区分 TLS 服务器，因此客户端依赖此名称来避免意外，尝试恢复与错误的服务器的连接。这里不一定使用加密安全名称，因为底层实现可以完成这项工作。从此函数返回的具有相同名称的两个 TlsServerSession 可能不相等，并且不保证可替换。尽管它们是从相同的名称创建的，因此服务器实例应该在整个生命周期内创建一个 TlsServerSession ，并且在每次 [TlsSocket](tls_package_classes.md#class-tlssocket).[server](tls_package_classes.md#static-func-serverstreamingsocket-tlsserversession-tlsserverconfig)() 调用中使用它。

参数：

- name: String - 会话上下文名称。

返回值：

- [TlsServerSession](tls_package_classes.md#class-tlsserversession) - 会话上下文。

示例：

<!-- verify -->
```cangjie
import stdx.net.tls.*

main() {
    // 通过名称创建 TLS 服务端会话
    let session1 = TlsServerSession.fromName("my-server")

    println("会话名称: ${session1}")
    return 0
}
```

运行结果：

```text
会话名称: TlsServerSession(my-server)
```

### func toString()

```cangjie
public override func toString(): String
```

功能：生成会话上下文名称字符串。

返回值：

- String - [TlsServerSession](tls_package_classes.md#class-tlsserversession)（会话上下文名称字符串）。

示例：

<!-- verify -->
```cangjie
import stdx.net.tls.*

main() {
    // 创建 TLS 服务端会话
    let session = TlsServerSession.fromName("test-session")

    // 获取会话名称字符串
    let sessionName = session.toString()

    println("获取到会话名称: ${sessionName}")
    return 0
}
```

运行结果：

```text
获取到会话名称: TlsServerSession(test-session)
```

### operator func !=(TlsServerSession)

```cangjie
public override operator func !=(other: TlsServerSession): Bool
```

功能：判断两 [TlsServerSession](tls_package_classes.md#class-tlsserversession) 实例名称是否不同。

参数：

- other: [TlsServerSession](tls_package_classes.md#class-tlsserversession) - 被比较的会话上下文对象。

返回值：

- Bool - 若 [TlsServerSession](tls_package_classes.md#class-tlsserversession) 对象不同，返回 `true`；否则，返回 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.net.tls.*

main() {
    // 创建两个不同名称的 TLS 服务端会话
    let session1 = TlsServerSession.fromName("server1")
    let session2 = TlsServerSession.fromName("server2")
    let session3 = TlsServerSession.fromName("server1")

    // 比较会话是否不同
    let isDifferent1 = session1 != session2 // 应该返回 true
    let isDifferent2 = session1 != session3 // 应该返回 false

    println("session1 与 session2 不同: ${isDifferent1}")
    println("session1 与 session3 不同: ${isDifferent2}")
    return 0
}
```

运行结果：

```text
session1 与 session2 不同: true
session1 与 session3 不同: false
```

### operator func ==(TlsServerSession)

```cangjie
public override operator func ==(other: TlsServerSession): Bool
```

功能：判断两 [TlsServerSession](tls_package_classes.md#class-tlsserversession) 实例名称是否相同。

参数：

- other: [TlsServerSession](tls_package_classes.md#class-tlsserversession) - 被比较的会话上下文对象。

返回值：

- Bool - 若 [TlsServerSession](tls_package_classes.md#class-tlsserversession) 对象相同，返回 `true`；否则，返回 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.net.tls.*

main() {
    // 创建两个相同名称的 TLS 服务端会话
    let session1 = TlsServerSession.fromName("same-server")
    let session2 = TlsServerSession.fromName("same-server")
    let session3 = TlsServerSession.fromName("different-server")

    // 比较会话是否相同
    let isSame1 = session1 == session2 // 应该返回 true
    let isSame2 = session1 == session3 // 应该返回 false

    println("session1 与 session2 相同: ${isSame1}")
    println("session1 与 session3 相同: ${isSame2}")
    return 0
}
```

运行结果：

```text
session1 与 session2 相同: true
session1 与 session3 相同: false
```

## class TlsSocket

```cangjie
public class TlsSocket <: TlsConnection & Equatable<TlsSocket> & Hashable
```

功能：[TlsSocket](tls_package_classes.md#class-tlssocket) 用于在客户端及服务端间创建加密传输通道。

父类型：

- [TlsConnection](../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlsconnection)
- Equatable\<[TlsSocket](#class-tlssocket)>
- Hashable

### prop certificate

```cangjie
public prop certificate: Array<X509Certificate>
```

功能：获取本端证书。

类型：?Array\<[X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate)>

异常：

- [TlsException](../common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - 当套接字未完成 TLS 握手或本端 TLS 套接字已关闭时，抛出异常。

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

main() {
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
        config.supportedAlpnProtocols = ["h2", "http/1.1"]
        // 启动 TCP 服务器
        try (server = TcpServerSocket(bindAt: 8443)) {
            // 绑定并监听
            server.bind()
            // 接受客户端连接，如果需要多次连接，可以使用循环，参考模块下示例教程
            try (clientSocket = server.accept()) {
                // 创建 TLS 套接字并进行握手
                try (tls = TlsSocket.server(clientSocket, serverConfig: config)) {
                    tls.handshake()
                    println("服务端 certificate size: ${tls.certificate.size}")
                    // alpnProtocol 将返回选择列表中第一个双方都支持的协议，而不是遍历
                    println("服务端 handshakeResult: ${tls.handshakeResult?.alpnProtocol ?? ""}")
                    println("服务端 remoteAddress: ${tls.remoteAddress}")
                }
            }
        }
    }
    // 等待服务器启动
    sleep(Duration.second)

    // 客户端配置
    var config = TlsClientConfig()
    config.verifyMode = TrustAll
    config.supportedAlpnProtocols = ["http/1.1"]

    // 连接服务器
    try (socket = TcpSocket("127.0.0.1", 8443)) {
        // 首先进行 TCP 连接
        socket.connect()
        // 创建 TLS 套接字并进行握手
        try (tls = TlsSocket.client(socket, clientConfig: config)) {
            tls.handshake()
            // alpnProtocol 将返回选择列表中第一个双方都支持的协议，而不是遍历
            println("客户端 handshakeResult: ${tls.handshakeResult?.alpnProtocol ?? ""}")
            println("客户端 localAddress: ${tls.localAddress}")
            // 未设置就是默认值 None
            println("客户端 readTimeout: ${tls.readTimeout}")
            println("客户端 writeTimeout: ${tls.writeTimeout}")
            println("客户端 remoteAddress: ${tls.remoteAddress}")
            // 获取底层套接字
            let _: StreamingSocket = tls.socket
        }
    } catch (e: Exception) {
        println("客户端连接失败: ${e.message}")
    }
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
    return 0
}
```

可能的运行结果：

```text
客户端 handshakeResult: http/1.1
客户端 localAddress: 127.0.0.1:48824
客户端 readTimeout: None
客户端 writeTimeout: None
客户端 remoteAddress: 127.0.0.1:8443
服务端 certificate size: 1
服务端 handshakeResult: http/1.1
服务端 remoteAddress: 127.0.0.1:48824
```

### prop handshakeResult

```cangjie
public prop handshakeResult: ?TlsHandshakeResult
```

功能：获取 TLS 握手结果。握手失败或者未握手，返回 None。

类型：[TlsHandshakeResult](../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlshandshakeresult)

示例：
<!-- associated_example -->
参见 [prop certificate](#prop-certificate) 示例。

### prop localAddress

```cangjie
public override prop localAddress: SocketAddress
```

功能：读取 [TlsSocket](tls_package_classes.md#class-tlssocket) 的本地地址。

类型：SocketAddress

异常：

- SocketException - 本端建连的底层 TCP 套接字关闭，抛出异常。
- [TlsException](../common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - 本端配置为 TLS 的套接字已关闭时，抛出异常。

示例：
<!-- associated_example -->
参见 [prop certificate](#prop-certificate) 示例。

### prop readTimeout

```cangjie
public override mut prop readTimeout: ?Duration
```

功能：读写 [TlsSocket](tls_package_classes.md#class-tlssocket) 的读超时时间。

类型：?Duration

异常：

- SocketException - 本端建连的底层 TCP 套接字关闭，抛出异常。
- [TlsException](../common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - 本端配置为 TLS 的套接字已关闭时，抛出异常。
- IllegalArgumentException - 设定的读超时时间为负值时，抛出异常。

示例：
<!-- associated_example -->
参见 [prop certificate](#prop-certificate) 示例。

### prop remoteAddress

```cangjie
public override prop remoteAddress: SocketAddress
```

功能：读取 [TlsSocket](tls_package_classes.md#class-tlssocket) 的远端地址。

类型：SocketAddress

异常：

- SocketException - 本端建连的底层 TCP 套接字关闭，抛出异常。
- [TlsException](../common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - 本端配置为 TLS 的套接字已关闭时，抛出异常。

示例：
<!-- associated_example -->
参见 [prop certificate](#prop-certificate) 示例。

### prop socket

```cangjie
public prop socket: StreamingSocket
```

功能：[TlsSocket](tls_package_classes.md#class-tlssocket) 创建所使用的 StreamingSocket。

类型：StreamingSocket

异常：

- [TlsException](../common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - 本端配置为 TLS 套接字已关闭时，抛出异常。

示例：
<!-- associated_example -->
参见 [prop certificate](#prop-certificate) 示例。

### prop writeTimeout

```cangjie
public override mut prop writeTimeout: ?Duration
```

功能：读写 [TlsSocket](tls_package_classes.md#class-tlssocket) 的写超时时间。

类型：?Duration

异常：

- SocketException - 本端建连的底层 TCP 套接字关闭，抛出异常。
- [TlsException](../common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - 本端配置为 TLS 的套接字已关闭时，抛出异常。
- IllegalArgumentException - 设定的写超时时间为负值时，抛出异常。

示例：
<!-- associated_example -->
参见 [prop certificate](#prop-certificate) 示例。

### static func client(StreamingSocket, ?TlsClientSession, TlsClientConfig)

```cangjie
public static func client(
    socket: StreamingSocket,
    session!: ?TlsClientSession = None,
    clientConfig!: TlsClientConfig = TlsClientConfig()
): TlsSocket
```

功能：根据传入的 StreamingSocket 实例创建指定地址的客户端 TLS 套接字，该套接字可用于客户端 TLS 握手及会话。

参数：

- socket: StreamingSocket - 已连接到服务端的客户端 TCP 套接字。
- session!: ?[TlsClientSession](tls_package_classes.md#class-tlsclientsession) - TLS 会话 id，若存在可用的 TLS 会话， 则可通过该 id 恢复历史 TLS 会话，省去 TLS 建立连接时间，但使用该会话依然可能协商失败。默认为 `None`。
- clientConfig!: [TlsClientConfig](tls_package_structs.md#struct-tlsclientconfig) - 客户端配置，默认为 [TlsClientConfig](tls_package_structs.md#struct-tlsclientconfig)()。

返回值：

- [TlsSocket](tls_package_classes.md#class-tlssocket) - 构造出的 [TlsSocket](tls_package_classes.md#class-tlssocket) 实例。

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

main() {
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
        try (server = TcpServerSocket(bindAt: 8446)) {
            // 绑定并监听
            server.bind()
            // 接受客户端连接，如果需要多次连接，可以使用循环，参考模块下示例教程
            try (clientSocket = server.accept()) {
                // 创建 TLS 套接字并进行握手
                try (tls = TlsSocket.server(clientSocket, serverConfig: config)) {
                    tls.handshake()
                    // 读取数据并打印
                    let buffer = Array<Byte>(39, repeat: 0)
                    tls.read(buffer)
                    println(String.fromUtf8(buffer))
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
    try (socket = TcpSocket("127.0.0.1", 8446)) {
        // 首先进行 TCP 连接
        socket.connect()
        // 创建 TLS 套接字并进行握手
        try (tls = TlsSocket.client(socket, clientConfig: config)) {
            tls.handshake()
            // 发送数据
            tls.write("这是一个由客户端发送的消息".toArray())
        }
    } catch (e: Exception) {
        println("客户端连接失败: ${e.message}")
    }
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
    return 0
}
```

运行结果：

```text
这是一个由客户端发送的消息
```

### static func server(StreamingSocket, ?TlsServerSession, KeylessTlsServerConfig)

```cangjie
public static func server(
    socket: StreamingSocket,
    session!: ?TlsServerSession = None,
    serverConfig!: KeylessTlsServerConfig
): TlsSocket
```

功能：根据传入的 StreamingSocket 实例创建指定地址的服务端 TLS 套接字，该套接字可用于服务端无私钥场景下 TLS 握手及会话。

参数：

- socket: StreamingSocket - TCP 连接建立完成后接受到套接字。
- session!: ?[TlsServerSession](tls_package_classes.md#class-tlsserversession) - TLS 会话 id， 若存在可用的 TLS 会话， 则可通过该 id 恢复历史 TLS 会话，省去 TLS 建立连接时间，但使用该会话依然可能协商失败。默认为 None。
- serverConfig!: [KeylessTlsServerConfig](./tls_package_classes.md#class-keylesstlsserverconfig) - 服务端配置。

返回值：

- [TlsSocket](tls_package_classes.md#class-tlssocket) - 构造出的 [TlsSocket](tls_package_classes.md#class-tlssocket) 实例。

示例：

<!-- run -->
```cangjie
import std.io.*
import std.fs.*
import std.net.*
import std.process.*
import stdx.net.tls.*
import stdx.crypto.x509.*
import stdx.net.tls.common.*

// 此处私钥仅用于生成证书，该示例采用 Keyless TLS
let serverKey = "./server.key"
let serverCrt = "./server.crt"

main() {
    // 启动服务器
    spawn {
        // OpenSSL 官方标准、无风险的测试命令用来本地生成证书和私钥
        let cmdStr = "openssl req -x509 -newkey rsa:2048 -nodes -keyout ${serverKey} -out ${serverCrt} -days 365 -subj \"/CN=localhost\""
        executeWithOutput("sh", ["-c", cmdStr])
        // 对证书以及私钥进行解析
        let pemString = String.fromUtf8(File.readFrom(serverCrt))

        let certificate = X509Certificate.decodeFromPem(pemString)

        // 签名回调函数和解密回调函数由第三方安全组件提供，此处只做模拟
        let config = KeylessTlsServerConfig(certificate, keylessSignFunc, decryptCallback: decryptCallback)

        // 启动 TCP 服务器
        try (server = TcpServerSocket(bindAt: 8443)) {
            // 绑定并监听
            server.bind()
            // 接受客户端连接，如果需要多次连接，可以使用循环，参考模块下示例教程
            try (clientSocket = server.accept()) {
                // 创建 TLS 套接字并进行握手
                try (tls = TlsSocket.server(clientSocket, serverConfig: config)) {
                    // 因为是模拟，所以不进行握手
                    // tls.handshake()
                    // 后续其他行为
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
        try (tls = TlsSocket.client(socket, clientConfig: config)) {
            // 因为是模拟，所以不进行握手
            // tls.handshake()
            // 后续其他行为
        }
    } catch (e: Exception) {
        println("客户端连接失败: ${e.message}")
    }
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
    return 0
}

// 签名回调函数：接收待签名数据，调用第三方组件完成签名
public func keylessSignFunc(_: Array<Byte>): Array<Byte> {
    println("此处模拟调用外部密钥服务完成签名操作")
    return []
}

// 解密回调函数：接收加密数据，调用第三方组件完成解密
public func decryptCallback(_: Array<Byte>): Array<Byte> {
    println("此处模拟调用外部密钥服务完成解密操作")
    return []
}
```

### static func server(StreamingSocket, ?TlsServerSession, TlsServerConfig)

```cangjie
public static func server(
    socket: StreamingSocket,
    session!: ?TlsServerSession = None,
    serverConfig!: TlsServerConfig
): TlsSocket
```

功能：根据传入的 StreamingSocket 实例创建指定地址的服务端 TLS 套接字，该套接字可用于服务端 TLS 握手及会话。

参数：

- socket: StreamingSocket - TCP 连接建立完成后接受到套接字。
- session!: ?[TlsServerSession](tls_package_classes.md#class-tlsserversession) - TLS 会话 id， 若存在可用的 TLS 会话， 则可通过该 id 恢复历史 TLS 会话，省去 TLS 建立连接时间，但使用该会话依然可能协商失败。默认为 None。
- serverConfig!: [TlsServerConfig](tls_package_structs.md#struct-tlsserverconfig) - 服务端配置，默认为 [TlsServerConfig](tls_package_structs.md#struct-tlsserverconfig)()。

返回值：

- [TlsSocket](tls_package_classes.md#class-tlssocket) - 构造出的 [TlsSocket](tls_package_classes.md#class-tlssocket) 实例。

示例：
<!-- associated_example -->
参见 [static func client](#static-func-clientstreamingsocket-tlsclientsession-tlsclientconfig) 示例。

### func close()

```cangjie
public func close(): Unit
```

功能：关闭套接字。

异常：

- SocketException - 底层连接无法关闭时，抛出异常。

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

main() {
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
                let tls = TlsSocket.server(clientSocket, serverConfig: config)
                tls.handshake()
                // 读取数据并打印
                let buffer = Array<Byte>(39, repeat: 0)
                tls.read(buffer)
                println(String.fromUtf8(buffer))
                // 关闭连接，此处如果使用try-with-resources，可以省略
                tls.close()
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
        let tls = TlsSocket.client(socket, clientConfig: config)
        tls.handshake()
        // 发送数据
        tls.write("这是一个由客户端发送的消息".toArray())

        // 关闭连接，此处如果使用try-with-resources，可以省略
        tls.close()
        println("客户端成功关闭连接: ${tls.isClosed()}")
    } catch (e: Exception) {
        println("客户端连接失败: ${e.message}")
    }
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
    return 0
}
```

运行结果：

```text
这是一个由客户端发送的消息
客户端成功关闭连接: true
```

### func handshake(?Duration)

```cangjie
public func handshake(timeout!: ?Duration = None): TlsHandshakeResult
```

功能：TLS 握手。不支持重新协商握手，因此只能被调用一次。调用对象可以为客户端或者服务端的 [TlsSocket](tls_package_classes.md#class-tlssocket)。

参数：

- timeout!: ?Duration - 握手超时时间，默认为 None 不对超时时间进行设置，此时采用默认 30s 的超时时间。

返回值：

- [TlsHandshakeResult](../common/tls_common_package_api/tls_common_package_interfaces.md#interface-tlshandshakeresult) - 握手结果。

异常：

- SocketException - 本端建连的底层 TCP 套接字关闭，抛出异常。
- SocketTimeoutException - 底层 TCP 套接字连接超时时，抛出异常。
- [TlsException](../common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - 当握手已经开始或者已经结束，抛出异常；或当握手阶段出现系统错误时，抛出异常。
- IllegalArgumentException - 设定的握手超时时间为负值时，抛出异常。

示例：
<!-- associated_example -->
参见 [static func client](#static-func-clientstreamingsocket-tlsclientsession-tlsclientconfig) 示例。

### func hashCode()

```cangjie
public override func hashCode(): Int64
```

功能：返回 TLS 套接字对象的哈希值。

返回值：

- Int64 - 对 TLS 套接字对象进行哈希计算后得到的结果。

示例：
<!-- associated_example -->
参见 [func toString](#func-tostring) 示例。

### func isClosed()

```cangjie
public func isClosed(): Bool
```

功能：返回套接字是否关闭的状态。

返回值：

- Bool - 连接断开返回 true；否则，返回 false。

示例：
<!-- associated_example -->
参见 [func close](#func-close) 示例。

### func read(Array\<Byte>)

```cangjie
public override func read(buffer: Array<Byte>): Int64
```

功能：[TlsSocket](tls_package_classes.md#class-tlssocket) 读取数据。

参数：

- buffer: Array\<Byte> - 存储读取到的数据内容的数组。

返回值：

- Int64 - 读取到的数据内容字节数。

异常：

- SocketException - 本端建连的底层 TCP 套接字关闭，抛出异常。
- [TlsException](../common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - 当 `buffer` 为空，或者 [TlsSocket](tls_package_classes.md#class-tlssocket) 未连接，或读取数据出现系统错误等。

示例：
<!-- associated_example -->
参见 [static func client](#static-func-clientstreamingsocket-tlsclientsession-tlsclientconfig) 示例。

### func toString()

```cangjie
public func toString(): String
```

功能：套接字的字符串表示，字符串内容为当前套接字状态。

> **说明：**
>
> 例如：当前套接字处于可开始进行握手状态时，该接口将返回字符串 "[TlsSocket](tls_package_classes.md#class-tlssocket)(TcpSocket(\${本端地址} -> \${对端地址}), ready for handshake)"

返回值：

- String - 该 TLS 连接字符串。

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

main() {
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
                try (tls = TlsSocket.server(clientSocket, serverConfig: config)) {
                    tls.handshake()
                    // 读取数据并打印
                    let buffer = Array<Byte>(100, repeat: 0)
                    tls.read(buffer)
                    println(String.fromUtf8(buffer))

                    // 打印 TLS 套接字的字符串表示和哈希值
                    println("服务端 toString: ${tls}")
                    println("服务端 hashCode: ${tls.hashCode()}")
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
        try (tls = TlsSocket.client(socket, clientConfig: config)) {
            tls.handshake()
            // 发送数据
            tls.write("客户端发送: 这是一个由客户端发送的消息".toArray())

            // 打印 TLS 套接字的字符串表示和哈希值
            println("客户端 toString: ${tls}")
            println("客户端 hashCode: ${tls.hashCode()}")
        }
    } catch (e: Exception) {
        println("客户端连接失败: ${e.message}")
    }
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
    return 0
}
```

可能的运行结果：

```text
客户端 toString: TlsSocket(TcpSocket(127.0.0.1:35680 -> 127.0.0.1:8443), connected)
客户端 hashCode: 1
客户端发送: 这是一个由客户端发送的消息
服务端 toString: TlsSocket(TcpSocket(127.0.0.1:8443 -> 127.0.0.1:35680), connected)
服务端 hashCode: 2
```

### func write(Array\<Byte>)

```cangjie
public func write(buffer: Array<Byte>): Unit
```

功能：[TlsSocket](tls_package_classes.md#class-tlssocket) 发送数据。

参数：

- buffer: Array\<Byte> - 存储将要发送的数据内容数组。

异常：

- SocketException - 本端建连的底层 TCP 套接字关闭，抛出异常。
- [TlsException](../common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - 当套接字已关闭，或者 [TlsSocket](tls_package_classes.md#class-tlssocket) 未连接，或写入数据出现系统错误等。

示例：
<!-- associated_example -->
参见 [static func client](#static-func-clientstreamingsocket-tlsclientsession-tlsclientconfig) 示例。

### operator func !=(TlsSocket)

```cangjie
public override operator func !=(other: TlsSocket): Bool
```

功能：判断两 [TlsSocket](tls_package_classes.md#class-tlssocket) 是否引用不同实例。

参数：

- other: [TlsSocket](tls_package_classes.md#class-tlssocket) - 对比的 TLS 套接字。

返回值：

- Bool - 对比的套接字不同返回 `true`；否则，返回 `false`。

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

main() {
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
        try (server = TcpServerSocket(bindAt: 8444)) {
            // 绑定并监听
            server.bind()
            // 接受客户端连接，如果需要多次连接，可以使用循环，参考模块下示例教程
            try (clientSocket = server.accept()) {
                // 创建 TLS 套接字并进行握手
                try (tls = TlsSocket.server(clientSocket, serverConfig: config)) {
                    tls.handshake()
                    // 读取数据并打印
                    let buffer = Array<Byte>(39, repeat: 0)
                    tls.read(buffer)
                    println(String.fromUtf8(buffer))
                    println("和自己对比相等: ${tls == tls}")
                    println("和自己对比不等: ${tls != tls}")
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
    try (socket = TcpSocket("127.0.0.1", 8444)) {
        // 首先进行 TCP 连接
        socket.connect()
        // 创建 TLS 套接字并进行握手
        try (tls = TlsSocket.client(socket, clientConfig: config)) {
            tls.handshake()
            // 发送数据
            tls.write("这是一个由客户端发送的消息".toArray())
        }
    } catch (e: Exception) {
        println("客户端连接失败: ${e.message}")
    }
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
    return 0
}
```

运行结果：

```text
这是一个由客户端发送的消息
和自己对比相等: true
和自己对比不等: false
```

### operator func ==(TlsSocket)

```cangjie
public override operator func ==(other: TlsSocket): Bool
```

功能：判断两 [TlsSocket](tls_package_classes.md#class-tlssocket) 是否引用同一实例。

参数：

- other: [TlsSocket](tls_package_classes.md#class-tlssocket) - 对比的 TLS 套接字。

返回值：

- Bool - 对比的套接字相同返回 `true`；否则，返回 `false`。

示例：
<!-- associated_example -->
参见 [operator func !=](#operator-func-tlssocket) 示例。
