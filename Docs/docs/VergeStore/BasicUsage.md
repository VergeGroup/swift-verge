---
id: BasicUsage
title: BasicUsage
sidebar_label: BasicUsage
---

## 🍐 Basic Usage

To start to use Verge in our app, we use these domains:

- **State**
  - A type of state-tree that describes the data our feature needs.
- **Activity**
  - A type that describes an activity that happens during performs the action.
  - This instance won't be stored in anywhere. It would help us to perform something by event-driven.
  - Consider to use this depends on that if can be represented as a state.
  - For example, to present alert or notifcitaions by the action.
- **Action**
  - Just a method that a store or dispatcher defines.
- **Store**
  - A storage object to manage a state and emit activities by the action.
  - Store can dispatch actions to itself.
- **Dispatcher (Optional)**

  - A type to dispatch an action to specific store.
  - For a large application, to separate the logics each domain.

**Setup a Store**

Define a state

```swift
struct MyState {
  var count = 0
}
```

Define an activity

```swift
enum MyActivity {
  case countWasIncremented
}
```

Define a store that uses defined state and activity

```swift
class MyStore: Store<MyState, MyActivity> {

  init(dependency: Dependency) {
    super.init(initialState: .init(), logger: nil)
  }

}
```

We can create an instance from `Store` but we can put some dependencies (e.g. API client) with creating a sub-class of `Store`.

(If you don't need Activity, you can set `Never` there.)

And then, add an action in the store

```swift
class MyStore: Store<MyState, MyActivity> {

  init(dependency: Dependency) {
    super.init(initialState: .init(), logger: nil)
  }

  func incrementCount() {
    commit {
      $0.count += 1
    }
  }
}
```

Yes, this point is most different with Redux. it's close to Vuex.<br/>
Store knows what the application's needs.

For example, call that action.

```swift
let store = MyStore(...)
store.incrementCount()
```

There are some advantages:

- **Better Performance**
  - Swift can perform this action with Swift's method dispatching instead switch-case computing.
- **Returns anything we need**

  - the action can return anything from that action (e.g. state or result)
  - If that action dispatch async operation, it can return `Future` object. (such as Vuex action)

Perform a commit asynchronously

```swift
func incrementCount() {
  DispatchQueue.main.async {
    commit {
      $0.count += 1
    }
  }
}
```

Send an activity from the action

```swift
func incrementCount() {
  commit {
    $0.count += 1
  }
  send(.countWasIncremented)
}
```

**Use the store in SwiftUI**

(Currently, Verge's development is focusing on UIKit.)

```swift
struct MyView: View {

  @EnvironmentObject var store: MyStore

  var body: some View {
    Group {
      Text(store.state.name)
      Text(store.state.age)
    }
    .onReceive(session.store.activityPublisher) { (activity) in
      ...
    }
  }
}
```

**Use the store in UIKit**

In UIKit, UIKit doesn't work with differentiating.<br/>
To keep better performance, we need to set a value if it's changed.

Verge publishes an object that contains previous state and latest state, Changes object would be so helpful to check if a value changed.

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
