# stdx.contract.runtime

## Feature Description

The contract.runtime package provides the runtime support for contract checking, including:

- **Checking switch** (`contractCheckEnabled`): returns whether contract checking is currently active (base state fixed at compile time by the conditional compilation variable `contract_check`, one-shot runtime demotion supported); intended only for use by macro expansion output, and users should not call it directly;
- **Runtime demotion** (`disableContractChecks`): disables all subsequent contract checks in the process; one-way, thread-safe, and idempotent;
- **Contract exception classes**: the common base class [ContractCheckException](./contract_runtime_package_api/contract_runtime_package_exceptions.md#abstract-class-contractcheckexception) and 7 exceptions thrown when contract checks fail; the base class inherits from `Exception`;
- **Contract exception identification** (`isContractException`): determines whether an exception is a contract exception;
- **Runtime helper functions** (`contractEvalEnter`, `contractEvalExit`, `contractInEvaluation`, `contractCaptureSnapshot`, `contractGhostGet`): mainly intended for use by macro-expanded code, and users should not call them directly;
- **Visibility enum** (`ContractVisibility`): used to compare the member visibility required by contract checking.

To declare contracts, use the macros in the [stdx.contract.macros](../contract_package_api/contract_package_macros.md) package. The contract checking switch has two layers. At **compile time** it is determined and fixed by the conditional compilation variable `contract_check` when the `stdx.contract.runtime` package is compiled, and is enabled by default (the `cfg.toml` file in the source directory of that package declares `contract_check = "on"`; cjc reads the cfg.toml in the current working directory when building, cjpm reads it as well, and the `--cfg` option takes precedence); to build a zero-checking-overhead artifact, rebuild the package with `cjc --cfg "contract_check=off" ...`. At **run time** a one-shot demotion is supported: calling [disableContractChecks](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-disablecontractchecks) disables all subsequent check points in the process; demotion is one-way and cannot be re-enabled.

## API List

### Functions

| Function Name | Functionality |
| --- | --- |
| [contractCaptureSnapshot](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-contractcapturesnapshot) | Captures the entry snapshot when checking is enabled; otherwise returns `None`. |
| [contractCheckEnabled](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-contractcheckenabled) | Returns whether contract checking is currently active (for macro expansion output only). |
| [disableContractChecks](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-disablecontractchecks) | One-way disabling of all subsequent contract checks in the process (thread-safe, idempotent). |
| [contractGhostGet](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-contractghostget) | Reads an auxiliary variable, throwing `ContractCheckGhostStateException` if it is uninitialized. |
| [contractEvalEnter](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-contractevalenter) | Enters contract expression evaluation, incrementing the evaluation depth of the current thread. |
| [contractEvalExit](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-contractevalexit) | Exits contract expression evaluation, decrementing the evaluation depth of the current thread. |
| [contractInEvaluation](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-contractinevaluation) | Determines whether the current thread is inside contract expression evaluation. |
| [_contract_gateEnabled](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-contract-gateenabled) | The gate function of every check point: returns `true` when checking is active and the current thread is not inside contract evaluation (internal API, for macro expansion output only; controlled by the compile-time `contract_check`). |
| [isContractException](./contract_runtime_package_api/contract_runtime_package_funcs.md#func-iscontractexception) | Determines whether an exception is a contract exception. |

### Enums

| Enum Name | Functionality |
| --- | --- |
| [ContractVisibility](./contract_runtime_package_api/contract_runtime_package_enums.md#enum-contractvisibility) | The member visibility ordering used by contract checking. |

### Exceptions

| Exception Name | Functionality |
| --- | --- |
| [ContractCheckException](./contract_runtime_package_api/contract_runtime_package_exceptions.md#abstract-class-contractcheckexception) | The common base class (abstract) of all contract exceptions; catch it to handle all contract failures. |
| [ContractCheckGhostStateException](./contract_runtime_package_api/contract_runtime_package_exceptions.md#class-contractcheckghoststateexception) | Thrown when an auxiliary variable is read by a contract before being initialized. |
| [ContractCheckAssertException](./contract_runtime_package_api/contract_runtime_package_exceptions.md#class-contractcheckassertexception) | Thrown when an assertion check fails. |
| [ContractCheckEnsuresException](./contract_runtime_package_api/contract_runtime_package_exceptions.md#class-contractcheckensuresexception) | Thrown when a postcondition check fails. |
| [ContractCheckInvariantException](./contract_runtime_package_api/contract_runtime_package_exceptions.md#class-contractcheckinvariantexception) | Thrown when a type invariant check fails. |
| [ContractCheckLoopInvariantException](./contract_runtime_package_api/contract_runtime_package_exceptions.md#class-contractcheckloopinvariantexception) | Thrown when a loop invariant check fails. |
| [ContractCheckRequiresException](./contract_runtime_package_api/contract_runtime_package_exceptions.md#class-contractcheckrequiresexception) | Thrown when a precondition check fails. |
| [ContractCheckThrowsException](./contract_runtime_package_api/contract_runtime_package_exceptions.md#class-contractcheckthrowsexception) | Thrown when an exception contract check fails. |
