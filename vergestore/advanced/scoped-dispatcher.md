# Scoped Dispatcher

#### Mutating on nested state with StateType

Basically, the application state should be flattened as possible. \(Avoid nesting\)   
 However, sometimes we can't avoid this. And then it may be hard to update the nested state.   
 If it's an optional state, we have to check non-nil every time when mutating or dispatching.   


So, VergeStore provides the following method to make it easier.

```swift
Dispatcher.commit(\.target)
```

#### ScopedDispatching with StateType

To handle nested states efficiently.

VergeStore provides the `ScopedDispatching` protocol to expand Dispatcher's function.

```swift
public protocol ScopedDispatching: Dispatching {
  associatedtype Scoped

  var scopedStateKeyPath: WritableKeyPath<State, Scoped> { get }
}
```

Explanation with following state example.

```swift
struct State: StateType {

  struct NestedState {

    var myName: String = ""
  }

  var optionalNested: NestedState?
  var nested: NestedState = .init()
}
```

Create Dispatcher that has `ScopedDispatching`

```swift
final class OptionalNestedDispatcher: DispatcherBase<State>, ScopedDispatching {

  static var scopedStateKeyPath: WritableKeyPath<State, State.NestedState?> {
    \.optionalNested
  }

  func setMyName() -> Mutation {
    .commitIfPresent {
      $0.myName = "Hello"
    }
  }

}
```

`ScopedDispatching` works with a slice of the state.

`ScopedDispatching.Scoped` points where is a slice on the state.

`ScopedDispatching` requires `selector` to get a slice of the state.

If `Scoped` is optional type, can use `commitScopedIfPresent()`.  
 It runs only when the selected slice is existing.

If it's not, can use `commitScoped()`

