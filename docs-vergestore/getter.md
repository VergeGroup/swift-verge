---
description: Getting values from state tree with memoization(caching) to keep performance.
---

# 💫 Getter\(Selector\) and Memoization

{% hint style="danger" %}
Because Getter does provide the latest computed value and emits a new value. it's like a stream with buffer. Of course, the stream will need several operators. Verge stopped implementing this from scratch. Instead, using Combine or other Reactive Framework. Currently, Combine.framework is used as a standard implementation and RxSwift's support.

This is a huge dependency, but Reactive Framework would be official such as Combine.framework.
{% endhint %}

## Computing derived data from state tree

{% hint style="info" %}
**Getter** is inspired by [redux/reselect](https://github.com/reduxjs/reselect).

But naming uses **Getter** instead of **Selector**, because Objective-C also uses **Selector** and then this causes ambiguity with writing without module name.
{% endhint %}

* Computes derived data from state tree
* Supports Memoization

## Overview

### Setting up the Store

```swift
struct State {
  var title: String = ""
  var count: Int = 0
}
```

```swift
let store = StoreBase<State, Never>(initialState: .init(), logger: nil)
```

### Create a GetterSource / Getter

```swift
let getterSource: GetterSource<State, Int> = store.makeGetter {
  // Why here is closure it would be touched later.
  $0.map(\.count)
}
```

**GetterSource** has the type of State to indicates the output object comes from.  
To erase this type, call **asGetter\(\)  
  
You could get Getter object.** Technically GetterSource is subclass of Getter, you can pass to the argument of Getter in the function directly.

```swift
let getterSource: GetterSource<State, Int> = ...
let getter: Getter<Int> = getterSource.asGetter()
```

### Get the value from Getter

```swift
let getter: Getter<Int> = 

let count: Int = getter.value
```

_As explained above, GetterSource has same interfaces as well._

### Subscribe the value

Getter / GetterSource compatible **Publisher** of Combine.framework

```swift
getter.sink { (value) in
  // Receive the new value
}
```

## Memoization to keep performance

Almost of Getter usages would be to project source object into a new form with **Map.**  
  
Basically, the operations in Map must be high-performance, to keep the good performance.  
**However,** **sometimes it's impossible to create fast Map.**  
For example, getting value from the huge dictionary.

In that case, we can consider using Memoization.

{% embed url="https://en.wikipedia.org/wiki/Memoization" %}



### Use Pre-Filter

Pre-filter can filter the object before passing the map function.

```swift
store.makeGetter {
  $0.changed(keySelector: \.title, comparer: .init(==))
    .map { $0.title.count }
}
```



### Use Post-Filter

Post-filter can filter the object with the mapped object after the map function.

```swift
store.makeGetter {
  $0.map { $0.title.count }
    .changed(==)
}
```

## Create Getter from other Getter

{% hint style="danger" %}
Don't use operator that dispatches asynchronously, when we create new Getter from other Getter.

Because, Publisher must emit value synchronously on subscribed to make Getter could provide current computed value whenever,.
{% endhint %}



```swift
let first = store.makeGetter { ... }

let second = Getter {
  // 🚨Don't use operator that dispatches asynchronously.
  first
    .map { ... } 
}
```

## Combine getters

```swift
let first: Getter<Int> = store.makeGetter { ... }

let second: Getter<Int> = store.makeGetter { ... }

let combined = Getter {
  first.combineLatest(second)
    .map { $0 + $1 }
    .removeDuplicates()
}

XCTAssertEqual(combined.value, 0)
```

## Make Getter from constant value

{% hint style="info" %}
Inspired by SwiftUI.Binding&lt;Value&gt;
{% endhint %}

```swift
Getter<String>.constant("hello")
```

## With RxSwift, Use Getter on less than iOS 13

{% hint style="success" %}
Getter supports only iOS13+ macOS10.15+ because **it uses Combine.framework**

If you need to use Getter on less than iOS13, you can install VergeRx module.  
It provides Getter functions as RxGetter.
{% endhint %}

### Install VergeRx

```text
pod 'Verge/Rx'
```

### Create RxGetter / RxGetterSource

The syntax are completely same with Getter

```swift
let getter: RxGetterSource<State, Int> = store.rx.store.makeGetter {
  $0.map(\.count)
}
```

### Transform Getter

{% hint style="warning" %}
It's unsafe to create RxGetter from any Observable object.
{% endhint %}

```swift
let nextGetter: RxGetter<T> = getter.map { ... }.unsafeGetterCast()
```

### 

### SubscriptionGroup with DSL style

With `SubscriptionGroup`, we can create Disposable object with DSL style declarations.

```swift
SubscriptionGroup {
      
  Single.just(1).subscribe()
  
}

SubscriptionGroup {
  
  Single.just(1).subscribe()
  Single.just(1).subscribe()
        
}

SubscriptionGroup {
  [
  Single.just(1).subscribe(),
  Single.just(1).subscribe()
  ]
}
```

`SubscriptionGroup` compatibles **Disposable** protocol.

```swift
SubscriptionGroup {

  Single.just(1).subscribe()
  Single.just(1).subscribe()
            
}
.disposed(by: ...)
```



