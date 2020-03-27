---
description: Getting values from state tree with memoization(caching) to keep performance.
---

# 💫 Getter\(Selector\) and Memoization

{% hint style="danger" %}
Because Getter does provide the latest computed value and emits a new value. it's like a stream with buffer. Of course, the stream will need several operators. Verge stopped implementing this from scratch. Instead, using Combine or other Reactive Framework. 

Currently, Combine.framework is used as a standard implementation and **RxSwift is also supported.**

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
let getterSource: GetterSource<State, Int> = store.getterBuilder().map(\.count)
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

Getter / GetterSource is compatible with **Publisher** of Combine.framework

```swift
getter.sink { (value) in
  // Receive the new value
}
```

## Memoization to keep performance

Most of Getter usages would be to project source object into a new form with **Map.**  
  
Basically, the operations in Map must be high-performance, to keep the good performance.  
**However,** **sometimes it's impossible to create fast Map.**  
For example, getting value from the huge dictionary.

In that case, we can consider using Memoization.

{% embed url="https://en.wikipedia.org/wiki/Memoization" %}



### Set condition before map

**Using `changed`** **before `map`** can filter the object before passing the map function.

```swift
store.getterBuilder()
  .changed(keySelector: \.title, comparer: .init(==))
  .map { $0.title.count }
  .build()
```



### Set condition after map

**Using `changed`** **after `map`** can filter the object with the mapped object after the map function.

```swift
store.getterBuilder()
  .mapWithoutPreFilter { $0.title.count }
  .changed(==)
  .build()
```

{% hint style="warning" %}
Whether to put **.map** before or after **.changed** should be considered according to the costs of **.map** and **.changed**.
{% endhint %}

## Create Getter from other Getter

✅

```swift
let first = store.makeGetter { ... }

let second = Getter {
  first
    .map { ... } 
}
```

### ⚠️

{% hint style="danger" %}
Don't use operator that dispatches asynchronously, when we create new Getter from other Getter.

To make Getter, it requires initial value when initializing itself.  
Publisher must have the replayed value and must emit value synchronously when subscription started.
{% endhint %}

```swift
let first = store.getterBuilder() ... .build()

let second = Getter {
  first
    .observeOn(...) // ❌ Don't use asynchronous operators.
    .map { ... } 
}
```



## Combine getters

```swift
let first: Getter<Int> = store.getterBuilder() ... .build()

let second: Getter<Int> = store.getterBuilder() ... .build()

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
let getter: RxGetterSource<State, Int> = store.rx.store.getterBuilder()
  .mapWithoutPreFilter(\.count)
  .build()
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



