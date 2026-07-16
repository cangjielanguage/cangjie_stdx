# stdx.plugin

> **说明：**
>
> 当前处于开发阶段，尚不具备完整功能。

## 功能介绍

plugin 包提供 CHIR 插件的注册机制：

- **插件注册宏**（`CHIRPlugin`）：自动将类声明转换为 CHIRPluginBase 子类并注册到 PluginManager。

> 插件管理与执行相关 API 位于 [stdx.plugin.manager](./manager/plugin_manager_package_overview.md) 子包中。

## API 列表

### 宏

| 宏名 | 功能 |
| --- | --- |
| [CHIRPlugin](./plugin_package_api/plugin_package_macros.md) | CHIR 插件注册宏。 |
