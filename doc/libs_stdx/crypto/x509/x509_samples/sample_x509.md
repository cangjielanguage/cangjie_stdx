# x509 使用

## 读取、解析证书

示例：

<!-- run -->
```cangjie
import std.fs.*
import stdx.crypto.x509.*
import std.process.*

main() {
    // 使用 OpenSSL 生成测试证书
    let certFile = "./test_read_cert.pem"
    let keyFile = "./test_read_key.pem"
    let cmdStr = "openssl req -new -x509 -keyout ${keyFile} -out ${certFile} -days 365 -subj '/CN=TestCert' -nodes"
    executeWithOutput("sh", ["-c", cmdStr])

    // 读取证书文件
    let pemContent = String.fromUtf8(File.readFrom(certFile))
    let certificates = X509Certificate.decodeFromPem(pemContent)

    // 获取第一个证书并解析必选字段
    let certificate = certificates[0]
    println("序列号: ${certificate.serialNumber}")
    println("颁发者: ${certificate.issuer}")
    println("生效时间: ${certificate.notBefore}")
    println("失效时间: ${certificate.notAfter}")
    println("签名算法: ${certificate.signatureAlgorithm}")
    println("签名哈希值: ${certificate.signature.hashCode()}")
    println("公钥算法: ${certificate.publicKeyAlgorithm}")
    println("公钥: ${certificate.publicKey.encodeToPem().encode()}")
    println("使用者: ${certificate.subject}")

    // 解析证书的扩展字段
    println("DNS 名称: ${certificate.dnsNames}")
    println("邮箱地址: ${certificate.emailAddresses}")
    println("IP 地址: ${certificate.IPAddresses}")
    println("密钥用途: ${certificate.keyUsage}")
    println("扩展密钥用途: ${certificate.extKeyUsage}")

    // 清理测试文件
    removeIfExists(certFile)
    removeIfExists(keyFile)
    return 0
}
```

可能的运行结果：

```text
序列号: 1F924AA654316B55DAB1DA65FD9E2C8520EF23E3
颁发者: cn=TestCert
生效时间: 2026-07-14T08:12:02Z
失效时间: 2027-07-14T08:12:02Z
签名算法: Signature Algorithm: sha256WithRSAEncryption
签名哈希值: -8087033568281295724
公钥算法: Public Key Algorithm: rsaEncryption
公钥: -----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxwJbTrg19PU5JpKYf/UD
83xuRbzAOvvumzOhZcX33ykEbId8TsPz/AjxOCQJgcqcyikLxyIw8YQqK6pzXsEc
W6qRBklco98U6cgDsiMB8LmtYDNbK+jrKNcmWyADPrMGHJp0TgW7qFnugKMS/2X7
PiIeWyztKlseKe6EA1PHDTRbcIYCsYyj1YnF71FVPCba750kj/ILc0n/5Tn5iGC8
GescCTj10WrThP8ya3LhZHucTnfQTX0+oJDiJf7n2P/rFDLq9kf16XHeY10F6qkR
CeXcgs+JkCXh77zm1zbTdUMAPMLeSrKzfW+6DFc84ShBriFSNQm6z14jW1PUGtr4
AQIDAQAB
-----END PUBLIC KEY-----

使用者: cn=TestCert
DNS 名称: []
邮箱地址: []
IP 地址: []
密钥用途: 
扩展密钥用途: 
```

## 读取、验证证书

示例：

<!-- verify -->
```cangjie
import std.fs.*
import stdx.crypto.x509.*
import std.process.*

main() {
    // 使用 OpenSSL 生成根证书、中间证书和服务端证书
    // 注意：必须添加正确的 CA 扩展字段，否则验证会失败
    let rootKey = "./test_verify_root_key.pem"
    let rootCert = "./test_verify_root_cert.pem"
    let middleKey = "./test_verify_middle_key.pem"
    let middleCert = "./test_verify_middle_cert.pem"
    let serverKey = "./test_verify_server_key.pem"
    let serverCert = "./test_verify_server_cert.pem"

    // 创建 OpenSSL 配置文件（添加 CA:true 扩展）
    let caConfig = """
[ v3_ca ]
basicConstraints = critical, CA:true
keyUsage = critical, keyCertSign, cRLSign

[ v3_intermediate ]
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, keyCertSign, cRLSign

[ v3_server ]
basicConstraints = CA:false
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
"""

    // 写入配置文件
    let configFile = "./openssl.cnf"
    File.writeTo(configFile, caConfig.toArray())

    let cmdStr =
        // 生成根证书（自签名，带 CA:true）
        "openssl genrsa -out ${rootKey} 2048 && " +
        "openssl req -new -x509 -key ${rootKey} -out ${rootCert} -days 365 -subj '/CN=TestRootCA' -config ${configFile} -extensions v3_ca && " +
        // 生成中间证书（由根证书签名，带 CA:true）
        "openssl genrsa -out ${middleKey} 2048 && " +
        "openssl req -new -key ${middleKey} -out ./middle.csr -subj '/CN=TestMiddleCA' && " +
        "openssl x509 -req -in ./middle.csr -CA ${rootCert} -CAkey ${rootKey} -CAcreateserial -out ${middleCert} -days 365 -extfile ${configFile} -extensions v3_intermediate && " +
        // 生成服务端证书（由中间证书签名，不带 CA）
        "openssl genrsa -out ${serverKey} 2048 && " +
        "openssl req -new -key ${serverKey} -out ./server.csr -subj '/CN=www.example.com' && " +
        "openssl x509 -req -in ./server.csr -CA ${middleCert} -CAkey ${middleKey} -CAcreateserial -out ${serverCert} -days 365 -extfile ${configFile} -extensions v3_server"

    executeWithOutput("sh", ["-c", cmdStr])

    // 加载证书
    let serverCerts = X509Certificate.decodeFromPem(String.fromUtf8(File.readFrom(serverCert)))
    let rootCerts = X509Certificate.decodeFromPem(String.fromUtf8(File.readFrom(rootCert)))
    let middleCerts = X509Certificate.decodeFromPem(String.fromUtf8(File.readFrom(middleCert)))

    /**
     * 本示例生成的证书链关系：
     *   root (CA:true)
     *     |
     *   middle (CA:true)
     *     |
     *   server (CA:false)
     */

    // 验证证书链（服务端证书 <- 中间证书 <- 根证书）
    var option = VerifyOption()
    option.roots = rootCerts
    option.intermediates = middleCerts
    let isValid = serverCerts[0].verify(option)
    println("证书链验证结果: ${isValid}")

    // 清理测试文件
    removeIfExists(rootKey)
    removeIfExists(rootCert)
    removeIfExists(middleKey)
    removeIfExists(middleCert)
    removeIfExists(serverKey)
    removeIfExists(serverCert)
    removeIfExists(configFile)
    removeIfExists("./middle.csr")
    removeIfExists("./server.csr")
    removeIfExists("./test_verify_middle_cert.srl")
    removeIfExists("./test_verify_server_cert.srl")
    return 0
}
```

运行结果：

```text
证书链验证结果: true
```

## 创建、解析证书

示例：

<!-- run -->
```cangjie
import std.fs.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*
import std.time.*
import std.io.*
import std.process.*

main() {
    // 生成根证书和密钥
    let rootKeyFile = "./test_create_root_key.pem"
    let rootCertFile = "./test_create_root_cert.pem"
    let cmdStr = "openssl genrsa -out ${rootKeyFile} 2048 && " +
        "openssl req -new -x509 -key ${rootKeyFile} -out ${rootCertFile} -days 365 -subj '/CN=TestRootCA'"
    executeWithOutput("sh", ["-c", cmdStr])

    // 读取根证书和私钥
    let parentCertPem = String.fromUtf8(File.readFrom(rootCertFile))
    let parentCert = X509Certificate.decodeFromPem(parentCertPem)[0]
    let parentKeyPem = String.fromUtf8(File.readFrom(rootKeyFile))
    let parentPrivateKey = GeneralPrivateKey.decodeFromPem(parentKeyPem)

    // 生成用户密钥对
    let userPrivateKey = RSAPrivateKey(2048)
    let userPublicKey = RSAPublicKey(userPrivateKey)

    // 创建证书信息
    let subjectName = X509Name(
        countryName: "CN",
        provinceName: "beijing",
        localityName: "haidian",
        organizationName: "organization",
        commonName: "x509_test"
    )

    let serialNumber = SerialNumber(length: 20)
    let startTime = DateTime.now()
    let endTime = startTime.addYears(1)
    let ipv4: IP = [8, 8, 8, 8]

    let certInfo = X509CertificateInfo(
        serialNumber: serialNumber,
        notBefore: startTime,
        notAfter: endTime,
        subject: subjectName,
        dnsNames: ["test.example.com"],
        IPAddresses: [ipv4]
    )

    // 使用根证书签发新证书
    let certificate = X509Certificate(certInfo, parent: parentCert, publicKey: userPublicKey,
        privateKey: parentPrivateKey)

    // 输出证书信息
    println("证书创建成功")
    println("序列号: ${certificate.serialNumber}")
    println("颁发者: ${certificate.issuer}")
    println("使用者: ${certificate.subject}")
    println("生效时间: ${certificate.notBefore}")
    println("失效时间: ${certificate.notAfter}")
    println("签名算法: ${certificate.signatureAlgorithm}")
    println("DNS 名称: ${certificate.dnsNames}")
    println("IP 地址: ${certificate.IPAddresses}")

    // 清理测试文件
    removeIfExists(rootKeyFile)
    removeIfExists(rootCertFile)
    return 0
}
```

可能的运行结果：

```text
证书创建成功
序列号: 01C51A6B4C2256F666E043F21035337B700B15DA
颁发者: cn=TestRootCA
使用者: c=CN,st=beijing,l=haidian,o=organization,cn=x509_test
生效时间: 2026-07-14T08:15:25Z
失效时间: 2027-07-14T08:15:25Z
签名算法: Signature Algorithm: sha256WithRSAEncryption
DNS 名称: [test.example.com]
IP 地址: [[8, 8, 8, 8]]
```

## 创建、解析证书签名请求

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main() {
    // 生成 RSA 私钥并保存
    let rsaPrivate = RSAPrivateKey(2048)
    let privateKeyPem = rsaPrivate.encodeToPem()
    let keyFile = File("./test_csr_key.pem", Write)
    keyFile.write(privateKeyPem.encode().toArray())
    keyFile.close()

    // 从文件读取私钥
    let privateKeyContent = String.fromUtf8(File.readFrom("./test_csr_key.pem"))
    let privateKey = GeneralPrivateKey.decodeFromPem(privateKeyContent)

    // 创建证书签名请求信息
    let subjectName = X509Name(
        countryName: "CN",
        provinceName: "beijing",
        localityName: "haidian",
        organizationName: "organization",
        commonName: "test_csr"
    )

    let ipv4: IP = [8, 8, 8, 8]

    let csrInfo = X509CertificateRequestInfo(
        subject: subjectName,
        dnsNames: ["test.example.com"],
        IPAddresses: [ipv4]
    )

    // 创建证书签名请求
    let csr = X509CertificateRequest(privateKey, certificateRequestInfo: csrInfo, signatureAlgorithm: SHA256WithRSA)

    // 输出证书签名请求信息
    println("证书签名请求创建成功")
    println("使用者: ${csr.subject.toString()}")
    println("DNS 名称: ${csr.dnsNames}")

    // 清理测试文件
    removeIfExists("./test_csr_key.pem")
    return 0
}
```

运行结果：

```text
证书签名请求创建成功
使用者: c=CN,st=beijing,l=haidian,o=organization,cn=test_csr
DNS 名称: [test.example.com]
```
