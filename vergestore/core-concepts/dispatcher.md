# Dispatcher

Mainly, Dispatcher allows Store.state to be updated.

To change state, use **Mutation** via `commit()`.  
 To run asynchronous operation, use **Action** via `dispatch()`.

```swift
class MyDispatcher: Dispatcher<RootState> {

}

let store = MyStore()
let dispatcher = MyDispatcher(target: store)
```

`MyStore` provies typealias to `Dispatcher<RootState>` as `MyStore.DispatcherType`.

