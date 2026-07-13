# 接口

## interface Certificate

```cangjie
public interface Certificate {}
```

功能：证书接口，用于适配不同的加密套件。

## interface CryptoKit

```cangjie
public interface CryptoKit {
    func getRandomGen(): RandomGenerator
    func publicKeyFromDer(encoded: DerBlob): PublicKey
    func publicKeyFromPem(text: String): PublicKey
    func privateKeyFromDer(encoded: DerBlob): PrivateKey
    func privateKeyFromPem(text: String): PrivateKey
    func privateKeyFromDer(encoded: DerBlob, password!: ?String): PrivateKey
    func privateKeyFromPem(text: String, password!: ?String): PrivateKey
    func dhParametersFromDer(encoded: DerBlob): DHParameters
    func dhParametersFromPem(text: String): DHParameters
    func certificateFromDer(encoded: DerBlob): Certificate
    func certificateFromPem(text: String): Array<Certificate>
}
```

功能：加密套件接口。提供随机数生成器及解码 DER、PEM 的能力。

> **说明：**
>
> PEM 是一种基于 Base64 的编码格式。

### func certificateFromDer(DerBlob)

```cangjie
func certificateFromDer(encoded: DerBlob): Certificate
```

功能：将证书从 DER 格式解码。

参数：

- encoded: [DerBlob](./crypto_common_package_structs.md#struct-derblob) - 待解码的 DerBlob 对象。

返回值：

- [Certificate](#interface-certificate) - 解码得到的证书。

### func certificateFromPem(String)

```cangjie
func certificateFromPem(text: String): Array<Certificate>
```

功能：将证书从 PEM 格式解码。

参数：

- text: String - 待解码的 PEM 格式字符串。

返回值：

- Array\<[Certificate](#interface-certificate)> - 解码得到的证书集合。

### func dhParametersFromDer(DerBlob)

```cangjie
func dhParametersFromDer(encoded: DerBlob): DHParameters
```

功能：将 DH 密钥参数从 DER 格式解码。

参数：

- encoded: [DerBlob](./crypto_common_package_structs.md#struct-derblob) - 待解码的 DerBlob 对象。

返回值：

- [DHParameters](#interface-dhparameters) - 解码得到的 DH 密钥参数。

### func dhParametersFromPem(String)

```cangjie
func dhParametersFromPem(text: String): DHParameters
```

功能：将 DH 密钥参数从 PEM 格式解码。

参数：

- text: String - 待解码的 PEM 格式字符串。

返回值：

- [DHParameters](#interface-dhparameters) - 解码得到的 DH 密钥参数。

### func getRandomGen()

```cangjie
func getRandomGen(): RandomGenerator
```

功能：获取随机数生成器。

返回值：

- [RandomGenerator](#interface-randomgenerator) - 随机数生成器。

### func privateKeyFromDer(DerBlob)

```cangjie
func privateKeyFromDer(encoded: DerBlob): PrivateKey
```

功能：将私钥从 DER 格式解码。

参数：

- encoded: [DerBlob](./crypto_common_package_structs.md#struct-derblob) - 待解码的 DerBlob 对象。

返回值：

- [PrivateKey](#interface-privatekey) - 解码得到的私钥。

### func privateKeyFromDer(DerBlob, ?String)

```cangjie
func privateKeyFromDer(encoded: DerBlob, password!: ?String): PrivateKey
```

功能：将私钥从 DER 格式解密解码。密码为 None 时则不解密。

参数：

- encoded: [DerBlob](./crypto_common_package_structs.md#struct-derblob) - 待解密解码的 DerBlob 对象。
- password!: ?String - 解密密码。

返回值：

- [PrivateKey](#interface-privatekey) - 解密解码得到的私钥。

### func privateKeyFromPem(String)

```cangjie
func privateKeyFromPem(text: String): PrivateKey
```

功能：将私钥从 PEM 格式解码。

参数：

- text: String - 待解码的 PEM 格式字符串。

返回值：

- [PrivateKey](#interface-privatekey) - 解码得到的私钥。

### func privateKeyFromPem(String, ?String)

```cangjie
func privateKeyFromPem(text: String, password!: ?String): PrivateKey
```

功能：将私钥从 PEM 格式解密解码。密码为 `None` 时则不解密。

参数：

- text: String - 待解密解码的 PEM 格式字符串。
- password!: ?String - 解密密码。

返回值：

- [PrivateKey](#interface-privatekey) - 解密解码得到的私钥。

### func publicKeyFromDer(DerBlob)

```cangjie
func publicKeyFromDer(encoded: DerBlob): PublicKey
```

功能：将公钥从 DER 格式解码。

参数：

- encoded: [DerBlob](./crypto_common_package_structs.md#struct-derblob) - 待解码的 DerBlob 对象。

返回值：

- [PublicKey](#interface-publickey) - 解码得到的公钥。

### func publicKeyFromPem(String)

```cangjie
func publicKeyFromPem(text: String): PublicKey
```

功能：将公钥从 PEM 格式解码。

参数：

- text: String - 待解码的 PEM 格式字符串。

返回值：

- [PublicKey](#interface-publickey) - 解码得到的公钥。

## interface DHParameters

```cangjie
public interface DHParameters <: Key {
    static func decodeDer(encoded: DerBlob): DHParameters
    static func decodeFromPem(text: String): DHParameters
}
```

功能：DH 密钥参数接口。

父类型：

- [Key](#interface-key)

### static func decodeDer(DerBlob)

```cangjie
static func decodeDer(encoded: DerBlob): DHParameters
```

功能：将 DH 密钥参数从 DER 格式解码。

> **说明：**
>
> - DH（Diffie-Hellman）密钥交换协议是一种确保共享 KEY 安全穿越不安全网络的方法。
> - DER 和 PEM 是两种常见的编码格式。

参数：

- encoded: [DerBlob](./crypto_common_package_structs.md#struct-derblob) - DER 格式的 DH 密钥参数对象。

返回值：

- [DHParameters](#interface-dhparameters) - 由 DER 格式解码出的 DH 密钥参数。

### static func decodeFromPem(String)

```cangjie
static func decodeFromPem(text: String): DHParameters
```

功能：将 DH 密钥参数从 PEM 格式解码。

参数：

- text: String - PEM 格式的 DH 密钥参数字符流。

返回值：

- [DHParameters](#interface-dhparameters) - 由 PEM 格式解码出的 DH 密钥参数。

## interface Key

```cangjie
public interface Key <: ToString {
    func encodeToDer(): DerBlob
    func encodeToPem(): PemEntry
    static func decodeDer(encoded: DerBlob): Key
    static func decodeFromPem(text: String): Key
}
```

功能：密钥接口。公钥用于签名验证或加密，私钥用于签名或解密，公钥和私钥必须相互匹配并形成一对。该类为密钥类，无具体实现，供 [PrivateKey](#interface-privatekey)/[PublicKey](#interface-publickey) 及用户扩展接口。

父类型：

- ToString

### static func decodeDer(DerBlob)

```cangjie
static func decodeDer(encoded: DerBlob): Key
```

功能：将密钥从 DER 格式解码。

参数：

- encoded: [DerBlob](./crypto_common_package_structs.md#struct-derblob) - DER 格式的对象。

返回值：

- [Key](#interface-key) - 由 DER 格式解码出的密钥。

### static func decodeFromPem(String)

```cangjie
static func decodeFromPem(text: String): Key
```

功能：将密钥从 PEM 格式解码。

参数：

- text: String - PEM 格式的字符流。

返回值：

- [Key](#interface-key) - 由 PEM 格式解码出的密钥。

### func encodeToDer()

```cangjie
func encodeToDer(): DerBlob
```

功能：将密钥编码为 DER 格式。

返回值：

- [DerBlob](./crypto_common_package_structs.md#struct-derblob) - 密钥数据 DER 格式编码生成的对象。

### func encodeToPem()

```cangjie
func encodeToPem(): PemEntry
```

功能：将密钥编码为 PEM 格式。

返回值：

- [PemEntry](./crypto_common_package_structs.md#struct-pementry) - 密钥数据 PEM 格式编码生成的对象。

## interface PrivateKey

```cangjie
public interface PrivateKey <: Key {
    func encodeToDer(password!: ?String): DerBlob
    func encodeToPem(password!: ?String): PemEntry
    static func decodeDer(encoded: DerBlob): PrivateKey
    static func decodeFromPem(text: String): PrivateKey
    static func decodeDer(encoded: DerBlob, password!: ?String): PrivateKey
    static func decodeFromPem(text: String, password!: ?String): PrivateKey
}
```

功能：私钥接口。

父类型：

- [Key](#interface-key)

### static func decodeDer(DerBlob)

```cangjie
static func decodeDer(encoded: DerBlob): PrivateKey
```

功能：将私钥从 DER 格式解码。

参数：

- encoded: [DerBlob](./crypto_common_package_structs.md#struct-derblob) - DER 格式的私钥对象。

返回值：

- [PrivateKey](#interface-privatekey) - 由 DER 格式解码出的私钥。

### static func decodeDer(DerBlob, ?String)

```cangjie
static func decodeDer(encoded: DerBlob, password!: ?String): PrivateKey
```

功能：将 DER 格式的私钥解密解码成 [PrivateKey](#interface-privatekey) 对象，密码为 None 时则不解密。

参数：

- encoded: [DerBlob](./crypto_common_package_structs.md#struct-derblob) - DER 格式的私钥。
- password!: ?String - 解密密码。

返回值：

- [PrivateKey](#interface-privatekey) - 解密解码后的私钥对象。

### static func decodeFromPem(String)

```cangjie
static func decodeFromPem(text: String): PrivateKey
```

功能：将私钥从 PEM 格式解码。

参数：

- text: String - PEM 格式的私钥字符流。

返回值：

- [PrivateKey](#interface-privatekey) - 由 PEM 格式解码出的私钥。

### static func decodeFromPem(String, ?String)

```cangjie
static func decodeFromPem(text: String, password!: ?String): PrivateKey
```

功能：将 PEM 格式的私钥解密解码成 [PrivateKey](#interface-privatekey) 对象，密码为 None 时则不解密。

参数：

- text: String - PEM 格式的私钥。
- password!: ?String - 解密密码。

返回值：

- [PrivateKey](#interface-privatekey) - 解密解码后的私钥对象。

### func encodeToDer(?String)

```cangjie
func encodeToDer(password!: ?String): DerBlob
```

功能：将私钥加密编码成 DER 格式，密码为 None 时则不加密。

参数：

- password!: ?String - 加密密码。

返回值：

- [DerBlob](./crypto_common_package_structs.md#struct-derblob) - 加密后的 DER 格式的私钥。

### func encodeToPem(?String)

```cangjie
func encodeToPem(password!: ?String): PemEntry
```

功能：将私钥加密编码成 PEM 格式，密码为 None 时则不加密。

参数：

- password!: ?String - 加密密码。

返回值：

- [PemEntry](./crypto_common_package_structs.md#struct-pementry) - 加密后的 PEM 格式的私钥。

## interface PublicKey

```cangjie
public interface PublicKey <: Key {
    static func decodeDer(encoded: DerBlob): PublicKey
    static func decodeFromPem(text: String): PublicKey
}
```

功能：公钥接口。

父类型：

- [Key](#interface-key)

### static func decodeDer(DerBlob)

```cangjie
static func decodeDer(encoded: DerBlob): PublicKey
```

功能：将公钥从 DER 格式解码。

参数：

- encoded: [DerBlob](./crypto_common_package_structs.md#struct-derblob) - DER 格式的公钥对象。

返回值：

- [PublicKey](#interface-publickey) - 由 DER 格式解码出的公钥。

### static func decodeFromPem(String)

```cangjie
static func decodeFromPem(text: String): PublicKey
```

功能：将公钥从 PEM 格式解码。

参数：

- text: String - PEM 格式的公钥字符流。

返回值：

- [PublicKey](#interface-publickey) - 由 PEM 格式解码出的公钥。

## interface RandomGenerator

```cangjie
public interface RandomGenerator {
    func nextBits(bits: UInt64): UInt64
    func nextBytes(bytes: Array<Byte>): Unit
}
```

功能：安全随机数生成器接口。

### func nextBits(UInt64)

```cangjie
func nextBits(bits: UInt64): UInt64
```

功能：生成一个指定位长的随机整数。

参数：

- bits: UInt64 - 要生成的随机数的位数，取值范围 (0, 64]。

返回值：

- UInt64 - 生成的指定位长的随机数。

### func nextBytes(Array\<Byte>)

```cangjie
func nextBytes(bytes: Array<Byte>): Unit
```

功能：生成随机数替换入参数组中的每个元素。

参数：

- bytes: Array\<Byte> - 被替换的数组。
