# 客户端示例

带证书的详细使用参见 [struct TlsClientConfig](./../tls_package_api/tls_package_structs.md#struct-tlsclientconfig)

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
    tlsConfig.verifyMode = TrustAll
    // 配置 ALPN 协议，用于应用层协议协商
    tlsConfig.supportedAlpnProtocols = ["h2"]

    // 保存会话信息，用于后续连接复用
    var sessionCache: ?TlsClientSession = None

    // 循环连接服务端
    while (true) {
        try (tcpSocket = TcpSocket("127.0.0.1", 8443)) {
            tcpSocket.connect()

            try (tlsSocket = TlsSocket.client(tcpSocket, clientConfig: tlsConfig, session: sessionCache)) {
                try {
                    // 执行 TLS 握手
                    tlsSocket.handshake()

                    // 握手成功后保存会话，下次连接可复用
                    sessionCache = match (tlsSocket.handshakeResult) {
                        case Some(result) => result.session as TlsClientSession
                        case None => None
                    }
                } catch (e: Exception) {
                    // 握手失败时清除会话缓存
                    sessionCache = None
                    throw e
                }

                // 通过 TLS 连接发送数据
                tlsSocket.write("Hello, peer! Let's discuss our personal secrets.\n".toArray())
            }
        } catch (e: Exception) {
            println("连接失败: ${e}，正在重试...")
        }
    }
}
```
