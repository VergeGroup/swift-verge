# Store

* Store holds application state.
* Allows access to `Store.state`
* Allows state to be updated via `Dispatcher.commit()`

```swift
struct State {

  struct Todo {
    var title: String
    var hasCompleted: Bool
  }

  var todos: [Todo] = []

}

final class MyStore: StoreBase<State> {

  init() {
    super.init(initialState: .init(), logger: nil)
  }
}

let store = MyStore()
```

