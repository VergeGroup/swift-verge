# Store

Store is a reference type object and it manages the state object that contains the application state.

To get current state, use `Store.state`

  
Basically, Store focuses to manage the state only.  
To update the state with **Mutation** from **Dispatcher.**  
  
We can create multiple Dispatcher that for same Store.  
To see more the detail of Dispatcher, move to Dispatcher page.

![Updating the state from multiple dispatcher](../.gitbook/assets/image%20%282%29.png)

{% page-ref page="dispatcher.md" %}



```swift
struct State {

  struct Todo {
    var title: String
    var hasCompleted: Bool
  }

  var todos: [Todo] = []

}

final class MyStore: StoreBase<State, Never> {

  init() {
    super.init(initialState: .init(), logger: nil)
  }
}

let store = MyStore()
```



{% hint style="info" %}
If you need only one Dispatcher, you can add `DispatcherType` protocol to Store object.
{% endhint %}

