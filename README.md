---
description: >-
  A Store-Pattern based data-flow architecture for iOS Application with UIKit /
  SwiftUI
---

# Verge - Flux and ORM for creating iOS App with SwiftUI and UIKit

## Verge - Store

![](.gitbook/assets/top-image-01%20%281%29.png)

* Current v7.0.0 beta status to publish release
  * Trying to use on author's product.
    * to get the feel for syntax on writing.
    * to check the capability and scalability when using on the large projects.
  * Status

    * Started using VergeORM and RxGetter on the product \(2020-02\)

{% hint style="danger" %}
Verge 7.0 is still in development. API and the concept of Verge might be changed a bit.
{% endhint %}

**A Store-Pattern based data-flow architecture.**

```swift
struct State: StateType {
  var name: String = ""
  var age: Int = 0
}

enum Activity {
  case somethingHappen
}

// 🌟with UIKit
class ViewController: UIViewController {
  
  ...  
  
  let store = Store<State, Activity>(initialState: .init(), logger: nil)
  
  ...
            
  func update(changes: Changes<State>) {
    
    changes.ifChanged(\.name) { (name) in
      nameLabel.text = name
    }
    
    changes.ifChanged(\.age) { (age) in
      ageLabel.text = age.description
    }
    
  }
}


// 🌟with SwiftUI
struct MyView: View {
  
  @EnvironmentObject var store: Store<State, Activity>
  
  var body: some View {
    Group {
      Text(store.state.name)
      Text(store.state.age)
    }
  }
}
```

The concept of Verge Store is inspired by [Redux](https://redux.js.org/), [Vuex](https://vuex.vuejs.org/) and [ReSwift](https://github.com/ReSwift/ReSwift).

Plus, releasing from so many definition of the actions.  
To be more Swift's Style on the writing code.

`store.myOperation()` instead of `store.dispatch(.myOperation)`

The characteristics are

* **Creates one or more Dispatcher. \(Single store, multiple dispatcher\)**
* **A dispatcher can have dependencies service needs. \(e.g. API Client, DB\)**
* **No switch-case to handle Mutation and Action**
* **Emits any events that isolated from State It's for SwiftUI's onReceive\(:\)**
* **Supports Logging \(Commit, Action, Performance monitoring\)**
* **Supports binding with Combine and RxSwift**
* **Supports normalizing the state with ORM.**

\*\*\*\*

**🔗**[ **You can see more detail of Verge on Documentation**](https://muukii-app.gitbook.io/verge/) **🔗**

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
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      self.increment()
      self.send(.happen)
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
store.subscribeStateChanges { (changes) in
  changes.ifChanged(\.name) { name in
    // it's called only name changed.
  }
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

## ORM module to normalize State Shape

Most important thing in using state-tree is **Normalization.**

**We can get detail of normalization from Redux documentation**

{% embed url="https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape/" %}

{% page-ref page="docs-verge-orm/core-concepts.md" %}

### 

### Logging

Verge supports logging functions.

Using the console of Xcode or Console.app, we can track how the application runs

![](.gitbook/assets/cleanshot-2020-03-08-at-09.25.36-2x.png)

{% page-ref page="docs-vergestore/logging.md" %}





## Concept from...

{% embed url="https://medium.com/eureka-engineering/thought-about-arch-for-swiftui-1b0496d8094" %}



