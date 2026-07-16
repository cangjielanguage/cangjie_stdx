# Classes

## class PluginBase

```cangjie
sealed abstract class PluginBase {}
```

Description: Plugin base class, providing name management for all plugins. This class is `sealed` (cannot be subclassed outside the package) and its constructor is `internal` (cannot be instantiated outside the package). Use its public subclass [CHIRPluginBase](#class-chirpluginbase) for plugin functionality.

### prop name

```cangjie
public prop name: String
```

Description: Gets the plugin name.

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
    let plugin = MyPlugin()
    println(plugin.name)
}
```

Output:

```text
MyPlugin
```

## class CHIRPluginBase

```cangjie
public abstract class CHIRPluginBase <: PluginBase {
    public init(name: String)
}
```

Description: Abstract base class for CHIR plugins. All CHIR plugins must inherit this class and implement the `run` method.

> **Note:**
>
> Directly inheriting `CHIRPluginBase` is not recommended. Prefer the [CHIRPlugin](../../plugin_package_api/plugin_package_macros.md) macro to implement plugins.

Parent types:

- PluginBase

> **Note:**
>
> The constructor of `PluginBase` is `internal` and cannot be instantiated directly outside the package; use `CHIRPluginBase` instead. See [PluginBase](#class-pluginbase) for details.

### init(String)

```cangjie
public init(name: String)
```

Description: Constructs a CHIR plugin base instance with the specified plugin name.

Parameters:

- name: String - The plugin name.

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
        println("Running plugin: ${name}")
        return true
    }
}

main() {
    let plugin = MyPlugin()
    println(plugin.name)
}
```

Output:

```text
MyPlugin
```

### func run(Package)

```cangjie
public open func run(pkg: Package): Bool
```

Description: Executes the plugin's processing logic on a CHIR package. Subclasses must override this method.

Parameters:

- pkg: Package - The CHIR package to process.

Return value:

- Bool - `true` if processing succeeded, `false` otherwise.

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

Output:

```text
Plugin MyPlugin processed package: demo
result: true
```

## class PluginManager

```cangjie
public class PluginManager {}
```

Description: Plugin manager, providing plugin registration functionality.

> **Note:**
>
> Manually using `PluginManager` for plugin registration is not recommended. Prefer the [CHIRPlugin](../../plugin_package_api/plugin_package_macros.md) macro.

### static func registerCHIRPlugin(() -> CHIRPluginBase)

```cangjie
public static func registerCHIRPlugin(f: () -> CHIRPluginBase): Unit
```

Description: Registers a CHIR plugin factory function, used to create plugin instances during plugin execution.

Parameters:

- f: () -> CHIRPluginBase - A factory function that returns a CHIRPluginBase instance.

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
    PluginManager.registerCHIRPlugin({ => MyPlugin() })
    println("Plugin registered")
}
```

Output:

```text
Plugin registered
```

## func executeCHIRPlugins(CPointer\<UInt8>, Int64)

```cangjie
public func executeCHIRPlugins(data: CPointer<UInt8>, length: Int64): PluginResult
```

Description: Executes all registered CHIR plugins on CHIR package binary data sequentially.

> **Note:**
>
> Manually calling `executeCHIRPlugins` to run plugins is not recommended. Prefer the [CHIRPlugin](../../plugin_package_api/plugin_package_macros.md) macro.

Parameters:

- data: CPointer\<UInt8> - Pointer to the CHIR package binary data.
- length: Int64 - Data length.

Return value:

- PluginResult - The plugin execution result, containing processed data, length, and success status.

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
        println("length: ${result.length}")
        freeSerializedMemory()
    }
}
```

Output:

```text
success: true
length: 56
```
