# Verge - Flux and ORM for creating iOS App with SwiftUI and UIKit

## Verge 7.0.0 Beta

![](https://user-images.githubusercontent.com/1888355/80621676-98133a80-8a82-11ea-952f-3c3e52f9c222.png)

> 🚧 Verge 7.0 is still in development. API and the concept of Verge might be changed a bit.

[**🔗 You can see more detail of Verge on Documentation**](https://muukii-app.gitbook.io/verge/)

**A Store-Pattern based data-flow architecture.**

<details><summary>See first look</summary>
<p>

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

</p>
</details>

## Overview

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

## What differences between other Flux libraries in the iOS application world

Firstly, Verge provides the functions to keep excellent performance in using Store-Pattern.

Verge focuses on using in the real-world.

For example, the application must have many features depends on its business.<br>
Such as the application might be getting complicated.

To solve this issue, we can choose Store-Pattern such as flux.

At a glance, Flux architecture is amazing.<br>
However, we have to follow the disadvantages behind it.

They are coming from the application runs with Data-Driven (Mostly).<br>
Data-Driven will cause some expensive calculations in the application that depends on the complexity of the application.<br>
Sometimes, we may face some performance issues we can't overlook it.

Redux and Vuex are already following that.

- Redux
  - reselect
  - ORM
- Vuex
  - Getters
  - ORM

Verge is trying to do that in iOS application with Swift.

Specifically:
- Derived
- ORM

## Prepare moving to SwiftUI from now with Verge

SwiftUI's concept is similar to the concept of React, Vue, and Elm. Therefore, the concept of state management will become to be similar as well.

That is Redux or Vuex and more.

Now, almost of iOS Applications are developed on top of UIKit. And We can't say SwiftUI is ready for top production. However, it would be changed.

It's better to use the state management that fits SwiftUI from now. It's not only for that, current UIKit based applications can get more productivity as well.

## Installation

With Cocoapods,

VergeStore

```ruby
pod 'Verge/Store'
```

VergeORM

```ruby
pod 'Verge/ORM'
```

VergeRx

```ruby
pod 'Verge/Rx'
```

These are separated with subspecs in Podspec.
After installed, these are merged into single module as `Verge`.

To use Verge in your code, define import decralation following.

```swift
import Verge
```

## Author

[muukii](https://github.com/muukii)

## License

Verge is released under the MIT license.


