# keys 使用

## RSA 密钥示例

### 生成 RSA 公钥及私钥，并使用公钥的 OAEP 填充模式加密，用私钥的 OAEP 填充模式解密

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*
import stdx.crypto.digest.*
import std.io.*
import std.crypto.digest.*

main() {
    // 生成 RSA 密钥对（2048 位）
    let rsaPrivate = RSAPrivateKey(2048)
    let rsaPublic = RSAPublicKey(rsaPrivate)

    // 准备待加密的数据
    let message = "hello world, hello cangjie"
    let inputBuffer = ByteBuffer()
    let encryptedBuffer = ByteBuffer()
    let decryptedBuffer = ByteBuffer()
    inputBuffer.write(message.toArray())

    // 使用公钥加密（OAEP 填充模式）
    let oaepOption = OAEPOption(SHA1(), SHA256())
    rsaPublic.encrypt(inputBuffer, encryptedBuffer, padType: OAEP(oaepOption))

    // 使用私钥解密
    let oaepOption2 = OAEPOption(SHA1(), SHA256())
    rsaPrivate.decrypt(encryptedBuffer, decryptedBuffer, padType: OAEP(oaepOption2))

    // 验证解密结果
    let decryptedData = Array<Byte>(message.size, repeat: 0)
    decryptedBuffer.read(decryptedData)
    if (message.toArray() == decryptedData) {
        println("RSA 加解密验证成功")
    } else {
        println("RSA 加解密验证失败")
    }
}
```

运行结果：

```text
RSA 加解密验证成功
```

### 从文件中读取 RSA 公钥和私钥，并使用私钥的 PKCS1 填充模式签名，用公钥的 PKCS1 填充模式验证签名结果

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*
import stdx.crypto.digest.*
import std.fs.*
import std.io.*

main(): Unit {
    // 生成 RSA 密钥对并保存到文件
    let rsaPrivate = RSAPrivateKey(2048)
    let rsaPublic = RSAPublicKey(rsaPrivate)

    let privateKeyPem = rsaPrivate.encodeToPem()
    let privateKeyFile = File("./rsa_keys_private.pem", Write)
    privateKeyFile.write(privateKeyPem.encode().toArray())
    privateKeyFile.close()

    let publicKeyPem = rsaPublic.encodeToPem()
    let publicKeyFile = File("./rsa_keys_public.pem", Write)
    publicKeyFile.write(publicKeyPem.encode().toArray())
    publicKeyFile.close()

    // 从文件读取 PEM 格式的密钥
    let privateKeyContent = String.fromUtf8(File.readFrom("./rsa_keys_private.pem"))
    let loadedPrivateKey = RSAPrivateKey.decodeFromPem(privateKeyContent)

    let publicKeyContent = String.fromUtf8(File.readFrom("./rsa_keys_public.pem"))
    let loadedPublicKey = RSAPublicKey.decodeFromPem(publicKeyContent)

    // 计算消息的哈希值
    let message = "helloworld"
    let sha512 = SHA512()
    sha512.write(message.toArray())
    let hash = sha512.finish()

    // 使用私钥签名
    let signature = loadedPrivateKey.sign(sha512, hash, padType: PKCS1)

    // 使用公钥验证签名
    if (loadedPublicKey.verify(sha512, hash, signature, padType: PKCS1)) {
        println("RSA 签名验证成功")
    }

    // 清理测试文件
    removeIfExists("./rsa_keys_private.pem")
    removeIfExists("./rsa_keys_public.pem")
}
```

运行结果：

```text
RSA 签名验证成功
```

## ECDSA 密钥示例

### 生成 ECDSA 公钥及私钥，并使用私钥签名，公钥验证签名结果

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*
import stdx.crypto.digest.*

main() {
    // 生成 ECDSA 密钥对（P-224 曲线）
    let ecdsaPrivate = ECDSAPrivateKey(P224)
    let ecdsaPublic = ECDSAPublicKey(ecdsaPrivate)

    // 计算消息的哈希值
    let message = "helloworld"
    let sha512 = SHA512()
    sha512.write(message.toArray())
    let hash = sha512.finish()

    // 使用私钥签名
    let signature = ecdsaPrivate.sign(hash)

    // 使用公钥验证签名
    if (ecdsaPublic.verify(hash, signature)) {
        println("ECDSA 签名验证成功")
    }
}
```

运行结果：

```text
ECDSA 签名验证成功
```

## SM2 密钥示例

### 生成 SM2 公钥及私钥，并使用私钥签名，公钥验证签名结果

示例：

<!-- verify -->
```cangjie
import stdx.crypto.keys.*
import std.fs.*
import std.io.*

main(): Unit {
    // 生成 SM2 密钥对
    let sm2PrivateKey = SM2PrivateKey()
    let sm2PublicKey = SM2PublicKey(sm2PrivateKey)

    // 导出密钥到文件
    let privateKeyPem = sm2PrivateKey.encodeToPem()
    let privateKeyFile = File("./sm2_keys_private.pem", Write)
    privateKeyFile.write(privateKeyPem.encode().toArray())
    privateKeyFile.close()

    let publicKeyPem = sm2PublicKey.encodeToPem()
    let publicKeyFile = File("./sm2_keys_public.pem", Write)
    publicKeyFile.write(publicKeyPem.encode().toArray())
    publicKeyFile.close()

    // 公钥加密，私钥解密
    let message = "helloworld"
    let encrypted = sm2PublicKey.encrypt(message.toArray())
    let decrypted = sm2PrivateKey.decrypt(encrypted)
    println("解密结果: ${String.fromUtf8(decrypted)}")

    // 私钥签名，公钥验证
    let signature = sm2PrivateKey.sign(message.toArray())
    let isValid = sm2PublicKey.verify(message.toArray(), signature)
    println("签名验证: ${isValid}")

    // 从文件导入密钥
    let importedPrivateKeyPem = String.fromUtf8(File.readFrom("./sm2_keys_private.pem"))
    let importedPrivateKey = SM2PrivateKey.decodeFromPem(importedPrivateKeyPem)
    println("导入私钥: ${importedPrivateKey}")

    let importedPublicKeyPem = String.fromUtf8(File.readFrom("./sm2_keys_public.pem"))
    let importedPublicKey = SM2PublicKey.decodeFromPem(importedPublicKeyPem)
    println("导入公钥: ${importedPublicKey}")

    // 清理文件
    removeIfExists("./sm2_keys_private.pem")
    removeIfExists("./sm2_keys_public.pem")
}
```

运行结果：

```text
解密结果: helloworld
签名验证: true
导入私钥: SM2 PRIVATE KEY
导入公钥: SM2 PUBLIC KEY
```
