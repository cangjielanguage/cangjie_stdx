# Form 的构造使用

## Form 的构造与其函数 get 的使用

创建 Form 类，并通过 get 获取 key 对应映射的 value。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main(): Int64 {
    // 从 URL 编码字符串构造 Form
    let form = Form("1=2&2=3&1=2&&")

    // 获取 key 为 "1" 的 value 值
    println("key='1' 的 value: ${form.get("1").getOrThrow()}")

    return 0
}
```

运行结果：

```text
key='1' 的 value: 2
```

## Form 的构造与重复 key 情况下函数 get 的使用

创建 Form 类，并通过 get 获取 key 对应映射的 value。当有重复 key 时，get 返回第一个 value。URL 编码的值会自动解码。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main(): Int64 {
    // 从 URL 编码字符串构造 Form
    // %6A 会被解码为 'j'
    let form = Form("2=3&1=%6AD&1=2")

    // 获取重复 key 的第一个 value（自动解码）
    println("key='1' 的第一个 value: ${form.get("1").getOrThrow()}")

    return 0
}
```

运行结果：

```text
key='1' 的第一个 value: jD
```

## Form 的构造与其他函数使用

分别调用 add，set，clone 函数，展示前后变化。

示例：

<!-- verify -->
```cangjie
import stdx.encoding.url.*

main(): Int64 {
    // 创建空的 Form 并添加键值对
    let form = Form()
    form.add("k", "v1")
    form.add("k", "v2")
    println("添加后，key='k' 的第一个 value: ${form.get("k").getOrThrow()}")

    // 使用 set 设置键值（会覆盖之前的值）
    form.set("k", "v")
    println("set 后，key='k' 的 value: ${form.get("k").getOrThrow()}")

    // 克隆 Form 并添加新的键值对
    let clonedForm = form.clone()
    clonedForm.add("k1", "v1")
    println("克隆的 Form，key='k1' 的 value: ${clonedForm.get("k1").getOrThrow()}")

    // 原 Form 没有键 k1，返回默认值
    println("原 Form，key='k1' 的 value: ${form.get("k1") ?? "kkk"}")

    return 0
}
```

运行结果：

```text
添加后，key='k' 的第一个 value: v1
set 后，key='k' 的 value: v
克隆的 Form，key='k1' 的 value: v1
原 Form，key='k1' 的 value: kkk
```
