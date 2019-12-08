# Action

Action is similar to Mutation. Action can contain arbitrary asynchronous operations.

To run Action, use `dispatch()`.

To commit Mutations inside Action, Use context.commit.

```swift
class MyDispatcher: DispatcherBase<RootState> {

  @discardableResult
  func fetchRemoteTodos() -> Action<Future<Void>> {
    .dispatch { context in

      return Future<[Todo], Never> { ... }
        .sink { todos in

          context.commit { state in
            state.todos = todos
          }

       }
       ...
    }
  }

}

let store = MyStore()
let dispatcher = MyDispatcher(target: store)

dispatcher.accept { $0.fetchRemoteTodos() }

// After Future completed

print(store.state.todos)
// [...]
```

Actions are often asynchronous, So we may need to know the timing action completed inside the view.  
 `dispatch()` allows returning anything. For example, we can return Future object to caller.  
 It can allow composite actions.

