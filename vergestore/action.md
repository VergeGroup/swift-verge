# Action

Action appears similar to Mutation. But actually it's not.  
Action can contain arbitrary asynchronous operations and it can commit Mutation inside asynchronous operations.

Action object's looks

```swift
public struct AnyAction<Dispatcher, Result>: ActionType where Dispatcher : VergeStore.DispatcherType {

  public let metadata: ActionMetadata
  
  public init(_ name: StaticString = "", _ action: @escaping (VergeStoreDispatcherContext<Dispatcher>) -> Return)
}
```

Firstly, let's take a look creating Action.

```swift
class MyDispatcher: MyStore.Dispatcher {

  func someAsyncOperation() -> Action<Void> {
    .action { context in
      // Do something async operation.
    }
  }

}
```

To run\(dispatch\) Action

```swift
let store = MyStore()
let dispatcher = MyDispatcher(target: store)

dispatcher.accept { $0.someAsyncOperation() }
```

To commit Mutation, do it from context.

```swift
class MyDispatcher: MyStore.Dispatcher {

  func someMutation() -> Mutation<Void> {
    ...
  }
  
  func someAsyncOperation() -> Action<Void> {
    .action { context in
      context.accept { $0.someMutation() }
    }
  }

}
```

Since Action can contain asynchronous operation, we can do following.

```swift
class MyDispatcher: MyStore.Dispatcher {

  func someMutation() -> Mutation<Void> {
    ...
  }
  
  func someAsyncOperation() -> Action<Void> {
    .action { context in
      DispatchQueue.global().async {
        context.accept { $0.someMutation() }
      }
    }
  }

}
```



You may already notice that, Action can return anything you need outside.  
This feature is super inspired by **Vuex**

Just like this,

```swift
class MyDispatcher: MyStore.Dispatcher {

  var subscriptions = Set<AnyCancellable>()

  func fetchRemoteTodos() -> Action<Future<Void>> {
    .dispatch { context in
    
      let future = Future<[Todo], Never> { ... }
        .sink { todos in
    
          context.commit { state in
            state.todos = todos
          }
    
       }
       .store(in: &self.subscriptions)
       
       return future
    }
  }
}
```

Actions are often asynchronous, So we may need to know the timing action completed inside the view.

```swift
dispatcher.accept { $0.someAsyncOperation() }
  .sink { 
    // completed action
  }
```

