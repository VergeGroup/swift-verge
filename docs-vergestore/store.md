# 🌑 Store - Manages State

## **Store** is ...

* a reference type object 
* manages the state object that contains the application state
* commits **Mutation** to update the state
* dispatches **Action** to run arbitrary async operation 

### Define Store

```swift
struct State: StateType {
  var count: Int = 0
}

enum Activity {
  case happen
}

final class MyStore: StoreBase<State, Activity> {
  
  init() {
    super.init(
      initialState: .init(),
      logger: DefaultStoreLogger.shared
    )
  }
    
}
```

### Add Mutation

```swift
final class MyStore: StoreBase<State, Activity> {

  func increment() -> Mutation<Void> {
    return .mutation {
      $0.count += 0
    }
  }
  
}
```

### Commit mutation

```swift
let store = MyStore()

store.commit { $0.increment() }
```

### Add Action

```swift
final class MyStore: StoreBase<State, Activity> {
  
  func delayedIncrement() -> Action<Void> {
    return .action { context in
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        context.commit { $0.increment() }
        
        context.send(.happen)
      }
    }
  }
  
}
```

### Dispatch Action

```swift
let store = MyStore()

store.dispatch { $0.delayedIncrement() }
```

## Scaling up

Becoming large application, Store would have more mutations and actions.  
It's might be hard to manage these.  
  
Therefore, Verge provides **Dispatcher**

![Updating the state from multiple dispatcher](../.gitbook/assets/image%20%281%29.png)

{% page-ref page="dispatcher.md" %}

