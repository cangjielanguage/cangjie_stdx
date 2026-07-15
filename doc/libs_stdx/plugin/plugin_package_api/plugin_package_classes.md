# 类

## class CHIRPluginBase

```cangjie
public abstract class CHIRPluginBase <: PluginBase
```

功能：CHIR 插件的抽象基类，所有 CHIR 插件均需继承此类并实现 `run` 方法。

> **说明：**
>
> 不建议直接继承 `CHIRPluginBase` 类型，建议使用 [CHIRPlugin](#macro-chirplugin) 宏实现插件的功能

父类型：

- PluginBase

> **说明：**
>
> `PluginBase` 为内部类型，不可直接使用；`CHIRPluginBase` 是公开的插件基类入口。

### init(String)

```cangjie
public init(name: String)
```

功能：构造一个 CHIR 插件基类实例，指定插件名称。

参数：

- name: String - 插件名称。

示例：

<!-- verify -->
```cangjie
import stdx.plugin.manager.*
import stdx.chir.*

class MyPlugin <: CHIRPluginBase {
    public init() {
        super("MyPlugin")
    }
    public open func run(pkg: Package): Bool {
        println("Running plugin: ${name}")
        return true
    }
}

main() {
    let plugin = MyPlugin()
    println(plugin.name)
}
```

运行结果：

```text
MyPlugin
```

### prop name

```cangjie
public prop name: String
```

功能：获取插件名称。

示例：

<!-- verify -->
```cangjie
import stdx.plugin.manager.*
import stdx.chir.*

class MyPlugin <: CHIRPluginBase {
    public init() {
        super("MyPlugin")
    }
    public open func run(pkg: Package): Bool {
        return true
    }
}

main() {
    let plugin = MyPlugin()
    println(plugin.name)
}
```

运行结果：

```text
MyPlugin
```

### func run(Package)

```cangjie
public open func run(pkg: Package): Bool
```

功能：执行插件对 CHIR 包的处理逻辑，子类需重写此方法。

参数：

- pkg: Package - 待处理的 CHIR 包。

返回值：

- Bool - 处理成功返回 `true`，否则返回 `false`。

示例：

<!-- verify -->
```cangjie
import stdx.plugin.manager.*
import stdx.chir.*

class MyPlugin <: CHIRPluginBase {
    public init() {
        super("MyPlugin")
    }
    public open func run(pkg: Package): Bool {
        println("Plugin ${name} processed package: ${pkg.name}")
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
Plugin MyPlugin processed package: demo
result: true
```

## class PluginManager

```cangjie
public class PluginManager
```

功能：插件管理器，提供插件注册功能。

> **说明：**
>
> 不建议手动使用 `PluginManager` 类型实现插件注册的功能，建议使用 [CHIRPlugin](#macro-chirplugin) 宏实现

### static func registerCHIRPlugin(() -> CHIRPluginBase)

```cangjie
public static func registerCHIRPlugin(f: () -> CHIRPluginBase): Unit
```

功能：注册一个 CHIR 插件工厂函数，用于在插件执行时创建插件实例。

参数：

- f: () -> CHIRPluginBase - 插件工厂函数，返回一个 CHIRPluginBase 实例。

示例：

<!-- verify -->
```cangjie
import stdx.plugin.manager.*
import stdx.chir.*

class MyPlugin <: CHIRPluginBase {
    public init() {
        super("MyPlugin")
    }
    public open func run(pkg: Package): Bool {
        return true
    }
}

main() {
    PluginManager.registerCHIRPlugin({ => MyPlugin() })
    println("Plugin registered")
}
```

运行结果：

```text
Plugin registered
```

## macro CHIRPlugin

```cangjie
public macro CHIRPlugin(input: Tokens): Tokens
```

功能：CHIR 插件注册宏，将一个类声明自动转换为 CHIRPluginBase 子类并注册到 PluginManager。使用此宏标注的类将自动继承 CHIRPluginBase 并通过 PluginManager.registerCHIRPlugin 注册。

> **注意：**
>
> 使用 `@CHIRPlugin` 宏标注的类不要手动继承 `CHIRPluginBase`，否则会在运行时抛出异常。宏会自动处理继承和注册逻辑。

示例：

<!-- verify -->
```cangjie
import stdx.plugin.*
import stdx.chir.*

@CHIRPlugin
class MyPlugin {
    public override func run(pkg: Package): Bool {
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

## func executeCHIRPlugins

```cangjie
@C public func executeCHIRPlugins(data: CPointer<UInt8>, length: Int64): PluginResult
```

功能：对 CHIR 包二进制数据依次执行所有已注册的 CHIR 插件。

> **说明：**
>
> 不建议手动使用 `executeCHIRPlugins` 函数实现执行插件的功能，建议使用 [CHIRPlugin](#macro-chirplugin) 宏实现

参数：

- data: CPointer\<UInt8> - CHIR 包的二进制数据指针。
- length: Int64 - 数据长度。

返回值：

- PluginResult - 插件执行结果，包含处理后数据、长度及成功状态。

示例：

<!-- verify -->
```cangjie
import stdx.plugin.manager.*
import stdx.chir.*

class MyPlugin <: CHIRPluginBase {
    public init() {
        super("MyPlugin")
    }
    public open func run(pkg: Package): Bool {
        return true
    }
}

main() {
    let pkg = Package("demo", AccessLevel.Public)
    let (data, length) = serializePackage(pkg)
    PluginManager.registerCHIRPlugin({ => MyPlugin() })
    unsafe {
        let result = executeCHIRPlugins(data, length)
        println("success: ${result.success}")
        println("length: ${result.length}")
        freeSerializedMemory()
    }
}
```

运行结果：

```text
success: true
length: 56
```
