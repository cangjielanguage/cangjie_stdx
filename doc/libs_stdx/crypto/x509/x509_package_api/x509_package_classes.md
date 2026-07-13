# 类

## class GeneralDHParameters

```cangjie
public class GeneralDHParameters <: DHParameters
```

功能：通用的 DH 密钥参数加解密功能实现。

父类型：

- [DHParameters](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-dhparameters)

### static func decodeDer(DerBlob)

```cangjie
public static func decodeDer(encoded: DerBlob): DHParameters
```

功能：将 DH 密钥参数从 DER 格式解码。

> **说明：**
>
> - DH（Diffie-Hellman）密钥交换协议是一种确保共享 KEY 安全穿越不安全网络的方法。
> - DER 和 PEM 是两种常见的编码格式。

参数：

- encoded: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - DER 格式的 DH 密钥参数对象。

返回值：

- [DHParameters](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-dhparameters) - 由 DER 格式解码出的 DH 密钥参数。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.x509.*
import stdx.crypto.common.*

main() {
    // 生成测试用DH参数文件
    let dhPem = "./test_dh.pem03"
    let dhDer = "./test_dh.der"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl dhparam -out ${dhPem} 1024 && " + "openssl dhparam -in ${dhPem} -outform DER -out ${dhDer}"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从 DerBlob 解码DH参数
    let dhBlob = DerBlob(readToEnd(File(dhDer, Read)))
    let dhParams = GeneralDHParameters.decodeDer(dhBlob)
    println("DH参数DER解码成功")
    println("解码后类型: ${dhParams}")

    // 删除测试用文件
    removeIfExists(dhPem)
    removeIfExists(dhDer)
    return 0
}
```

运行结果：

```text
DH参数DER解码成功
解码后类型: DHParameters(138 bytes)
```

### static func decodeFromPem(String)

```cangjie
public static func decodeFromPem(text: String): DHParameters
```

功能：将 DH 密钥参数从 PEM 格式解码。

参数：

- text: String - PEM 格式的 DH 密钥参数字符流。

返回值：

- [DHParameters](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-dhparameters) - 由 PEM 格式解码出的 DH 密钥参数。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.x509.*

main() {
    // 生成测试用DH参数文件
    let dhPem = "./test_dh.pem04"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl dhparam -out ${dhPem} 1024"

    executeWithOutput("sh", ["-c", cmdStr])

    // 读取PEM格式的DH参数内容
    let pemContent = String.fromUtf8(readToEnd(File(dhPem, Read)))

    // 从 PEM 字符串解码DH参数
    let dhParams = GeneralDHParameters.decodeFromPem(pemContent)
    println("DH参数PEM解码成功")
    println("解码后类型: ${dhParams}")

    // 删除测试用文件
    removeIfExists(dhPem)
    return 0
}
```

运行结果：

```text
DH参数PEM解码成功
解码后类型: DHParameters(138 bytes)
```

### func encodeToDer()

```cangjie
public override func encodeToDer(): DerBlob
```

功能：将 DH 密钥参数编码为 DER 格式。

返回值：

- [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - DH 密钥参数数据 DER 格式编码生成的对象。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.x509.*
import stdx.crypto.common.*

main() {
    // 生成测试用DH参数文件
    let dhPem = "./test_dh.pem05"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl dhparam -out ${dhPem} 1024"

    executeWithOutput("sh", ["-c", cmdStr])

    // 读取PEM格式的DH参数内容并解码
    let pemContent = String.fromUtf8(readToEnd(File(dhPem, Read)))
    let dhParams = GeneralDHParameters.decodeFromPem(pemContent)

    // 将DH参数编码为DER格式
    let derBlob = dhParams.encodeToDer()
    println("DH参数编码为DER格式成功")
    println("DER数据大小: ${derBlob.size}")

    // 删除测试用文件
    removeIfExists(dhPem)
    return 0
}
```

运行结果：

```text
DH参数编码为DER格式成功
DER数据大小: 138
```

### func encodeToPem()

```cangjie
public func encodeToPem(): PemEntry
```

功能：将 DH 密钥参数编码为 PEM 格式。

返回值：

- [PemEntry](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-pementry) - DH 密钥参数数据 PEM 格式编码生成的对象。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.x509.*

main() {
    // 生成测试用DH参数文件
    let dhPem = "./test_dh.pem06"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl dhparam -out ${dhPem} 1024"

    executeWithOutput("sh", ["-c", cmdStr])

    // 读取PEM格式的DH参数内容并解码
    let pemContent = String.fromUtf8(readToEnd(File(dhPem, Read)))
    let dhParams = GeneralDHParameters.decodeFromPem(pemContent)

    // 将DH参数编码为PEM格式
    let pemEntry = dhParams.encodeToPem()
    println("DH参数编码为PEM格式成功")
    println("PEM标签: ${pemEntry.label}")

    // 删除测试用文件
    removeIfExists(dhPem)
    return 0
}
```

运行结果：

```text
DH参数编码为PEM格式成功
PEM标签: DH PARAMETERS
```

### func toString()

```cangjie
public override func toString(): String
```

功能：转换为字符串格式。

返回值：

- String - 字符串。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.x509.*

main() {
    // 生成测试用DH参数文件
    let dhPem = "./test_dh.pem07"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl dhparam -out ${dhPem} 1024"

    executeWithOutput("sh", ["-c", cmdStr])

    // 读取PEM格式的DH参数内容并解码
    let pemContent = String.fromUtf8(readToEnd(File(dhPem, Read)))
    let dhParams = GeneralDHParameters.decodeFromPem(pemContent)

    // 获取DH参数的字符串表示
    let typeStr = dhParams.toString()
    println("DH参数类型: ${typeStr}")

    // 删除测试用文件
    removeIfExists(dhPem)
    return 0
}
```

运行结果：

```text
DH参数类型: DHParameters(138 bytes)
```

## class X509Certificate

```cangjie
public class X509Certificate <: Certificate & Equatable<X509Certificate> & Hashable & ToString {
    public init(
        certificateInfo: X509CertificateInfo,
        parent!: X509Certificate,
        publicKey!: PublicKey,
        privateKey!: PrivateKey,
        signatureAlgorithm!: ?SignatureAlgorithm = None
    )
}
```

功能：X509 数字证书是一种用于加密通信的数字证书，它是公钥基础设施（PKI）的核心组件之一。X509 数字证书包含了一个实体的公钥和身份信息，用于验证该实体的身份和确保通信的安全性。

父类型：

- [Certificate](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-certificate)
- Equatable\<[X509Certificate](#class-x509certificate)>
- Hashable
- ToString

### prop dnsNames

```cangjie
public prop dnsNames: Array<String>
```

功能：解析数字证书备选名称中的域名。

类型：Array\<String>

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 找到系统根证书中的ISRG Root X1证书用作演示
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        // 如果找不到ISRG Root X1可以选择其他证书作演示
        if (cert.issuer.commonName == "ISRG Root X1") {
            let x509Certificate: X509Certificate = cert
            // 打印证书的DNS名称
            println("DNS Names: ${x509Certificate.dnsNames}")
            break
        }
    }
}
```

运行结果：

```text
DNS Names: []
```

### prop emailAddresses

```cangjie
public prop emailAddresses: Array<String>
```

功能：解析数字证书备选名称中的 email 地址。

类型：Array\<String>

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 找到系统根证书中的ISRG Root X1证书用作演示
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        // 如果找不到ISRG Root X1可以选择其他证书作演示
        if (cert.issuer.commonName == "ISRG Root X1") {
            let x509Certificate: X509Certificate = cert
            // 打印证书的Email地址
            println("Email Addresses: ${x509Certificate.emailAddresses}")
            break
        }
    }
}
```

运行结果：

```text
Email Addresses: []
```

### prop extKeyUsage

```cangjie
public prop extKeyUsage: ExtKeyUsage
```

功能：解析数字证书中的扩展密钥用法。

类型：[ExtKeyUsage](x509_package_structs.md#struct-extkeyusage)

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 找到系统根证书中的ISRG Root X1证书用作演示
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        // 如果找不到ISRG Root X1可以选择其他证书作演示
        if (cert.issuer.commonName == "ISRG Root X1") {
            let x509Certificate: X509Certificate = cert
            // 打印证书的扩展密钥用法
            println("Ext Key Usage: ${x509Certificate.extKeyUsage}")
            break
        }
    }
}
```

运行结果：

```text
Ext Key Usage:
```

### prop IPAddresses

```cangjie
public prop IPAddresses: Array<IP>
```

功能：解析数字证书备选名称中的 [IP](x509_package_type.md#type-ip) 地址。

类型：Array\<[IP](x509_package_type.md#type-ip)>

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 找到系统根证书中的ISRG Root X1证书用作演示
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        // 如果找不到ISRG Root X1可以选择其他证书作演示
        if (cert.issuer.commonName == "ISRG Root X1") {
            let x509Certificate: X509Certificate = cert
            // 打印证书的IP地址
            println("IP Addresses: ${x509Certificate.IPAddresses}")
            break
        }
    }
}
```

运行结果：

```text
IP Addresses: []
```

### prop issuer

```cangjie
public prop issuer: X509Name
```

功能：解析数字证书的颁发者信息。

类型：[X509Name](x509_package_classes.md#class-x509name)

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 找到系统根证书中的ISRG Root X1证书用作演示
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        // 如果找不到ISRG Root X1可以选择其他证书作演示
        if (cert.issuer.commonName == "ISRG Root X1") {
            let x509Certificate: X509Certificate = cert
            // 打印证书的颁发者信息
            println("Issuer: ${x509Certificate.issuer}")
            break
        }
    }
}
```

运行结果：

```text
Issuer: c=US,o=Internet Security Research Group,cn=ISRG Root X1
```

### prop keyUsage

```cangjie
public prop keyUsage: KeyUsage
```

功能：解析数字证书中的密钥用法。

类型：[KeyUsage](x509_package_structs.md#struct-keyusage)

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 找到系统根证书中的ISRG Root X1证书用作演示
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        // 如果找不到ISRG Root X1可以选择其他证书作演示
        if (cert.issuer.commonName == "ISRG Root X1") {
            let x509Certificate: X509Certificate = cert
            // 打印证书的密钥用法
            println("Key Usage: ${x509Certificate.keyUsage}")
            break
        }
    }
}
```

运行结果：

```text
Key Usage: CRLSign, CertSign
```

### prop notAfter

```cangjie
public prop notAfter: DateTime
```

功能：解析数字证书的有效期截止时间。

类型：DateTime

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 找到系统根证书中的ISRG Root X1证书用作演示
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        // 如果找不到ISRG Root X1可以选择其他证书作演示
        if (cert.issuer.commonName == "ISRG Root X1") {
            let x509Certificate: X509Certificate = cert
            // 打印证书的有效期截止时间
            println("Not After: ${x509Certificate.notAfter}")
            break
        }
    }
}
```

运行结果：

```text
Not After: 2035-06-04T11:04:38Z
```

### prop notBefore

```cangjie
public prop notBefore: DateTime
```

功能：解析数字证书的有效期开始时间。

类型：DateTime

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 找到系统根证书中的ISRG Root X1证书用作演示
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        // 如果找不到ISRG Root X1可以选择其他证书作演示
        if (cert.issuer.commonName == "ISRG Root X1") {
            let x509Certificate: X509Certificate = cert
            // 打印证书的有效期开始时间
            println("Not Before: ${x509Certificate.notBefore}")
            break
        }
    }
}
```

运行结果：

```text
Not Before: 2015-06-04T11:04:38Z
```

### prop publicKey

```cangjie
public prop publicKey: PublicKey
```

功能：解析数字证书的公钥。

类型：[PublicKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-publickey)

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 找到系统根证书中的ISRG Root X1证书用作演示
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        // 如果找不到ISRG Root X1可以选择其他证书作演示
        if (cert.issuer.commonName == "ISRG Root X1") {
            let x509Certificate: X509Certificate = cert
            // 打印证书的公钥信息
            println("Public Key: ${x509Certificate.publicKey}")
            break
        }
    }
}
```

运行结果：

```text
Public Key: PublicKey(for 2.5.4.6: US
2.5.4.10: Internet Security Research Group
2.5.4.3: ISRG Root X1
)
```

### prop publicKeyAlgorithm

```cangjie
public prop publicKeyAlgorithm: PublicKeyAlgorithm
```

功能：解析数字证书的公钥算法。

类型：[PublicKeyAlgorithm](x509_package_enums.md#enum-publickeyalgorithm)

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 找到系统根证书中的ISRG Root X1证书用作演示
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        // 如果找不到ISRG Root X1可以选择其他证书作演示
        if (cert.issuer.commonName == "ISRG Root X1") {
            let x509Certificate: X509Certificate = cert
            // 打印证书的公钥算法
            println("Public Key Algorithm: ${x509Certificate.publicKeyAlgorithm}")
            break
        }
    }
}
```

运行结果：

```text
Public Key Algorithm: Public Key Algorithm: rsaEncryption
```

### prop serialNumber

```cangjie
public prop serialNumber: SerialNumber
```

功能：解析数字证书的序列号。

类型：[SerialNumber](x509_package_structs.md#struct-serialnumber)

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 找到系统根证书中的ISRG Root X1证书用作演示
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        // 如果找不到ISRG Root X1可以选择其他证书作演示
        if (cert.issuer.commonName == "ISRG Root X1") {
            let x509Certificate: X509Certificate = cert
            // 打印证书的序列号
            println("Serial Number: ${x509Certificate.serialNumber}")
            break
        }
    }
}
```

运行结果：

```text
Serial Number: 8210CFB0D240E3594463E0BB63828B00
```

### prop signature

```cangjie
public prop signature: Signature
```

功能：解析数字证书的签名。

类型：[Signature](x509_package_structs.md#struct-signature)

示例：

<!-- run -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 找到系统根证书中的ISRG Root X1证书用作演示
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        // 如果找不到ISRG Root X1可以选择其他证书作演示
        if (cert.issuer.commonName == "ISRG Root X1") {
            let x509Certificate: X509Certificate = cert
            // 获取证书的签名
            let signature = x509Certificate.signature
            break
        }
    }
}
```

### prop signatureAlgorithm

```cangjie
public prop signatureAlgorithm: SignatureAlgorithm
```

功能：解析数字证书的签名算法。

类型：[SignatureAlgorithm](./x509_package_enums.md#enum-signaturealgorithm)

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 找到系统根证书中的ISRG Root X1证书用作演示
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        // 如果找不到ISRG Root X1可以选择其他证书作演示
        if (cert.issuer.commonName == "ISRG Root X1") {
            let x509Certificate: X509Certificate = cert
            // 打印证书的签名算法
            println(x509Certificate.signatureAlgorithm)
            break
        }
    }
}
```

运行结果：

```text
Signature Algorithm: sha256WithRSAEncryption
```

### prop subject

```cangjie
public prop subject: X509Name
```

功能：解析数字证书的使用者信息。

类型：[X509Name](x509_package_classes.md#class-x509name)

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 找到系统根证书中的ISRG Root X1证书用作演示
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        // 如果找不到ISRG Root X1可以选择其他证书作演示
        if (cert.issuer.commonName == "ISRG Root X1") {
            let x509Certificate: X509Certificate = cert
            // 打印证书的使用者信息
            println("Subject: ${x509Certificate.subject}")
            break
        }
    }
}
```

运行结果：

```text
Subject: c=US,o=Internet Security Research Group,cn=ISRG Root X1
```

### init(X509CertificateInfo, X509Certificate, PublicKey, PrivateKey, ?SignatureAlgorithm)

```cangjie
public init(
    certificateInfo: X509CertificateInfo,
    parent!: X509Certificate,
    publicKey!: PublicKey,
    privateKey!: PrivateKey,
    signatureAlgorithm!: ?SignatureAlgorithm = None
)
```

功能：创建数字证书对象。

参数：

- certificateInfo: [X509CertificateInfo](x509_package_structs.md#struct-x509certificateinfo) - 数字证书配置信息。
- parent!: [X509Certificate](x509_package_classes.md#class-x509certificate) - 颁发者证书。
- publicKey!: [PublicKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-publickey) - 申请人公钥，仅支持 RSA、ECDSA 和 DSA 公钥。
- privateKey!: [PrivateKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey) - 颁发者私钥，仅支持 RSA、ECDSA 和 DSA 私钥。
- signatureAlgorithm!: ?[SignatureAlgorithm](./x509_package_enums.md#enum-signaturealgorithm) - 证书签名算法，默认值为 None，使用默认值时默认的摘要类型是 [SHA256](../../digest/digest_package_api/digest_package_classes.md#class-sha256)。

异常：

- [X509Exception](./x509_package_exceptions.md#class-x509exception) - 公钥或私钥类型不支持、私钥类型和证书签名算法中的私钥类型不匹配或数字证书信息设置失败时，抛出异常。

示例：

<!-- run -->
```cangjie
import std.fs.*
import std.io.*
import std.time.*
import std.process.*
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main() {
    // 生成测试用的根证书和密钥对
    let rootCertPem = "./test_root_cert.pem"
    let rootKeyPem = "./test_root_key.pem"
    let caKeyPem = "./test_ca_key.pem"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${rootKeyPem} 2048 && " +
        "openssl req -new -x509 -key ${rootKeyPem} -out ${rootCertPem} -days 365 -subj '/CN=TestRootCA' && " +
        "openssl genrsa -out ${caKeyPem} 2048"

    executeWithOutput("sh", ["-c", cmdStr])

    // 读取根证书
    let rootCertContent = String.fromUtf8(readToEnd(File(rootCertPem, Read)))
    let rootCerts = X509Certificate.decodeFromPem(rootCertContent)
    let rootCert = rootCerts[0]

    // 读取根私钥
    let rootKeyContent = String.fromUtf8(readToEnd(File(rootKeyPem, Read)))
    let rootPrivateKey = GeneralPrivateKey.decodeFromPem(rootKeyContent)

    // 读取CA私钥
    let caKeyContent = String.fromUtf8(readToEnd(File(caKeyPem, Read)))
    let caKey = RSAPrivateKey.decodeFromPem(caKeyContent)

    // 获取CA的公钥
    let caPubKey = RSAPublicKey(caKey)

    // 创建X509证书对象的参数
    let x509Name = X509Name(commonName: "TestCA")
    let startTime = DateTime.of(year: 2023, month: 1, dayOfMonth: 1)
    let endTime = DateTime.of(year: 2025, month: 1, dayOfMonth: 1)
    let serialNumber = SerialNumber()
    let certInfo = X509CertificateInfo(
        serialNumber: serialNumber,
        notBefore: startTime,
        notAfter: endTime,
        subject: x509Name,
        dnsNames: [],
        IPAddresses: [],
        emailAddresses: [],
        keyUsage: KeyUsage(KeyUsage.DigitalSignature | KeyUsage.CertSign | KeyUsage.CRLSign),
        extKeyUsage: ExtKeyUsage([ExtKeyUsage.ServerAuth])
    )

    // 创建X509证书对象
    let cert = X509Certificate(certInfo, parent: rootCert, publicKey: caPubKey, privateKey: rootPrivateKey)

    // 删除测试用文件
    removeIfExists(rootCertPem)
    removeIfExists(rootKeyPem)
    removeIfExists(caKeyPem)
    return 0
}
```

### static func decodeFromDer(DerBlob)

```cangjie
public static func decodeFromDer(der: DerBlob): X509Certificate
```

功能：将 DER 格式的数字证书解码。

参数：

- der: [DerBlob](./../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - DER 格式的二进制数据。

返回值：

- [X509Certificate](x509_package_classes.md#class-x509certificate) - 由 DER 格式解码出的数字证书。

异常：

- [X509Exception](./x509_package_exceptions.md#class-x509exception) - 数据为空时，或数据不是有效的数字证书 DER 格式时抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.common.*
import stdx.crypto.x509.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 DerBlob（此处通过系统根证书ISRG Root X1模拟）
    var derDataOpt: ?DerBlob = None
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        if (cert.issuer.commonName == "ISRG Root X1") {
            // 将证书编码为DER格式
            derDataOpt = cert.encodeToDer()
            break
        }
    }
    // 获取到DER数据
    let derData = derDataOpt.getOrThrow()

    // 从DER数据解码证书
    let decodedCert = X509Certificate.decodeFromDer(derData)

    println("解码后根证书的通用名称: ${decodedCert.issuer.commonName}")
}
```

运行结果：

```text
解码后根证书的通用名称: Some(ISRG Root X1)
```

### static func decodeFromPem(String)

```cangjie
public static func decodeFromPem(pem: String): Array<X509Certificate>
```

功能：将数字证书从 PEM 格式解码。

参数：

- pem: String - PEM 格式的数字证书字符流。

返回值：

- Array\<[X509Certificate](x509_package_classes.md#class-x509certificate)> - 由 PEM 格式解码出的数字证书数组。

异常：

- [X509Exception](./x509_package_exceptions.md#class-x509exception) - 字符流不符合 PEM 格式时，或文件头不符合数字证书头标准时抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 模拟场景：从外部（文件/网络）获取的PEM格式证书字符串（此处通过系统根证书ISRG Root X1模拟）
    var pemStrOpt: ?String = None
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        if (cert.issuer.commonName == "ISRG Root X1") {
            // 将证书编码为PEM格式
            let pemEntry = cert.encodeToPem()
            pemStrOpt = pemEntry.encode()
            break
        }
    }
    // 获取到PEM字符串
    let pemStr = pemStrOpt.getOrThrow()

    // 从PEM字符串解码证书
    let decodedCerts = X509Certificate.decodeFromPem(pemStr)

    println("解码后证书数组长度: ${decodedCerts.size}")
    println("解码后根证书的通用名称: ${decodedCerts[0].issuer.commonName}")
}
```

运行结果：

```text
解码后证书数组长度: 1
解码后根证书的通用名称: Some(ISRG Root X1)
```

### static func systemRootCerts()

```cangjie
public static func systemRootCerts(): Array<X509Certificate>
```

功能：返回操作系统的根证书。

返回值：

- Array\<[X509Certificate](x509_package_classes.md#class-x509certificate)> - 操作系统的根证书链。

示例：

<!-- run -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 获取系统根证书
    let rootCerts = X509Certificate.systemRootCerts()

    println("系统根证书数量: ${rootCerts.size}")
    if (rootCerts.size > 0) {
        // 打印第一个证书的通用名称
        println("第一个根证书的通用名称: ${rootCerts[0].issuer.commonName}")
    }
}
```

可能的运行结果：

```text
系统根证书数量: 100
第一个根证书的通用名称: Some(ISRG Root X1)
```

### func encodeToDer()

```cangjie
public func encodeToDer(): DerBlob
```

功能：将数字证书编码成 Der 格式。

返回值：

- [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 编码后的 Der 格式的数字证书。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 模拟场景：已有的X509证书对象（此处通过系统根证书ISRG Root X1模拟）
    var certOpt: ?X509Certificate = None
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        if (cert.issuer.commonName == "ISRG Root X1") {
            certOpt = cert
            break
        }
    }
    // 将证书编码为DER格式
    let derBlob = certOpt?.encodeToDer()

    println("DER格式证书数据长度: ${derBlob?.size ?? 0}")
}
```

运行结果：

```text
DER格式证书数据长度: 1391
```

### func encodeToPem()

```cangjie
public func encodeToPem(): PemEntry
```

功能：将数字证书编码成 PEM 格式。

返回值：

- [PemEntry](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-pementry) - 编码后的 PEM 格式的数字证书。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 模拟场景：已有的X509证书对象（此处通过系统根证书ISRG Root X1模拟）
    var certOpt: ?X509Certificate = None
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        if (cert.issuer.commonName == "ISRG Root X1") {
            certOpt = cert
            break
        }
    }

    // 将证书编码为PEM格式
    let pemEntry = certOpt?.encodeToPem()

    println("PEM格式证书编码后字符串长度: ${pemEntry?.encode().size ?? 0}")
}
```

运行结果：

```text
PEM格式证书编码后字符串长度: 1939
```

### func hashCode()

```cangjie
public override func hashCode(): Int64
```

功能：返回证书哈希值。

返回值：

- Int64 - 对证书对象进行哈希计算后得到的结果。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 模拟场景：已有的X509证书对象（此处通过系统根证书ISRG Root X1模拟）
    var certOpt: ?X509Certificate = None
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        if (cert.issuer.commonName == "ISRG Root X1") {
            certOpt = cert
            break
        }
    }

    // 获取证书哈希值
    let hashCode = certOpt?.hashCode()

    println("证书哈希值: ${hashCode ?? 0}")
}
```

运行结果：

```text
证书哈希值: -3207102703759299675
```

### func toString()

```cangjie
public override func toString(): String
```

功能：生成证书名称字符串，包含证书的使用者信息、有效期以及颁发者信息。

返回值：

- String - 证书名称字符串。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 模拟场景：已有的X509证书对象（此处通过系统根证书ISRG Root X1模拟）
    var certOpt: ?X509Certificate = None
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        if (cert.issuer.commonName == "ISRG Root X1") {
            certOpt = cert
            break
        }
    }

    // 获取证书字符串表示
    let certStr = certOpt?.toString()

    println("证书字符串表示: ${certStr ?? "未找到证书"}")
}
```

运行结果：

```text
证书字符串表示: X509Certificate(for=c=US,o=Internet Security Research Group,cn=ISRG Root X1, valid in 2015-06-04T11:04:38Z..2035-06-04T11:04:38Z, issued by c=US,o=Internet Security Research Group,cn=ISRG Root X1)
```

### func verify(VerifyOption)

```cangjie
public func verify(verifyOption: VerifyOption): Bool
```

功能：根据验证选项验证当前证书的有效性。

验证优先级：

1. 优先验证有效期；
2. 可选验证 DNS 域名；
3. 最后根据根证书和中间证书验证其有效性。

参数：

- verifyOption: [VerifyOption](x509_package_structs.md#struct-verifyoption) - 证书验证选项。

返回值：

- Bool - 证书有效返回 true，否则返回 false。

异常：

- [X509Exception](./x509_package_exceptions.md#class-x509exception) - 检验过程中失败，比如内存分配异常等内部错误，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*
import std.time.*

main() {
    // 模拟场景：已有的X509证书对象（此处通过系统根证书ISRG Root X1模拟）
    var certOpt: ?X509Certificate = None
    let certs = X509Certificate.systemRootCerts()
    for (cert in certs) {
        if (cert.issuer.commonName == "ISRG Root X1") {
            certOpt = cert
            break
        }
    }

    // 创建验证选项
    var verifyOpt = VerifyOption()
    // 设置验证时间
    verifyOpt.time = DateTime.of(year: 2036, month: 1, dayOfMonth: 1)
    // 验证证书
    let isValid = certOpt?.verify(verifyOpt)

    println("证书是否有效: ${isValid ?? false}")

    // 创建另一个验证选项
    var verifyOpt2 = VerifyOption()
    verifyOpt2.time = DateTime.of(year: 2026, month: 1, dayOfMonth: 1)
    // 验证证书
    let isValid2 = certOpt?.verify(verifyOpt2)

    println("证书是否有效: ${isValid2 ?? false}")
}
```

运行结果：

```text
证书是否有效: false
证书是否有效: true
```

### operator func !=(X509Certificate)

```cangjie
public override operator func !=(other: X509Certificate): Bool
```

功能：判不等。

参数：

- other: [X509Certificate](x509_package_classes.md#class-x509certificate) - 被比较的证书对象。

返回值：

- Bool - 若证书不同，返回 true；否则，返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 模拟场景：已有的X509证书对象（此处通过系统根证书ISRG Root X1模拟）
    var certOpt1: ?X509Certificate = None
    var certOpt2: ?X509Certificate = None
    let certs = X509Certificate.systemRootCerts()
    var i = 0
    for (cert in certs) {
        if (i == 0 && cert.issuer.commonName == "ISRG Root X1") {
            certOpt1 = cert
            i = 1
        } else if (i == 1) {
            certOpt2 = cert
            break
        }
    }

    // 比较两个证书是否不相等
    let isNotEqual = certOpt1 != certOpt2

    println("两个不同证书是否不相等: ${isNotEqual}")

    // 比较同一个证书是否不相等
    let isNotEqualSelf = certOpt1 != certOpt1
    println("同一个证书是否与自身不相等: ${isNotEqualSelf}")
}
```

运行结果：

```text
两个不同证书是否不相等: true
同一个证书是否与自身不相等: false
```

### operator func ==(X509Certificate)

```cangjie
public override operator func ==(other: X509Certificate): Bool
```

功能：判等。

参数：

- other: [X509Certificate](x509_package_classes.md#class-x509certificate) - 被比较的证书对象。

返回值：

- Bool - 若证书相同，返回 true；否则，返回 false。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 模拟场景：已有的X509证书对象（此处通过系统根证书ISRG Root X1模拟）
    var certOpt1: ?X509Certificate = None
    var certOpt2: ?X509Certificate = None
    let certs = X509Certificate.systemRootCerts()
    var i = 0
    for (cert in certs) {
        if (i == 0 && cert.issuer.commonName == "ISRG Root X1") {
            certOpt1 = cert
            i = 1
        } else if (i == 1) {
            certOpt2 = cert
            break
        }
    }

    // 比较两个不同证书是否相等
    let isEqual = certOpt1 == certOpt2

    println("两个不同证书是否相等: ${isEqual}")

    // 比较同一个证书是否相等
    let isEqualSelf = certOpt1 == certOpt1
    println("同一个证书是否与自身相等: ${isEqualSelf}")
}
```

运行结果：

```text
两个不同证书是否相等: false
同一个证书是否与自身相等: true
```

## class X509CertificateRequest

```cangjie
public class X509CertificateRequest <: Hashable & ToString {
    public init(
        privateKey: PrivateKey,
        certificateRequestInfo!: ?X509CertificateRequestInfo = None,
        signatureAlgorithm!: ?SignatureAlgorithm = None
    )
}
```

功能：数字证书签名请求。

父类型：

- Hashable
- ToString

### prop dnsNames

```cangjie
public prop dnsNames: Array<String>
```

功能：解析数字证书签名请求备选名称中的域名。

类型：Array\<String>

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main() {
    // 创建测试用的私钥
    let rsaKey = RSAPrivateKey(2048)

    // 创建证书请求信息
    let x509Name = X509Name(
        countryName: "CN",
        provinceName: "Beijing",
        localityName: "Haidian",
        organizationName: "ExampleTech Inc.",
        organizationalUnitName: "CA Department",
        commonName: "example.com",
        email: "test@email.com"
    )

    let csrInfo = X509CertificateRequestInfo(subject: x509Name, dnsNames: ["test.example.com"])
    let csr = X509CertificateRequest(rsaKey, certificateRequestInfo: csrInfo, signatureAlgorithm: SHA256WithRSA)

    // 获取证书请求的DNS名称
    let dnsNames = csr.dnsNames
    println("DNS Names: ${dnsNames}")
}
```

运行结果：

```text
DNS Names: [test.example.com]
```

### prop emailAddresses

```cangjie
public prop emailAddresses: Array<String>
```

功能：解析数字证书签名请求备选名称中的 email 地址。

类型：Array\<String>

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main() {
    // 创建测试用的私钥
    let rsaKey = RSAPrivateKey(2048)

    // 创建证书请求信息
    let x509Name = X509Name(
        countryName: "CN",
        provinceName: "Beijing",
        localityName: "Haidian",
        organizationName: "ExampleTech Inc.",
        organizationalUnitName: "CA Department",
        commonName: "example.com",
        email: "test@email.com"
    )

    let csrInfo = X509CertificateRequestInfo(subject: x509Name, emailAddresses: ["user@example.com"])
    let csr = X509CertificateRequest(rsaKey, certificateRequestInfo: csrInfo, signatureAlgorithm: SHA256WithRSA)

    // 获取证书请求的邮箱地址
    let emailAddresses = csr.emailAddresses
    println("Email Addresses: ${emailAddresses}")
}
```

运行结果：

```text
Email Addresses: [user@example.com]
```

### prop IPAddresses

```cangjie
public prop IPAddresses: Array<IP>
```

功能：解析数字证书签名请求备选名称中的 [IP](x509_package_type.md#type-ip) 地址。

类型：Array\<[IP](x509_package_type.md#type-ip)>

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main() {
    // 创建测试用的私钥
    let rsaKey = RSAPrivateKey(2048)

    // 创建证书请求信息
    let x509Name = X509Name(
        countryName: "CN",
        provinceName: "Beijing",
        localityName: "Haidian",
        organizationName: "ExampleTech Inc.",
        organizationalUnitName: "CA Department",
        commonName: "192, 168, 1, 1",
        email: "test@email.com"
    )

    let ip1: IP = [192, 168, 1, 1] // 演示常用，无实际指向
    let ip2: IP = [32, 1, 13, 184, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1] // 示例IPv6（RFC 3849保留地址） 

    let csrInfo = X509CertificateRequestInfo(subject: x509Name, IPAddresses: [ip1, ip2])
    let csr = X509CertificateRequest(rsaKey, certificateRequestInfo: csrInfo, signatureAlgorithm: SHA256WithRSA)

    // 获取证书请求的IP地址
    let ipAddresses = csr.IPAddresses
    println("IP Addresses: ${ipAddresses}")
}
```

运行结果：

```text
IP Addresses: [[192, 168, 1, 1], [32, 1, 13, 184, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]]
```

### prop publicKey

```cangjie
public prop publicKey: PublicKey
```

功能：解析数字证书签名请求的公钥。

类型：[PublicKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-publickey)

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main() {
    // 创建测试用的私钥
    let rsaKey = RSAPrivateKey(2048)

    // 创建证书请求信息
    let x509Name = X509Name(
        countryName: "CN",
        provinceName: "Beijing",
        localityName: "Haidian",
        organizationName: "ExampleTech Inc.",
        organizationalUnitName: "CA Department",
        commonName: "example.com",
        email: "test@email.com"
    )

    let csrInfo = X509CertificateRequestInfo(subject: x509Name)
    let csr = X509CertificateRequest(rsaKey, certificateRequestInfo: csrInfo, signatureAlgorithm: SHA256WithRSA)

    // 获取证书请求的公钥
    let publicKey = csr.publicKey
    println("Public Key: ${publicKey}")
}
```

运行结果：

```text
Public Key: PublicKey(for 2.5.4.6: CN
2.5.4.8: Beijing
2.5.4.7: Haidian
2.5.4.10: ExampleTech Inc.
2.5.4.11: CA Department
2.5.4.3: example.com
1.2.840.113549.1.9.1: test@email.com
)
```

### prop publicKeyAlgorithm

```cangjie
public prop publicKeyAlgorithm: PublicKeyAlgorithm
```

功能：解析数字证书签名请求的公钥算法。

类型：[PublicKeyAlgorithm](x509_package_enums.md#enum-publickeyalgorithm)

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main() {
    // 创建测试用的私钥
    let rsaKey = RSAPrivateKey(2048)

    // 创建证书请求信息
    let x509Name = X509Name(
        countryName: "CN",
        provinceName: "Beijing",
        localityName: "Haidian",
        organizationName: "ExampleTech Inc.",
        organizationalUnitName: "CA Department",
        commonName: "example.com",
        email: "test@email.com"
    )

    let csrInfo = X509CertificateRequestInfo(subject: x509Name)
    let csr = X509CertificateRequest(rsaKey, certificateRequestInfo: csrInfo, signatureAlgorithm: SHA256WithRSA)

    // 获取证书请求的公钥算法
    let publicKeyAlgorithm = csr.publicKeyAlgorithm
    println(publicKeyAlgorithm)
}
```

运行结果：

```text
Public Key Algorithm: rsaEncryption
```

### prop signature

```cangjie
public prop signature: Signature
```

功能：解析数字证书签名请求的签名。

类型：[Signature](x509_package_structs.md#struct-signature)

示例：

<!-- run -->
```cangjie
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main() {
    // 创建测试用的私钥
    let rsaKey = RSAPrivateKey(2048)

    // 创建证书请求信息
    let x509Name = X509Name(
        countryName: "CN",
        provinceName: "Beijing",
        localityName: "Haidian",
        organizationName: "ExampleTech Inc.",
        organizationalUnitName: "CA Department",
        commonName: "example.com",
        email: "test@email.com"
    )

    let csrInfo = X509CertificateRequestInfo(subject: x509Name)
    let csr = X509CertificateRequest(rsaKey, certificateRequestInfo: csrInfo, signatureAlgorithm: SHA256WithRSA)

    // 获取证书请求的签名
    let signature = csr.signature
}
```

### prop signatureAlgorithm

```cangjie
public prop signatureAlgorithm: SignatureAlgorithm
```

功能：解析数字证书签名请求的签名算法。

类型：[SignatureAlgorithm](./x509_package_enums.md#enum-signaturealgorithm)

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main() {
    // 创建测试用的私钥
    let rsaKey = RSAPrivateKey(2048)

    // 创建证书请求信息
    let x509Name = X509Name(
        countryName: "CN",
        provinceName: "Beijing",
        localityName: "Haidian",
        organizationName: "ExampleTech Inc.",
        organizationalUnitName: "CA Department",
        commonName: "example.com",
        email: "test@email.com"
    )

    let csrInfo = X509CertificateRequestInfo(subject: x509Name)
    let csr = X509CertificateRequest(rsaKey, certificateRequestInfo: csrInfo, signatureAlgorithm: SHA256WithRSA)

    // 获取证书请求的签名算法
    let signatureAlgorithm = csr.signatureAlgorithm
    println(signatureAlgorithm)
}
```

运行结果：

```text
Signature Algorithm: sha256WithRSAEncryption
```

### prop subject

```cangjie
public prop subject: X509Name
```

功能：解析数字证书签名请求的使用者信息。

类型：[X509Name](x509_package_classes.md#class-x509name)

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main() {
    // 创建测试用的私钥
    let rsaKey = RSAPrivateKey(2048)

    // 创建证书请求信息
    let x509Name = X509Name(
        countryName: "CN",
        provinceName: "Beijing",
        localityName: "Haidian",
        organizationName: "ExampleTech Inc.",
        organizationalUnitName: "CA Department",
        commonName: "example.com",
        email: "test@email.com"
    )

    let csrInfo = X509CertificateRequestInfo(subject: x509Name)
    let csr = X509CertificateRequest(rsaKey, certificateRequestInfo: csrInfo, signatureAlgorithm: SHA256WithRSA)

    // 获取证书请求的使用者信息
    let subject = csr.subject
    println("Subject: ${subject}")
}
```

运行结果：

```text
Subject: c=CN,st=Beijing,l=Haidian,o=ExampleTech Inc.,ou=CA Department,cn=example.com,email=test@email.com
```

### init(PrivateKey, ?X509CertificateRequestInfo, ?SignatureAlgorithm)

```cangjie
public init(
    privateKey: PrivateKey,
    certificateRequestInfo!: ?X509CertificateRequestInfo = None,
    signatureAlgorithm!: ?SignatureAlgorithm = None
)
```

功能：创建数字证书签名请求对象。

参数：

- privateKey: [PrivateKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey) - 私钥，仅支持 RSA、ECDSA 和 DSA 私钥。
- certificateRequestInfo!: ?[X509CertificateRequestInfo](x509_package_structs.md#struct-x509certificaterequestinfo) - 数字证书签名信息，默认值为 None。
- signatureAlgorithm!: ?[SignatureAlgorithm](./x509_package_enums.md#enum-signaturealgorithm) - 证书签名算法，默认值为 None，使用默认值时默认的摘要类型是 [SHA256](../../digest/digest_package_api/digest_package_classes.md#class-sha256)。

异常：

- [X509Exception](./x509_package_exceptions.md#class-x509exception) - 私钥类型不支持、私钥类型和证书签名算法中的私钥类型不匹配或数字证书签名信息设置失败时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main() {
    // 创建测试用的私钥
    let rsaKey = RSAPrivateKey(2048)

    // 创建证书请求信息
    let x509Name = X509Name(
        countryName: "CN",
        provinceName: "Beijing",
        localityName: "Haidian",
        organizationName: "ExampleTech Inc.",
        organizationalUnitName: "CA Department",
        commonName: "example.com",
        email: "test@email.com"
    )

    let csrInfo = X509CertificateRequestInfo(subject: x509Name)
    let csr = X509CertificateRequest(rsaKey, certificateRequestInfo: csrInfo, signatureAlgorithm: SHA256WithRSA)

    // 输出证书请求对象信息
    println("Certificate Request Subject: ${csr.subject}")
}
```

运行结果：

```text
Certificate Request Subject: c=CN,st=Beijing,l=Haidian,o=ExampleTech Inc.,ou=CA Department,cn=example.com,email=test@email.com
```

### static func decodeFromDer(DerBlob)

```cangjie
public static func decodeFromDer(der: DerBlob): X509CertificateRequest
```

功能：将 DER 格式的数字证书签名请求解码。

参数：

- der: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - DER 格式的二进制数据。

返回值：

- [X509CertificateRequest](x509_package_classes.md#class-x509certificaterequest) - 由 DER 格式解码出的数字证书签名请求。

异常：

- [X509Exception](./x509_package_exceptions.md#class-x509exception) - 数据为空时，或数据不是有效的数字证书签名请求 DER 格式时抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main() {
    // 创建测试用的私钥
    let rsaKey = RSAPrivateKey(2048)

    // 创建证书请求信息
    let x509Name = X509Name(
        countryName: "CN",
        provinceName: "Beijing",
        localityName: "Haidian",
        organizationName: "ExampleTech Inc.",
        organizationalUnitName: "CA Department",
        commonName: "example.com",
        email: "test@email.com"
    )

    let csrInfo = X509CertificateRequestInfo(subject: x509Name)
    let originalCsr = X509CertificateRequest(rsaKey, certificateRequestInfo: csrInfo, signatureAlgorithm: SHA256WithRSA)

    // 模拟场景：从外部（文件/网络）获取的 DerBlob（此处通过代码生成）
    let derBlob = originalCsr.encodeToDer()

    // 从DER格式解码证书请求
    let decodedCsr = X509CertificateRequest.decodeFromDer(derBlob)

    // 输出解码后的证书请求信息
    println("Decoded CSR Subject: ${decodedCsr.subject}")
}
```

运行结果：

```text
Decoded CSR Subject: c=CN,st=Beijing,l=Haidian,o=ExampleTech Inc.,ou=CA Department,cn=example.com,email=test@email.com
```

### static func decodeFromPem(String)

```cangjie
public static func decodeFromPem(pem: String): Array<X509CertificateRequest>
```

功能：将数字证书签名请求从 PEM 格式解码。

参数：

- pem: String - PEM 格式的数字证书签名请求字符流。

返回值：

- Array\<[X509CertificateRequest](x509_package_classes.md#class-x509certificaterequest)> - 由 PEM 格式解码出的数字证书签名请求数组。

异常：

- [X509Exception](./x509_package_exceptions.md#class-x509exception) - 字符流不符合 PEM 格式时，或文件头不符合数字证书签名请求头标准时抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main() {
    // 创建测试用的私钥
    let rsaKey = RSAPrivateKey(2048)

    // 创建证书请求信息
    let x509Name = X509Name(
        countryName: "CN",
        provinceName: "Beijing",
        localityName: "Haidian",
        organizationName: "ExampleTech Inc.",
        organizationalUnitName: "CA Department",
        commonName: "example.com",
        email: "test@email.com"
    )

    let csrInfo = X509CertificateRequestInfo(subject: x509Name)
    let originalCsr = X509CertificateRequest(rsaKey, certificateRequestInfo: csrInfo, signatureAlgorithm: SHA256WithRSA)

    // 模拟场景：从外部（文件/网络）获取的PEM字符串（此处通过代码生成）
    let pemEntry = originalCsr.encodeToPem()
    let pemString = pemEntry.encode()

    // 从PEM格式解码证书请求
    let decodedCsrs = X509CertificateRequest.decodeFromPem(pemString)
    let decodedCsr = decodedCsrs[0]

    // 输出解码后的证书请求信息
    println("Decoded CSR Subject: ${decodedCsr.subject}")
}
```

运行结果：

```text
Decoded CSR Subject: c=CN,st=Beijing,l=Haidian,o=ExampleTech Inc.,ou=CA Department,cn=example.com,email=test@email.com
```

### func encodeToDer()

```cangjie
public func encodeToDer(): DerBlob
```

功能：将数字证书签名请求编码成 Der 格式。

返回值：

- [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 编码后的 Der 格式的数字证书签名请求。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main() {
    // 创建测试用的私钥
    let rsaKey = RSAPrivateKey(2048)

    // 创建证书请求信息
    let x509Name = X509Name(
        countryName: "CN",
        provinceName: "Beijing",
        localityName: "Haidian",
        organizationName: "ExampleTech Inc.",
        organizationalUnitName: "CA Department",
        commonName: "example.com",
        email: "test@email.com"
    )

    let csrInfo = X509CertificateRequestInfo(subject: x509Name)
    let csr = X509CertificateRequest(rsaKey, certificateRequestInfo: csrInfo, signatureAlgorithm: SHA256WithRSA)

    // 将证书请求编码为DER格式
    let derBlob = csr.encodeToDer()

    // 输出DER数据的大小
    println("DER Blob Size: ${derBlob.size}")
}
```

运行结果：

```text
DER Blob Size: 767
```

### func encodeToPem()

```cangjie
public func encodeToPem(): PemEntry
```

功能：将数字证书签名请求编码成 PEM 格式。

返回值：

- [PemEntry](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-pementry) - 编码后的 PEM 格式的数字证书签名请求。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main() {
    // 创建测试用的私钥
    let rsaKey = RSAPrivateKey(2048)

    // 创建证书请求信息
    let x509Name = X509Name(
        countryName: "CN",
        provinceName: "Beijing",
        localityName: "Haidian",
        organizationName: "ExampleTech Inc.",
        organizationalUnitName: "CA Department",
        commonName: "example.com",
        email: "test@email.com"
    )

    let csrInfo = X509CertificateRequestInfo(subject: x509Name)
    let csr = X509CertificateRequest(rsaKey, certificateRequestInfo: csrInfo, signatureAlgorithm: SHA256WithRSA)

    // 将证书请求编码为PEM格式
    let pemEntry = csr.encodeToPem()

    // 输出PEM条目的标签
    println("PEM Entry Label: ${pemEntry.label}")
}
```

运行结果：

```text
PEM Entry Label: CERTIFICATE REQUEST
```

### func hashCode()

```cangjie
public override func hashCode(): Int64
```

功能：返回证书签名请求哈希值。

返回值：

- Int64 - 对证书签名请求对象进行哈希计算后得到的结果。

示例：

<!-- run -->
```cangjie
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main() {
    // 创建测试用的私钥
    let rsaKey = RSAPrivateKey(2048)

    // 创建证书请求信息
    let x509Name = X509Name(
        countryName: "CN",
        provinceName: "Beijing",
        localityName: "Haidian",
        organizationName: "ExampleTech Inc.",
        organizationalUnitName: "CA Department",
        commonName: "example.com",
        email: "test@email.com"
    )

    let csrInfo = X509CertificateRequestInfo(subject: x509Name)
    let csr = X509CertificateRequest(rsaKey, certificateRequestInfo: csrInfo, signatureAlgorithm: SHA256WithRSA)

    // 获取证书请求的哈希值
    let hashCode = csr.hashCode()

    // 输出哈希值
    println("Hash Code: ${hashCode}")
}
```

可能的运行结果：

```text
Hash Code: -461863998621080557
```

### func toString()

```cangjie
public override func toString(): String
```

功能：生成证书签名请求名称字符串，包含证书签名请求的使用者信息。

返回值：

- String - 证书签名请求名称字符串。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*
import stdx.crypto.keys.*

main() {
    // 创建测试用的私钥
    let rsaKey = RSAPrivateKey(2048)

    // 创建证书请求信息
    let x509Name = X509Name(
        countryName: "CN",
        provinceName: "Beijing",
        localityName: "Haidian",
        organizationName: "ExampleTech Inc.",
        organizationalUnitName: "CA Department",
        commonName: "example.com",
        email: "test@email.com"
    )

    let csrInfo = X509CertificateRequestInfo(subject: x509Name)
    let csr = X509CertificateRequest(rsaKey, certificateRequestInfo: csrInfo, signatureAlgorithm: SHA256WithRSA)

    // 获取证书请求的字符串表示
    let str = csr.toString()

    // 输出字符串表示
    println("String representation: ${str}")
}
```

运行结果：

```text
String representation: X509CertificateRequest(for c=CN,st=Beijing,l=Haidian,o=ExampleTech Inc.,ou=CA Department,cn=example.com,email=test@email.com)
```

## class X509Name

```cangjie
public class X509Name <: ToString {
    public init(
        countryName!: ?String = None,
        provinceName!: ?String = None,
        localityName!: ?String = None,
        organizationName!: ?String = None,
        organizationalUnitName!: ?String = None,
        commonName!: ?String = None,
        email!: ?String = None
    )
}
```

功能：证书实体可辨识名称（Distinguished Name）是数字证书中的一个重要组成部分，作用是确保证书的持有者身份的真实性和可信度，同时也是数字证书验证的重要依据之一。

[X509Name](x509_package_classes.md#class-x509name) 通常包含证书实体的国家或地区名称（Country Name）、州或省名称（State or Province Name）、城市名称（Locality Name）、组织名称（Organization Name）、组织单位名称（Organizational Unit Name）、通用名称（Common Name）。有时也会包含 email 地址。

父类型：

- ToString

### prop commonName

```cangjie
public prop commonName: ?String
```

功能：返回证书实体的通用名称。

类型：?String

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 创建X509Name对象
    let x509Name = X509Name(commonName: "example.com")

    // 获取通用名称
    let cn = x509Name.commonName
    println("Common Name: ${cn}")
}
```

运行结果：

```text
Common Name: Some(example.com)
```

### prop countryName

```cangjie
public prop countryName: ?String
```

功能：返回证书实体的国家或地区名称。

类型：?String

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 创建X509Name对象
    let x509Name = X509Name(countryName: "CN")

    // 获取国家或地区名称
    let country = x509Name.countryName
    println("Country Name: ${country}")
}
```

运行结果：

```text
Country Name: Some(CN)
```

### prop email

```cangjie
public prop email: ?String
```

功能：返回证书实体的 email 地址。

类型：?String

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 创建X509Name对象
    let x509Name = X509Name(email: "test@example.com")

    // 获取email地址
    let email = x509Name.email
    println("Email: ${email}")
}
```

运行结果：

```text
Email: Some(test@example.com)
```

### prop localityName

```cangjie
public prop localityName: ?String
```

功能：返回证书实体的城市名称。

类型：?String

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 创建X509Name对象
    let x509Name = X509Name(localityName: "Beijing")

    // 获取城市名称
    let locality = x509Name.localityName
    println("Locality Name: ${locality}")
}
```

运行结果：

```text
Locality Name: Some(Beijing)
```

### prop organizationalUnitName

```cangjie
public prop organizationalUnitName: ?String
```

功能：返回证书实体的组织单位名称。

类型：?String

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 创建X509Name对象
    let x509Name = X509Name(organizationalUnitName: "IT Department")

    // 获取组织单位名称
    let orgUnit = x509Name.organizationalUnitName
    println("Organizational Unit Name: ${orgUnit}")
}
```

运行结果：

```text
Organizational Unit Name: Some(IT Department)
```

### prop organizationName

```cangjie
public prop organizationName: ?String
```

功能：返回证书实体的组织名称。

类型：?String

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 创建X509Name对象
    let x509Name = X509Name(organizationName: "Example Corp")

    // 获取组织名称
    let org = x509Name.organizationName
    println("Organization Name: ${org}")
}
```

运行结果：

```text
Organization Name: Some(Example Corp)
```

### prop provinceName

```cangjie
public prop provinceName: ?String
```

功能：返回证书实体的州或省名称。

类型：?String

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 创建X509Name对象
    let x509Name = X509Name(provinceName: "Beijing")

    // 获取州或省名称
    let province = x509Name.provinceName
    println("Province Name: ${province}")
}
```

运行结果：

```text
Province Name: Some(Beijing)
```

### init(?String, ?String, ?String, ?String, ?String, ?String, ?String)

```cangjie
public init(
    countryName!: ?String = None,
    provinceName!: ?String = None,
    localityName!: ?String = None,
    organizationName!: ?String = None,
    organizationalUnitName!: ?String = None,
    commonName!: ?String = None,
    email!: ?String = None
)
```

功能：构造 [X509Name](x509_package_classes.md#class-x509name) 对象。

参数：

- countryName!: ?String - 国家或地区名称，默认值为 None。
- provinceName!: ?String - 州或省名称，默认值为 None。
- localityName!: ?String - 城市名称，默认值为 None。
- organizationName!: ?String - 组织名称，默认值为 None。
- organizationalUnitName!: ?String - 组织单位名称，默认值为 None。
- commonName!: ?String - 通用名称，默认值为 None。
- email!: ?String - email 地址，默认值为 None。

异常：

- [X509Exception](./x509_package_exceptions.md#class-x509exception) - 设置证书实体可辨识名称时失败，比如内存分配异常等内部错误，则抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 创建包含所有字段的X509Name对象
    let x509Name = X509Name(
        countryName: "CN",
        provinceName: "Beijing",
        localityName: "Haidian",
        organizationName: "Example Corp",
        organizationalUnitName: "IT Department",
        commonName: "example.com",
        email: "admin@example.com"
    )

    // 输出X509Name对象信息
    println("X509Name: ${x509Name}")
}
```

运行结果：

```text
X509Name: c=CN,st=Beijing,l=Haidian,o=Example Corp,ou=IT Department,cn=example.com,email=admin@example.com
```

### func toString()

```cangjie
public override func toString(): String
```

功能：生成证书实体名称字符串。

返回值：

- String - 证书实体名称字符串，包含实体名称中存在的字段信息。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.x509.*

main() {
    // 创建X509Name对象
    let x509Name = X509Name(
        countryName: "CN",
        provinceName: "Beijing",
        localityName: "Haidian",
        organizationName: "Example Corp",
        commonName: "example.com"
    )

    // 获取X509Name的字符串表示
    let nameStr = x509Name.toString()
    println("X509Name String: ${nameStr}")
}
```

运行结果：

```text
X509Name String: c=CN,st=Beijing,l=Haidian,o=Example Corp,cn=example.com
```
