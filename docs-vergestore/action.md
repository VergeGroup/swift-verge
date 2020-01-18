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
    dispatch { context -> Void in
    
      // Call other mutation
      context.redirect { $0.someMutation() }
      
      // or inline mutation
      context.commit { state in
        // state.xxx = ...      
      }

    }
  }

}
```

### Run action

To run\(dispatch\) Action

```swift
let store = MyStore()
let dispatcher = MyDispatcher(target: store)

dispatcher.someAsyncOperation()
```

## Return value to caller

You may already notice that, Action can return anything you need outside.  
This feature is super inspired by **Vuex**

Just like this,

```swift
class MyDispatcher: MyStore.Dispatcher {

  var subscriptions = Set<AnyCancellable>()

  func fetchRemoteTodos() -> Future<Void> {
    dispatch { context in

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
dispatcher.someAsyncOperation()
  .sink { 
    // completed action
  }
```

