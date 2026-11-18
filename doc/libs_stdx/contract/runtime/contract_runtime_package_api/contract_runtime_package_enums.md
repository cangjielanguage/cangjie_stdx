# 枚举

## enum ContractVisibility

```cangjie
public enum ContractVisibility {
    | Private
    | Internal
    | Protected
    | Public
}
```

功能：契约检查使用的成员可见性顺序，由低到高依次为 `Private`、`Internal`、`Protected`、`Public`。

### Private

```cangjie
Private
```

功能：构造一个表示 `private` 可见性的枚举实例。

### Internal

```cangjie
Internal
```

功能：构造一个表示 `internal` 可见性的枚举实例。

### Protected

```cangjie
Protected
```

功能：构造一个表示 `protected` 可见性的枚举实例。

### Public

```cangjie
Public
```

功能：构造一个表示 `public` 可见性的枚举实例。

### func isAtLeast(ContractVisibility)

```cangjie
public func isAtLeast(minimum: ContractVisibility): Bool
```

功能：判断当前可见性是否不低于指定可见性。可见性顺序为 `Private <= Internal <= Protected <= Public`。

参数：

- minimum: ContractVisibility - 作为下限的可见性。

返回值：

- Bool - 当前可见性不低于 `minimum` 时返回 `true`，否则返回 `false`。
