# stdx.plugin

> **Note:**
>
> Currently in development stage, not yet with full functionality.

## Feature Introduction

The plugin package provides the CHIR plugin registration mechanism:

- **Plugin registration macro** (`CHIRPlugin`): Automatically transforms a class declaration into a CHIRPluginBase subclass and registers it with PluginManager.

> Plugin management and execution APIs are in the [stdx.plugin.manager](./manager/plugin_manager_package_overview.md) sub-package.

## API List

### Macros

| Macro name | Description |
| --- | --- |
| [CHIRPlugin](./plugin_package_api/plugin_package_macros.md) | CHIR plugin registration macro. |
