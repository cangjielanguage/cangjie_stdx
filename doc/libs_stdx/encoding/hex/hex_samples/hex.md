# Byte 数组和 Hex 互转

示例：

<!-- verify -->
```cangjie
import stdx.encoding.hex.*

main(): Int64 {
    // 准备字节数组
    let bytes: Array<Byte> = [65, 66, 94, 97] // ASCII: 'A', 'B', '^', 'a'

    // 字节数组转换为十六进制字符串
    let hexString = toHexString(bytes)
    println("十六进制字符串: ${hexString}")

    // 十六进制字符串转换回字节数组
    if (let Some(decodedBytes) <- fromHexString(hexString)) {
        println("解码成功，字节数组: ${decodedBytes}")
    } else {
        println("解码失败")
    }
    return 0
}
```

运行结果：

```text
十六进制字符串: 41425e61
解码成功，字节数组: [65, 66, 94, 97]
```
