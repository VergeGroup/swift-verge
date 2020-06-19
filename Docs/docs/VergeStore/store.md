---
id: store
title: Store - retains a state
sidebar_label: Store
---

**Store**

- a reference type object
- manages the state object that contains the application state
- commits **Mutation** to update the state
- Compatible with SwiftUI's observableObject and `UseState`

## Define a Store

```swift
struct State: StateType {
  var count: Int = 0
}

enum Activity {
  case happen
}

final class MyStore: Store<State, Activity> {

  init() {
    super.init(
      initialState: .init(),
      logger: DefaultStoreLogger.shared
    )
  }

}
```

## Add a Mutation

```swift
final class MyStore: Store<State, Activity> {

  func increment() {
    commit {
      $0.count += 0
    }
  }

}
```

## Commit the mutation

```swift
let store = MyStore()
store.increment()
```
