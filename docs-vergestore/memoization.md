---
description: Getting values from state tree with memoization(caching) to keep performance.
---

# Getter\(Selector\) and Memoization

## Computing derived data from state tree

{% hint style="info" %}
**Getter** is inspired by [redux/reselect](https://github.com/reduxjs/reselect).

But naming uses **Getter** instead of **Selector**, because Objective-C also uses **Selector** and then this causes ambiguity with writing without module name.
{% endhint %}

* Computes derived data from state tree
* Supports Memoization

{% hint style="info" %}
Getter uses Combine.framework
{% endhint %}

## GetterSource object

```swift
@available(iOS 13, macOS 10.15, *)
public final class GetterSource<Input, Output>: Getter<Output>
```

```swift
struct State {

  var count: Int = 0

}

let getterSource: GetterSource<State, Int> = store.getter(
  filter: .init(selector: { $0.count }, equals: ==)
  map: { (state) -> Int in
    state.count * 2
})

getterSource.value
```

## Getter object

AnySelector erases Input type and displays only Output type.

```swift
let anySelector: AnyGetter<Output> = getterSource.asGetter()
```

## Create Getter from other Getter

{% hint style="danger" %}
Don't use operator that dispatches asynchronously, when we create new Getter from other Getter.

Because, Publisher must emit value synchronously on subscribed to make Getter could provide current computed value whenever,.
{% endhint %}



```swift
let first = store.getter(filter: .init(), map: { ... })

let second = Getter {
  // 🚨Don't use operator that dispatches asynchronously.
  first
    .map { ... } 
}
```

## Combine getters

```swift
let first = store.getter(filter: .init(), map: { $0 })
let second = store.getter(filter: .init(), map: { -$0 })

let combined = Getter {
  first.combineLatest(second)
    .map { $0 + $1 }
    .removeDuplicates()
}

XCTAssertEqual(combined.value, 0)
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

### Create Getter

```swift
let getter = store.rx.getter(filter: .init(), map: { ... })
```

### Transform Getter

{% hint style="warning" %}
It's unsafe to create RxGetter from any Observable object.
{% endhint %}

```swift
let nextGetter: RxGetter<T> = getter.map { ... }.unsafeGetterCast()
```

