# 🔭 Logging - Take logs performed Mutation and Action

{% hint style="warning" %}
Sorry, this documentation is currently working in progress.
{% endhint %}

With creating an object that using `VergeStoreLogger`, we can get the log that VergeStore emits.

As a default implementation, we can use `DefaultLogger.shared`.

```swift
public protocol StoreLogger {

  func willCommit(store: AnyObject, state: Any, mutation: MutationMetadata, context: AnyObject?)
  func didCommit(store: AnyObject, state: Any, mutation: MutationMetadata, context: AnyObject?, time: CFTimeInterval)
  func didDispatch(store: AnyObject, state: Any, action: ActionMetadata, context: AnyObject?)

  func didCreateDispatcher(store: AnyObject, dispatcher: Any)
  func didDestroyDispatcher(store: AnyObject, dispatcher: Any)
}
```

