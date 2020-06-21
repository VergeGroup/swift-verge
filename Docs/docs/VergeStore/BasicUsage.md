---
id: BasicUsage
title: Basic Usage
sidebar_label: Basic Usage
---

This section shows you how we start to use Verge.  
It's very basic usage. You need to read Advanced Usage section if you're considering to use in production.

To understand smoothly about Verge, we need to figure the following domains out.

## Domains

### Store

- A storage object to manage a state and emit activities by the action.
- Store can dispatch actions to itself.

### State

- A type of state-tree that describes the data our feature needs.

### Activity

- A type that describes an activity that happens during performs the action.
- This instance won't be stored in anywhere. It would help us to perform something by event-driven.
- Consider to use this depends on that if can be represented as a state.
- For example, to present alert or notifcitaions by the action.

### Action

- Action runs any operations (sync / async) and commits any mutations to the state of the store.
- Action is described by Swift's method in Store or Dispatcher.

### Dispatcher (Optional)

- A type to dispatch an action to specific store.
- For a large application, to separate the logics each domain.

## Setup a Store

### Define a state

```swift
struct MyState {
  var count = 0
}
```

### Define an activity

```swift
enum MyActivity {
  case countWasIncremented
}
```

:::info
`Activity` is not required type.  
If you don't need to use `Activity`, you can set`Never` in Store's type parameter.
:::

### Define a store

```swift
class MyStore: Store<MyState, MyActivity> {

  init(dependency: Dependency) {
    super.init(initialState: .init(), logger: nil)
  }

}
```

In example, it created a subclass of `Store`. Of course, we can also create an instance from `Store` without subclassing.  
But we can put some dependencies (e.g. API client) with creating a sub-class of `Store`.

:::note When don't use Activity

```swift {1}
class MyStore: Store<MyState, Never> {

}
```

:::

## Add an action

Next, add an action to mutate the state.
Essentially, Verge uses Swift's method to describe an action against enum or struct based action descriptor other Flux library has.
This approach has advantages that adding an action faster and call it naturally and dispatches with a faster way by Swift's native method dispatching system.

- **Better Performance**
  - Swift can perform this action with Swift's method dispatching instead switch-case computing.
- **Returns anything we need**
  - the action can return anything from that action (e.g. state or result)
  - If that action dispatch async operation, it can return `Future` object. (such as Vuex action)

As a future direction, Verge might get a dispatching action system with describing with enum or struct based to run action.  
However, the current approach would be the base system for it.

We're currently researching that needs.

```swift {3-7}
class MyStore: Store<MyState, MyActivity> {

  func incrementCount() {
    commit {
      $0.count += 1
    }
  }

}
```

Yes, this point is most different with Redux. we could say it close to Vuex.<br/>
Store knows what the application's needs.

To mutate the state, we use `commit` method.  
the argument inside commit's closure is `inout State`, you can modify it anything but you can't put the asynchronous operations.  
If you need to do this, call `commit` from the asynchronous operation. like this:

```swift
func incrementCount() {
  DispatchQueue.main.async {
    commit {
      $0.count += 1
    }
  }
}
```

:::tip You can define actions aware from the Store
Using `Dispatcher`, you can manage the set of actions aware from the store.
:::

### Run the action

For example, call that action.

```swift
let store = MyStore(...)
store.incrementCount()
```

## Send an activity from the action

```swift
func incrementCount() {
  ...
  send(.countWasIncremented)
}
```

## Binding the state with UI

### Use the store in SwiftUI

To bind the state with `View`, it uses `UseState`.  
Since `Store` is also compatible with `ObservableObject`, we can declare `@ObservedObject` or `@EnviromentObject`.

`UseState` provides several options to reduce no changes updates.  
Please check it out from Xcode.

```swift
struct MyView: View {

  let store: MyStore

  var body: some View {
    UseState { state in
      Text(state.name)
    }
    .onReceive(session.store.activityPublisher) { (activity) in
      ...
    }
  }
}
```

### Use the store in UIKit

In UIKit, UIKit doesn't work with differentiating.  
To keep better performance, we need to set a value if it's changed.

Verge publishes an object that contains previous state and latest state, `Changes` object would be so helpful to check if a value changed.

```swift
class ViewController: UIViewController {

  let store: MyStore

  var cancellable: VergeAnyCancellable?

  init(store: MyStore) {
    ...

    self.cancellable = store.sinkChanges { [weak self] changes in
      self?.update(changes: changes)
    }

  }

  private func update(changes: Changes<MyStore.State>) {

    changes.ifChanged(\.name) { (name) in
      nameLabel.text = name
    }

    changes.ifChanged(\.age) { (age) in
      ageLabel.text = age.description
    }

  }
}
```
