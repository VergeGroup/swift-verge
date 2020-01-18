# ☄️ Mutation - Updates state

## What Mutation is

The only way to actually change state in a Store is by committing a mutation.   
Define a function that returns Mutation object.   
That expresses that function is Mutation

{% hint style="success" %}
Mutation does **NOT** allow to run asynchronous operation.
{% endhint %}

```swift
public struct AnyMutation<Dispatcher, Result>: MutationType where Dispatcher : VergeStore.DispatcherType {

  public let metadata: MutationMetadata

  public init(_ name: StaticString = "", mutate: @escaping (inout Dispatcher.State) -> Return)
}
```

Mutation object is simple struct that has a closure what passes current state to change it.

**To define mutations in the Store**

```swift
class MyDispatcher: MyStore.Dispatcher {

  func addNewTodo(title: String) -> Mutation<Void> {
    .mutation { (state: inout RootState) in
      state.todos.append(Todo(title: title, hasCompleted: false))
    }
  }
  
}
```

{% hint style="info" %}
AnyMutation object provides several factory methods.  
`.mutation` is also a part of those.  
  
To check more methods, starting type `.mutation` and see the code completion in Xcode.
{% endhint %}

{% hint style="danger" %}
In Swift 5.1, we can return value without typing **return** keyword.  
But it causes problems on SourceKit, we may lose the code completion in the state properties.  
  
If you faced this issue, please try to type return keyword explicitly.
{% endhint %}

**To run Mutation**

```swift
let store = MyStore()
let dispatcher = MyDispatcher(target: store)

dispatcher.commit { $0.addNewTodo(title: "Create SwiftUI App") }

print(store.state.todos)
// store.state.todos => [Todo(title: "Create SwiftUI App", hasCompleted: false)]
```



