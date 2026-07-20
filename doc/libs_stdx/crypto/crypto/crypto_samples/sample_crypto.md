# SM4 使用

SM4 加解密数据。

示例：

<!-- verify -->
```cangjie
import stdx.crypto.crypto.*

main() {
    // 准备明文数据
    let plaintext = "hello cangjie!"

    // 准备密钥和初始向量（SM4 使用 16 字节密钥和 IV）
    let key = "YOUR_KEYYYYYYYYY"
    let iv = "YOUR_IVVVVVVVVVV"

    // 创建 SM4 加密器（CBC 模式）
    let sm4 = SM4(OperationMode.CBC, key.toArray(), iv: iv.toArray())

    // 加密数据
    let ciphertext = sm4.encrypt(plaintext.toArray())
    println("加密成功")

    // 解密数据
    let decrypted = sm4.decrypt(ciphertext)
    println("解密结果: ${String.fromUtf8(decrypted)}")
}
```

运行结果：

```text
加密成功
解密结果: hello cangjie!
```
