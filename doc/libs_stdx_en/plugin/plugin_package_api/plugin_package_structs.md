# Structs

## struct PluginResult

```cangjie
@C public struct PluginResult
```

Description: CHIR plugin execution result, containing processed data pointer, data length, and execution success status.

### init(CPointer\<UInt8>, Int64, Bool)

```cangjie
public init(data: CPointer<UInt8>, length: Int64, success: Bool)
```

Description: Constructs a plugin execution result instance. This constructor is internal; typically, a `PluginResult` instance is obtained via the `executeCHIRPlugins` function.

Parameters:

- data: CPointer\<UInt8> - Pointer to the processed data.
- length: Int64 - Data length.
- success: Bool - Whether the execution succeeded.

Example:

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
        println("length: ${result.length}")
        println("success: ${result.success}")
        freeSerializedMemory()
    }
}
```

Output:

```text
length: 56
success: true
```

### prop data

```cangjie
public let data: CPointer<UInt8>
```

Description: Gets the pointer to the processed data.

### prop length

```cangjie
public let length: Int64
```

Description: Gets the length of the processed data.

Example:

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
        println("length: ${result.length}")
        freeSerializedMemory()
    }
}
```

Output:

```text
length: 56
```

### prop success

```cangjie
public let success: Bool
```

Description: Gets whether the plugin execution succeeded.

Example:

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
        freeSerializedMemory()
    }
}
```

Output:

```text
success: true
```
