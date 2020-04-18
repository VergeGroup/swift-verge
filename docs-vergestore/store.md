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

  func increment() {
    commit {
      $0.count += 0
    }
  }
  
}
```

### Commit mutation

```swift
let store = MyStore()

store.increment()
```

{% page-ref page="mutation.md" %}

### 

### Add Action

```swift
final class MyStore: StoreBase<State, Activity> {
  
  func delayedIncrement() {
    dispatch { context in
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

store.delayedIncrement()
```

{% page-ref page="action.md" %}



## Scaling up

Becoming large application, Store would have more mutations and actions.  
It's might be hard to manage these.  
  
Therefore, Verge provides **Dispatcher**

![Updating the state from multiple dispatcher](../.gitbook/assets/image%20%282%29.png)

{% page-ref page="dispatcher.md" %}

