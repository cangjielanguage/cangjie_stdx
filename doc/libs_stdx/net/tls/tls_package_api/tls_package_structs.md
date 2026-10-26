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
    public var verifyMode: CertificateVerifyMode = CertificateVerifyMode.Default
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

类型：?([TlsSocket](tls_package_classes.md#class-tlssocket), String) -> Unit

### prop certificate

```cangjie
public mut prop certificate: ?(Array<Certificate>, PrivateKey)
```

功能：设置或获取客户端证书和对应的私钥文件。其中证书必须为 [X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate) 类型。

类型：?(Array\<[Certificate](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-certificate)>, [PrivateKey](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey))

异常：

- [TlsException](../common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - 设置的客户端证书不是 [X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate) 类型时，抛出异常。

### prop securityLevel

```cangjie
public mut prop securityLevel: Int32
```

功能：指定客户端的安全级别，默认值为 2，可选参数值在 0-5 内，参数值含义参见 openssl 的 SSL_CTX_set_security_level 说明。

类型：Int32

### prop serverName

```cangjie
public mut prop serverName: ?String
```

功能：读写要求的服务端主机地址 (SNI)， `None` 表示不要求。通过 `stdx.net.http` 客户端发起请求且未设置该字段时，将使用请求 URL 中的主机名作为 SNI 并校验服务器证书（主机名为空时握手失败）。

类型：?String

异常：

- IllegalArgumentException - 参数有 '\0' 字符时，抛出异常。

### prop signatureAlgorithms

```cangjie
public mut prop signatureAlgorithms: ?Array<SignatureAlgorithm>
```

功能：指定保序的签名和哈希算法。在值为 `None` 或者列表为空时，客户端会使用默认的列表。指定列表后，客户端可能不会发送不合适的签名算法。
参见 [RFC5246 7.4.1.4.1 (TLS 1.2)](https://www.rfc-editor.org/rfc/rfc5246.html#section-7.4.1.4.1) 章节， [RFC8446 4.2.3. (TLS 1.3)](https://www.rfc-editor.org/rfc/rfc8446.html#section-4.2.3) 章节。

类型：?Array\<[SignatureAlgorithm](tls_package_enums.md#enum-signaturealgorithm)>

### prop supportedAlpnProtocols

```cangjie
public mut prop supportedAlpnProtocols: Array<String>
```

功能：应用层协商协议，若列表为空，则客户端将不协商应用层协议。

类型：Array\<String>

异常：

- IllegalArgumentException - 列表元素有 '\0' 字符时，抛出异常。

### prop supportedCipherSuites

```cangjie
public mut prop supportedCipherSuites: Map<TlsVersion, Array<String>>
```

功能：设置或获取每个 TLS 版本对应的密码套件。

类型：Map\<[TlsVersion](../common/tls_common_package_api/tls_common_package_enums.md#enum-tlsversion), Array\<String>>

异常：

- IllegalArgumentException - 通过传入 `Map` 设置密码套件时，某个 TLS 版本对应的密码套件字符串中包含空字符 `\0`，则抛出异常。

### prop supportedVersions

```cangjie
public mut prop supportedVersions: Array<TlsVersion>
```

功能：设置或获取支持的 TLS 版本。

类型：Array\<[TlsVersion](../common/tls_common_package_api/tls_common_package_enums.md#enum-tlsversion)>

### prop verifyMode

```cangjie
public mut prop verifyMode: CertificateVerifyMode
```

功能：设置或获取认证模式，默认值为 [CertificateVerifyMode](../common/tls_common_package_api/tls_common_package_enums.md#enum-certificateverifymode).Default，即认证系统证书。

类型：[CertificateVerifyMode](../common/tls_common_package_api/tls_common_package_enums.md#enum-certificateverifymode)

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
    public mut prop clientIdentityRequired: TlsClientIdentificationMode
    public mut prop verifyMode: CertificateVerifyMode
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

类型：?([TlsSocket](tls_package_classes.md#class-tlssocket), String) -> Unit

### prop certificate

```cangjie
public mut prop certificate: ?(Array<Certificate>, PrivateKey)
```

功能：设置或获取服务端证书和对应的私钥文件。其中证书必须为 [X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate) 类型。不可设置为 None。

类型：?(Array\<[Certificate](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-certificate)>, [PrivateKey](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey))

异常：

- [TlsException](../common/tls_common_package_api/tls_common_package_exceptions.md#class-tlsexception) - 设置的服务端证书不是 [X509Certificate](../../../crypto/x509/x509_package_api/x509_package_classes.md#class-x509certificate) 类型时，抛出异常；设置服务端证书和对应的私钥文件为 None 时，抛出异常。

### prop clientIdentityRequired

```cangjie
public mut prop clientIdentityRequired: TlsClientIdentificationMode
```

功能：设置或获取服务端要求客户端的认证模式，默认值为 [TlsClientIdentificationMode](tls_package_enums.md#enum-tlsclientidentificationmode).Disable，即不要求客户端认证服务端证书，也不要求客户端发送本端证书。

类型：[TlsClientIdentificationMode](tls_package_enums.md#enum-tlsclientidentificationmode)

### prop dhParameters

```cangjie
public mut prop dhParameters: ?DHParameters
```

功能：指定服务端的 DH 密钥参数，默认为 `None`， 默认情况下使用 openssl 自动生成的参数值。

类型：?[DHParameters](../../../crypto/common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-dhparameters)

### prop securityLevel

```cangjie
public mut prop securityLevel: Int32
```

功能：指定服务端的安全级别，默认值为 2，可选参数值在 [0,5] 内，参数值含义参见 [openssl-SSL_CTX_set_security_level](https://docs.openssl.org/1.1.1/man3/SSL_CTX_set_security_level/) 说明。

类型：Int32

异常：

- IllegalArgumentException - 当配置值不在 0-5 范围内时，抛出异常。

### prop supportedAlpnProtocols

```cangjie
public mut prop supportedAlpnProtocols: Array<String>
```

功能：应用层协商协议，若客户端尝试协商该协议，服务端将与选取其中相交的协议名称。若客户端未尝试协商协议，则该配置将被忽略。

类型：Array\<String>

异常：

- IllegalArgumentException - 列表元素有 '\0' 字符时，抛出异常。

### prop supportedCipherSuites

```cangjie
public mut prop supportedCipherSuites: Map<TlsVersion, Array<String>>
```

功能：设置或获取每个 TLS 版本对应的密码套件。

类型：Map\<[TlsVersion](../common/tls_common_package_api/tls_common_package_enums.md#enum-tlsversion), Array\<String>>

异常：

- IllegalArgumentException - 通过传入 `Map` 设置密码套件时，某个 TLS 版本对应的密码套件字符串中包含空字符 `\0`，则抛出异常。

### prop supportedVersions

```cangjie
public mut prop supportedVersions: Array<TlsVersion>
```

功能：设置或获取支持的 TLS 版本。

类型：Array\<[TlsVersion](../common/tls_common_package_api/tls_common_package_enums.md#enum-tlsversion)>

### prop verifyMode

```cangjie
public mut prop verifyMode: CertificateVerifyMode
```

功能：设置或获取认证模式，默认值为 [CertificateVerifyMode](../common/tls_common_package_api/tls_common_package_enums.md#enum-certificateverifymode).Default，即认证系统证书。

类型：[CertificateVerifyMode](../common/tls_common_package_api/tls_common_package_enums.md#enum-certificateverifymode)

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
    let serverCrtContent = String.fromUtf8(readToEnd(File(serverCrt, Read)))
    let serverCertificate = X509Certificate.decodeFromPem(serverCrtContent)

    let serverKeyContent = String.fromUtf8(readToEnd(File(serverKey, Read)))
    let serverPrivateKey = GeneralPrivateKey.decodeFromPem(serverKeyContent)

    // 创建 TLS 服务器配置
    let _ = TlsServerConfig(serverCertificate, serverPrivateKey)

    // 删除证书和私钥文件
    removeIfExists(serverKey)
    removeIfExists(serverCrt)
    return 0
}
```
