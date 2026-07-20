# 类

## class ECDSAPrivateKey

```cangjie
public class ECDSAPrivateKey <: PrivateKey {
    public init(curve: Curve)
}
```

功能：ECDSA 私钥类，提供生成 ECDSA 私钥能力，ECDSA 的私钥支持签名操作，同时支持 PEM 和 DER 格式的编码解码。使用示例见 [ECDSA 密钥示例](../keys_samples/sample_keys.md#ecdsa-密钥示例)。

父类型：

- [PrivateKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey)

### init(Curve)

```cangjie
public init(curve: Curve)
```

功能：init 初始化生成私钥。

参数：

- curve: [Curve](keys_package_enums.md#enum-curve) - 椭圆曲线类型。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 初始化失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let key = ECDSAPrivateKey(Curve.P256)
    println("ECDSA私钥创建成功")
    println("密钥类型: ${key}")

    return 0
}
```

运行结果：

```text
ECDSA私钥创建成功
密钥类型: ECDSA PRIVATE KEY
```

### static func decodeDer(DerBlob)

```cangjie
public static func decodeDer(blob: DerBlob): ECDSAPrivateKey
```

功能：将私钥从 DER 格式解码。

参数：

- blob: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 二进制格式的私钥对象。

返回值：

- [ECDSAPrivateKey](keys_package_classes.md#class-ecdsaprivatekey) - 解码出的 ECDSA 私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解码失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 DerBlob（此处通过生成私钥并编码模拟）
    let originalKey = ECDSAPrivateKey(Curve.P256)
    let encodedBlob = originalKey.encodeToDer()

    // 从 DerBlob 解码还原 ECDSA 私钥
    let decodedKey = ECDSAPrivateKey.decodeDer(encodedBlob)
    println("解码成功")
    println("解码后密钥类型: ${decodedKey}")

    return 0
}
```

运行结果：

```text
解码成功
解码后密钥类型: ECDSA PRIVATE KEY
```

### static func decodeDer(DerBlob, ?String)

```cangjie
public static func decodeDer(blob: DerBlob, password!: ?String): ECDSAPrivateKey
```

功能：将加密的私钥从 DER 格式解码。

参数：

- blob: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 二进制格式的私钥对象。
- password!: ?String - 解密私钥需要提供的密码，密码为 None 时则不解密。

返回值：

- [ECDSAPrivateKey](keys_package_classes.md#class-ecdsaprivatekey) - 解码出的 ECDSA 私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解码失败、解密失败或者参数密码为空字符串，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 DerBlob（此处通过生成私钥并编码模拟）
    let originalKey = ECDSAPrivateKey(Curve.P256)
    let encodedBlob = originalKey.encodeToDer(password: "mypassword")

    // 从 DerBlob 解码还原 ECDSA 私钥
    let decodedKey = ECDSAPrivateKey.decodeDer(encodedBlob, password: "mypassword")
    println("解码加密DER成功")
    println("解码后密钥类型: ${decodedKey}")

    return 0
}
```

运行结果：

```text
解码加密DER成功
解码后密钥类型: ECDSA PRIVATE KEY
```

### static func decodeFromPem(String)

```cangjie
public static func decodeFromPem(text: String): ECDSAPrivateKey
```

功能：将私钥从 PEM 格式解码。

参数：

- text: String - PEM 格式的私钥字符流。

返回值：

- [ECDSAPrivateKey](keys_package_classes.md#class-ecdsaprivatekey) - 解码出的 ECDSA 私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解码失败、字符流不符合 PEM 格式或文件头不符合私钥头标准时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 PEM 字符串
    let originalKey = ECDSAPrivateKey(Curve.P256)
    let pemEntry = originalKey.encodeToPem()
    let pemString = pemEntry.encode()

    // 从 PEM 字符串解码还原 ECDSA 私钥
    let decodedKey = ECDSAPrivateKey.decodeFromPem(pemString)
    println("从PEM解码成功")
    println("解码后密钥类型: ${decodedKey}")

    return 0
}
```

运行结果：

```text
从PEM解码成功
解码后密钥类型: ECDSA PRIVATE KEY
```

### static func decodeFromPem(String, ?String)

```cangjie
public static func decodeFromPem(text: String, password!: ?String): ECDSAPrivateKey
```

功能：将私钥从 PEM 格式解码。

参数：

- text: String - PEM 格式的私钥字符流。
- password!: ?String - 解密私钥需要提供的密码，密码为 None 时则不解密。

返回值：

- [ECDSAPrivateKey](keys_package_classes.md#class-ecdsaprivatekey) - 解码出的 ECDSA 私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解码失败、解密失败、参数密码为空字符串、字符流不符合 PEM 格式或文件头不符合私钥头标准时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 PEM 字符串
    let originalKey = ECDSAPrivateKey(Curve.P256)
    let pemEntry = originalKey.encodeToPem(password: "mypassword")
    let pemString = pemEntry.encode()

    // 从加密的 PEM 字符串解码还原 ECDSA 私钥
    let decodedKey = ECDSAPrivateKey.decodeFromPem(pemString, password: "mypassword")
    println("从加密PEM解码成功")
    println("解码后密钥类型: ${decodedKey}")

    return 0
}
```

运行结果：

```text
从加密PEM解码成功
解码后密钥类型: ECDSA PRIVATE KEY
```

### func encodeToDer()

```cangjie
public func encodeToDer(): DerBlob
```

功能：将私钥编码为 DER 格式。

返回值：

- [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 编码后的 Der 格式私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let key = ECDSAPrivateKey(Curve.P256)
    let derBlob = key.encodeToDer()

    println("编码为DER格式成功")
    println("DER数据大小: ${derBlob.size}")

    return 0
}
```

运行结果：

```text
编码为DER格式成功
DER数据大小: 121
```

### func encodeToDer(?String)

```cangjie
public func encodeToDer(password!: ?String): DerBlob
```

功能：使用 AES-256-CBC 加密私钥，将私钥编码为 DER 格式。

参数：

- password!: ?String - 加密私钥需要提供的密码，密码为 None 时则不加密。

返回值：

- [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 编码后的 DER 格式私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败、加密失败或者参数密码为空字符串，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let key = ECDSAPrivateKey(Curve.P256)
    let derBlob = key.encodeToDer(password: "mypassword")

    println("编码为加密DER格式成功")
    println("DER数据大小: ${derBlob.size}")

    return 0
}
```

运行结果：

```text
编码为加密DER格式成功
DER数据大小: 239
```

### func encodeToPem()

```cangjie
public func encodeToPem(): PemEntry
```

功能：将私钥编码为 PEM 格式。

返回值：

- [PemEntry](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-pementry) - 私钥 PEM 格式的对象。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let key = ECDSAPrivateKey(Curve.P256)
    let pemEntry = key.encodeToPem()

    println("编码为PEM格式成功")
    println("PEM标签: ${pemEntry.label}")

    return 0
}
```

运行结果：

```text
编码为PEM格式成功
PEM标签: EC PRIVATE KEY
```

### func encodeToPem(?String)

```cangjie
public func encodeToPem(password!: ?String): PemEntry
```

功能：将加密的私钥编码为 PEM 格式。

参数：

- password!: ?String - 加密私钥需要提供的密码，密码为 None 时则不加密。

返回值：

- [PemEntry](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-pementry) - 私钥 PEM 格式的对象。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败、加密失败或者参数密码为空字符串，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let key = ECDSAPrivateKey(Curve.P256)
    let pemEntry = key.encodeToPem(password: "mypassword")

    println("编码为加密PEM格式成功")
    println("PEM标签: ${pemEntry.label}")

    return 0
}
```

运行结果：

```text
编码为加密PEM格式成功
PEM标签: ENCRYPTED PRIVATE KEY
```

### func sign(Array\<Byte>)

```cangjie
public func sign(digest: Array<Byte>): Array<Byte>
```

功能：sign 对数据的摘要结果进行签名。

参数：

- digest: Array\<Byte> - 数据的摘要结果。

返回值：

- Array\<Byte> - 签名后的数据。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 签名失败，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.keys.*
import stdx.crypto.digest.*

main() {
    let priKey = ECDSAPrivateKey(Curve.P256)
    let data = "Hello, World!".toArray()

    // 先计算数据的摘要
    let sha256 = SHA256()
    sha256.write(data)
    let digest = sha256.finish()

    let signature = priKey.sign(digest)
    println("签名成功")
    println("签名长度: ${signature.size}")

    return 0
}
```

可能的运行结果：

```text
签名成功
签名长度: 70
```

### func toString()

```cangjie
public override func toString(): String
```

功能：输出私钥种类。

返回值：

- String - 密钥类别描述。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let key = ECDSAPrivateKey(Curve.P256)

    let keyType = key.toString()
    println("密钥类型: ${keyType}")

    return 0
}
```

运行结果：

```text
密钥类型: ECDSA PRIVATE KEY
```

## class ECDSAPublicKey

```cangjie
public class ECDSAPublicKey <: PublicKey {
    public init(pri: ECDSAPrivateKey)
}
```

功能：ECDSA 公钥类，提供生成 ECDSA 公钥能力，ECDSA 公钥支持验证签名操作，支持 PEM 和 DER 格式的编码解码。使用示例见 [ECDSA 密钥示例](../keys_samples/sample_keys.md#ecdsa-密钥示例)。

父类型：

- [PublicKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-publickey)

### init(ECDSAPrivateKey)

```cangjie
public init(pri: ECDSAPrivateKey)
```

功能：init 初始化公钥，从私钥中获取对应的公钥。

参数：

- pri: [ECDSAPrivateKey](keys_package_classes.md#class-ecdsaprivatekey) - ECDSA 私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 初始化失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let priKey = ECDSAPrivateKey(P256)
    // 公钥需要从私钥派生
    let pubKey = ECDSAPublicKey(priKey)

    println("ECDSA公钥创建成功")
    println("公钥类型: ${pubKey}")

    return 0
}
```

运行结果：

```text
ECDSA公钥创建成功
公钥类型: ECDSA PUBLIC KEY
```

### static func decodeDer(DerBlob)

```cangjie
public static func decodeDer(blob: DerBlob): ECDSAPublicKey
```

功能：将公钥从 DER 格式解码。

参数：

- blob: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 二进制格式的公钥对象。

返回值：

- [ECDSAPublicKey](keys_package_classes.md#class-ecdsapublickey) - 解码出的 ECDSA 公钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 DER 字节数组
    let priKey = ECDSAPrivateKey(P256)
    let pubKey = ECDSAPublicKey(priKey)
    let derBlob = pubKey.encodeToDer()

    // 从 DER 字节数组解码公钥
    let decodedPubKey = ECDSAPublicKey.decodeDer(derBlob)
    println("从DER解码公钥成功")
    println("解码后公钥类型: ${decodedPubKey}")

    return 0
}
```

运行结果：

```text
从DER解码公钥成功
解码后公钥类型: ECDSA PUBLIC KEY
```

### static func decodeFromPem(String)

```cangjie
public static func decodeFromPem(text: String): ECDSAPublicKey
```

功能：将公钥从 PEM 格式解码。

参数：

- text: String - PEM 格式的公钥字符流。

返回值：

- [ECDSAPublicKey](keys_package_classes.md#class-ecdsapublickey) - 解码出的 ECDSA 公钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解码失败、字符流不符合 PEM 格式或文件头不符合公钥头标准时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 PEM 字符串
    let priKey = ECDSAPrivateKey(P256)
    let pubKey = ECDSAPublicKey(priKey)
    let pemEntry = pubKey.encodeToPem()
    let pemString = pemEntry.encode()

    // 从 PEM 字符串解码公钥
    let decodedPubKey = ECDSAPublicKey.decodeFromPem(pemString)
    println("从PEM解码公钥成功")
    println("解码后公钥类型: ${decodedPubKey}")

    return 0
}
```

运行结果：

```text
从PEM解码公钥成功
解码后公钥类型: ECDSA PUBLIC KEY
```

### func encodeToDer()

```cangjie
public func encodeToDer(): DerBlob
```

功能：将公钥编码为 DER 格式。

返回值：

- [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 编码后的 Der 格式公钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let priKey = ECDSAPrivateKey(P256)
    // 公钥需要从私钥派生
    let pubKey = ECDSAPublicKey(priKey)
    let derBlob = pubKey.encodeToDer()

    println("编码为DER格式成功")
    println("DER数据大小: ${derBlob.size}")

    return 0
}
```

运行结果：

```text
编码为DER格式成功
DER数据大小: 91
```

### func encodeToPem()

```cangjie
public func encodeToPem(): PemEntry
```

功能：将公钥编码为 PEM 格式。

返回值：

- [PemEntry](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-pementry) - [PemEntry](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-pementry) 对象。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let priKey = ECDSAPrivateKey(P256)
    // 公钥需要从私钥派生
    let pubKey = ECDSAPublicKey(priKey)
    let pemEntry = pubKey.encodeToPem()

    println("编码为PEM格式成功")
    println("PEM标签: ${pemEntry.label}")

    return 0
}
```

运行结果：

```text
编码为PEM格式成功
PEM标签: PUBLIC KEY
```

### func toString()

```cangjie
public override func toString(): String
```

功能：输出公钥种类。

返回值：

- String - 密钥类别描述。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let priKey = ECDSAPrivateKey(P256)
    let pubKey = ECDSAPublicKey(priKey)

    let keyType = pubKey.toString()
    println("公钥类型: ${keyType}")

    return 0
}
```

运行结果：

```text
公钥类型: ECDSA PUBLIC KEY
```

### func verify(Array\<Byte>, Array\<Byte>)

```cangjie
public func verify(digest: Array<Byte>, sig: Array<Byte>): Bool
```

功能：verify 验证签名结果。

参数：

- digest: Array\<Byte> - 数据的摘要结果。
- sig: Array\<Byte> - 数据的签名结果。

返回值：

- Bool - 返回 true 表示验证成功，false 失败。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*
import stdx.crypto.digest.*

main() {
    let priKey = ECDSAPrivateKey(P256)
    let pubKey = ECDSAPublicKey(priKey)
    let data = "Hello, World!".toArray()

    // 计算数据摘要
    let sha256 = SHA256()
    sha256.write(data)
    let digest = sha256.finish()

    // 使用私钥签名
    let signature = priKey.sign(digest)

    // 使用公钥验证签名
    let isValid = pubKey.verify(digest, signature)
    println("签名验证结果: ${isValid}")

    // 验证错误的签名
    let wrongData = "Wrong data".toArray()
    sha256.reset()
    sha256.write(wrongData)
    let wrongDigest = sha256.finish()
    let isWrongValid = pubKey.verify(wrongDigest, signature)
    println("错误数据验证结果: ${isWrongValid}")

    return 0
}
```

运行结果：

```text
签名验证结果: true
错误数据验证结果: false
```

## class GeneralPrivateKey

```cangjie
public class GeneralPrivateKey <: PrivateKey
```

功能：通用的私钥参数加解密功能实现。

父类型：

- [PrivateKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey)

### static func decodeDer(DerBlob)

```cangjie
public static func decodeDer(encoded: DerBlob): PrivateKey
```

功能：将私钥从 DER 格式解码。

参数：

- encoded: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - DER 格式的私钥对象。

返回值：

- [PrivateKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey) - 由 DER 格式解码出的私钥。

示例：

<!-- run -->
```cangjie
import std.fs.*
import std.process.*
import stdx.crypto.keys.*
import stdx.crypto.common.*

main() {
    // 生成测试用文件
    let privatePem = "./test_private.key"
    let privateDer = "./test_private.der"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${privatePem} 2048; " +
        "openssl rsa -in ${privatePem} -out ${privateDer} -outform der"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从 DerBlob 解码还原私钥
    let decodedKey = GeneralPrivateKey.decodeDer(DerBlob(File.readFrom(privateDer)))
    println("解码成功")
    println("解码后密钥类型: ${decodedKey}")

    // 删除测试用文件
    removeIfExists(privatePem)
    removeIfExists(privateDer)
    return 0
}
```

可能的运行结果：

```text
解码成功
解码后密钥类型: PrivateKey(1217 bytes, RSA 2048 bits)
```

### static func decodeDer(DerBlob, ?String)

```cangjie
public static func decodeDer(encoded: DerBlob, password!: ?String): PrivateKey
```

功能：将 DER 格式的私钥解密解码成 [PrivateKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey) 对象，密码为 None 时则不解密。

参数：

- encoded: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - DER 格式的私钥。
- password!: ?String - 解密密码。

返回值：

- [PrivateKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey) - 解密解码后的私钥对象。

示例：

<!-- run -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.keys.*
import stdx.crypto.common.*

main() {
    // 生成测试用加密文件
    let privatePem = "./test_private.key"
    let privateDer = "./test_private.der"
    let password = "mypassword"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${privatePem} 2048; " +
        "openssl rsa -in ${privatePem} -aes256 -passout pass:${password} -out ${privateDer} -outform der"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从加密的 DerBlob 解码还原私钥
    let decodedKey = GeneralPrivateKey.decodeDer(DerBlob(File.readFrom(privateDer)), password: password)
    println("解码加密DER成功")
    println("解码后密钥类型: ${decodedKey}")

    // 删除测试用文件
    removeIfExists(privatePem)
    removeIfExists(privateDer)
    return 0
}
```

可能的运行结果：

```text
解码加密DER成功
解码后密钥类型: PrivateKey(1217 bytes, RSA 2048 bits)
```

### static func decodeFromPem(String)

```cangjie
public static func decodeFromPem(text: String): PrivateKey
```

功能：将私钥从 PEM 格式解码。

参数：

- text: String - PEM 格式的私钥字符流。

返回值：

- [PrivateKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey) - 由 PEM 格式解码出的私钥。

示例：

<!-- run -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.keys.*

main() {
    // 生成测试用文件
    let privatePem = "./test_private.key"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${privatePem} 2048"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从 PEM 字符串解码还原私钥
    let pemContent = String.fromUtf8(File.readFrom(privatePem))
    let decodedKey = GeneralPrivateKey.decodeFromPem(pemContent)
    println("从PEM解码成功")
    println("解码后密钥类型: ${decodedKey}")

    // 删除测试用文件
    removeIfExists(privatePem)
    return 0
}
```

可能的运行结果：

```text
从PEM解码成功
解码后密钥类型: PrivateKey(1217 bytes, RSA 2048 bits)
```

### static func decodeFromPem(String, ?String)

```cangjie
public static func decodeFromPem(text: String, password!: ?String): PrivateKey
```

功能：将 PEM 格式的私钥解密解码成 [PrivateKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey) 对象，密码为 None 时则不解密。

参数：

- text: String - PEM 格式的私钥。
- password!: ?String - 解密密码。

返回值：

- [PrivateKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey) - 解密解码后的私钥对象。

示例：

<!-- run -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.keys.*

main() {
    // 生成测试用加密文件
    let privatePem = "./test_private.key"
    let password = "mypassword"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genpkey -algorithm rsa -out ${privatePem} -aes256 -pass pass:${password}"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从加密的 PEM 字符串解码还原私钥
    let pemContent = String.fromUtf8(File.readFrom(privatePem))
    let decodedKey = GeneralPrivateKey.decodeFromPem(pemContent, password: password)
    println("从加密PEM解码成功")
    println("解码后密钥类型: ${decodedKey}")

    // 删除测试用文件
    removeIfExists(privatePem)
    return 0
}
```

可能的运行结果：

```text
从加密PEM解码成功
解码后密钥类型: PrivateKey(1217 bytes, RSA 2048 bits)
```

### func encodeToDer()

```cangjie
public func encodeToDer(): DerBlob
```

功能：将私钥编码成 DER 格式。

返回值：

- [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - DER 格式的私钥。

示例：

<!-- run -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.keys.*
import stdx.crypto.common.*

main() {
    // 生成测试用文件
    let privatePem = "./test_private.key"
    let privateDer = "./test_private.der"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${privatePem} 2048; " +
        "openssl rsa -in ${privatePem} -out ${privateDer} -outform der"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从 DER 文件读取并解码为私钥
    let originalKey = GeneralPrivateKey.decodeDer(DerBlob(File.readFrom(privateDer)))

    // 将私钥编码为 DER 格式
    let encodedBlob = originalKey.encodeToDer()
    println("编码为DER格式成功")
    println("DER数据大小: ${encodedBlob.size}")

    // 删除测试用文件
    removeIfExists(privatePem)
    removeIfExists(privateDer)
    return 0
}
```

可能的运行结果：

```text
编码为DER格式成功
DER数据大小: 1217
```

### func encodeToDer(?String)

```cangjie
public func encodeToDer(password!: ?String): DerBlob
```

功能：将私钥加密编码成 DER 格式，密码为 None 时则不加密。

参数：

- password!: ?String - 加密密码。

返回值：

- [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 加密后的 DER 格式的私钥。

示例：

<!-- run -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.keys.*
import stdx.crypto.common.*

main() {
    // 生成测试用文件
    let privatePem = "./test_private.key"
    let privateDer = "./test_private.der"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${privatePem} 2048; " +
        "openssl rsa -in ${privatePem} -out ${privateDer} -outform der"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从 DER 文件读取并解码为私钥
    let originalKey = GeneralPrivateKey.decodeDer(DerBlob(File.readFrom(privateDer)))

    // 将私钥加密编码为 DER 格式
    let encodedBlob = originalKey.encodeToDer(password: "mypassword")
    println("编码为加密DER格式成功")
    println("DER数据大小: ${encodedBlob.size}")

    // 删除测试用文件
    removeIfExists(privatePem)
    removeIfExists(privateDer)
    return 0
}
```

可能的运行结果：

```text
编码为加密DER格式成功
DER数据大小: 1354
```

### func encodeToPem()

```cangjie
public func encodeToPem(): PemEntry
```

功能：将私钥编码成 PEM 格式。

返回值：

- [PemEntry](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-pementry) - 编码后的 PEM 格式的私钥。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.keys.*

main() {
    // 生成测试用文件
    let privatePem = "./test_private.key"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${privatePem} 2048"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从 PEM 文件读取并解码为私钥
    let pemContent = String.fromUtf8(File.readFrom(privatePem))
    let originalKey = GeneralPrivateKey.decodeFromPem(pemContent)

    // 将私钥编码为 PEM 格式
    let encodedPem = originalKey.encodeToPem()
    println("编码为PEM格式成功")
    println("PEM标签: ${encodedPem.label}")

    // 删除测试用文件
    removeIfExists(privatePem)
    return 0
}
```

运行结果：

```text
编码为PEM格式成功
PEM标签: PRIVATE KEY
```

### func encodeToPem(?String)

```cangjie
public func encodeToPem(password!: ?String): PemEntry
```

功能：将私钥加密编码成 PEM 格式，密码为 None 时则不加密。

参数：

- password!: ?String - 加密密码。

返回值：

- [PemEntry](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-pementry) - 加密后的 PEM 格式的私钥。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.keys.*

main() {
    // 生成测试用文件
    let privatePem = "./test_private.key"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${privatePem} 2048"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从 PEM 文件读取并解码为私钥
    let pemContent = String.fromUtf8(File.readFrom(privatePem))
    let originalKey = GeneralPrivateKey.decodeFromPem(pemContent)

    // 将私钥加密编码为 PEM 格式
    let encodedPem = originalKey.encodeToPem(password: "mypassword")
    println("编码为加密PEM格式成功")
    println("PEM标签: ${encodedPem.label}")

    // 删除测试用文件
    removeIfExists(privatePem)
    return 0
}
```

运行结果：

```text
编码为加密PEM格式成功
PEM标签: ENCRYPTED PRIVATE KEY
```

### func toString()

```cangjie
public func toString(): String
```

功能：转换为字符串格式。

返回值：

- String - 字符串。

示例：

<!-- run -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.keys.*

main() {
    // 生成测试用文件
    let privatePem = "./test_private.key"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${privatePem} 2048"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从 PEM 文件读取并解码为私钥
    let pemContent = String.fromUtf8(File.readFrom(privatePem))
    let key = GeneralPrivateKey.decodeFromPem(pemContent)

    // 获取私钥类型描述
    let keyType = key.toString()
    println("私钥类型: ${keyType}")

    // 删除测试用文件
    removeIfExists(privatePem)
    return 0
}
```

可能的运行结果：

```text
私钥类型: PrivateKey(1216 bytes, RSA 2048 bits)
```

## class GeneralPublicKey

```cangjie
public class GeneralPublicKey <: PublicKey
```

功能：通用的公钥参数加解密功能实现。

父类型：

- [PublicKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-publickey)

### static func decodeDer(DerBlob)

```cangjie
public static func decodeDer(encoded: DerBlob): PublicKey
```

功能：将公钥从 DER 格式解码。

参数：

- encoded: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - DER 格式的公钥对象。

返回值：

- [PublicKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-publickey) - 由 DER 格式解码出的公钥。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.keys.*
import stdx.crypto.common.*

main() {
    // 生成测试用文件
    let privatePem = "./test_private.key"
    let publicPem = "./test_public.key"
    let publicDer = "./test_public.der"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${privatePem} 2048; " + "openssl rsa -in ${privatePem} -pubout -out ${publicPem}; " +
        "openssl rsa -in ${publicPem} -pubin -out ${publicDer} -outform der"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从 DerBlob 解码还原公钥
    let decodedKey = GeneralPublicKey.decodeDer(DerBlob(File.readFrom(publicDer)))
    println("解码成功")
    println("解码后公钥类型: ${decodedKey}")

    // 删除测试用文件
    removeIfExists(privatePem)
    removeIfExists(publicPem)
    removeIfExists(publicDer)
    return 0
}
```

运行结果：

```text
解码成功
解码后公钥类型: PublicKey(294 bytes)
```

### static func decodeFromPem(String)

```cangjie
public static func decodeFromPem(text: String): PublicKey
```

功能：将公钥从 PEM 格式解码。

参数：

- text: String - PEM 格式的公钥字符流。

返回值：

- [PublicKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-publickey) - 由 PEM 格式解码出的公钥。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.keys.*

main() {
    // 生成测试用文件
    let privatePem = "./test_private.key"
    let publicPem = "./test_public.key"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${privatePem} 2048; " + "openssl rsa -in ${privatePem} -pubout -out ${publicPem}"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从 PEM 字符串解码还原公钥
    let pemContent = String.fromUtf8(File.readFrom(publicPem))
    let decodedKey = GeneralPublicKey.decodeFromPem(pemContent)
    println("从PEM解码成功")
    println("解码后公钥类型: ${decodedKey}")

    // 删除测试用文件
    removeIfExists(privatePem)
    removeIfExists(publicPem)
    return 0
}
```

运行结果：

```text
从PEM解码成功
解码后公钥类型: PublicKey(294 bytes)
```

### func encodeToDer()

```cangjie
public override func encodeToDer(): DerBlob
```

功能：将公钥编码成 DER 格式。

返回值：

- [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - DER 格式的公钥。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.keys.*
import stdx.crypto.common.*

main() {
    // 生成测试用文件
    let privatePem = "./test_private.key"
    let publicPem = "./test_public.key"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${privatePem} 2048; " + "openssl rsa -in ${privatePem} -pubout -out ${publicPem}"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从 PEM 文件读取并解码为公钥
    let pemContent = String.fromUtf8(File.readFrom(publicPem))
    let originalKey = GeneralPublicKey.decodeFromPem(pemContent)

    // 将公钥编码为 DER 格式
    let encodedBlob = originalKey.encodeToDer()
    println("编码为DER格式成功")
    println("DER数据大小: ${encodedBlob.size}")

    // 删除测试用文件
    removeIfExists(privatePem)
    removeIfExists(publicPem)
    return 0
}
```

运行结果：

```text
编码为DER格式成功
DER数据大小: 294
```

### func encodeToPem()

```cangjie
public func encodeToPem(): PemEntry
```

功能：将公钥编码为 PEM 格式。

返回值：

- [PemEntry](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-pementry) - 公钥数据 PEM 格式编码生成的对象。

示例：

<!-- verify -->
```cangjie
import std.fs.*
import std.io.*
import std.process.*
import stdx.crypto.keys.*

main() {
    // 生成测试用文件
    let privatePem = "./test_private.key"
    let publicPem = "./test_public.key"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${privatePem} 2048; " + "openssl rsa -in ${privatePem} -pubout -out ${publicPem}"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从 PEM 文件读取并解码为公钥
    let pemContent = String.fromUtf8(File.readFrom(publicPem))
    let originalKey = GeneralPublicKey.decodeFromPem(pemContent)

    // 将公钥编码为 PEM 格式
    let encodedPem = originalKey.encodeToPem()
    println("编码为PEM格式成功")
    println("PEM标签: ${encodedPem.label}")

    // 删除测试用文件
    removeIfExists(privatePem)
    removeIfExists(publicPem)
    return 0
}
```

运行结果：

```text
编码为PEM格式成功
PEM标签: PUBLIC KEY
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
import stdx.crypto.keys.*

main() {
    // 生成测试用文件
    let privatePem = "./test_private.key"
    let publicPem = "./test_public.key"

    let cmdStr =
        // OpenSSL 官方标准、无风险的测试用命令
        "openssl genrsa -out ${privatePem} 2048; " + "openssl rsa -in ${privatePem} -pubout -out ${publicPem}"

    executeWithOutput("sh", ["-c", cmdStr])

    // 从 PEM 文件读取并解码为公钥
    let pemContent = String.fromUtf8(File.readFrom(publicPem))
    let key = GeneralPublicKey.decodeFromPem(pemContent)

    // 获取公钥类型描述
    let keyType = key.toString()
    println("公钥类型: ${keyType}")

    // 删除测试用文件
    removeIfExists(privatePem)
    removeIfExists(publicPem)
    return 0
}
```

运行结果：

```text
公钥类型: PublicKey(294 bytes)
```

## class RSAPrivateKey

```cangjie
public class RSAPrivateKey <: PrivateKey {
    public init(bits: Int32)
    public init(bits: Int32, e: BigInt)
}
```

功能：RSA 私钥类，提供生成 RSA 私钥能力，RSA 私钥支持签名和解密操作，支持 PEM 和 DER 格式的编码解码，符合 PKCS1 标准。使用示例见 [RSA 密钥示例](../keys_samples/sample_keys.md#rsa-密钥示例)。

> **注意：**
>
> 推荐使用的密钥长度不小于 3072 位，小于这个值的密钥长度可能是不安全的。

父类型：

- [PrivateKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey)

### init(Int32)

```cangjie
public init(bits: Int32)
```

功能：init 初始化生成私钥，公钥指数默认值为 65537，业界推荐。公钥指数 e 的大小直接影响了 RSA 算法的安全性和加密效率。通常情况下，e 的值越小，加密速度越快，但安全性越低。

参数：

- bits: Int32 - 密钥长度，需要大于等于 512 位，并且小于等于 16384 位。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 密钥长度不符合要求或初始化失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let key = RSAPrivateKey(2048)
    println("RSA私钥创建成功")
    println("密钥类型: ${key}")

    return 0
}
```

运行结果：

```text
RSA私钥创建成功
密钥类型: RSA PRIVATE KEY
```

### init(Int32, BigInt)

```cangjie
public init(bits: Int32, e: BigInt)
```

功能：init 初始化生成私钥，允许用户指定公共指数。

参数：

- bits: Int32 - 密钥长度，需要大于等于 512 位，并且小于等于 16384 位，推荐使用的密钥长度不小于 3072 位。
- e: BigInt - 公钥公共指数，范围是 [3, 2^256-1] 的奇数。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 密钥长度不符合要求、公钥公共指数值不符合要求或初始化失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*
import std.math.numeric.*

main() {
    let e = BigInt(65537)
    let key = RSAPrivateKey(2048, e)
    println("RSA私钥创建成功")
    println("密钥类型: ${key}")

    return 0
}
```

运行结果：

```text
RSA私钥创建成功
密钥类型: RSA PRIVATE KEY
```

### static func decodeDer(DerBlob)

```cangjie
public static func decodeDer(blob: DerBlob): RSAPrivateKey
```

功能：将私钥从 DER 格式解码。

参数：

- blob: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 二进制格式的私钥对象。

返回值：

- [RSAPrivateKey](keys_package_classes.md#class-rsaprivatekey) - 解码出的 RSA 私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解码失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 DerBlob（此处通过生成私钥并编码模拟）
    let originalKey = RSAPrivateKey(2048)
    let encodedBlob = originalKey.encodeToDer()

    // 从 DerBlob 解码还原 RSA 私钥
    let decodedKey = RSAPrivateKey.decodeDer(encodedBlob)
    println("解码成功")
    println("解码后密钥类型: ${decodedKey}")

    return 0
}
```

运行结果：

```text
解码成功
解码后密钥类型: RSA PRIVATE KEY
```

### static func decodeDer(DerBlob, ?String)

```cangjie
public static func decodeDer(blob: DerBlob, password!: ?String): RSAPrivateKey
```

功能：将加密的私钥从 DER 格式解码。

参数：

- blob: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 二进制格式的私钥对象。
- password!: ?String - 解密私钥需要提供的密码，密码为 None 时则不解密。

返回值：

- [RSAPrivateKey](keys_package_classes.md#class-rsaprivatekey) - 解码出的 RSA 私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解码失败、解密失败或者参数密码为空字符串，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 DerBlob（此处通过生成私钥并编码模拟）
    let originalKey = RSAPrivateKey(2048)
    let encodedBlob = originalKey.encodeToDer(password: "mypassword")

    // 从加密的 DerBlob 解码还原 RSA 私钥
    let decodedKey = RSAPrivateKey.decodeDer(encodedBlob, password: "mypassword")
    println("解码加密DER成功")
    println("解码后密钥类型: ${decodedKey}")

    return 0
}
```

运行结果：

```text
解码加密DER成功
解码后密钥类型: RSA PRIVATE KEY
```

### static func decodeFromPem(String)

```cangjie
public static func decodeFromPem(text: String): RSAPrivateKey
```

功能：将私钥从 PEM 格式解码。

参数：

- text: String - PEM 格式的私钥字符流。

返回值：

- [RSAPrivateKey](keys_package_classes.md#class-rsaprivatekey) - 解码出的 RSA 私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解码失败、解密失败、字符流不符合 PEM 格式或文件头不符合私钥头标准时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 PEM 字符串
    let originalKey = RSAPrivateKey(2048)
    let pemEntry = originalKey.encodeToPem()
    let pemString = pemEntry.encode()

    // 从 PEM 字符串解码还原 RSA 私钥
    let decodedKey = RSAPrivateKey.decodeFromPem(pemString)
    println("从PEM解码成功")
    println("解码后密钥类型: ${decodedKey}")

    return 0
}
```

运行结果：

```text
从PEM解码成功
解码后密钥类型: RSA PRIVATE KEY
```

### static func decodeFromPem(String, ?String)

```cangjie
public static func decodeFromPem(text: String, password!: ?String): RSAPrivateKey
```

功能：将私钥从 PEM 格式解码。

参数：

- text: String - PEM 格式的私钥字符流。
- password!: ?String - 解密私钥需要提供的密码，密码为 None 时则不解密。

返回值：

- [RSAPrivateKey](keys_package_classes.md#class-rsaprivatekey) - 解码出的 RSA 私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解码失败、解密失败、参数密码为空字符串、字符流不符合 PEM 格式或文件头不符合私钥头标准时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 PEM 字符串
    let originalKey = RSAPrivateKey(2048)
    let pemEntry = originalKey.encodeToPem(password: "mypassword")
    let pemString = pemEntry.encode()

    // 从加密的 PEM 字符串解码还原 RSA 私钥
    let decodedKey = RSAPrivateKey.decodeFromPem(pemString, password: "mypassword")
    println("从加密PEM解码成功")
    println("解码后密钥类型: ${decodedKey}")

    return 0
}
```

运行结果：

```text
从加密PEM解码成功
解码后密钥类型: RSA PRIVATE KEY
```

### func decrypt(InputStream, OutputStream, PadOption)

```cangjie
public func decrypt(input: InputStream, output: OutputStream, padType!: PadOption): Unit
```

功能：decrypt 解密出原始数据。

参数：

- input: InputStream - 加密的数据。
- output: OutputStream - 解密后的数据。
- padType!: [PadOption](keys_package_enums.md#enum-padoption) - 填充模式，可以选择 PKCS1 或 OAEP 模式，不支持 PSS 模式，在对安全场景要求较高的情况下，推荐使用 OAEP 填充模式。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 设置填充模式失败或解密失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*
import std.io.*

main() {
    let priKey = RSAPrivateKey(2048)
    let pubKey = RSAPublicKey(priKey)

    // 准备要加密的数据
    let data = "Hello, World!".toArray()
    let input = ByteBuffer()
    let output = ByteBuffer()
    let decrypted = ByteBuffer()
    input.write(data)

    // 使用公钥加密数据
    pubKey.encrypt(input, output, padType: PKCS1)

    // 使用私钥解密数据
    priKey.decrypt(output, decrypted, padType: PKCS1)

    let result = Array<Byte>(data.size, repeat: 0)
    decrypted.read(result)

    if (data == result) {
        println("解密成功")
    } else {
        println("解密失败")
    }

    return 0
}
```

运行结果：

```text
解密成功
```

### func encodeToDer()

```cangjie
public func encodeToDer(): DerBlob
```

功能：将私钥编码为 DER 格式。

返回值：

- [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 编码后的 DER 格式私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let key = RSAPrivateKey(2048)
    let derBlob = key.encodeToDer()

    println("编码为DER格式成功")

    return 0
}
```

运行结果：

```text
编码为DER格式成功
```

### func encodeToDer(?String)

```cangjie
public func encodeToDer(password!: ?String): DerBlob
```

功能：使用 AES-256-CBC 加密私钥，将私钥编码为 DER 格式。

参数：

- password!: ?String - 加密私钥需要提供的密码，密码为 None 时则不加密。

返回值：

- [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 编码后的 DER 格式私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败、加密失败或者参数密码为空字符串，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let key = RSAPrivateKey(2048)
    let derBlob = key.encodeToDer(password: "mypassword")

    println("编码为加密DER格式成功")

    return 0
}
```

运行结果：

```text
编码为加密DER格式成功
```

### func encodeToPem()

```cangjie
public func encodeToPem(): PemEntry
```

功能：将私钥编码为 PEM 格式。

返回值：

- [PemEntry](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-pementry) - 私钥 PEM 格式的对象。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let key = RSAPrivateKey(2048)
    let pemEntry = key.encodeToPem()

    println("编码为PEM格式成功")
    println("PEM标签: ${pemEntry.label}")

    return 0
}
```

运行结果：

```text
编码为PEM格式成功
PEM标签: RSA PRIVATE KEY
```

### func encodeToPem(?String)

```cangjie
public func encodeToPem(password!: ?String): PemEntry
```

功能：将加密的私钥编码为 PEM 格式。

参数：

- password!: ?String - 加密私钥需要提供的密码，密码为 None 时则不加密。

返回值：

- [PemEntry](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-pementry) - 私钥 PEM 格式的对象。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败、加密失败或者参数密码为空字符串，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let key = RSAPrivateKey(2048)
    let pemEntry = key.encodeToPem(password: "mypassword")

    println("编码为加密PEM格式成功")
    println("PEM标签: ${pemEntry.label}")

    return 0
}
```

运行结果：

```text
编码为加密PEM格式成功
PEM标签: ENCRYPTED PRIVATE KEY
```

### func sign(Digest, Array\<Byte>, PadOption)

```cangjie
public func sign(hash: Digest, digest: Array<Byte>, padType!: PadOption): Array<Byte>
```

功能：对数据的摘要结果进行签名。

参数：

- hash: Digest - 摘要方法，获取 digest 结果使用的摘要方法。
- digest: Array\<Byte> - 数据的摘要结果。
- padType!: [PadOption](keys_package_enums.md#enum-padoption) - 填充模式，可以选择 PKCS1 或 PSS 模式，不支持 OAEP 模式，在对安全场景要求较高的情况下，推荐使用 PSS 填充模式。

返回值：

- Array\<Byte> - 签名后的数据。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 设置摘要方法失败、设置填充模式失败或签名失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*
import stdx.crypto.digest.*

main() {
    let priKey = RSAPrivateKey(2048)
    let pubKey = RSAPublicKey(priKey)
    let data = "Hello, World!".toArray()

    // 先计算数据的摘要
    let sha256 = SHA256()
    sha256.write(data)
    let digest = sha256.finish()

    // 使用私钥签名
    let signature = priKey.sign(sha256, digest, padType: PKCS1)

    // 使用公钥验证签名
    let isValid = pubKey.verify(sha256, digest, signature, padType: PKCS1)

    println("签名验证结果: ${isValid}")

    return 0
}
```

运行结果：

```text
签名验证结果: true
```

### func toString()

```cangjie
public override func toString(): String
```

功能：输出私钥种类。

返回值：

- String - 密钥类别描述。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let key = RSAPrivateKey(2048)

    let keyType = key.toString()
    println("密钥类型: ${keyType}")

    return 0
}
```

运行结果：

```text
密钥类型: RSA PRIVATE KEY
```

## class RSAPublicKey

```cangjie
public class RSAPublicKey <: PublicKey {
    public init(pri: RSAPrivateKey)
}
```

功能：RSA 公钥类，提供生成 RSA 公钥能力，RSA 公钥支持验证签名和加密操作，支持 PEM 和 DER 格式的编码解码。使用示例见 [RSA 密钥示例](../keys_samples/sample_keys.md#rsa-密钥示例)。

父类型：

- [PublicKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-publickey)

### init(RSAPrivateKey)

```cangjie
public init(pri: RSAPrivateKey)
```

功能：init 初始化公钥，从私钥中获取对应的公钥。

参数：

- pri: [RSAPrivateKey](keys_package_classes.md#class-rsaprivatekey) - RSA 私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 初始化失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let priKey = RSAPrivateKey(2048)
    let pubKey = RSAPublicKey(priKey)

    println("RSA公钥创建成功")
    println("公钥类型: ${pubKey}")

    return 0
}
```

运行结果：

```text
RSA公钥创建成功
公钥类型: RSA PUBLIC KEY
```

### static func decodeDer(DerBlob)

```cangjie
public static func decodeDer(blob: DerBlob): RSAPublicKey
```

功能：将公钥从 DER 格式解码。

参数：

- blob: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 二进制格式的公钥对象。

返回值：

- [RSAPublicKey](keys_package_classes.md#class-rsapublickey) - 解码出的 RSA 公钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解码失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 DER 字节数组
    let priKey = RSAPrivateKey(2048)
    let pubKey = RSAPublicKey(priKey)
    let derBlob = pubKey.encodeToDer()

    // 从 DER 字节数组解码公钥
    let decodedPubKey = RSAPublicKey.decodeDer(derBlob)
    println("从DER解码公钥成功")
    println("解码后公钥类型: ${decodedPubKey}")

    return 0
}
```

运行结果：

```text
从DER解码公钥成功
解码后公钥类型: RSA PUBLIC KEY
```

### static func decodeFromPem(String)

```cangjie
public static func decodeFromPem(text: String): RSAPublicKey
```

功能：将公钥从 PEM 格式解码。

参数：

- text: String - PEM 格式的公钥字符流。

返回值：

- [RSAPublicKey](keys_package_classes.md#class-rsapublickey) - 解码出的 RSA 公钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解码失败、字符流不符合 PEM 格式或文件头不符合公钥头标准时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 PEM 字符串
    let priKey = RSAPrivateKey(2048)
    let pubKey = RSAPublicKey(priKey)
    let pemEntry = pubKey.encodeToPem()
    let pemString = pemEntry.encode()

    // 从 PEM 字符串解码公钥
    let decodedPubKey = RSAPublicKey.decodeFromPem(pemString)
    println("从PEM解码公钥成功")
    println("解码后公钥类型: ${decodedPubKey}")

    return 0
}
```

运行结果：

```text
从PEM解码公钥成功
解码后公钥类型: RSA PUBLIC KEY
```

### func encodeToDer()

```cangjie
public func encodeToDer(): DerBlob
```

功能：将公钥编码为 DER 格式。

返回值：

- [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 编码后的 Der 格式公钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let priKey = RSAPrivateKey(2048)
    // 公钥需要从私钥派生
    let pubKey = RSAPublicKey(priKey)
    let derBlob = pubKey.encodeToDer()

    println("编码为DER格式成功")
    println("DER数据大小: ${derBlob.size}")

    return 0
}
```

运行结果：

```text
编码为DER格式成功
DER数据大小: 294
```

### func encodeToPem()

```cangjie
public func encodeToPem(): PemEntry
```

功能：将公钥编码为 PEM 格式。

返回值：

- [PemEntry](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-pementry) - [PemEntry](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-pementry) 对象。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let priKey = RSAPrivateKey(2048)
    // 公钥需要从私钥派生
    let pubKey = RSAPublicKey(priKey)
    let pemEntry = pubKey.encodeToPem()

    println("编码为PEM格式成功")
    println("PEM标签: ${pemEntry.label}")

    return 0
}
```

运行结果：

```text
编码为PEM格式成功
PEM标签: PUBLIC KEY
```

### func encrypt(InputStream, OutputStream, PadOption)

```cangjie
public func encrypt(input: InputStream, output: OutputStream, padType!: PadOption): Unit
```

功能：encrypt 给一段数据进行加密。

参数：

- input: InputStream - 需要加密的数据。
- output: OutputStream - 加密后的数据。
- padType!: [PadOption](keys_package_enums.md#enum-padoption) - 填充模式，可以选择 PKCS1 或 OAEP 模式，不支持 PSS 模式，在对安全场景要求较高的情况下，推荐使用 OAEP 填充模式。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 设置填充模式失败或加密失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*
import std.io.*

main() {
    let priKey = RSAPrivateKey(2048)
    let pubKey = RSAPublicKey(priKey)

    // 准备要加密的数据
    let data = "Hello, World!".toArray()
    let input = ByteBuffer()
    let output = ByteBuffer()
    input.write(data)

    // 使用公钥加密数据
    pubKey.encrypt(input, output, padType: PKCS1)

    println("加密成功")

    return 0
}
```

运行结果：

```text
加密成功
```

### func toString()

```cangjie
public override func toString(): String
```

功能：输出公钥种类。

返回值：

- String - 密钥类别描述。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let priKey = RSAPrivateKey(2048)
    let pubKey = RSAPublicKey(priKey)

    let keyType = pubKey.toString()
    println("公钥类型: ${keyType}")

    return 0
}
```

运行结果：

```text
公钥类型: RSA PUBLIC KEY
```

### func verify(Digest, Array\<Byte>, Array\<Byte>, PadOption)

```cangjie
public func verify(hash: Digest, digest: Array<Byte>, sig: Array<Byte>, padType!: PadOption): Bool
```

功能：verify 验证签名结果。

参数：

- hash: Digest  - 摘要方法，获取 digest 结果使用的摘要方法。
- digest: Array\<Byte> - 数据的摘要结果。
- sig: Array\<Byte> - 数据的签名结果。
- padType!: [PadOption](keys_package_enums.md#enum-padoption) - 填充模式，可以选择 PKCS1 或 PSS 模式，不支持 OAEP 模式，在对安全场景要求较高的情况下，推荐使用 PSS 填充模式。

返回值：

- Bool - 返回 true 表示验证成功，false 失败。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 设置填充模式失败或验证失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*
import stdx.crypto.digest.*

main() {
    let priKey = RSAPrivateKey(2048)
    let pubKey = RSAPublicKey(priKey)
    let data = "Hello, World!".toArray()

    // 计算数据摘要
    let sha256 = SHA256()
    sha256.write(data)
    let digest = sha256.finish()

    // 使用私钥签名
    let signature = priKey.sign(sha256, digest, padType: PKCS1)

    // 使用公钥验证签名
    let isValid = pubKey.verify(sha256, digest, signature, padType: PKCS1)
    println("签名验证结果: ${isValid}")

    // 验证错误的签名
    let wrongData = "Wrong data".toArray()
    sha256.reset()
    sha256.write(wrongData)
    let wrongDigest = sha256.finish()
    let isWrongValid = pubKey.verify(sha256, wrongDigest, signature, padType: PKCS1)
    println("错误数据验证结果: ${isWrongValid}")

    return 0
}
```

运行结果：

```text
签名验证结果: true
错误数据验证结果: false
```

## class SM2PrivateKey

```cangjie
public class SM2PrivateKey <: PrivateKey {
    public init()
}
```

功能：SM2 私钥类，提供生成 SM2 私钥能力，SM2 私钥支持签名和解密操作，支持 PEM 和 DER 格式的编码解码，符合 PKCS1 标准。使用示例见 [SM2 密钥示例](../keys_samples/sample_keys.md#sm2-密钥示例)。

父类型：

- [PrivateKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-privatekey)

### init()

```cangjie
public init()
```

功能：init 初始化生成私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 初始化失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let key = SM2PrivateKey()
    println("SM2私钥创建成功")
    println("密钥类型: ${key}")

    return 0
}
```

运行结果：

```text
SM2私钥创建成功
密钥类型: SM2 PRIVATE KEY
```

### static func decodeDer(DerBlob)

```cangjie
public static func decodeDer(blob: DerBlob): SM2PrivateKey
```

功能：将私钥从 DER 格式解码。

参数：

- blob: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 二进制格式的私钥对象。

返回值：

- [SM2PrivateKey](keys_package_classes.md#class-sm2privatekey) - 解码出的 SM2 私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解码失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 DerBlob（此处通过生成私钥并编码模拟）
    let originalKey = SM2PrivateKey()
    let encodedBlob = originalKey.encodeToDer()

    // 从 DerBlob 解码还原 SM2 私钥
    let decodedKey = SM2PrivateKey.decodeDer(encodedBlob)
    println("解码成功")
    println("解码后密钥类型: ${decodedKey}")

    return 0
}
```

运行结果：

```text
解码成功
解码后密钥类型: SM2 PRIVATE KEY
```

### static func decodeDer(DerBlob, ?String)

```cangjie
public static func decodeDer(blob: DerBlob, password!: ?String): SM2PrivateKey
```

功能：将加密的私钥从 DER 格式解码。

参数：

- blob: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 二进制格式的私钥对象。
- password!: ?String - 解密私钥需要提供的密码，密码为 None 时则不解密。

返回值：

- [SM2PrivateKey](keys_package_classes.md#class-sm2privatekey) - 解码出的 SM2 私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解码失败、解密失败或者参数密码为空字符串，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 DerBlob（此处通过生成私钥并编码模拟）
    let originalKey = SM2PrivateKey()
    let encodedBlob = originalKey.encodeToDer(password: "mypassword")

    // 从加密的 DerBlob 解码还原 SM2 私钥
    let decodedKey = SM2PrivateKey.decodeDer(encodedBlob, password: "mypassword")
    println("解码加密DER成功")
    println("解码后密钥类型: ${decodedKey}")

    return 0
}
```

运行结果：

```text
解码加密DER成功
解码后密钥类型: SM2 PRIVATE KEY
```

### static func decodeFromPem(String)

```cangjie
public static func decodeFromPem(text: String): SM2PrivateKey
```

功能：将私钥从 PEM 格式解码。

参数：

- text: String - PEM 格式的私钥字符流。

返回值：

- [SM2PrivateKey](keys_package_classes.md#class-sm2privatekey) - 解码出的 SM2 私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解码失败、解密失败、字符流不符合 PEM 格式或文件头不符合私钥头标准时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 PEM 字符串
    let originalKey = SM2PrivateKey()
    let pemEntry = originalKey.encodeToPem()
    let pemString = pemEntry.encode()

    // 从 PEM 字符串解码还原 SM2 私钥
    let decodedKey = SM2PrivateKey.decodeFromPem(pemString)
    println("从PEM解码成功")
    println("解码后密钥类型: ${decodedKey}")

    return 0
}
```

运行结果：

```text
从PEM解码成功
解码后密钥类型: SM2 PRIVATE KEY
```

### static func decodeFromPem(String, ?String)

```cangjie
public static func decodeFromPem(text: String, password!: ?String): SM2PrivateKey
```

功能：将私钥从 PEM 格式解码。

参数：

- text: String - PEM 格式的私钥字符流。
- password!: ?String - 解密私钥需要提供的密码，密码为 None 时则不解密。

返回值：

- [SM2PrivateKey](keys_package_classes.md#class-sm2privatekey) - 解码出的 SM2 私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解码失败、解密失败、参数密码为空字符串、字符流不符合 PEM 格式或文件头不符合私钥头标准时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 PEM 字符串
    let originalKey = SM2PrivateKey()
    let pemEntry = originalKey.encodeToPem(password: "mypassword")
    let pemString = pemEntry.encode()

    // 从加密的 PEM 字符串解码还原 SM2 私钥
    let decodedKey = SM2PrivateKey.decodeFromPem(pemString, password: "mypassword")
    println("从加密PEM解码成功")
    println("解码后密钥类型: ${decodedKey}")

    return 0
}
```

运行结果：

```text
从加密PEM解码成功
解码后密钥类型: SM2 PRIVATE KEY
```

### func decrypt(Array\<Byte>)

```cangjie
public func decrypt(input: Array<Byte>): Array<Byte>
```

功能：decrypt 解密出原始数据，待解密密文需要遵循 ASN.1 编码规则。

参数：

- input: Array\<Byte> - 加密的数据。

返回值：

- Array\<Byte> - 解密后的数据。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解密失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let priKey = SM2PrivateKey()
    let pubKey = SM2PublicKey(priKey)

    // 准备要加密的数据
    let data = "Hello, World!".toArray()

    // 使用公钥加密数据
    let encryptedData = pubKey.encrypt(data)

    // 使用私钥解密数据
    let decryptedData = priKey.decrypt(encryptedData)

    let result = String.fromUtf8(decryptedData)
    println("解密结果: ${result}")

    return 0
}
```

运行结果：

```text
解密结果: Hello, World!
```

### func encodeToDer()

```cangjie
public func encodeToDer(): DerBlob
```

功能：将私钥编码为 DER 格式。

返回值：

- [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 编码后的 DER 格式私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let key = SM2PrivateKey()
    let derBlob = key.encodeToDer()

    println("编码为DER格式成功")
    println("DER数据大小: ${derBlob.size}")

    return 0
}
```

运行结果：

```text
编码为DER格式成功
DER数据大小: 121
```

### func encodeToDer(?String)

```cangjie
public func encodeToDer(password!: ?String): DerBlob
```

功能：使用 AES-256-CBC 加密私钥，将私钥编码为 DER 格式。

参数：

- password!: ?String - 加密私钥需要提供的密码，密码为 None 时则不加密。

返回值：

- [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 编码后的 DER 格式公钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败、加密失败或者参数密码为空字符串，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let key = SM2PrivateKey()
    let derBlob = key.encodeToDer(password: "mypassword")

    println("编码为加密DER格式成功")
    println("DER数据大小: ${derBlob.size}")

    return 0
}
```

运行结果：

```text
编码为加密DER格式成功
DER数据大小: 239
```

### func encodeToPem()

```cangjie
public func encodeToPem(): PemEntry
```

功能：将私钥编码为 PEM 格式。

返回值：

- [PemEntry](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-pementry) - 私钥 PEM 格式的对象。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let key = SM2PrivateKey()
    let pemEntry = key.encodeToPem()

    println("编码为PEM格式成功")
    println("PEM标签: ${pemEntry.label}")

    return 0
}
```

运行结果：

```text
编码为PEM格式成功
PEM标签: EC PRIVATE KEY
```

### func encodeToPem(?String)

```cangjie
public func encodeToPem(password!: ?String): PemEntry
```

功能：将加密的私钥编码为 PEM 格式。

参数：

- password!: ?String - 加密私钥需要提供的密码，密码为 None 时则不加密。

返回值：

- [PemEntry](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-pementry) - 私钥 PEM 格式的对象。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败、加密失败或者参数密码为空字符串，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let key = SM2PrivateKey()
    let pemEntry = key.encodeToPem(password: "mypassword")

    println("编码为加密PEM格式成功")
    println("PEM标签: ${pemEntry.label}")

    return 0
}
```

运行结果：

```text
编码为加密PEM格式成功
PEM标签: EC PRIVATE KEY
```

### func sign(Array\<Byte>)

```cangjie
public func sign(data: Array<Byte>): Array<Byte>
```

功能：sign 对数据进行签名，SM2 采用[SM3](../../digest/digest_package_api/digest_package_classes.md#class-sm3)数据摘要算法。

参数：

- data: Array\<Byte> - 数据。

返回值：

- Array\<Byte> - 签名后的数据。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 签名失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let priKey = SM2PrivateKey()
    let pubKey = SM2PublicKey(priKey)
    let data = "Hello, World!".toArray()

    // 使用私钥签名，直接传原始数据，内部自动算 SM3
    let signature = priKey.sign(data)

    // 使用公钥验证签名
    let isValid = pubKey.verify(data, signature)

    println("签名验证结果: ${isValid}")

    return 0
}
```

运行结果：

```text
签名验证结果: true
```

### func toString()

```cangjie
public override func toString(): String
```

功能：输出私钥种类。

返回值：

- String - 密钥类别描述。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let key = SM2PrivateKey()

    let keyType = key.toString()
    println("密钥类型: ${keyType}")

    return 0
}
```

运行结果：

```text
密钥类型: SM2 PRIVATE KEY
```

## class SM2PublicKey

```cangjie
public class SM2PublicKey <: PublicKey {
    public init(pri: SM2PrivateKey)
}
```

功能：SM2 公钥类，提供生成 SM2 公钥能力，SM2 公钥支持验证签名和加密操作，支持 PEM 和 DER 格式的编码解码。使用示例见 [SM2 密钥示例](../keys_samples/sample_keys.md#sm2-密钥示例)。

父类型：

- [PublicKey](../../common/crypto_common_package_api/crypto_common_package_interfaces.md#interface-publickey)

### init(SM2PrivateKey)

```cangjie
public init(pri: SM2PrivateKey)
```

功能：init 初始化公钥，从私钥中获取对应的公钥。

参数：

- pri: [SM2PrivateKey](keys_package_classes.md#class-sm2privatekey) - SM2 私钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 初始化失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let priKey = SM2PrivateKey()
    let pubKey = SM2PublicKey(priKey)

    println("SM2公钥创建成功")
    println("公钥类型: ${pubKey}")

    return 0
}
```

运行结果：

```text
SM2公钥创建成功
公钥类型: SM2 PUBLIC KEY
```

### static func decodeDer(DerBlob)

```cangjie
public static func decodeDer(blob: DerBlob): SM2PublicKey
```

功能：将公钥从 DER 格式解码。

参数：

- blob: [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 二进制格式的公钥对象。

返回值：

- [SM2PublicKey](keys_package_classes.md#class-sm2publickey) - 解码出的 SM2 公钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解码失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 DER 字节数组
    let priKey = SM2PrivateKey()
    let pubKey = SM2PublicKey(priKey)
    let derBlob = pubKey.encodeToDer()

    // 从 DER 字节数组解码公钥
    let decodedPubKey = SM2PublicKey.decodeDer(derBlob)
    println("从DER解码公钥成功")
    println("解码后公钥类型: ${decodedPubKey}")

    return 0
}
```

运行结果：

```text
从DER解码公钥成功
解码后公钥类型: SM2 PUBLIC KEY
```

### static func decodeFromPem(String)

```cangjie
public static func decodeFromPem(text: String): SM2PublicKey
```

功能：将公钥从 PEM 格式解码。

参数：

- text: String - PEM 格式的公钥字符流。

返回值：

- [SM2PublicKey](keys_package_classes.md#class-sm2publickey) - 解码出的 SM2 公钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 解码失败、字符流不符合 PEM 格式或文件头不符合公钥头标准时，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    // 模拟场景：从外部（文件/网络）获取的 PEM 字符串
    let priKey = SM2PrivateKey()
    let pubKey = SM2PublicKey(priKey)
    let pemEntry = pubKey.encodeToPem()
    let pemString = pemEntry.encode()

    // 从 PEM 字符串解码公钥
    let decodedPubKey = SM2PublicKey.decodeFromPem(pemString)
    println("从PEM解码公钥成功")
    println("解码后公钥类型: ${decodedPubKey}")

    return 0
}
```

运行结果：

```text
从PEM解码公钥成功
解码后公钥类型: SM2 PUBLIC KEY
```

### func encodeToDer()

```cangjie
public func encodeToDer(): DerBlob
```

功能：将公钥编码为 DER 格式。

返回值：

- [DerBlob](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-derblob) - 编码后的 Der 格式公钥。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let priKey = SM2PrivateKey()
    // 公钥需要从私钥派生
    let pubKey = SM2PublicKey(priKey)
    let derBlob = pubKey.encodeToDer()

    println("编码为DER格式成功")
    println("DER数据大小: ${derBlob.size}")

    return 0
}
```

运行结果：

```text
编码为DER格式成功
DER数据大小: 92
```

### func encodeToPem()

```cangjie
public func encodeToPem(): PemEntry
```

功能：将公钥编码为 PEM 格式。

返回值：

- [PemEntry](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-pementry) - [PemEntry](../../common/crypto_common_package_api/crypto_common_package_structs.md#struct-pementry) 对象。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 编码失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let priKey = SM2PrivateKey()
    // 公钥需要从私钥派生
    let pubKey = SM2PublicKey(priKey)
    let pemEntry = pubKey.encodeToPem()

    println("编码为PEM格式成功")
    println("PEM标签: ${pemEntry.label}")

    return 0
}
```

运行结果：

```text
编码为PEM格式成功
PEM标签: PUBLIC KEY
```

### func encrypt(Array\<Byte>)

```cangjie
public func encrypt(input: Array<Byte>): Array<Byte>
```

功能：encrypt 给一段数据进行加密，输出密文遵循 ASN.1 编码规则。

参数：

- input: Array\<Byte> - 需要加密的数据。

返回值：

- Array\<Byte> - 加密后的数据。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 加密失败，抛出异常。

示例：

<!-- run -->
```cangjie
import stdx.crypto.keys.*

main() {
    let priKey = SM2PrivateKey()
    let pubKey = SM2PublicKey(priKey)

    // 准备要加密的数据
    let data = "Hello, World!".toArray()

    // 使用公钥加密数据
    let encryptedData = pubKey.encrypt(data)

    println("加密成功")
    println("加密后数据大小: ${encryptedData.size}")

    return 0
}
```

可能的运行结果：

```text
加密成功
加密后数据大小: 121
```

### func toString()

```cangjie
public override func toString(): String
```

功能：输出公钥种类。

返回值：

- String - 密钥类别描述。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let priKey = SM2PrivateKey()
    let pubKey = SM2PublicKey(priKey)

    let keyType = pubKey.toString()
    println("公钥类型: ${keyType}")

    return 0
}
```

运行结果：

```text
公钥类型: SM2 PUBLIC KEY
```

### func verify(Array\<Byte>, Array\<Byte>)

```cangjie
public func verify(data: Array<Byte>, sig: Array<Byte>): Bool
```

功能：verify 验证签名结果。

参数：

- data: Array\<Byte> - 数据。
- sig: Array\<Byte> - 数据的签名结果。

返回值：

- Bool - 返回 true 表示验证成功，false 失败。

异常：

- [CryptoException](../../common/crypto_common_package_api/crypto_common_package_exceptions.md#class-cryptoexception) - 设置填充模式失败或验证失败，抛出异常。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*

main() {
    let priKey = SM2PrivateKey()
    let pubKey = SM2PublicKey(priKey)
    let data = "Hello, World!".toArray()

    // 使用私钥签名
    let signature = priKey.sign(data)

    // 使用公钥验证签名
    let isValid = pubKey.verify(data, signature)

    println("签名验证结果: ${isValid}")

    // 验证错误的签名
    let wrongData = "Wrong data".toArray()
    let isWrongValid = pubKey.verify(wrongData, signature)
    println("错误数据验证结果: ${isWrongValid}")

    return 0
}
```

运行结果：

```text
签名验证结果: true
错误数据验证结果: false
```
