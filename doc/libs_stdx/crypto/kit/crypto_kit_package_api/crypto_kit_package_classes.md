# 类

## class DefaultCryptoKit

```cangjie
public class DefaultCryptoKit <: CryptoKit
```

功能：[CryptoKit](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-cryptokit) 的默认实现。提供随机数生成器及解码 DER、PEM 的能力。

父类型：

- [CryptoKit](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-cryptokit)

> **说明：**
>
> PEM 是一种基于 Base64 的编码格式。

### func certificateFromDer(DerBlob)

```cangjie
public func certificateFromDer(encoded: DerBlob): Certificate
```

功能：将证书从 DER 格式解码。

参数：

- encoded: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 待解码的 DerBlob 对象。

返回值：

- [Certificate](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-certificate) - 解码得到的证书。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码文件中无有效信息时抛出异常。
- [X509Exception](../../x509/x509_package_api/x509_package_exceptions.md#class-x509exception) - 解码失败时抛出异常。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.kit.*
import stdx.crypto.common.*

main() {
    // 创建默认的CryptoKit实例
    let cryptoKit = DefaultCryptoKit()

    // 生成测试用证书文件
    let certPem = "./test_cert.pem"
    let certDer = "./test_cert.der"
    let keyPem = "./test_key.pem"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl req -x509 -newkey rsa:2048 -keyout ${keyPem} -out ${certPem} -days 1 -nodes -subj '/CN=test' && " +
        "openssl x509 -in ${certPem} -outform DER -out ${certDer}"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从 DerBlob 解码证书
    let certBlob = DerBlob(File.readFrom(certDer))
    let certificate = cryptoKit.certificateFromDer(certBlob)
    println("证书解码成功")

    // 删除测试用文件
    removeIfExists(certPem)
    removeIfExists(certDer)
    removeIfExists(keyPem)
    return 0
}
```

运行结果：

```text
证书解码成功
```

### func certificateFromPem(String)

```cangjie
public func certificateFromPem(text: String): Array<Certificate>
```

功能：将证书从 PEM 格式解码。

参数：

- text: String - 待解码的 PEM 格式字符串。

返回值：

- Array\<[Certificate](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-certificate)> - 解码得到的证书集合。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码文件中无有效信息时抛出异常。
- [X509Exception](../../x509/x509_package_api/x509_package_exceptions.md#class-x509exception) - 解码失败时抛出异常。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.kit.*

main() {
    // 创建默认的CryptoKit实例
    let cryptoKit = DefaultCryptoKit()

    // 生成测试用证书文件
    let certPem = "./test_cert.pem"
    let keyPem = "./test_key.pem"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl req -x509 -newkey rsa:2048 -keyout ${keyPem} -out ${certPem} -days 1 -nodes -subj '/CN=test'"

    executeWithOutput("sh", ["-c", cmdStr])

    // 读取PEM格式的证书内容
    let pemContent = String.fromUtf8(File.readFrom(certPem))

    // 从 PEM 字符串解码证书
    let certificates = cryptoKit.certificateFromPem(pemContent)
    println("证书PEM解码成功")
    println("证书数量: ${certificates.size}")

    // 删除测试用文件
    removeIfExists(certPem)
    removeIfExists(keyPem)
    return 0
}
```

运行结果：

```text
证书PEM解码成功
证书数量: 1
```

### func dhParametersFromDer(DerBlob)

```cangjie
public func dhParametersFromDer(encoded: DerBlob): DHParameters
```

功能：将 DH 密钥参数从 DER 格式解码。

参数：

- encoded: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 待解码的 DerBlob 对象。

返回值：

- [DHParameters](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-dhparameters) - 解码得到的 DH 密钥参数。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码文件中无有效信息时抛出异常。
- [X509Exception](../../x509/x509_package_api/x509_package_exceptions.md#class-x509exception) - 解码失败时抛出异常。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.kit.*
import stdx.crypto.common.*

main() {
    // 创建默认的CryptoKit实例
    let cryptoKit = DefaultCryptoKit()

    // 生成测试用DH参数文件
    let dhPem = "./test_dh01.pem"
    let dhDer = "./test_dh.der"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl dhparam -out ${dhPem} 1024 && " + "openssl dhparam -in ${dhPem} -outform DER -out ${dhDer}"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从 DerBlob 解码DH参数
    let dhBlob = DerBlob(File.readFrom(dhDer))
    let dhParams = cryptoKit.dhParametersFromDer(dhBlob)
    println("DH参数DER解码成功")

    // 删除测试用文件
    removeIfExists(dhPem)
    removeIfExists(dhDer)
    return 0
}
```

运行结果：

```text
DH参数DER解码成功
```

### func dhParametersFromPem(String)

```cangjie
public func dhParametersFromPem(text: String): DHParameters
```

功能：将 DH 密钥参数从 PEM 格式解码。

参数：

- text: String - 待解码的 PEM 格式字符串。

返回值：

- [DHParameters](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-dhparameters) - 解码得到的 DH 密钥参数。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码文件中无有效信息时抛出异常。
- [X509Exception](../../x509/x509_package_api/x509_package_exceptions.md#class-x509exception) - 解码失败时抛出异常。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.kit.*

main() {
    // 创建默认的CryptoKit实例
    let cryptoKit = DefaultCryptoKit()

    // 生成测试用DH参数文件
    let dhPem = "./test_dh02.pem"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl dhparam -out ${dhPem} 1024"

    executeWithOutput("sh", ["-c", cmdStr])

    // 读取PEM格式的DH参数内容
    let pemContent = String.fromUtf8(File.readFrom(dhPem))

    // 从 PEM 字符串解码DH参数
    let dhParams = cryptoKit.dhParametersFromPem(pemContent)
    println("DH参数PEM解码成功")

    // 删除测试用文件
    removeIfExists(dhPem)
    return 0
}
```

运行结果：

```text
DH参数PEM解码成功
```

### func getRandomGen()

```cangjie
public func getRandomGen(): RandomGenerator
```

功能：获取随机数生成器。

返回值：

- [RandomGenerator](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-randomgenerator) - 随机数生成器。

示例：

<!-- run -->
```cangjie
import stdx.crypto.kit.*
import stdx.crypto.common.*

main() {
    // 创建默认的CryptoKit实例
    let cryptoKit = DefaultCryptoKit()

    // 获取随机数生成器
    let randomGen = cryptoKit.getRandomGen()

    let randomNum = randomGen.nextBits(32)
    println("随机数生成器获取成功，随机数: ${randomNum}")

    return 0
}
```

可能的运行结果：

```text
随机数生成器获取成功，随机数: 1153017157
```

### func privateKeyFromDer(DerBlob)

```cangjie
public func privateKeyFromDer(encoded: DerBlob): PrivateKey
```

功能：将私钥从 DER 格式解码。

参数：

- encoded: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 待解码的 DerBlob 对象。

返回值：

- [PrivateKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey) - 解码得到的私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码文件中无有效信息时抛出异常。
- [X509Exception](../../x509/x509_package_api/x509_package_exceptions.md#class-x509exception) - 解码失败时抛出异常。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.kit.*
import stdx.crypto.common.*

main() {
    // 创建默认的CryptoKit实例
    let cryptoKit = DefaultCryptoKit()

    // 生成测试用私钥文件
    let privateKeyPem = "./test_private.pem"
    let privateKeyDer = "./test_private.der"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${privateKeyPem} 2048 && " +
        "openssl rsa -in ${privateKeyPem} -outform DER -out ${privateKeyDer}"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从 DerBlob 解码私钥
    let keyBlob = DerBlob(File.readFrom(privateKeyDer))
    let privateKey = cryptoKit.privateKeyFromDer(keyBlob)
    println("私钥DER解码成功")

    // 删除测试用文件
    removeIfExists(privateKeyPem)
    removeIfExists(privateKeyDer)
    return 0
}
```

运行结果：

```text
私钥DER解码成功
```

### func privateKeyFromDer(DerBlob, ?String)

```cangjie
public func privateKeyFromDer(encoded: DerBlob, password!: ?String): PrivateKey
```

功能：将私钥从 DER 格式解密解码。密码为 None 时则不解密。

参数：

- encoded: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 待解密解码的 DerBlob 对象。
- password!: ?String - 解密密码。

返回值：

- [PrivateKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey) - 解密解码得到的私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码文件中无有效信息时抛出异常。
- [X509Exception](../../x509/x509_package_api/x509_package_exceptions.md#class-x509exception) - 解码失败时抛出异常。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.kit.*
import stdx.crypto.common.*

main() {
    // 创建默认的CryptoKit实例
    let cryptoKit = DefaultCryptoKit()

    // 生成测试用加密私钥文件
    let encryptedKeyPem = "./test_encrypted_private.pem"
    let encryptedKeyDer = "./test_encrypted_private.der"
    let password = "testpass"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${encryptedKeyPem} 2048 && " +
        "openssl rsa -in ${encryptedKeyPem} -outform DER -aes256 -passout pass:${password} -out ${encryptedKeyDer}"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从 DerBlob 解密解码私钥
    let encryptedKeyBlob = DerBlob(File.readFrom(encryptedKeyDer))
    let privateKey = cryptoKit.privateKeyFromDer(encryptedKeyBlob, password: password)
    println("加密私钥DER解码成功")

    // 删除测试用文件
    removeIfExists(encryptedKeyPem)
    removeIfExists(encryptedKeyDer)
    return 0
}
```

运行结果：

```text
加密私钥DER解码成功
```

### func privateKeyFromPem(String)

```cangjie
public func privateKeyFromPem(text: String): PrivateKey
```

功能：将私钥从 PEM 格式解码。

参数：

- text: String - 待解码的 PEM 格式字符串。

返回值：

- [PrivateKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey) - 解码得到的私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码文件中无有效信息时抛出异常。
- [X509Exception](../../x509/x509_package_api/x509_package_exceptions.md#class-x509exception) - 解码失败时抛出异常。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.kit.*

main() {
    // 创建默认的CryptoKit实例
    let cryptoKit = DefaultCryptoKit()

    // 生成测试用私钥文件
    let privateKeyPem = "./test_private.pem"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${privateKeyPem} 2048"

    executeWithOutput("sh", ["-c", cmdStr])

    // 读取PEM格式的私钥内容
    let pemContent = String.fromUtf8(File.readFrom(privateKeyPem))

    // 从 PEM 字符串解码私钥
    let privateKey = cryptoKit.privateKeyFromPem(pemContent)
    println("私钥PEM解码成功")

    // 删除测试用文件
    removeIfExists(privateKeyPem)
    return 0
}
```

运行结果：

```text
私钥PEM解码成功
```

### func privateKeyFromPem(String, ?String)

```cangjie
public func privateKeyFromPem(text: String, password!: ?String): PrivateKey
```

功能：将私钥从 PEM 格式解密解码。密码为 `None` 时则不解密。

参数：

- text: String - 待解密解码的 PEM 格式字符串。
- password!: ?String - 解密密码。

返回值：

- [PrivateKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey) - 解密解码得到的私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码文件中无有效信息时抛出异常。
- [X509Exception](../../x509/x509_package_api/x509_package_exceptions.md#class-x509exception) - 解码失败时抛出异常。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.kit.*

main() {
    // 创建默认的CryptoKit实例
    let cryptoKit = DefaultCryptoKit()

    // 生成测试用加密私钥文件
    let encryptedKeyPem = "./test_encrypted_private.pem"
    let password = "testpass"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${encryptedKeyPem} 2048 && " +
        "openssl rsa -in ${encryptedKeyPem} -aes256 -passout pass:${password} -out ${encryptedKeyPem}"

    executeWithOutput("sh", ["-c", cmdStr])

    // 读取PEM格式的加密私钥内容
    let pemContent = String.fromUtf8(File.readFrom(encryptedKeyPem))

    // 从 PEM 字符串解密解码私钥
    let privateKey = cryptoKit.privateKeyFromPem(pemContent, password: password)
    println("加密私钥PEM解码成功")

    // 删除测试用文件
    removeIfExists(encryptedKeyPem)
    return 0
}
```

运行结果：

```text
加密私钥PEM解码成功
```

### func publicKeyFromDer(DerBlob)

```cangjie
public func publicKeyFromDer(encoded: DerBlob): PublicKey
```

功能：将公钥从 DER 格式解码。

参数：

- encoded: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 待解码的 DerBlob 对象。

返回值：

- [PublicKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-publickey) - 解码得到的公钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码文件中无有效信息时抛出异常。
- [X509Exception](../../x509/x509_package_api/x509_package_exceptions.md#class-x509exception) - 解码失败时抛出异常。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.kit.*
import stdx.crypto.common.*

main() {
    // 创建默认的CryptoKit实例
    let cryptoKit = DefaultCryptoKit()

    // 生成测试用私钥和公钥文件
    let privateKeyPem = "./test_private.pem"
    let publicKeyPem = "./test_public.pem"
    let publicKeyDer = "./test_public.der"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${privateKeyPem} 2048 && " +
        "openssl rsa -in ${privateKeyPem} -pubout -out ${publicKeyPem} && " +
        "openssl rsa -in ${publicKeyPem} -pubin -outform DER -out ${publicKeyDer}"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从 DerBlob 解码公钥
    let keyBlob = DerBlob(File.readFrom(publicKeyDer))
    let publicKey = cryptoKit.publicKeyFromDer(keyBlob)
    println("公钥DER解码成功")

    // 删除测试用文件
    removeIfExists(privateKeyPem)
    removeIfExists(publicKeyPem)
    removeIfExists(publicKeyDer)
    return 0
}
```

运行结果：

```text
公钥DER解码成功
```

### func publicKeyFromPem(String)

```cangjie
public func publicKeyFromPem(text: String): PublicKey
```

功能：将公钥从 PEM 格式解码。

参数：

- text: String - 待解码的 PEM 格式字符串。

返回值：

- [PublicKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-publickey) - 解码得到的公钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码文件中无有效信息时抛出异常。
- [X509Exception](../../x509/x509_package_api/x509_package_exceptions.md#class-x509exception) - 解码失败时抛出异常。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.kit.*

main() {
    // 创建默认的CryptoKit实例
    let cryptoKit = DefaultCryptoKit()

    // 生成测试用私钥和公钥文件
    let privateKeyPem = "./test_private.pem"
    let publicKeyPem = "./test_public.pem"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${privateKeyPem} 2048 && " +
        "openssl rsa -in ${privateKeyPem} -pubout -out ${publicKeyPem}"

    executeWithOutput("sh", ["-c", cmdStr])

    // 读取PEM格式的公钥内容
    let pemContent = String.fromUtf8(File.readFrom(publicKeyPem))

    // 从 PEM 字符串解码公钥
    let publicKey = cryptoKit.publicKeyFromPem(pemContent)
    println("公钥PEM解码成功")

    // 删除测试用文件
    removeIfExists(privateKeyPem)
    removeIfExists(publicKeyPem)
    return 0
}
```

运行结果：

```text
公钥PEM解码成功
```
