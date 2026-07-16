# 类

## class WeaveAspects

```cangjie
public class WeaveAspects {}
```

功能：基于注解的 CHIR 织入插件，自动注册到 PluginManager。该插件遍历 CHIR 包中的函数，根据注解信息（`InsertAtEntry`、`InsertAtExit`、`ReplaceFuncBody`）在指定位置织入被注解标注的函数调用。

> **说明：**
>
> `WeaveAspects` 通过 `@CHIRPlugin` 宏自动注册，无需手动调用 `PluginManager.registerCHIRPlugin`。在执行 `executeCHIRPlugins` 时会自动创建实例并调用 `run` 方法。

### func run(Package)

```cangjie
public override func run(pkg: Package): Bool
```

功能：对 CHIR 包执行织入逻辑。遍历包内所有有函数体的函数，根据注解信息在函数入口、出口或替换函数体处织入被注解标注的函数调用。

参数：

- pkg: [Package](../../../../chir/chir_package_api/chir_package_classes.md#class-package) - 待处理的 CHIR 包。

返回值：

- Bool - 处理成功返回 `true`，否则返回 `false`。

示例：

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

运行结果：

```text
package: demo
packageAccessLevel: public


success: true
```
