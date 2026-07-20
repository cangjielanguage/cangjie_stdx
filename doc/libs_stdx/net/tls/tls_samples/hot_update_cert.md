# 证书热更新

示例：

<!-- run -->
```cangjie
import std.net.StreamingSocket
import stdx.crypto.common.{Certificate, PrivateKey}
import stdx.net.tls.*

class TlsServer {
    // 当前使用的 TLS 配置
    private var activeConfig: TlsServerConfig

    init(initialConfig: TlsServerConfig) {
        activeConfig = initialConfig
    }

    // 动态更新证书和私钥，仅影响新建立的连接
    public mut prop certificate: ?(Array<Certificate>, PrivateKey) {
        get() {
            activeConfig.certificate
        }
        set(newCertificate) {
            activeConfig.certificate = newCertificate
        }
    }

    // 处理客户端连接
    public func handleConnection(clientSocket: StreamingSocket) {
        try (tlsSocket = TlsSocket.server(clientSocket, serverConfig: activeConfig)) {
            // 执行 TLS 握手
            tlsSocket.handshake()
            // 握手成功后可进行数据读写
        }
    }
}

main() {}
```
