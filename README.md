<p align="center">
  <a href="https://vergegroup.org">
<img width="128" alt="VergeIcon" src="https://user-images.githubusercontent.com/1888355/85241314-5ac19c80-b476-11ea-9be6-e04ed3bc6994.png">
    </a>
</p>


<h1 align="center">Verge.swift</h1>
<p align="center">
  <b>📍An effective state management architecture for iOS - UIKit, SwiftUI📍</b><br/>
<sub>_ An easier way to get unidirectional data flow _</sub><br/>
<sub>_ Supports concurrent processing _</sub><br/>
</p>

- [Verge Docs](https://vergegroup.github.io/swift-Verge/Verge/documentation/verge/)
- [VergeORM Docs](https://vergegroup.github.io/swift-Verge/VergeORM/documentation/vergeorm/)


<p align="center">
<img alt="swift5.5" src="https://img.shields.io/badge/swift-5.5-ED523F.svg?style=flat"/>
<img alt="Tests" src="https://github.com/VergeGroup/Verge/workflows/Tests/badge.svg"/>
</p>

## Support this projects
<a href="https://www.buymeacoffee.com/muukii">
<img width="160" alt="yellow-button" src="https://user-images.githubusercontent.com/1888355/146226808-eb2e9ee0-c6bd-44a2-a330-3bbc8a6244cf.png">
</a>

## Introduction

Verge is a library that provides a store-pattern, which is a primitive concept of flux and redux, but with a stronger focus on it.  
The store-pattern doesn't specify how to manage actions to modify the state. It just focuses on sharing the state between components using a single source of truth.

Verge provides only a commit function to modify the state, which accepts a closure to describe how to change it.  
If you prefer a more strict way, such as using an enum-based action to indicate how to modify the state, you can create a layer on top of Verge.

One of the notable features of Verge is that it can work with multi-threading, making it faster, safer, and more efficient.  
It supports both UIKit and SwiftUI, making it versatile for different application types.

Verge also provides tool APIs to handle real-world application development use cases, such as managing asynchronous operations.  
Additionally, it focuses on the hardest things to use the store-pattern in large and complex applications, such as the cost of updating the state in complex applications, where the state structure will be large and take a lot of computing resources to make a copy.

Another important feature of Verge is providing an ORM to manage a lot of entities in an efficient way. When using this kind of design pattern, it's essential to use normalizing techniques to store entities into the state.

Overall, Verge is a framework that works best for business-focused applications.

## Requirements

* Swift 5.7 +
* @available(iOS 13, macOS 10.13, tvOS 10, watchOS 3)
* UIKit
* SwiftUI

## Disclaimer

Verge might be updated without migration guide as we are not sure how many projects are using this library.
Please feel free to ask us about how to use and how to migrate.  

## Verge is a framework for store-pattern software development

Verge is a performant store-pattern based state management library for iOS.

[And the article about store-pattern](https://medium.com/eureka-engineering/verge-start-store-pattern-state-management-before-beginning-flux-in-uikit-ios-app-development-6c74d4413829)

### What store-pattern is

The word 'store-pattern' is used on [Vue.js documentation](https://vuejs.org/v2/guide/state-management.html#Simple-State-Management-from-Scratch) that about how we manage the state between multiple components.

## Projects which use Verge

- [Pairs for JP](https://apps.apple.com/app/id583376064)
- [Pairs for TW/KR](https://apps.apple.com/app/id825433065)
- [Pairs Engage](https://apps.apple.com/app/id1456982763)
- 👉 YOUR APP or PROJECT!

**We're welcome to publish here your application which powered by Verge!**  
Please Submit from Pull requests

## Minimal usage example - In UIView - UIViewController

State-management is everywhere, you can put a store and start state-management.

```swift
final class CropViewController: UIViewController {

  private struct State: Equatable {
    var isSelectingAspectRatio = false
  }
  
  private let store: Store<State, Never> = .init(initialState: .init())

  override public func viewDidLoad() {
    
    store.sinkState { [weak self] state in 
      guard let self = self else { return }
      
      state.ifChanged(\.isSelectingAspectRatio) { value in 
        //
      }

    }
    .storeWhileSourceActive()
    
  }

  func showAspectRatioSelection() {
    store.commit {
      $0.isSelectingAspectRatio = true
    }
  }
  
  func hideAspectRatioSelection() {
    store.commit {
      $0.isSelectingAspectRatio = false
    }
  }
}
```

## Advanced usage exmaple - UIKit / SwiftUI

Creating a view-model (meaning Store)

```swift
final class MyViewModel: StoreComponentType {

  /// 💡 The state declaration can be aslo inner-type.
  /// As possible adding Equatable for better performance.
  struct State: Equatable {
  
    struct NestedState: Equatable {
      ...
    }
    
    var name: String = ""
    var count: Int = 0
    
    var nested: NestedState = .init()  
    
  }

  /// 💡 This is basically a template statement. You might have something type of `Store`.
  let store: Store<State, Never> = .init(initialState: .init())

  // MARK: - ✅ These are actions as well as writing methods.

  func myAction() {
    // 💥 Mutating a state
    commit {
      $0.name = "Hello, Verge"
    }
  }

  func incrementAsync() {
    /**
    💥 Asynchronously mutating.
    Verge just provides thread-safety.
    We should manage operations in the Action.
    */
    DispatchQueue.global().async {    
      commit {
        // We must finish here synchronously - here is a critical session.
        $0.count += 1
      }
    }
  }
}
```

### In SwiftUI

Use **StoreReader** to read a state of the store.  
It optimizes frequency of update its content for performance wise.
The content closure runs when reading properties have changed or parent tree updated.

```swift
struct MyView: View {

  let store: MyViewModel

  var body: some View {
    // ✅ Uses `StateReader` to read the state this clarifies where components need the state.
    StoreReader(store) { state in
      Text(state.name)
      Button(action: {
        self.store.myAction()
      }) {
        Text("Action")
      }
    }
  }
}
```

### In UIKit

Binding with a view (or view controller)

```swift
final class MyViewController: UIViewController {

  let viewModel: MyViewModel

  ...

  var cancellable: VergeAnyCancellable?

  init(viewModel: MyViewModel) {

    self.viewModel = viewModel

    // ✅ Start subscribing the state.
    self.cancellable = viewModel.sinkState { [weak self] (state: Changes<MyViewModel.State>) in
      self?.update(state: state)
    }

  }

  /**
  Actually we don't need to create such as this method, but here is for better clarity in this document.  
  */
  private func update(state: Changes<MyViewModel.State>) {
    
    /**
    💡 `Changes` is a reference-type, but it's immutable.
    And so can not subscribe.
    
    Why is it a reference-type? Because it's for reducing copying cost.
    
    It can detect difference with previous value with it contains a previous value.
    Which is using `.ifChanged` or `.takeIfChanged`.
    */

    /// 🥤 An example that setting the value if the target value has updated.
    state.ifChanged(\.name) { (name) in
      // ✅ `name` has changed! Update the text.
      nameLabel.text = name
    }
    
    /// 🥤 An example that composing as a tuple to behave like RxSwift's combine latest.
    state.ifChanged({ ($0.name, $0.count) }, ==) { (name, count) in
      /**
      Receives every time the tuple differs from the previous one.
      This means it changes when anyone in the tuple changed
      */
      nameLabel.text = name
      countLabel.text = age.description
    }

    ...
  }

}
```

[The details are here!](https://www.notion.so/Verge-a-performant-state-management-architecture-for-iOS-app-987250442b5c4645b816d4d58d27bb07)

## Supports Integrating with RxSwift

Verge supports to integrate with RxSwift that enables to create a stream of `State` and `Activity`.
To activate it, install `VergeRx` module.

## What differences between Flux library are

'store-pattern' is the core-concept of Flux.
Flux works with the multiple restricted rules top of the 'store-pattern'.

![store-pattern](https://user-images.githubusercontent.com/1888355/100537431-07951680-326c-11eb-93bd-4b9246fbeb96.png)

This means we can start using like Flux without using Action, Mutation payload values.  

```swift
// ✌️ no needs to use.
enum Action {
  case increment
  case decrement
}
```

This declarations might be quite big cost of implementation in order to start to use Flux.  
Verge does not have this rules, so we can do like this when we update the state.

```swift
// 🤞 just like this
extension MyStore {
  func increment() {
    commit { 
      $0.count += 1
    }
  }
}

let store: MyStore
store.increment()
```

It can be easy start.  
Of course, we can create the layer to manage strict action and mutation payload on top of the Verge primitive layer.  
Because 'store-pattern' is core-concept of Flux.

--

## Motivation

### Verge focuses use-cases in the real-world

Recently, we could say the unidirectional data flow is a popular architecture such as flux.

### Does store-pattern(flux) architecture have a good performance?

It depends.
The performance will be the worst depends on how it is used.

However, most of the cases, we don't know the app we're creating how it will grow and scales.  
While the application is scaling up, the performance might decrease by getting complexity.  
To keep performance, we need to tune it up with several approaches.  
Considering the performance takes time from the beginning.  
it will make us be annoying to use flux architecture.

### Verge is designed for use from small and supports to scale.

Setting Verge up quickly, and tune-up when we need it.

Verge automatically tune-up and shows us what makes performance badly while development from Xcode's documentation.

For example, Verge provides these stuff to tune performance up.

- Derived (Similar to [facebookexperimental/Recoil](https://github.com/facebookexperimental/Recoil)'s Selector)
- ORM

## Sending volatile events instead of using state

In certain scenarios, event-driven programming is essential for creating responsive and efficient applications. The Verge library's Activity of Store feature is designed to cater to this need, allowing developers to handle events seamlessly within their projects.

The Activity of Store comes into play when your application requires event-driven programming. It enables you to manage events and associated logic independently from the main store management, promoting a clean and organized code structure. This separation of concerns simplifies the overall development process and makes it easier to maintain and extend your application over time.

By leveraging the Activity of Store functionality, you can efficiently handle events within your application while keeping the store management intact. This ensures that your application remains performant and scalable, enabling you to build robust and reliable Swift applications using the Verge library.

```swift
let store: Store<MyState, MyActivity>

store.send(MyActivity.somethingHappend)
```

```swift
store.sinkActivity { (activity: MyActivity) in
  // handle activities.
}
.storeWhileSourceActive()
```

## Installation

## SwiftPM

Verge supports SwiftPM.

## Demo applications

This repo has several demo applications in Demo directory.
And we're looking for your demo applications to list it here!
Please tell us from Issue!

## Thanks

- [Redux](https://redux.js.org/)
- [Vuex](https://vuex.vuejs.org/)
- [ReSwift](https://github.com/ReSwift/ReSwift)
- [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture)

## Author

[🇯🇵 Muukii (Hiroshi Kimura)](https://github.com/muukii)

## License

Verge is released under the MIT license.
