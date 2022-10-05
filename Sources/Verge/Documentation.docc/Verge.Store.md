# ``Verge/Store``

- Store:
    - Should be a reference type object,
    - To share the state they manage to multiple subscribers.
    - Receives **Mutation** to update the state with thread-safety
    - Compatible with SwiftUI’s observableObject and we can use `StateReader` to read the state partially.

## Ways to creating a store

Verge provides 2 ways to create a store.

1. Declare a class that conforms with `StoreComponentType` - It’s a protocol that indicates the class wraps a store inside and behaves like a store.
2. Subclassing from `Store` - a most basic way, but we need to define State and Activity outside

Now, we recommend using No.1 in order to manage the source code with better portability.

## Declare a class that conforms with `StoreComponentType`

```swift
final class MyStore: StoreComponentType {

  struct State: StateType {
    var count: Int = 0
  }

  /// This means wrapping store inside. (Probably it should be renamed as like `innerStore` or `wrappedStore`)
  /// `DefaultStore` is a typealias that declared by `StoreComponentType`.
  /// You can use any class that inherited from `Store` for your use-cases.
  let store: DefaultStore

  init() {

    self.store = .init(initialState: .init())

  }

}
```

### Add a Mutation

```swift
extension MyStore {

  func increment() {
    commit {
      $0.count += 0
    }
  }

}
```

### Commit the mutation

```swift
let store = MyStore()
store.increment()
```

## Subclassing from `Store`

```swift
struct State: StateType {
  var count: Int = 0
}

enum Activity {
  case happen
}

final class MyStore: Store<State, Never> {

  init() {
    super.init(
      initialState: .init(),
      logger: DefaultStoreLogger.shared
    )
  }

}
```

### Add a Mutation

```swift
extension MyStore {

  func increment() {
    commit {
      $0.count += 0
    }
  }

}
```

### Commit the mutation

```swift
let store = MyStore()
store.increment()
```
