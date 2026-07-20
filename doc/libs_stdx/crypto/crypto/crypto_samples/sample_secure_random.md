# SecureRandom 使用

SecureRandom 创建随机数对象。

示例：

<!-- run -->
```cangjie
import stdx.crypto.crypto.*

main() {
    // 创建安全随机数生成器
    let random = SecureRandom()

    // 生成 10 个随机布尔值
    println("随机生成的布尔值：")
    for (_ in 0..10) {
        let flip = random.nextBool()
        println(flip)
    }
    return 0
}
```

可能的运行结果：

```text
随机生成的布尔值：
false
true
false
false
false
true
true
false
false
true
```
