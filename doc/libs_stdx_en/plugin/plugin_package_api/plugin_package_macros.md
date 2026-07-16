# Macros

## `@CHIRPlugin` Macro

```cangjie
public macro CHIRPlugin(input: Tokens): Tokens
```

Function: CHIR plugin registration macro that automatically transforms a class declaration into a CHIRPluginBase subclass and registers it with PluginManager. Classes annotated with this macro will automatically inherit CHIRPluginBase and be registered via PluginManager.registerCHIRPlugin.

> **Note:**
>
> Classes annotated with `@CHIRPlugin` should not manually inherit `CHIRPluginBase`, otherwise a runtime exception will be thrown. The macro handles inheritance and registration automatically.

Macro parameters:

- input: Tokens - The token sequence of the class declaration to process.

Example:

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

Output:

```text
Macro plugin processed: demo
result: true
```
