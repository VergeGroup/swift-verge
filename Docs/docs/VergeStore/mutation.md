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

### Define mutations in the Store

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

### Run Mutation

```swift
let store = MyStore()
store.addNewTodo(title: "Create SwiftUI App")

print(store.state.todos)
// store.state.todos => [Todo(title: "Create SwiftUI App", hasCompleted: false)]
```

## Perform batch commits

In a case that commits multiple mutations that can't be integrated, it will dispatch multiple updated events to each subscriber.  
It means the application performance might be decreased.

Like the following operation:

```swift
class MyStore: Store<MyState, Never> {

  func myMutation() {
    if ... {
      commit {
        ...
      }
      // emits updated event
    }

    if ... {
      commit {
        ...
      }
      // emits updated event
    }

    if ... {
      commit {
        ...
      }
      // emits updated event
    }
  }

}
```

We can brush up with batching mutation feature.  
`batchCommit` method groups multiple mutations then it applies at once.  
If `batchCommit` has no operations, it happens nothing.

```swift
class MyStore: Store<MyState, Never> {

  func myMutation() {
    batchCommit { context in

      if ... {
        commit {
          ...
        }
      }

      if ... {
        commit {
          ...
        }
      }

      if ... {
        commit {
          ...
        }
      }

    }
  }
}
```
