# Classes

## class WeaveAspects

```cangjie
public class WeaveAspects {}
```

Description: Annotation-based CHIR weaving plugin, auto-registered with PluginManager. This plugin traverses functions in a CHIR package and weaves annotated function calls at specified positions (entry, exit, or body replacement) based on annotation information (`InsertAtEntry`, `InsertAtExit`, `ReplaceFuncBody`).

> **Note:**
>
> `WeaveAspects` is auto-registered via the `@CHIRPlugin` macro; no manual call to `PluginManager.registerCHIRPlugin` is needed. When `executeCHIRPlugins` is invoked, an instance is created and `run` is called automatically.

### func run(Package)

```cangjie
public override func run(pkg: Package): Bool
```

Description: Executes the weaving logic on a CHIR package. Traverses all functions with bodies in the package and weaves annotated function calls at entry, exit, or body replacement positions based on annotation information.

Parameters:

- pkg: [Package](../../../../chir/chir_package_api/chir_package_classes.md#class-package) - The CHIR package to process.

Return value:

- Bool - `true` if processing succeeded, `false` otherwise.

Example:

<!-- verify -->
```cangjie
import stdx.aspect_cj.plugins.weave_aspects.*
import stdx.plugin.manager.*
import stdx.chir.*

main() {
    let pkg = Package("demo", AccessLevel.Public)
    pkg.dump()
    let (data, length) = serializePackage(pkg)
    unsafe {
        let result = executeCHIRPlugins(data, length)
        println("success: ${result.success}")
        freeSerializedMemory()
    }
}
```

Output:

```text
package: demo
packageAccessLevel: public


success: true
```
