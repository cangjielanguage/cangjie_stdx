# 结构体

## struct PluginResult

```cangjie
public struct PluginResult {}
```

功能：CHIR 插件执行结果，包含处理后数据指针、数据长度及执行是否成功。

### init(CPointer\<UInt8>, Int64, Bool)

```cangjie
public init(data: CPointer<UInt8>, length: Int64, success: Bool)
```

功能：构造一个插件执行结果实例。该构造函数为内部实现，通常通过 `executeCHIRPlugins` 函数获取 `PluginResult` 实例。

参数：

- data: CPointer\<UInt8> - 处理后的数据指针。
- length: Int64 - 数据长度。
- success: Bool - 执行是否成功。

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
    pkg.dump()
    let (data, length) = serializePackage(pkg)
    PluginManager.registerCHIRPlugin({ => MyPlugin() })
    unsafe {
        let result = executeCHIRPlugins(data, length)
        println("length: ${result.length}")
        println("success: ${result.success}")
        freeSerializedMemory()
    }
}
```

运行结果：

```text
package: demo
packageAccessLevel: public


length: 56
success: true
```

### prop data

```cangjie
public let data: CPointer<UInt8>
```

功能：获取处理后数据的指针。

### prop length

```cangjie
public let length: Int64
```

功能：获取处理后数据的长度。

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
    pkg.dump()
    let (data, length) = serializePackage(pkg)
    PluginManager.registerCHIRPlugin({ => MyPlugin() })
    unsafe {
        let result = executeCHIRPlugins(data, length)
        println("length: ${result.length}")
        freeSerializedMemory()
    }
}
```

运行结果：

```text
package: demo
packageAccessLevel: public


length: 56
```

### prop success

```cangjie
public let success: Bool
```

功能：获取插件执行是否成功的状态。

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
    pkg.dump()
    let (data, length) = serializePackage(pkg)
    PluginManager.registerCHIRPlugin({ => MyPlugin() })
    unsafe {
        let result = executeCHIRPlugins(data, length)
        println("success: ${result.success}")
        freeSerializedMemory()
    }
}
```

运行结果：

```text
package: demo
packageAccessLevel: public


success: true
```
