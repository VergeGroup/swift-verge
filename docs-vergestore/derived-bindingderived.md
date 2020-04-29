# 🌙 Derived / BindingDerived

## Computing derived data from state tree

{% hint style="info" %}
**Derived** is inspired by [redux/reselect](https://github.com/reduxjs/reselect).
{% endhint %}

Derived's functions are:

* Computes derived data from state tree
* Supports Memoization

## Overview

### Setting up the Store

```swift
struct State {
  var title: String = ""
  var count: Int = 0
}

let store = StoreBase<State, Never>(initialState: .init(), logger: nil)
```

### Create a Derived

```swift
let derived: Derived<Int> = store.derived(.map { $0.count })
```

### Subscribe the Derived

```swift
let cancellable = derived.subscribeChanges { (changes: Changes<Int>) in 
}
```

#### with Combine

```swift
derived
  .changesPublisher()
  .sink { (changes: Changes<Int>) in
  
  }
```

#### with RxSwift

```swift
derived.rx
  .changesObservable()
  .subscribe(onNext: { (changes: Changes<Int>) in
  
  })
```

