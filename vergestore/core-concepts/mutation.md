# Mutation

The only way to actually change state in a Verge store is by committing a mutation. Define a function that returns Mutation object. That expresses that function is Mutation

Mutation object is simple struct that has a closure what passes current state to change it.

{% hint style="success" %}
Mutation does not run asynchronous operation.
{% endhint %}

```swift
class MyDispatcher: DispatcherBase<RootState> {
  func addNewTodo(title: String) -> Mutation {
    .commit { (state: inout RootState) in
      state.todos.append(Todo(title: title, hasCompleted: false))
    }
  }
}

let store = MyStore()
let dispatcher = MyDispatcher(target: store)

dispatcher.accept { $0.addNewTodo(title: "Create SwiftUI App") }

print(store.state.todos)
// store.state.todos => [Todo(title: "Create SwiftUI App", hasCompleted: false)]
```

