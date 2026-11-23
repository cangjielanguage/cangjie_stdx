# Enums

## enum ContractVisibility

```cangjie
public enum ContractVisibility {
    | Private
    | Internal
    | Protected
    | Public
}
```

Function: The member visibility ordering used by contract checking, from lowest to highest: `Private`, `Internal`, `Protected`, `Public`.

### Private

```cangjie
Private
```

Function: Constructs an enum instance representing `private` visibility.

### Internal

```cangjie
Internal
```

Function: Constructs an enum instance representing `internal` visibility.

### Protected

```cangjie
Protected
```

Function: Constructs an enum instance representing `protected` visibility.

### Public

```cangjie
Public
```

Function: Constructs an enum instance representing `public` visibility.

### func isAtLeast(ContractVisibility)

```cangjie
public func isAtLeast(minimum: ContractVisibility): Bool
```

Function: Determines whether the current visibility is at least the specified visibility. The visibility ordering is `Private <= Internal <= Protected <= Public`.

Parameters:

- minimum: ContractVisibility - The visibility used as the lower bound.

Return Value:

- Bool - Returns `true` when the current visibility is at least `minimum`; otherwise returns `false`.
