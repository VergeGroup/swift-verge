# 🆙 Migrate from VergeClassic

For the users who using VergeClassic, recommend updating to new Verge.  
Here shows most easy way to get it.

Here is typical ViewModel that using **VergeType**

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

## Migrate State Container \(ViewModel\)

To be up to date, we can use **StoreWrapperType.**  
Overall, it's just changing to store from storage which manage current state.

{% tabs %}
{% tab title="Sample 1" %}
```swift
public final class ViewModel : StoreWrapperType {
              
  public enum Activity {
    
  }
  
  public struct State: StateType {
    
    var state1: String = ""
    var state2: String = ""
    var state3: String = ""
  }
  
  public let store: Store<State, Activity>
  
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
{% endtab %}

{% tab title="Sample 2" %}
```swift
public final class ViewModel : StoreWrapperType {
  
  public enum Activity {
    
  }
  
  public struct State: StateType {
    
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
{% endtab %}
{% endtabs %}

## Migrate how subscribing the state and activity

### With plain style

Get or subscribe a value with no any reactive frameworks dependency.

```swift
let _: ViewModel.State = viewModel.state
          
let _: Changes<ViewModel.State> = viewModel.changes

viewModel.subscribeStateChanges { (changes: Changes<ViewModel.State>) in
  
}

viewModel.subscribeActivity { (activity: ViewModel.Activity) in
  
}
```

### With RxSwift

```swift
let _: Observable<Changes<ViewModel.State>> = viewModel.rx.changesObservable
    
let _: Observable<ViewModel.State> = viewModel.rx.stateObservable

let _: Signal<ViewModel.Activity> = viewModel.rx.activitySignal
```

### With Combine

```swift
let _: AnyPublisher<ViewModel.State, Never> = viewModel.statePublisher
let _: AnyPublisher<ViewModel.State, Never> = viewModel.changesPublisher
let _: EventEmitter<ViewModel.Activity>.Publisher = viewModel.activityPublisher
```

