---
description: >-
  A Store-Pattern based data-flow architecture for iOS Application with UIKit /
  SwiftUI
---

# Verge - a state management pattern library for iOS App

![](.gitbook/assets/loop-2x%20%281%29.png)

## Verge - Store

{% hint style="danger" %}
Verge 7.0 is still in development. API and the concept of Verge might be changed a bit.
{% endhint %}

**A Store-Pattern based data-flow architecture.**

The concept of Verge Store is inspired by [Redux](https://redux.js.org/) and [Vuex](https://vuex.vuejs.org/).

Plus, releasing from so many definition of the actions.  
To be more Swift's Style on the writing code.

`store.myOperation()` instead of `store.dispatch(.myOperation)`

The characteristics are

* **Creates one or more Dispatcher. \(Single store, multiple dispatcher\)**
* **A dispatcher can have dependencies service needs. \(e.g. API Client, DB\)**
* **No switch-case to handle Mutation and Action**
* **Emits any events that isolated from State It's for SwiftUI's onReceive\(:\)**
* **Supports Logging \(Commit, Action, Performance monitoring\)**
* **Supports Middleware**

## Prepare moving to SwiftUI from now with Verge

SwiftUI's concept is similar to the concept of React, Vue, and Elm. Therefore, the concept of state management will become to be similar as well.

That is Redux or Vuex and more.

Now, almost of iOS Applications are developed on top of UIKit. And We can't say SwiftUI is ready for top production. However, it would be changed.

It's better to use the state management that fits SwiftUI from now. It's not only for that, current UIKit based applications can get more productivity as well.

## Overview Verge Store

### **Declare**

```swift
struct State: StateType {
  var count: Int = 0
}

enum Activity {
  case happen
}

final class MyStore: StoreBase<State, Activity> {
  
  init() {
    super.init(initialState: .init(), logger: DefaultStoreLogger.shared)
  }
  
  func increment() {
    commit {
      $0.count += 0
    }
  }
  
  func delayedIncrement() {
    dispatch { context in
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        context.redirect { $0.increment() }
        
        context.send(.happen)
      }
    }
  }
  
}
```

### Run

```swift
let store = MyStore()

store.increment()

store.delayedIncrement()
```

### Read the state

```swift
let count = store.state.count
```

### Subscribe the state

```swift
// Using combine
store.makeGetter()
  .sink { state in
        
}

// or Using RxSwift

import VergeRx
store.rx.makeGetter()
  .bind { state in
        
}
```

### Integrate with SwiftUI

```swift
struct MyView: View {
  
  @EnvironmentObject var store: MyStore
  
  var body: some View {
    Group {
      Text(store.state.count.description)
      Button(action: {
        self.store.increment()
      }) {
        Text("Increment")
      }
    }
  }
}
```

### Integrate with UIKit

Of course Verge supports UIKit based application.

## Normalizing State Shape

Most important thing in using state-tree is **Normalization.**

**We can get detail of normalization from Redux documentation**

{% embed url="https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape/" %}

### Verge supports ORM

{% page-ref page="docs-verge-orm/core-concepts.md" %}



## Concept from...

{% embed url="https://medium.com/eureka-engineering/thought-about-arch-for-swiftui-1b0496d8094" %}



