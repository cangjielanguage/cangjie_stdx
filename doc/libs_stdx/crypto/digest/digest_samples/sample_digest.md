# digest 使用

## MD5 算法示例

### 调用 MD5 成员函数

示例：

<!-- verify -->
```cangjie
import stdx.crypto.digest.*
import std.convert.*
import std.crypto.digest.*
import stdx.encoding.hex.*

main() {
    // 准备待哈希的数据
    let message = "helloworld"

    // 创建 MD5 实例
    let md5 = MD5()

    // 写入数据
    md5.write(message.toArray())

    // 计算哈希值
    let hash = md5.finish()

    // 转换为十六进制字符串输出
    let result = toHexString(hash)
    println("MD5 哈希值: ${result}")
    return 0
}
```

运行结果：

```text
MD5 哈希值: fc5e038d38a57032085441e7fe7010b0
```

## SHA1 算法示例

### 调用 SHA1 成员函数

示例：

<!-- verify -->
```cangjie
import stdx.crypto.digest.*
import std.convert.*
import std.crypto.digest.*
import stdx.encoding.hex.*

main() {
    // SHA1 哈希计算示例
    let message = "helloworld"
    let sha1 = SHA1()
    sha1.write(message.toArray())
    let hash = sha1.finish()
    println("SHA1 哈希值: ${toHexString(hash)}")
    return 0
}
```

运行结果：

```text
SHA1 哈希值: 6adfb183a4a2c94a2f92dab5ade762a47889a5a1
```

## SHA224 算法示例

### 调用 SHA224 成员函数

示例：

<!-- verify -->
```cangjie
import stdx.crypto.digest.*
import std.convert.*
import std.crypto.digest.*
import stdx.encoding.hex.*

main() {
    // SHA224 哈希计算示例
    let message = "helloworld"
    let sha224 = SHA224()
    sha224.write(message.toArray())
    let hash = sha224.finish()
    println("SHA224 哈希值: ${toHexString(hash)}")
    return 0
}
```

运行结果：

```text
SHA224 哈希值: b033d770602994efa135c5248af300d81567ad5b59cec4bccbf15bcc
```

## SHA256 算法示例

### 调用 SHA256 成员函数

示例：

<!-- verify -->
```cangjie
import stdx.crypto.digest.*
import std.convert.*
import std.crypto.digest.*
import stdx.encoding.hex.*

main() {
    // SHA256 哈希计算示例
    let message = "helloworld"
    let sha256 = SHA256()
    sha256.write(message.toArray())
    let hash = sha256.finish()
    println("SHA256 哈希值: ${toHexString(hash)}")
    return 0
}
```

运行结果：

```text
SHA256 哈希值: 936a185caaa266bb9cbe981e9e05cb78cd732b0b3280eb944412bb6f8f8f07af
```

## SHA384 算法示例

### 调用 SHA384 成员函数

示例：

<!-- verify -->
```cangjie
import stdx.crypto.digest.*
import std.convert.*
import std.crypto.digest.*
import stdx.encoding.hex.*

main() {
    // SHA384 哈希计算示例
    let message = "helloworld"
    let sha384 = SHA384()
    sha384.write(message.toArray())
    let hash = sha384.finish()
    println("SHA384 哈希值: ${toHexString(hash)}")
    return 0
}
```

运行结果：

```text
SHA384 哈希值: 97982a5b1414b9078103a1c008c4e3526c27b41cdbcf80790560a40f2a9bf2ed4427ab1428789915ed4b3dc07c454bd9
```

## SHA512 算法示例

### 调用 SHA512 成员函数

示例：

<!-- verify -->
```cangjie
import stdx.crypto.digest.*
import std.convert.*
import std.crypto.digest.*
import stdx.encoding.hex.*

main() {
    // SHA512 哈希计算示例
    let message = "helloworld"
    let sha512 = SHA512()
    sha512.write(message.toArray())
    let hash = sha512.finish()
    println("SHA512 哈希值: ${toHexString(hash)}")
    return 0
}
```

运行结果：

```text
SHA512 哈希值: 1594244d52f2d8c12b142bb61f47bc2eaf503d6d9ca8480cae9fcf112f66e4967dc5e8fa98285e36db8af1b8ffa8b84cb15e0fbcf836c3deb803c13f37659a60
```

## HMAC 算法示例

> **说明**
>
> 目前只支持 HMAC-SHA512。

### 调用 HMAC-SHA512 成员函数

示例：

<!-- verify -->
```cangjie
import stdx.crypto.digest.*
import stdx.encoding.hex.*

main() {
    // 准备密钥和数据
    let key = "cangjie".toArray()
    let algorithm = HashType.SHA512

    // 创建 HMAC 实例
    let hmac = HMAC(key, algorithm)

    // 分块写入数据
    hmac.write("123".toArray())
    hmac.write("456".toArray())
    hmac.write("789".toArray())

    // 计算第一个哈希值
    let hash1 = hmac.finish()
    println("HMAC 哈希值1: ${toHexString(hash1)}")

    // 重置并重新计算（验证分块和一次性写入结果相同）
    hmac.reset()
    hmac.write("123456789".toArray())
    let hash2 = hmac.finish()
    println("HMAC 哈希值2: ${toHexString(hash2)}")

    // 验证两次结果是否一致
    println("两次哈希值是否一致: ${HMAC.equal(hash1, hash2)}")
    return 0
}
```

运行结果：

```text
HMAC 哈希值1: 2bafeb53b60a119d38793a886c7744f5027d7eaa3702351e75e4ff9bf255e3ce296bf41f80adda2861e81bd8efc52219df821852d84a17fb625e3965ebf2fdd9
HMAC 哈希值2: 2bafeb53b60a119d38793a886c7744f5027d7eaa3702351e75e4ff9bf255e3ce296bf41f80adda2861e81bd8efc52219df821852d84a17fb625e3965ebf2fdd9
两次哈希值是否一致: true
```

## SM3 算法示例

### 调用 SM3 成员函数

示例：

<!-- verify -->
```cangjie
import stdx.crypto.digest.*
import std.convert.*
import std.crypto.digest.*
import stdx.encoding.hex.*

main() {
    // SM3 哈希计算示例
    let message = "helloworld"
    let sm3 = SM3()
    sm3.write(message.toArray())
    let hash = sm3.finish()
    println("SM3 哈希值: ${toHexString(hash)}")
    return 0
}
```

运行结果：

```text
SM3 哈希值: c70c5f73da4e8b8b73478af54241469566f6497e16c053a03a0170fa00078283
```
