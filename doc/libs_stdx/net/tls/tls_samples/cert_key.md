# 服务端证书及公钥在一份文件中

> **说明：**
>
> 需要自行准备证书文件。

带证书的详细使用参见 [prop supportedCipherSuites](./../tls_package_api/tls_package_structs.md#prop-supportedciphersuites-1)

示例：

<!-- compile -->
```cangjie
import std.io.*
import std.{fs.*, collection.*}
import stdx.net.tls.*
import stdx.crypto.x509.X509Certificate
import stdx.crypto.common.{PrivateKey, Pem, PemEntry, DerBlob}
import stdx.crypto.keys.GeneralPrivateKey

// 证书和私钥在同一文件中
let certAndKeyFilePath = "/etc/myserver/cert-and-key.pem"

func parsePem(pemText: String): (Array<X509Certificate>, PrivateKey) {
    let pemEntries = Pem.decode(pemText)

    // 从 PEM 中提取所有证书
    let certificateChain = pemEntries |> filter<PemEntry> {entry => entry.label == PemEntry.LABEL_CERTIFICATE} |>
        map<PemEntry, X509Certificate> {entry => X509Certificate.decodeFromDer(entry.body ?? DerBlob())} |> collectArray

    // 从 PEM 中提取私钥
    let privateKey = (pemEntries |> filter<PemEntry> {entry => entry.label == PemEntry.LABEL_PRIVATE_KEY} |>
        map<PemEntry, PrivateKey> {entry => GeneralPrivateKey.decodeDer(entry.body ?? DerBlob())} |> first) ?? throw Exception(
        "PEM 文件中未找到私钥")

    if (certificateChain.isEmpty()) {
        throw Exception("PEM 文件中未找到证书")
    }

    return (certificateChain, privateKey)
}

main() {
    // 读取并解析包含证书和私钥的 PEM 文件
    let pemContent = String.fromUtf8(File.readFrom(certAndKeyFilePath))

    let (certificates, privateKey) = parsePem(pemContent)

    // 使用解析出的证书和私钥创建 TLS 服务端配置
    let _ = TlsServerConfig(certificates, privateKey)

    // 后续可使用 tlsConfig 启动 HTTPS 服务，参考其他服务端示例
}
```
