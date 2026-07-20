# 自定义证书校验

TLS 配置的 `verifyMode` 使用 `CustomVerify` 模式。通过配置证书校验函数，使 TLS 握手时使用定制的证书校验流程。

> **注意：**
>
> 以下示例仅用于展示客户端写法，可通过编译但无法运行成功。如需查看运行效果，需用户自行提供服务端和有效证书文件。

带证书的详细使用参见 [prop certificate](./../tls_package_api/tls_package_structs.md#prop-certificate)

示例：

<!-- compile -->
```cangjie
import std.net.TcpSocket
import stdx.crypto.x509.X509Certificate
import stdx.net.tls.*
import stdx.net.tls.common.*

main() {
    // 创建 TLS 客户端配置
    var tlsConfig = TlsClientConfig()
    // 配置 ALPN 协议，用于应用层协议协商
    tlsConfig.supportedAlpnProtocols = ["h2"]

    // 配置自定义证书校验逻辑
    tlsConfig.verifyMode = CustomVerify(
        {
            certificates =>
                // 校验证书链不为空
                if (certificates.size == 0) {
                    return false
                }

                // 校验每个证书的颁发者
                for (cert in certificates) {
                    match (cert as X509Certificate) {
                        case Some(x509Cert) =>
                            // 校验证书颁发者组织名称
                            if (x509Cert.issuer.organizationName != "example") {
                                return false
                            }
                        case None => return false
                    }
                }

                return true
        }
    )

    // 连接服务端
    try (tcpSocket = TcpSocket("127.0.0.1", 8443)) {
        tcpSocket.connect()

        let tlsSocket = TlsSocket.client(tcpSocket, clientConfig: tlsConfig, session: None)
        // 执行 TLS 握手，握手过程中会调用自定义校验逻辑
        tlsSocket.handshake()
    }
}
```
