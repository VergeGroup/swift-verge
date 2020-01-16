# 🌟 Action - Grouping mutation with async operations

## What Action is

Action appears similar to Mutation. But actually it's not.

If the app can be created with synchronous operations only, that would be so easy, but it's not really.   
All of the application needs to run async operations. For example, networking, an operation that takes a long time, etc. We have more such async operations than we can see only.

Async operations make it harder to estimate results, and then make debugging harder as well. **Actually it means it increases the number of states we have to handle.**

To handle this as possible, we can separate async and sync as a first step.

As we've touched previously section, **Mutation means sync operation**.   
And about the async operation, **Action** means it.

{% hint style="success" %}
Action does not mutate state directly. 

Action does commit mutation asynchronously or synchronously with other operations.
{% endhint %}

## Sample 

### declaration

```swift
class MyDispatcher: MyStore.Dispatcher {

  func someAsyncOperation() -> Action<Void> {
    return .action { context -> Void in
      // Do something async operation.
      context.commit { $0.someMutation() }
      
      context.commit { $0.someMutation() }
    }
  }

}
```

### Run action

To run\(dispatch\) Action

```swift
let store = MyStore()
let dispatcher = MyDispatcher(target: store)

dispatcher.dispatch { $0.someAsyncOperation() }
```

## Detail

### AnyAction object

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

### Commit mutation inside of action

To commit Mutation, do it from context.

```swift
class MyDispatcher: MyStore.Dispatcher {

  func someMutation() -> Mutation<Void> {
    ...
  }

  func someAsyncOperation() -> Action<Void> {
    .action { context in
      context.commit { $0.someMutation() }
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
        context.commit { $0.someMutation() }
      }
    }
  }

}
```

### Create and Commit mutation inside of action

The context supports to commit mutation that created in inline.  
We can commit trivial mutations without to declare mutation.

```swift
func someAsyncOperation() -> Action<Void> {
  .action { context in
    context.commitInline { state in
      ...    
    }
  }
}
```

### Return value to caller

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

