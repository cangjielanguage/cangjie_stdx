# 类

## class ActorFuture

```cangjie
public class ActorFuture<T> {}
```

功能：提交给一个 Actor 的闭包的待定结果。


### func get()

```cangjie
public func get(): T
```

功能：阻塞当前线程，直到闭包完成。如果闭包抛出异常或错误，此方法将抛出相同的异常或错误。


返回值：

- T - 对应的闭包的计算结果。

### func get(Duration)

```cangjie
public func get(timeout: Duration): Option<T>
```

功能：阻塞当前线程，直到指定的时间段结束或结果准备好。如果结果已经准备好，它将返回结果，否则它将返回 None。如果结果是异常或错误，此方法将抛出相同的异常或错误。如果指定的超时时间为零，则表示没有时间限制。

参数：

- timeout: Duration - 它应该等待的最大时间。

返回值：

- Option\<T> - 如果结果在指定超时时间内未准备好，则返回 None，否则返回结果值。

### func tryGet()

```cangjie
public func tryGet(): Option<T>
```

功能：如果结果已经准备好，则立即返回结果；否则返回 None。如果结果是异常或错误，此方法将抛出相同的异常或错误。

返回值：

- Option\<T> - 如果结果尚未准备好，则返回 None，否则返回结果值。


## class SequentialDispatcher

```cangjie
public class SequentialDispatcher {
  public init(enableReceiverPriorty!: Bool)
}
```

功能：一个 SequentialDispatcher 实例代表了一个仓颉的线程，用户可以向一个 SequentialDispatcher 实例提交闭包，这些闭包会在一个仓颉线程上排队执行。

通常用户不需要直接使用这个类，而是应该使用 [@Actor](../macros/macros_package_api/macros_package_macros.md#actor-macro) 宏。

### init(Bool)

```cangjie
public init(enableReceiverPriorty!: Bool)
```

功能：创建一个 SequentialDispatcher 实例并启动 SequentialDispatcher 的线程来处理用户提交的闭包。


参数：

- enableReceiverPriorty!: Bool - 设置为 true 时提供提供优先值功能，让优先值高的闭包优先执行。

### func post\<T>(() -> T, Int64)

```cangjie
public func post<T>(task: () -> T, priority!: Int64 = 5): ActorFuture<T>
```

功能：将一个闭包提交给 dispatcher，该闭包将在 dispatcher 线程上排队并执行。此方法返回一个 [ActorFuture\<T>](actors_package_classes.md#class-actorfuture)，表示闭包的待定结果。如果这个 dispatcher 在构建时如果设置 enableReceiverPriorty 为 true，优先值高的闭包会优先执行；如果设置 enableReceiverPriorty 为 false 时，priority 值将不起作用。

参数：

- task: () -> T - 提交到 actor 的闭包。
- priority!: Int64 - 提交任务的优先级，1 <= priority <= 10，默认为 5。


返回值：

- [ActorFuture\<T>](actors_package_classes.md#class-actorfuture) - 该对象可用于获取闭包的计算结果。

异常：

- IllegalArgumentException - 如果优先级参数 priority 小于 1 或大于 10，则会抛出此异常。
