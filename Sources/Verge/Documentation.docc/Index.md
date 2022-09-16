# ``Verge``

## 🛹 Small start unidirectional data flow

Verge is designed for use from small and supports to scale. Setting Verge up quickly, and tune-up when we need it.

## 🏎 Focus on performance

Does flux have a good performance?The performance will be the worst depends on how it is used.Verge automatically tune-up and shows us how we could gain a performant.

## ⛱ Available in **UIKit** and **SwiftUI**

Verge supports both of UI framework. Especially, it highly supports to update partially UI on UIKit.

## Verge supports small start and scaling up

Verge is a state management library for iOS (UIKit / SwiftUI).Mostly it's based on Flux architecture.Flux architecture is so beautiful and simplified thinking.Although, we need to do several tuning to bring it into a real product.In fact, Flux needs to consider about computing resources.

Verge contains several ideas to do this from Web technologies such as Redux, Vuex, and Recoil.They have very useful techniques to be successful in real-world productions based on the core-concept of Flux.

Verge can be setting it up quickly, and tune performance up when we need it.Verge automatically tune-up as possible and shows us what makes performance badly while development from Xcode's documentation.

## At a glance

A way to create a ViewModel

```swift
final class MyViewModel: StoreComponentType {

  struct State: Equatable {
    var name: String = ""
    var count: Int = 0
  }

  let store: DefaultStore = .init(initialState: .init())

  func myAction() {
    commit {
      $0.name = "Hello, Verge"
    }
  }

  func increment() {
    commit {
      $0.count += 1
    }
  }
}
```

A way to create a customized store

```swift
struct MyState: Equatable {
  var name: String = ""
  var count: Int = 0
}

final class MyStore: Store<MyState, Never> {

  func myAction() {
    commit {
      $0.name = "Hello, Verge"
    }
  }

  func increment() {
    commit {
      $0.count += 1
    }
  }
}
```

### SwiftUI

```swift
struct MyView: View {

  let store: MyViewModel

  var body: some View {
    StateReader(store) { state in
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

### UIKit

```swift
final class MyViewController: UIViewController {

  let viewModel: MyViewModel

  ...

  var cancellable: VergeAnyCancellable?

  init(viewModel: MyViewModel) {

    self.viewModel = viewModel

    self.cancellable = viewModel.sinkState { [weak self] state in
      self?.update(state: state)
    }

  }

  private func update(state: Changes<MyStore.State>) {

    state.ifChanged(\.name) { (name) in
      nameLabel.text = name
    }

    state.ifChanged(\.count) { (age) in
      countLabel.text = age.description
    }

    ...
  }

}
```

## Prepare moving to SwiftUI from now with Verge

SwiftUI's concept is similar to the concept of React, Vue, and Elm.Therefore, the concept of state management will become to be similar as well.

That is Redux or Vuex and more.

Now, almost of iOS Applications are developed on top of UIKit.And We can't say SwiftUI is ready for top production.However, it would change.

It's better to use the state management that fits SwiftUI from now. It's not only for that, current UIKit based applications can get more productivity as well.

## Questions?

We accept your questions about usage of Verge and something else in GitHub Issues.

日本語での質問も大丈夫です
