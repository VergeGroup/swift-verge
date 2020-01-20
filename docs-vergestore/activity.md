# ⚡️ Activity - Dispatching Volatile Events

## What activity does

VergeStore supports send some events that won't be stored on state.

{% hint style="warning" %}
WIP
{% endhint %}

Even if an application runs with Data-Driven, it might have some issues that not easy to something with Data-Driven.

For example, something that would happen with the timer's trigger. This case is not easy with expressing state.

Activity helps that can do easily.

This means VergeStore can use Event-Driven from Data-Driven partially.

We think it's not so special concept. SwiftUI supports these use cases as well that using Combine's Publisher.

```swift
func onReceive<P>(_ publisher: P, perform action: @escaping (P.Output) -> Void) -> some View where P : Publisher, P.Failure == Never
```

{% embed url="https://developer.apple.com/documentation/swiftui/view/3365935-onreceive" %}

## Sends Activity

In sample code following this

```swift
final class MyStore: StoreBase<State, Never>
```

**Never** means no activity.

To send activity to subscriber, starting from defining the Activity.

```swift
struct State {
    
}

enum Activity {
  case didSendMessage
}

final class Store: StoreBase<State, Activity>, DispatcherType {
  
  var target: StoreBase<State, Activity> { self }
  
  init() {
    super.init(initialState: .init(), logger: DefaultLogger.shared)
  }
  
  func sendMessage() -> Action<Void> {
    return .action { context in
      context.send(.didSendMessage)
    }
  }
}
```

{% hint style="info" %}
In this sample, Store has DispatcherType.  
If you create the application not so much complicated, you don't need separate Store and Dispatcher.
{% endhint %}

This is the point, this is only way to send Activity. Action only can do this.

```swift
func sendMessage() -> Action<Void> {
  return .action { context in
    context.send(.didSendMessage)
  }
}
```

```swift
let store = Store()

store
  .activityPublisher
  .sink { event in
    // do something
  }
  .store(in: &subscriptions)
```



