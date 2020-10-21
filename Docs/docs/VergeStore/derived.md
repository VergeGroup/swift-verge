---
id: derived
title: Derived / BindingDerived - derives a any shape value from the state
sidebar_label: Derived / BindingDerived
---

:::info
**Derived** is inspired by [redux/reselect](https://github.com/reduxjs/reselect).
:::

Derived's functions are:

- Computes the derived data from the state tree
- Emit the updated data with updating Store
- Supports subscribe the data
- Supports Memoization
- Compatible with SwiftUI's observableObject and `StateReader`

## Overview

### Create a Derived object from the Store

**Select a tree from the state**

```swift
let derived: Derived<Int> = store.derived(.map(\.count))
```

```swift
// we can write also this.
// However, we recommend do above way as possible
// because it enables cache.
let derived: Derived<Int> = store.derived(.map { $0.count })
```

**Technically, above method callings are produced from below declaration.**

```swift
extension StoreType {
  public func derived<NewState>(_ memoizeMap: MemoizeMap<Changes<State>, NewState>, dropsOutput: ((Changes<NewState>) -> Bool)? = nil, queue: TargetQueue? = nil) -> Derived<NewState>
}
```

`MemoizeMap` manages to transform value from the state and keep performance that way of drops transform operations if the input value no changes.

**Compute a value from the state**

Derived can create any type of value what we need.
MemoizeMap

```swift
let derived = store.derived(.map(derive: { ($0.name, $0.age) }, dropsDerived: ==) { args in
  let (name, age) = args
  ...
  return ...
})
```

:::info
This method is quite optimized the performance If you create a Derived object that computes a new shape value that using multiple values from the state.  
Because Derived object uses the specified derived value to create a new shape value, It can detect no need to compute that value if the input derived value not changed.
:::

**Most manually way of creating a Derived object**

We can create fully tuned up Derived object with using custom initialized `MemoizedMap`.
Most of the cases, we don't need to do this.
Because several overloaded methods enable optimizations automatically that depending on doing things.
Verge shows current optimization status from the Complexity column of Xcode documentation.

<img
  width="533"
  alt="CleanShot 2020-05-31 at 00 46 27@2x"
  src="https://user-images.githubusercontent.com/1888355/83332811-41df2480-a2d8-11ea-8da0-d86c127fc926.png"
/>

## Take a value

Derived is an object (reference type). It provides a latest value from a store.
This supports getting the value ad-hoc or subscribing the value updating.

Derived allows us to take the latest value at the time.

```swift
let value: Int = derived.value
```

## Subscribe the latest value Derived provides

Derived allows us to subscribe to the updated value.

```swift
let cancellable = derived.sinkValue { (changes: Changes<Int>) in
}
```

:::caution
Please, carefully handle a cancellable object.  
A concealable object that returns that subscribe method is similar to AnyCancellable of Combine.framework.  
We need to retain that until we don't need to get the update event.
:::

## Supports other Reactive Frameworks

We might need to use some Reactive framework to integrate other sequence. Derived allows us to make to a sequence from itself. Currently, it supports Combine.framework and RxSwift.framework.

### + Combine

```swift
derived
  .valuePublisher()
  .sink { (changes: Changes<Int>) in

  }
```

### + RxSwift

:::caution
💡You need to install VergeRx module to use this.
:::

```swift
derived.rx
  .changesObservable()
  .subscribe(onNext: { (changes: Changes<Int>) in

  })
```

## Memoization to keep good performance

Mostly Derived is used for projecting the specified shape from the source object.
And some cases may contain an expensive operation. In that case, we can consider to tune Memoization up.​
We can see the detail of Memoization from below link.

[Wiki - Memoization](https://en.wikipedia.org/wiki/Memoization)

## Skips the map operation if the source state has no changes

In create Derived method, we can get the detail that how we suppress the no need updating and updated event.

```swift
extension StoreType {

  public func derived<NewState>(
    _ memoizeMap: MemoizeMap<Changes<State>, NewState>,
    dropsOutput: @escaping (Changes<NewState>) -> Bool = { _ in false }
  ) -> Derived<NewState>

}
```
