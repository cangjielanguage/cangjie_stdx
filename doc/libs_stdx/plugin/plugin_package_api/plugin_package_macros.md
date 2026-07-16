# 宏

## `@CHIRPlugin` 宏

```cangjie
public macro CHIRPlugin(input: Tokens): Tokens
```

功能：CHIR 插件注册宏，将一个类声明自动转换为 CHIRPluginBase 子类并注册到 PluginManager。使用此宏标注的类将自动继承 CHIRPluginBase 并通过 PluginManager.registerCHIRPlugin 注册。

> **注意：**
>
> 使用 `@CHIRPlugin` 宏标注的类不要手动继承 `CHIRPluginBase`，否则会在运行时抛出异常。宏会自动处理继承和注册逻辑。

宏参数：

- input: Tokens - 待处理的类声明 Token 序列。

示例：

<!-- verify -->
```cangjie
import stdx.plugin.manager.*
import stdx.chir.*

@CHIRPlugin
class MyPlugin {
    public init() {}
    public open func run(pkg: Package): Bool {
        println("Macro plugin processed: ${pkg.name}")
        return true
    }
}

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let plugin = MyPlugin()
    let result = plugin.run(pkg)
    println("result: ${result}")
}
```

运行结果：

```text
Macro plugin processed: demo
result: true
```
