# ☄️ Mutation - Updates state

## What Mutation is

The only way to actually change state in a Store is by committing a mutation.   
Define a function that returns Mutation object.   
That expresses that function is Mutation

{% hint style="success" %}
Mutation does **NOT** allow to run asynchronous operation.
{% endhint %}

## **To define mutations in the Store**

```swift
class MyDispatcher: MyStore.Dispatcher {

  func addNewTodo(title: String) {
    commit { (state: inout RootState) in
      state.todos.append(Todo(title: title, hasCompleted: false))
    }
  }
  
}
```

## **To run Mutation**

```swift
let store = MyStore()
let dispatcher = MyDispatcher(target: store)

dispatcher.addNewTodo(title: "Create SwiftUI App")

print(store.state.todos)
// store.state.todos => [Todo(title: "Create SwiftUI App", hasCompleted: false)]
```



