# 🌟 Changes from State

## Update UI from State

In subscribing the state and binding UI, it's most important to reduce the meaningless time to update UI.

What things are the meaningless? that is the update UI which contains no updates.

Basically, we can do this like followings

```swift
func updateUI(newState: State) {
  if self.label.text != newState.name {
    self.label.text = newState.name/
  }
}
```

Although, this approach make the code a little bit complicated by increasing the code to update UI.

## Update UI when only the state changed

Store provides **Changes&lt;State&gt;** object.  
It provides some functions to get the value from state with condition.

```swift
let store: Store<MyState, Never>

let changes: Changes<MyState> = store.changes

changes.ifChanged(\.name) { name in
  // called only name changed
}
```



## Subscribing the state

```swift
class ViewController: UIViewController {

  var subscriptions = Set<UntilDeinitCancellable>()
  
  let store: MyStore<MyState, MyActivity> 

  override func viewDidLoad() { 
  
    super.viewDidLoad()
  
    store.subscribeStateChanges { [weak self] (changes) in
      // it will be called on the thread which committed
      self?.update(changes: changes)
    }
    .store(in: &subscriptions)
  }
  
  private func update(changes: Changes<MyState> {
    changes.ifChanged(\.name) { name in
      // called only name changed
    }
    ...
  }

```

