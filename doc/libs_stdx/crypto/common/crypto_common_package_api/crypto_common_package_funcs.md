# 函数

## func getGlobalCryptoKit()

```cangjie
public func getGlobalCryptoKit(): CryptoKit
```

功能：获取当前全局使用的加密套件。

返回值：

- [CryptoKit](./crypto_common_package_interfaces.md#interface-cryptokit) - 当前全局使用的加密套件。

异常：

- [CryptoException](./crypto_common_package_exceptions.md#class-cryptoexception) - 若未设置全局加密套件，则会抛出异常。

## func setGlobalCryptoKit(CryptoKit)

```cangjie
public func setGlobalCryptoKit(kit: CryptoKit): Unit
```

功能：设置全局使用的加密套件。

参数：

- kit: [CryptoKit](./crypto_common_package_interfaces.md#interface-cryptokit) - 全局加密套件。
