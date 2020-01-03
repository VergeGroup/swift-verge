# Changelog

## Master

### Improve Getter

{% embed url="https://github.com/muukii/Verge/pull/37" %}



### Add AnyGetterType GetterType protocol

{% embed url="https://github.com/muukii/Verge/commit/c864deb23f2fa7d14bda93fa567845d82b28f784" %}



### Rename

{% embed url="https://github.com/muukii/Verge/pull/36" %}



### Add commitInline to context

{% embed url="https://github.com/muukii/Verge/pull/32" %}



## 6.0.0-beta.5

### Rename DispatcherType.dispatchTarget to target

### \[Breaking change\] Getter for ORM

{% embed url="https://github.com/muukii/Verge/pull/30" %}

### Rename HasDatabaseType to DatabaseEmbedding

### Add several ways of creating getter for ORM

## 6.0.0-beta.4

### [Rename accept\(\) to commit\(\) and dispatch\(\)](https://github.com/muukii/Verge/pull/29)

```swift
let dispatcher: MyDispatcher = ...

dispatcher.commit { $0.increment() }

dispatcher.dispatch { $0.asyncIncrement() }
```

### Remove ScopedDispatching protocol

Instead, use other Mutation factory method

```swift
extension AnyMutation where Dispatcher.State : VergeStore.StateType {

    public static func mutation<Target>(_ target: WritableKeyPath<Dispatcher.State, Target>, _ name: StaticString = "", _ file: StaticString = #file, _ function: StaticString = #function, _ line: UInt = #line, inlineMutation: @escaping (inout Target) -> Result) -> VergeStore.AnyMutation<Dispatcher, Result>
}
```

