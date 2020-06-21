---
id: optimization-tips
title: Optimization Tips
sidebar_label: Optimization Tips
---

## Writing high-performance state-management

- Simplify the state shape, thinking normalization to reduce the number of operations on mutating.
- Passes Changes object as it is if you want to bring the large state tree somewhere.
  - Since `Changes` is a reference type, it reduces the cost of copy.
- Using ExtendedComputedProperty
- Makes the state compatible with Equatable as possible to create a good Derived object
- Reduces creating new Derived object. Instead, share Derived.
- Makes Derived with a simple keyPath to enables caching Derived.
- Uses Fragment property wrapper to enables Differentiability.
- Uses Fragment property wrapper to enables Equatable easily that contains false negative.

## 🏎 Performance monitoring

Verge supports `os_sign_post`
We can check the performance from Xcode Instruments.
Please enables signpost profiling.

![CleanShot 2020-05-31 at 14 22 16@2x](https://user-images.githubusercontent.com/1888355/83345130-80152c00-a34a-11ea-925a-6c6a609be102.png)

## 📱 SwiftUI

> WIP

To integrate SwiftUI, we can use `UseState` struct or `@ObservedObject` property wrapper.
UseState never doing memory allocations.

Either way is fine, but UseState enables injecting the state into a specific location of the view hierarchy.
Using @ObservedObject updates the whole of view by state updated.

Injects Store

```swift
struct MyView: View {

  let: Store<MyState, Never>

  var body: some View {
    NavigationView {
      UseState(store) { (state: Changes<MyState>) in
        ...
      }
    }
  }
}
```

```swift
struct MyView: View {

  @ObservedObject var store: Store<MyState, Never>

  var body: some View {
    NavigationView {
      ...
    }
  }
}
```

Injects Derived

```swift
struct MyView: View {

  let users: Derived<[Entity.User]>

  var body: some View {
    UseState(users) { (users: Changes<[Entity.User]>) in
      ...
    }
  }
}
```

```swift
struct MyView: View {

  @ObservedObject var users: Derived<[Entity.User]>

  var body: some View {
    ...
  }
}
```
