---
description: Getting values from state tree with memoization(caching) to keep performance.
---

# Getter\(Selector\) and Memoization

## Getter

{% hint style="info" %}
**Getter** is inspired by [redux/reselect](https://github.com/reduxjs/reselect).

But naming uses **Getter** instead of **Selector**, because Objective-C also uses **Selector** and then this causes ambiguity with writing without module name.
{% endhint %}

Memoization will be needed in some cases.

* The cost of computing value from State is expensive.

```swift
open class Getter<Input, Output>
```

```swift
struct State {
       
  var count: Int = 0

}

let getter = store.getter(
  filter: .init(selector: { $0.count }, equals: ==)
  map: { (state) -> Int in
    state.count * 2
})

getter.value
```

## AnyGetter

AnySelector erases Input type and displays only Output type.

```swift
let selector: Getter<Input, Output>

let anySelector: AnyGetter<Output> = selector.asAny()
```

