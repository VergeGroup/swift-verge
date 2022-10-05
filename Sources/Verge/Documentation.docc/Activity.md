# Activity

## What Activity brings to us

Activity enables Event-driven partially.

Verge supports to send any events that won’t be stored persistently. Even if an application runs with State-Driven, it might have some issues that not easy to something with State-Driven.

For example, something that would happen with the timer’s trigger. It’s probably not easy to expressing that as a state.
In this case, Activity helps that can do easily.

This means Verge can use Event-Driven from Data-Driven partially.
We think it’s not so special concept. SwiftUI supports these use cases as well that using Combine’s Publisher.

```swift
func onReceive<P>(_ publisher: P, perform action: @escaping (P.Output) -> Void) -> some View where P : Publisher, P.Failure == Never
```

[Apple’s SwiftUI Ref](https://developer.apple.com/documentation/swiftui/view/3365935-onreceive)

## Add Activity to the Store

In sample code following this:

```swift
final class MyStore: StoreComponentType {

  struct State {
    ...
  }

}
```

To enable using Activity, we add new decralation just like this:

```swift
final class MyStore: StoreComponentType {

  struct State {
    ...
  }

  /// 👇
  enum Activity {
    case didSendMessage
  }

}
```

## Send an Activity

And finally, that Store now can emit an activity that we created.

```swift
extension MyStore {
  func sendMessage() {
    send(.didSendMessage)
  }
}
```

---

## Subscribe the Activity

**Normal**

```swift
store.sinkActivity { activity in
  ...
}
.store(in: &subscriptions)
```

**Using Combine**

```swift
store
  .activityPublisher
  .sink { event in
    // do something
  }
  .store(in: &subscriptions)
```
