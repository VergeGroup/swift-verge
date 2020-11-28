---
id: migrate-from-classic
title: Migrate from VergeClassic
sidebar_label: Migrate from VergeClassic
---

For the users who using VergeClassic, recommend updating to new Verge.
Here shows most easy way to get it.
Here is typical ViewModel that using `VergeType`

```swift
public final class ViewModel : VergeType {

  public enum Activity {

  }

  public struct State {

    var state1: String = ""
    var state2: String = ""
    var state3: String = ""
  }

  public let state: Storage<ViewModel.State>

  public init() {
    self.state = .init(.init())
  }

  func setSomeData() {

    commit { s in
      s.state1 = "hello"
    }
  }
}
```

## Migrate State Container (ViewModel)

To be up to date, we can use StoreWrapperType.
Overall, it's just changing to store from storage which manage current state.

```swift
public final class ViewModel : StoreWrapperType {

  public enum Activity {

  }

  public struct State: Equatable {

    var state1: String = ""
    var state2: String = ""
    var state3: String = ""
  }

  public let store: DefaultStore

  public init() {
    self.store = .init(initialState: .init(), logger: nil)
  }

  func setSomeData() {

    commit { s in
      s.state1 = "hello"
    }
  }
}
```

:::info
State type should have Equatable if it's possible.
It gains better performance on Derived.
:::

:::danger
dispatch has been obsoleted.
Instead, method means dispatch commit
:::

## Migrate how subscribing the state and activity

### With plain style

Get or subscribe a value with no any reactive frameworks dependency.

```swift
let _: ViewModel.State = viewModel.primitiveState

let _: Changes<ViewModel.State> = viewModel.state

viewModel.sinkState { (changes: Changes<ViewModel.State>) in

}

viewModel.sinkActivity { (activity: ViewModel.Activity) in

}
```

### With RxSwift

```swift
let _: Observable<Changes<ViewModel.State>> = viewModel.rx.stateObservable()

let _: Signal<ViewModel.Activity> = viewModel.rx.activitySignal
```

### With Combine

```swift
let _: AnyPublisher<ViewModel.State, Never> = viewModel.statePublisher()
let _: EventEmitter<ViewModel.Activity>.Publisher = viewModel.activityPublisher
```
