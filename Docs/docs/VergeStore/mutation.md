---
id: mutation
title: Mutation - updates the state of the store
sidebar_label: Mutation
---

## What Mutation is

The only way to actually change state in a Store is by committing a mutation.
Define a function that returns Mutation object.
That expresses that function is Mutation

:::caution
Mutation does **NOT** allow to run asynchronous operation.
:::

## To define mutations in the Store

```swift
struct MyState {
  var todos: [TODO] = []
}

class MyStore: Store<MyState, Never> {

  func addNewTodo(title: String) {
    commit { (state: inout MyState) in
      state.todos.append(Todo(title: title, hasCompleted: false))
    }
  }

}
```

## To run Mutation

```swift
let store = MyStore()
store.addNewTodo(title: "Create SwiftUI App")

print(store.state.todos)
// store.state.todos => [Todo(title: "Create SwiftUI App", hasCompleted: false)]
```
