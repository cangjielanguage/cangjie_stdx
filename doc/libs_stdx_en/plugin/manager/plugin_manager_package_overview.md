# stdx.plugin.manager

> **Note:**
>
> Currently in development stage, not yet with full functionality.

## Feature Introduction

The plugin.manager package provides CHIR plugin management and execution mechanisms, including:

- **Plugin base class** (`PluginBase`): Base class for all plugins, providing name management.
- **CHIR plugin base class** (`CHIRPluginBase`): Abstract base class for all CHIR plugins; subclasses must implement the `run` method.
- **Plugin manager** (`PluginManager`): Provides CHIR plugin registration functionality.
- **Plugin execution** (`executeCHIRPlugins`): Executes all registered plugins on CHIR package binary data sequentially.
- **Execution result** (`PluginResult`): Contains processed data, length, and success status.

## API List

### Classes

| Class name | Description |
| --- | --- |
| [PluginBase](./plugin_manager_package_api/plugin_manager_package_classes.md#class-pluginbase) | Plugin base class, providing name management. |
| [CHIRPluginBase](./plugin_manager_package_api/plugin_manager_package_classes.md#class-chirpluginbase) | Abstract base class for CHIR plugins. |
| [PluginManager](./plugin_manager_package_api/plugin_manager_package_classes.md#class-pluginmanager) | Plugin manager, providing plugin registration. |

### Top-level Functions

| Function name | Description |
| --- | --- |
| [executeCHIRPlugins](./plugin_manager_package_api/plugin_manager_package_classes.md) | Execute all registered CHIR plugins on package data. |

### Structs

| Struct name | Description |
| --- | --- |
| [PluginResult](./plugin_manager_package_api/plugin_manager_package_structs.md#struct-pluginresult) | CHIR plugin execution result. |
