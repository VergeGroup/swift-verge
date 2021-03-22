> Verge is giving the power of state-management in [muukii/Pixel](https://github.com/muukii/Pixel/pull/53) v2 development!

<p align="center">
  <a href="https://vergegroup.org">
<img width="128" alt="VergeIcon" src="https://user-images.githubusercontent.com/1888355/85241314-5ac19c80-b476-11ea-9be6-e04ed3bc6994.png">
    </a>
</p>


<h1 align="center">Verge.swift</h1>
<p align="center">
  <b>📍An effective state management architecture for iOS - SwiftUI and UIKit📍</b><br/>
<sub>_ An easier way to get unidirectional data flow _</sub><br/>
<sub>_ Supports concurrent processing _</sub><br/>
</p>

<p align="center">
 <a href="https://vergegroup.org">
   <b>📖 Docs and tips</b>
  </a>
  </p>

<p align="center">
<img alt="swift5.3" src="https://img.shields.io/badge/swift-5.3-ED523F.svg?style=flat"/>
<img alt="Tests" src="https://github.com/VergeGroup/Verge/workflows/Tests/badge.svg"/>
<img alt="cocoapods" src="https://img.shields.io/cocoapods/v/Verge" />
</p>

<p align="center">
  <a href="https://spectrum.chat/verge-swift">
    <img alt="Join the community on Spectrum" src="https://withspectrum.github.io/badge/badge.svg" />
  </a>
</p>

## Requirements

* Swift 5.3 +
* @available(iOS 10, macOS 10.13, tvOS 10, watchOS 3)
* UIKit
* SwiftUI

## Verge is not Flux, it's store-pattern and super powerful.

Verge is a performant store-pattern based state management library for iOS.

Please see the website: https://vergegroup.org

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

## Mininal usage exmaple - In UIView - UIViewController

State-management is everywhere, you can put a store and start state-management.

```swift
final class CropViewController: UIViewController {

  private struct State: Equatable {
    var isSelectingAspectRatio = false
  }
  
  private let store: Store<State, Never> = .init(initialState: .init())

  private var subscriptions = Set<VergeAnyCancellable>()

  override public func viewDidLoad() {
    
    store.sinkState { [weak self] state in 
      guard let self = self else { return }
      
      state.ifChanged(\.isSelectingAspectRatio) { value in 
        //
      }

    }
    .store(in: &subscriptions)
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
  let store: DefaultStore = .init(initialState: .init())

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

```swift
struct MyView: View {

  let store: MyViewModel

  var body: some View {
    // ✅ Uses `StateReader` to read the state this clarifies where components need the state.
    StateReader(store).content { state in
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

`StateReader` supports to derive a part of the state like below.

```swift
StateReader(store.derived(.map(\.nested))).content { state in
  ...
}
```

> 🤲 Verge has not gathered enough experience in SwiftUI. Please let us know your ideas that improve Verge using in SwiftUI! (in Discussions or Issues)


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

This means we can start using like Flux without using Action, Muation payload values.  

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
Of cource, we can create the layer to manage strict action and mutation payload on top of the Verge primitive layer.  
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

### Supports volatile events

We use an event as `Activity` that won't be stored in the state.  
This concept would help us to describe something that is not easy to describe as a state in the client application.

<img width=513 src="https://user-images.githubusercontent.com/1888355/85392055-fc83df00-b585-11ea-866d-7ab11dfa823a.png" />

## Installation

### CocoaPods

**Verge** (core module)

```ruby
pod 'Verge/Store'
```

**VergeORM**

```ruby
pod 'Verge/ORM'
```

**VergeRx**

```ruby
pod 'Verge/Rx'
```

These are separated with subspecs in Podspec.<br>
After installed, these are merged into single module as `Verge`.

To use Verge in your code, define import decralation following.

```swift
import Verge
```

## SwiftPM

Verge supports also SwiftPM.

## Questions

Please feel free to ask something about this library!  
I can reply to you faster in Twitter.

日本語での質問も全然オーケーです😆  
Twitterからだと早く回答できます⛱

[Twitter](https://twitter.com/muukii_app)

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
