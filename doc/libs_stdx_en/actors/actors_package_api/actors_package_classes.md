# Classes

## class ActorFuture

```cangjie
public class ActorFuture<T> {}
```

Function: Represents the pending result of a closure submitted to an Actor.


### func get()

```cangjie
public func get(): T
```

Function: Blocks the current thread until the closure completes. If the closure throws an exception or error, this method will throw the same exception or error.


Return Value:

- T - The computed result of the corresponding closure.

### func get(Duration)

```cangjie
public func get(timeout: Duration): Option<T>
```

Function: Blocks the current thread until either the specified timeout has expired or the result is ready. If the result is already prepared, it will return the result; otherwise, it will return `None`. If an exception or error is thrown, this method will propagate the same exception or error. If the timeout is set to zero, it means there is no time limit.

Parameters:

- timeout: Duration - The maximum time to wait.

Return Value:

- Option\<T> - Returns `None` if the result is not ready within the specified timeout, otherwise returns the result value.

### func tryGet()

```cangjie
public func tryGet(): Option<T>
```

Function: If the result is ready, it immediately returns the result; otherwise, it returns `None`. If the result is an exception or error, this method will throw the same exception or error.

Return Value:

- Option\<T> - If the result is not yet ready, it returns `None`; otherwise, it returns the result value.


## class SequentialDispatcher

```cangjie
public class SequentialDispatcher {
  public init(enableReceiverPriorty!: Bool)
}
```

Function: A `SequentialDispatcher` instance represents a thread in the Cangjie system. Users can submit closures to a `SequentialDispatcher` instance, and these closures will be queued and executed on that thread.

Typically, users do not need to use this class directly. Instead, they should use the [@Actor](../macros/macros_package_api/macros_package_macros.md#actor-macro) macro.

### init(Bool)

```cangjie
public init(enableReceiverPriorty!: Bool)
```

Function: Creates a `SequentialDispatcher` instance and starts a thread for the `SequentialDispatcher` to handle the closures submitted by the user.


Parameters:

- enableReceiverPriorty!: Bool - When set to `true`, it enables the priority feature, allowing closures with higher priority to be executed first.

### func post\<T>(() -> T, Int64)

```cangjie
public func post<T>(task: () -> T, priority!: Int64 = 5): ActorFuture<T>
```

Function: Submits a closure to the dispatcher, which will be queued and executed on the dispatcher thread. This method returns an [ActorFuture\<T>](actors_package_classes.md#class-actorfuture), representing the pending result of the closure. If the dispatcher was created with `enableReceiverPriority` set to true, closures with higher priority will be executed first. If `enableReceiverPriority` is set to false, the `priority` value will have no effect.

Parameters:

- task: () -> T - The closure submitted to the actor.
- priority!: Int64 - The priority of the submitted task, where 1 <= priority <= 10, with a default value of 5.


Return Value:

- [ActorFuture\<T>](actors_package_classes.md#class-actorfuture) - This object can be used to obtain the computed result of the closure.

Exceptions:

- IllegalArgumentException - This exception will be thrown if the priority parameter is less than 1 or greater than 10.
