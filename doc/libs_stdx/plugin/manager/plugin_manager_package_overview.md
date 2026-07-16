# stdx.plugin.manager

> **说明：**
>
> 当前处于开发阶段，尚不具备完整功能。

## 功能介绍

plugin.manager 包提供 CHIR 插件的管理与执行机制，包括：

- **插件基类**（`PluginBase`）：所有插件的基类，提供名称管理能力；
- **CHIR 插件基类**（`CHIRPluginBase`）：所有 CHIR 插件的抽象基类，子类需实现 `run` 方法；
- **插件管理器**（`PluginManager`）：提供 CHIR 插件的注册功能；
- **插件执行**（`executeCHIRPlugins`）：对 CHIR 包二进制数据依次执行所有已注册插件；
- **执行结果**（`PluginResult`）：包含处理后的数据、长度及成功状态。

## API 列表

### 类

| 类名 | 功能 |
| --- | --- |
| [PluginBase](./plugin_manager_package_api/plugin_manager_package_classes.md#class-pluginbase) | 插件基类，提供名称管理能力。 |
| [CHIRPluginBase](./plugin_manager_package_api/plugin_manager_package_classes.md#class-chirpluginbase) | CHIR 插件的抽象基类。 |
| [PluginManager](./plugin_manager_package_api/plugin_manager_package_classes.md#class-pluginmanager) | 插件管理器，提供插件注册功能。 |

### 顶层函数

| 函数名 | 功能 |
| --- | --- |
| [executeCHIRPlugins](./plugin_manager_package_api/plugin_manager_package_classes.md) | 对 CHIR 包数据执行所有已注册插件。 |

### 结构体

| 结构体名 | 功能 |
| --- | --- |
| [PluginResult](./plugin_manager_package_api/plugin_manager_package_structs.md#struct-pluginresult) | CHIR 插件执行结果。 |
