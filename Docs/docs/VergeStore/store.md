---
id: store
title: Store - a storage of the state
sidebar_label: Store
---

- Store is
  - A reference type object
  - Manages the state object that contains the application state
  - Receives **Mutation** to update the state with thread-safety
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
