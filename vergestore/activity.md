# ⚡️ Activity - Dispatching Volatile Events

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

[https://developer.apple.com/documentation/swiftui/view/3365935-onreceive](https://developer.apple.com/documentation/swiftui/view/3365935-onreceive)

