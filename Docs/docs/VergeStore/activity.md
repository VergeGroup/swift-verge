---
id: activity
title: Activity - a volatile event from an action
sidebar_label: Activity
---

## What activity does

VergeStore supports send some events that won't be stored on state.
Even if an application runs with Data-Driven, it might have some issues that not easy to something with Data-Driven.
For example, something that would happen with the timer's trigger. This case is not easy with expressing state.
Activity helps that can do easily.
This means VergeStore can use Event-Driven from Data-Driven partially.
We think it's not so special concept. SwiftUI supports these use cases as well that using Combine's Publisher.

```swift
func onReceive<P>(_ publisher: P, perform action: @escaping (P.Output) -> Void) -> some View where P : Publisher, P.Failure == Never
```

[Apple's SwiftUI Ref](https://developer.apple.com/documentation/swiftui/view/3365935-onreceive)

## Sends Activity

In sample code following this

```swift
final class MyStore: Store<State, Never>
```

`Never` means no activity.
To send activity to subscriber, starting from defining the Activity.

```swift
struct State {

}

enum Activity {
  case didSendMessage
}

final class MyStore: Store<State, Activity> {

  init() {
    super.init(initialState: .init(), logger: DefaultLogger.shared)
  }

  func sendMessage() {
    send(.didSendMessage)
  }
}
```

> In this sample, Store has DispatcherType. If you create the application not so much complicated, you don't need separate Store and Dispatcher.

```swift
let store = Store()

store
  .activityPublisher
  .sink { event in
    // do something
  }
  .store(in: &subscriptions)
```
