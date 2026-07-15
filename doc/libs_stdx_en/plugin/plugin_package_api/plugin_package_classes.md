# Classes

## class CHIRPluginBase

```cangjie
public abstract class CHIRPluginBase <: PluginBase
```

Description: Abstract base class for CHIR plugins. All CHIR plugins must inherit this class and implement the `run` method.

> **Note:**
>
> Directly inheriting `CHIRPluginBase` is not recommended. Prefer the [CHIRPlugin](#macro-chirplugin) macro to implement plugins.

Parent types:

- PluginBase

> **Note:**
>
> `PluginBase` is an internal type and cannot be used directly; `CHIRPluginBase` is the public plugin base class entry point.

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
public class PluginManager
```

Description: Plugin manager, providing plugin registration functionality.

> **Note:**
>
> Manually using `PluginManager` for plugin registration is not recommended. Prefer the [CHIRPlugin](#macro-chirplugin) macro.

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

## macro CHIRPlugin

```cangjie
public macro CHIRPlugin(input: Tokens): Tokens
```

Description: CHIR plugin registration macro that automatically transforms a class declaration into a CHIRPluginBase subclass and registers it with PluginManager. Classes annotated with this macro will automatically inherit CHIRPluginBase and be registered via PluginManager.registerCHIRPlugin.

> **Note:**
>
> Classes annotated with `@CHIRPlugin` should not manually inherit `CHIRPluginBase`, otherwise a runtime exception will be thrown. The macro handles inheritance and registration automatically.

Example:

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

Output:

```text
Macro plugin processed: demo
result: true
```

## func executeCHIRPlugins

```cangjie
@C public func executeCHIRPlugins(data: CPointer<UInt8>, length: Int64): PluginResult
```

Description: Executes all registered CHIR plugins on CHIR package binary data sequentially.

> **Note:**
>
> Manually calling `executeCHIRPlugins` to run plugins is not recommended. Prefer the [CHIRPlugin](#macro-chirplugin) macro.

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
