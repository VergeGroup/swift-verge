# Verge - Store (SwiftUI / UIKit) (Planning v6.0.0)

Classic Version is here => [Verge Classic](./Sources/VergeClassic)

<img src="loop@2x.png" width=646/>

## Gallary

- [APNsClient](https://github.com/muukii/APNsClient) : A desktop application to send a apns push with HTTP/2 based API.

## Installation VergeStore

Currently it supports only CocoaPods.

In Podfile

```
pod 'VergeStore/Core'
```

## Concept

The concept of VergeStore is inspired by [Redux](https://redux.js.org/) and [Vuex](https://vuex.vuejs.org/).

The characteristics are

- Creating one or more Dispatcher. (Single store, multiple dispatcher)
- A dispatcher can have dependencies service needs. (e.g. API Client, DB)
- No switch-case to reduce state
- Support Logging (Commit, Action, Performance monitoring)

### 🪐 Store

- Store holds application state.
- Allows access to `Store.state`
- Allows state to be updated via `Dispatcher.commit()`

```swift
struct State {

  struct Todo {
    var title: String
    var hasCompleted: Bool
  }

  var todos: [Todo] = []

}

class MyStore: VergeDefaultStore<State> {

  init() {
    super.init(initialState: .init(), logger: nil)
  }
}

let store = MyStore()
```

### 🚀 Dispatcher

Mainly, Dispatcher allows Store.state to be updated.

To change state, use **Mutation** via `commit()`.<br>
To run asynchronous operation, use **Action** via `dispatch()`.

```swift
class MyDispatcher: Dispatcher<RootState> {

}

let store = MyStore()
let dispatcher = MyDispatcher(target: store)
```

`MyStore` provies typealias to `Dispatcher<RootState>` as `MyStore.DispatcherType`.

### ☄️ Mutation

The only way to actually change state in a Verge store is by committing a mutation.
Define a function that returns Mutation object. That expresses that function is Mutation

Mutation object is simple struct that has a closure what passes current state to change it.

> Mutation does not run asynchronous operation.

```swift
class MyDispatcher: Dispatcher<RootState> {
}

extension Mutations where Base == MyDispatcher {
  func addNewTodo(title: String) {
    descriptor.commit { (state: inout RootState) in
      state.todos.append(Todo(title: title, hasCompleted: false))
    }
  }
}

let store = MyStore()
let dispatcher = MyDispatcher(target: store)

dispatcher.commit.addNewTodo(title: "Create SwiftUI App")

print(store.state.todos)
// store.state.todos => [Todo(title: "Create SwiftUI App", hasCompleted: false)]
```

### 🌟 Action

Action is similar to Mutation.
Action can contain arbitrary asynchronous operations.

To run Action, use `dispatch()`.

To commit Mutations inside Action, Use context.commit.

```swift
class MyDispatcher: Dispatcher<RootState> {
}

extension Actions where Base == MyDispatcher {

  @discardableResult
  func fetchRemoteTodos() -> Future<Void> {
    descriptor.dispatch { context in

      return Future<[Todo], Never> { ... }
        .sink { todos in

          context.commit { state in
            state.todos = todos
          }

       }
       ...
    }
  }

}

let store = MyStore()
let dispatcher = MyDispatcher(target: store)

dispatcher.dispatch.fetchRemoteTodos()

// After Future completed

print(store.state.todos)
// [...]
```

Actions are often asynchronous, So we may need to know the timing action completed inside the view.<br>
`dispatch()` allows returning anything. For example, we can return Future object to caller.<br>
It can allow composite actions.

## Advanced

### StateType protocol

VergeStore provides `StateType` protocol as a helper.

It will be used in State struct that Store uses.<br>
`StateType` protocol is just providing the extensions to mutate easily in the nested state.

Just like this.

```swift
public protocol StateType {
}

extension StateType {

  public mutating func update<T>(target keyPath: WritableKeyPath<Self, T>, update: (inout T.Wrapped) throws -> Void) rethrows where T : VergeStore._VergeStore_OptionalProtocol

  public mutating func update<T>(target keyPath: WritableKeyPath<Self, T>, update: (inout T) throws -> Void) rethrows

  public mutating func update(update: (inout Self) throws -> Void) rethrows
}
```

### Mutating on nested state with StateType

Basically, the application state should be flattened as possible. (Avoid nesting) <br>
However, sometimes we can't avoid this. And then it may be hard to update the nested state. <br>
If it's an optional state, we have to check non-nil every time when mutating or dispatching. <br>

So, VergeStore provides the following method to make it easier.

```swift
Dispatcher.commit(\.target)
```

### ScopedDispatching with StateType

To handle nested states efficiently.

VergeStore provides the `ScopedDispatching` protocol to expand Dispatcher's function.

```swift
public protocol ScopedDispatching: Dispatching {
  associatedtype Scoped

  var selector: WritableKeyPath<State, Scoped> { get }
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
final class OptionalNestedDispatcher: Store.DispatcherType, ScopedDispatching {

  var selector: WritableKeyPath<State, State.NestedState?> {
    \.optionalNested
  }

}

extension Mutations where Base == OptionalNestedDispatcher {

  func setMyName() {
    descriptor.commitIfPresent {
      $0.myName = "Hello"
    }
  }

}
```

`ScopedDispatching` works with a slice of the state.

`ScopedDispatching.Scoped` points where is a slice on the state.

`ScopedDispatching` requires `selector` to get a slice of the state.

If `Scoped` is optional type, can use `commitScopedIfPresent()`.<br>
It runs only when the selected slice is existing.

If it's not, can use `commitScoped()`

### Logging

With creating a object that using `VergeStoreLogger`, we can get the log that VergeStore emits.

As a default implementation, we can use `DefaultLogger.shared`.

```swift
public protocol VergeStoreLogger {

  func willCommit(store: AnyObject, state: Any, mutation: MutationMetadata, context: AnyObject?)
  func didCommit(store: AnyObject, state: Any, mutation: MutationMetadata, context: AnyObject?, time: CFTimeInterval)
  func didDispatch(store: AnyObject, state: Any, action: ActionMetadata, context: AnyObject?)

  func didCreateDispatcher(store: AnyObject, dispatcher: Any)
  func didDestroyDispatcher(store: AnyObject, dispatcher: Any)
}
```

## Rx Extensions

VergeStore provides RxSwift extensions.<br>
It may help using VergeStore in UIKit based application.

We can add this with following pod'

### Installation VergeStore/Rx

```ruby
pod 'VergeStore/Rx'
```

## VergeViewModel module

We have a sub-framework VergeViewModel.<br>
This helps UIKit based application.

VergeStore is a state container and that state will be bigger according to the application scale.<br>
You would need something that map to view-state.

In SwiftUI, `SwiftUI.View` is that. But UIKit is not.

It may be a better way to get ViewModel or something.

### Installation VergeStore/VM

```ruby
pod 'VergeStore/VM'
```

## References

## Normalized State Shape

[https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape](https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape)

## Author

Hiroshi Kimura (Muukii) <muukii.app@gmail.com>
