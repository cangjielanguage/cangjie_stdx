# 服务端示例

> **说明：**
>
> 需要自行准备证书文件。

带证书的详细使用参见 [struct TlsServerConfig](./../tls_package_api/tls_package_structs.md#struct-tlsserverconfig)

示例：

<!-- compile -->
```cangjie
import std.io.*
import std.fs.File
import std.net.{TcpServerSocket, TcpSocket}
import stdx.crypto.x509.X509Certificate
import stdx.crypto.keys.GeneralPrivateKey
import stdx.net.tls.*

// 证书和私钥文件路径
let certFilePath = "./files/apiserver.crt"
let keyFilePath = "./files/apiserver.key"

main() {
    // 读取并解析证书文件
    let certPemData = String.fromUtf8(File.readFrom(certFilePath))
    let keyPemData = String.fromUtf8(File.readFrom(keyFilePath))

    let serverCertificate = X509Certificate.decodeFromPem(certPemData)
    let privateKey = GeneralPrivateKey.decodeFromPem(keyPemData)

    // 创建 TLS 服务端配置
    let tlsConfig = TlsServerConfig(serverCertificate, privateKey)

    // 配置会话缓存，支持 TLS 会话复用
    let sessionCache = TlsServerSession.fromName("my-server")

    try (tcpServer = TcpServerSocket(bindAt: 8443)) {
        tcpServer.bind()

        // 循环接收客户端连接
        tcpServer.acceptLoop {
            clientSocket => try (tlsSocket = TlsSocket.server(clientSocket, serverConfig: tlsConfig,
                session: sessionCache)) {
                // 执行 TLS 握手
                tlsSocket.handshake()

                // 读取客户端发送的数据
                let buffer = Array<Byte>(100, repeat: 0)
                tlsSocket.read(buffer)
                println(buffer)
            }
        }
    }
}

extend TcpServerSocket {
    // 循环接收客户端连接，每个连接在独立协程中处理
    func acceptLoop(handler: (TcpSocket) -> Unit) {
        while (true) {
            let client = accept()
            spawn {
                try {
                    handler(client)
                } finally {
                    client.close()
                }
            }
        }
    }
}
```
