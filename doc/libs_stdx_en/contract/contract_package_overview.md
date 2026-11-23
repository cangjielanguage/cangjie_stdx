# stdx.contract

## Feature Description

Based on the Design by Contract philosophy, the contract package provides runtime contract checking capabilities for the Cangjie language. Developers can declare contract clauses on functions, properties, types, and loops, and the runtime automatically verifies these contracts when checking is enabled, so that calls or implementations violating the agreements can be detected as early as possible during development and testing.

The contract package consists of two subpackages:

- [stdx.contract.macros](./contract_package_api/contract_package_macros.md): provides macros such as `@Contract`, `@ghost`, `@contractAssert`, and `@loopInvariant`, serving as the entry point for declaring contracts;
- [stdx.contract.runtime](./runtime/contract_runtime_package_overview.md): provides the contract checking switch, contract exception types, and runtime helper functions.

### Contract Kinds

| Contract | Declaration Location | Keyword | Description |
| --- | --- | --- | --- |
| Precondition | functions, properties | `requires` | A condition that the caller must satisfy, checked before the function body executes. |
| Postcondition | functions, properties | `ensures` | A condition that must hold when the function returns; the return value can be bound with `ensures r:`. |
| Exception contract | functions, properties | `throws` | Declares the exception types that must be thrown when the specified conditions hold. |
| Type invariant | class, struct, interface | `invariant` | A condition that an instance of the type must maintain before and after calls to its public interface. |
| Abstract state | class, struct, interface, function contracts | `variable` | Declares abstract state that can be referenced by contracts, especially useful for interfaces; a function contract can also declare a function-level auxiliary variable referenced by other clauses. |
| Contract inheritance | class, struct, interface | `inherits from` / `inherits <kind> <parent type>.<name>` | By default, parent contracts are not inherited; `inherits from` reuses all contracts declared on the parent type and can be augmented with `[conforming]` to force implementations to conform to the contracts; `inherits requires/ensures/throws/variable/invariant` selectively inherits a single named contract (with renaming allowed). Class-level `variable` is always inherited automatically. Parent types within the same package (compilation unit) can be referenced directly; cross-package contract inheritance requires environment variable conventions (see "Cross-Package Contract Inheritance" below). |
| Function-body assertion | function body | `@contractAssert` | An assertion checked at arbitrary points inside a function body. |
| Loop invariant | function body | `@loopInvariant` | A condition that must hold at the loop's check points: checked at the start of each iteration and after loop exit for `while`, at the start of each iteration for `for-in`, and after each loop-body execution before the condition is evaluated for `do-while`. |
| Ghost code | function body | `@ghost` | Auxiliary code used only to maintain abstract state and not participating in business logic. |

> @Contract on an extend only carries member-level contracts: member functions/properties inside the extend can be annotated with @Contract to declare member-level clauses such as `requires`/`ensures`/`throws` (and members may use `inherits` to selectively inherit member contracts); the extend itself supports no type-level clauses (`variable`, `invariant`, `inherits`), and its `@Contract` clause list must be empty, otherwise the macro expansion reports a compile error.

> When `@Contract` is annotated directly on a type member (the enclosing type has no type-level `@Contract`), the macro expansion sees only that member and cannot know the enclosing type's member list: if a function-level `variable` shares its name with an enclosing type member, bare-name reads in the implementation body evaluate to the function-level auxiliary variable (the type-level path reports a compile ERROR for the same situation). Avoid such name clashes, or declare the contract on the enclosing type's `@Contract` instead.

> The macro analyzes `match` case patterns at the token level to identify the bindings a contract rewrite may touch: a no-payload enum constructor in a bare `case Red =>` pattern is indistinguishable from a binding and stays collected (over-reporting is the safe direction). A contract auxiliary variable sharing its name with such a constructor therefore also rewrites the constructor name. Avoid the name clash, or qualify the constructor path (e.g. `Color.Red`).

> For the full grammar of the clauses above (such as `[name]` labels, `ensures r:` return-value binding, `$pre(...)` entry snapshot references, and contracts on primary constructors), see the `@Contract` macro description in [stdx.contract.macros](./contract_package_api/contract_package_macros.md).

### Enabling and Disabling

The contract checking switch has two layers: compile time and run time.

**Compile time**: controlled by the conditional compilation variable `contract_check`, enabled by default. The value of the switch is fixed **when the `stdx.contract.runtime` package is compiled**. Where `cfg.toml` is read depends on the compilation mode: in **package mode** (`cjc -p <package directory>` or a cjpm build), cjc reads `cfg.toml` from the **package source directory** (the `stdx.contract.runtime` package ships a `cfg.toml` whose declared default is `contract_check = "on"`) and does not read `cfg.toml` from the process working directory; only **single-file mode** (compiling a single `.cj` file directly) reads `cfg.toml` from the process working directory. A `--cfg` command-line option has the highest priority and overrides `cfg.toml`. When this library is built with CMake, the build script passes `--cfg "contract_check=on"` explicitly; that option overrides the package's `cfg.toml`, so editing that file does not change the switch of CMake-built artifacts. If the package source directory contains no `cfg.toml` and the option is not supplied explicitly (on the command line or via `compile-option` in `cjpm.toml`), any code that uses the `contract_check` conditional compilation variable fails to compile. Applications consuming prebuilt stdx artifacts need no action. To build a runtime artifact that contains no contract checking at all, run `cjc -p <runtime source directory> --cfg "contract_check=off" --output-type=dylib` from outside the runtime source directory (appending this option when compiling the application side does not change the switch already fixed in the prebuilt runtime); in an off artifact the overhead of every check point is a compile-time constant test and contract clauses are never evaluated.

**Run time**: an artifact compiled with checking on supports a one-shot demotion — after [disableContractChecks](./runtime/contract_runtime_package_api/contract_runtime_package_funcs.md#func-disablecontractchecks) is called anywhere in the process, all subsequent check points in that process are skipped. Demotion is **one-way**: the library provides no API to re-enable checking, so in-process behavior is monotonically weakened (either fully checked, or checked only up to the demotion point), and the same call can never flip between throwing and not throwing depending on the switch state. The function is thread-safe and idempotent; in an off artifact it is a no-op. Beyond this, the library provides the read-only query [contractCheckEnabled](./runtime/contract_runtime_package_api/contract_runtime_package_funcs.md#func-contractcheckenabled) (intended only for macro expansion output, returning whether checking is currently active); the base state of the switch is determined solely by the compile-time `contract_check`, and no API to re-enable checking is provided at run time beyond the one-way demotion above.

When checking is enabled, each contract clause is evaluated once at its check point; a type invariant is evaluated twice — before and after every member call of that type. Without a selector, members at internal visibility and broader (public, protected, and package-internal members) are checked by default, and the `on_public`/`on_protected`/`on_private` selectors can narrow the scope. Each contract evaluation is bracketed by an in-thread evaluation-state flag update. Keep contract expressions lightweight and avoid deploying types built on this library onto performance-sensitive hot paths.

### `@ghost` Usage Restrictions

An `@ghost` block expands into conditionally executed code, and variables declared with `let`/`var` inside it are invisible outside the block, so they cannot be referenced by the enclosing function's `requires`/`ensures`/`throws` clauses; abstract state that contract clauses need to reference should be declared with the `variable` clause instead.

In addition, if the body of a function called from a contract expression contains an `@ghost` block, that ghost block is skipped while the macro expansion evaluates the contract (the evaluation-state flag is set), so the function may read abstract state that differs from the real one, which can in turn misjudge later invariants. Avoid maintaining state that contracts depend on with `@ghost` inside functions that contract expressions call.

### Concurrency and Suspension Restrictions

The enter/exit pairing of a contract evaluation (`contractEvalEnter`/`contractEvalExit`) relies on a thread-local evaluation-depth flag, and its correctness assumes that entry and exit happen on the same thread. Contract expressions must therefore not call functions that may suspend the current execution and trigger a thread migration (e.g. bounded-concurrency or blocking-wait operations); if a contract evaluation migrates to another thread across a suspension point, the depth flag may leak on the original thread (silently skipping subsequent contract checks there), while the exit on the destination thread is quietly ignored. Write contracts over purely synchronous, non-suspending expressions.

### Reserved Identifier Prefixes

Macro expansion generates helper identifiers prefixed with `_contract_` and `_abs_` (such as local bindings `_contract_r` and `_contract_pre_0`, and member helpers `_contract_aux_*` and `_contract_body`). Inside a declaration annotated with @Contract, type members, function names, parameters, or top-level function-body locals named with these two prefixes conflict with the generated code, and the macro expansion reports ERROR-level compile diagnostics (the reserved member-name check only covers the names actually occupied by generated code). Do not use these two prefixes for user code.

### Cross-Package Contract Inheritance

Parent contracts within the same package (compilation unit) are resolved directly from in-memory metadata. Cross-package contract inheritance relies on two environment variables to pass the parent type's contract metadata (`.cmeta` records) during the build:

- `CANGJIE_STDX_CONTRACT_PKG_NAME`: the fully qualified package name of the package being compiled. When set, the `.cmeta` records produced by macro expansion, the clause origin identifiers (`ClauseOrigin`), and the invariant checking method names all use package-qualified names, preventing same-named types from different packages from overwriting or colliding with each other;
- `CANGJIE_STDX_CONTRACT_META_DIR`: the directory for reading and writing `.cmeta` records; supports multiple `:`-separated directories (the first is the write target, the rest are read-only search locations). A single-letter entry is treated as a Windows drive prefix and rejoined with the next segment (e.g. `C:\cmeta`), so Windows absolute paths can participate in the separation. When a parent library is built, it writes its records to this directory; when a consumer package is compiled, pointing the same variable to this directory makes the parent contracts discoverable. If unset, `target/contract_meta` under the current directory is used by default as the write target, and the `target/contract_meta` directories of the path dependencies declared in the module's `cjpm.toml` are appended as read-only search locations (the module root is located by walking up from the working directory for `cjpm.toml`). Therefore, projects organized with cjpm path dependencies complete cross-package contract inheritance without setting this variable; git dependencies and builds that do not go through cjpm still need it set explicitly as described below.

Typical workflow: build the parent library with `CANGJIE_STDX_CONTRACT_PKG_NAME=<parent package name>` and `CANGJIE_STDX_CONTRACT_META_DIR=<record directory>`, then compile the consumer package with `CANGJIE_STDX_CONTRACT_META_DIR=<the same record directory>`. Packages built together with stdx have these two variables injected automatically by the build system; applications using cjpm whose parent libraries are path dependencies may omit `CANGJIE_STDX_CONTRACT_META_DIR` only (see above), but **`CANGJIE_STDX_CONTRACT_PKG_NAME` still needs to be set manually**: cjpm builds do not inject it, and without it records fall back to the simple-name identity, so same-named `@Contract` types declared by two different packages share one record (collisions only produce a WARNING, and inheritance may resolve to the wrong declaration, see below). Other scenarios (such as git dependencies or compiling directly with cjc) require setting both variables in the build command environment themselves.

If two packages without `CANGJIE_STDX_CONTRACT_PKG_NAME` set declare `@Contract` types with the same name, the later writer replaces the earlier one in the registry, and the compiler emits a `conflicting contract metadata` warning; in that case, set the package names as described above and rebuild.

Automatic inheritance of class-level `variable` clauses (no `inherits from` clause required) requires the parent type's contract metadata to be discoverable: within one package the parent must be expanded before the current type, and across packages it relies on the record directories above. When the metadata is not discoverable, this path silently skips the inheritance; if you rely on it, also write an explicit `inherits from <parent>` clause, which reports an error directly when the metadata is missing. A metadata **write** failure never breaks compilation but reports a one-time WARNING per process, noting that cross-package inheritance is unavailable for that build (typically a misconfigured `CANGJIE_STDX_CONTRACT_META_DIR` or an unwritable directory).

Byte-identical `.cmeta` records found in several searched directories count as one logical record: cjpm builds every dependency package with the top-level module as the working directory, so a dependency's records are aggregated into the top-level `target/contract_meta` and naturally duplicate the copy in the dependency's own directory. Only genuinely divergent same-name records trigger the `ambiguous contract metadata` warning and skip inheritance; in that case, reference the type with its package-qualified name or delete the stale record and rebuild.

Inheritance expansion has no depth or count limit: all contract clauses of a parent type (including those it inherited from its ancestors) are regenerated inside the consumer package. Keep inheritance chains within 5-8 levels, the number of `invariant` clauses per type to single digits, and avoid re-declaring the same clause in multiple branches of a diamond-shaped hierarchy; deeper combinations linearly inflate the generated code size and macro expansion time.

Inherited member contracts are adapted to the subclass positionally (**member functions only**): after an override renames a parameter, parent parameter names in replayed function clauses are replaced with the subclass counterparts by position (unequal parameter counts keep the original text; such an override must then keep the parent's parameter names to compile). When a replayed function `requires`/`ensures` condition references a parent's `private` member, it is rewritten into a call to a public condition checker generated during the parent's expansion (prefixed `_contract_member_cond_`, named after the declaring type and the clause ordinal) and evaluated in the parent's scope. **Property (`prop`/getter/setter) contract inheritance is not covered by these mechanisms**: property clauses keep their textual replay — no parameter alpha-renaming and no condition checker — so a property contract that references a parent's `private` member, or a parent setter parameter name that differs from the subclass override's parameter name, fails to compile in the subclass scope; prefer public members or re-declare the property contract explicitly in the subclass. Likewise, conditions carrying `$pre(...)` snapshot references, referencing function-level `variable` slots, or declared on interface default members cannot be hosted by a checker and keep their textual replay — such conditions must not reference parent members invisible to the subclass scope.

**Trust boundary**: `.cmeta` records in the `CANGJIE_STDX_CONTRACT_META_DIR` directory are re-parsed during macro expansion and take part in code generation; their trust level is equivalent to that of source code. Only let trusted build processes write to this directory, and do not point it to shared writable locations or blindly trust records from unknown origins. Every record carries a content fingerprint: when a record is corrupted or mixed with one from another build, the consumer's compilation prints a single WARNING line to stderr (the record is still used and compilation is not interrupted); when the parent library's sources are not part of the current compilation, a record left stale by a modified parent type cannot be detected — in that case, delete the record and rebuild the parent library.

### Contract Failure

When a contract check fails, the corresponding contract exception is thrown. The messages of `requires`/`ensures`/`throws` failures contain the name of the function whose contract failed and the original contract clause; an `invariant` message contains the type name and the clause, while the messages of `@contractAssert` and `@loopInvariant` contain only the corresponding assertion or invariant expression. Non-contract exceptions (business exceptions) thrown during contract expression evaluation are not wrapped and propagate to the caller with their original types. Contract exceptions are all located in the [stdx.contract.runtime](./runtime/contract_runtime_package_api/contract_runtime_package_exceptions.md) subpackage, and [isContractException](./runtime/contract_runtime_package_api/contract_runtime_package_funcs.md#func-iscontractexception) can be used to determine whether an exception is a contract exception.

### Example

The following example declares a precondition, a postcondition, and an exception contract for the withdrawal method of a bank account:

<!-- verify -->
```cangjie
import stdx.contract.macros.*

class BankAccount {
    private var balance: Float64

    init(balance: Float64) {
        this.balance = balance
    }

    @Contract[
        requires amount > 0.0
        requires amount <= this.balance
        ensures this.balance == $pre(this.balance) - amount
        throws IllegalArgumentException if amount <= 0.0
    ]
    public func withdraw(amount: Float64): Unit {
        if (amount <= 0.0) {
            throw IllegalArgumentException("amount must be positive")
        }
        this.balance -= amount
    }

    public func getBalance(): Float64 {
        this.balance
    }
}

main() {
    let account = BankAccount(100.0)
    account.withdraw(30.0)
    println(account.getBalance())
    try {
        account.withdraw(200.0)
    } catch (e: ContractCheckRequiresException) {
        println(e.message)
    }
}
```

Execution result:

```text
70.000000
requires failed in withdraw: requires amount <= this.balance
```

> **Note:**
>
> The output above assumes that contract checking is enabled at compile time (enabled by default). After rebuilding `stdx.contract.runtime` with `--cfg "contract_check=off"` to disable checking, contract clauses are not evaluated and the example does not throw an exception.

## API List

### Macros

| Macro Name | Functionality |
| --- | --- |
| [@Contract](./contract_package_api/contract_package_macros.md#contract-attribute-macro) | Declares contracts for functions, properties, or types. |
| [@ghost](./contract_package_api/contract_package_macros.md#ghost-macro) | Declares ghost code that executes only to maintain abstract state. |
| [@contractAssert](./contract_package_api/contract_package_macros.md#contractassert-macro) | Declares assertions in a function body. |
| [@loopInvariant](./contract_package_api/contract_package_macros.md#loopinvariant-attribute-macro) | Declares a loop invariant for a loop. |

> For the contract checking switch, contract exception classes, and runtime helper functions, see [stdx.contract.runtime](./runtime/contract_runtime_package_overview.md).
