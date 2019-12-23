# Changelog

## Master

### Remove ScopedDispatching protocol

Instead, use other Mutation factory method

```swift
extension AnyMutation where Dispatcher.State : VergeStore.StateType {

    public static func mutation<Target>(_ target: WritableKeyPath<Dispatcher.State, Target>, _ name: StaticString = "", _ file: StaticString = #file, _ function: StaticString = #function, _ line: UInt = #line, inlineMutation: @escaping (inout Target) -> Result) -> VergeStore.AnyMutation<Dispatcher, Result>
}
```

