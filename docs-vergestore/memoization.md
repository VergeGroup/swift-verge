---
description: Getting values from state tree with memoization(caching) to keep performance.
---

# Getter\(Selector\) and Memoization

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
  filter: Filters.Historical.init(selector: { $0.count }, predicate: !=).asFunction()
  map: { (state) -> Int in
    state.count * 2
})

getterSource.value
```

## Filters with Memoization

We have several Filters to get Memoization.

* Filters.Basic
* Filters.Combined
* Filters.Historical

Filter can be described with `(Input) -> Bool`

True means pass the value to getter as a new value.  
It means if value not changed you need to return **false.**

Basically, we use Filters.Historical because it needs to compare previous input value to get memoization.

Finally, To convert to `(Input) -> Bool` , we call `asFunction()`

```swift
let filter: Filters.Historical<Int> = Filters.Historical<Int>.init()
  
XCTAssertEqual(filter.check(input: 1), true)
XCTAssertEqual(filter.check(input: 1), false)
XCTAssertEqual(filter.check(input: 2), true)
```

convert to closure with `asFunction`

```swift
let filter: (Int) -> Bool = Filters.Historical<Int>.init().asFunction()

XCTAssertEqual(filter(1), true)
XCTAssertEqual(filter(1), false)
XCTAssertEqual(filter(2), true)
```

## Getter object

AnySelector erases Input type and displays only Output type.

```swift
let anyGetter: Getter<Output> = getterSource.asGetter()
```

## Create Getter from other Getter

{% hint style="danger" %}
Don't use operator that dispatches asynchronously, when we create new Getter from other Getter.

Because, Publisher must emit value synchronously on subscribed to make Getter could provide current computed value whenever,.
{% endhint %}



```swift
let first = store.getter(
  filter: Filters.Historical.init().asFunction(),
  map: { ... }
)

let second = Getter {
  // 🚨Don't use operator that dispatches asynchronously.
  first
    .map { ... } 
}
```

## Combine getters

```swift
let first = store.getter(
  filter: Filters.Historical.init().asFunction(),
  map: { $0 }
)

let second = store.getter(
  filter: Filters.Historical.init().asFunction(),
  map: { -$0 }
)

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

