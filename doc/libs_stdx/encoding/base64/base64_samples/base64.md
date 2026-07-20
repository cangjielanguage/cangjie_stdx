# Byte 数组和 Base64 互转

示例：

<!-- verify -->
```cangjie
import stdx.encoding.base64.*

main(): Int64 {
    // 准备字节数组
    let bytes: Array<Byte> = [77, 97, 110] // ASCII: 'M', 'a', 'n'

    // 字节数组转换为 Base64 字符串
    let base64String = toBase64String(bytes)
    println("Base64 字符串: ${base64String}")

    // Base64 字符串转换回字节数组
    if (let Some(decodedBytes) <- fromBase64String(base64String)) {
        println("解码成功，字节数组: ${decodedBytes}")
    } else {
        println("解码失败")
    }

    return 0
}
```

运行结果：

```text
Base64 字符串: TWFu
解码成功，字节数组: [77, 97, 110]
```
