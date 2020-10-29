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
    commit { (state: inout InoutRef<MyState>) in
      state.todos.append(Todo(title: title, hasCompleted: false))
    }
  }

}
```

:::tip
If the commit has no modifications, Store skips the mutation.
:::

### Run Mutation

```swift
let store = MyStore()
store.addNewTodo(title: "Create SwiftUI App")

print(store.state.todos)
// store.state.todos => [Todo(title: "Create SwiftUI App", hasCompleted: false)]
```

## Batches multiple commtis

Committing multiple mutations in a short time might decrease performance.  
Because the subscribers around the store derive a state many times.

Like this,

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

To keep better performance, we need to keep using fewer commits in a short time.

We have 2 ways.

### Using `commit`

`commit` provides `InoutRef<State>`, that can detect how the wrapped state will change.  
If there is no change, `commit` does nothing and no emitting the events from the Store.

However, you should attention `commit` is atomically operation which means, the Store getting lock while committing.

```swift
func myMutation() {
  commit { (state: inout InoutRef<State>) in
    if ... {
      state.aaa = ...
    }

    if ... {
      state.bbb = ...
    }

    if ... {
      state.ccc = ...
    }
  }
}
```

### Using `batchCommit`

We can brush up with batching mutation feature.  
`batchCommit` method groups multiple mutations then it applies at once.  
If `batchCommit` has no operations, it happens nothing.

`batchCommit` does not get a lock. it's possible the state might be changed while performing `batchCommit`.

```swift
class MyStore: Store<MyState, Never> {

  func myMutation() {
    batchCommit { context in

      if ... {
        context.commit {
          ...
        }
      }

      if ... {
        context.commit {
          ...
        }
      }

      if ... {
        context.commit {
          ...
        }
      }

    }
    // The mutations perform.
  }
}
```
