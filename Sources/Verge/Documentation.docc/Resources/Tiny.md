# Yet another super tiny store pattern with Verge/Tiny

In fact, `store-pattern` doesn't need something library to run.
The actually necessary thing is **the changing detection in UIKit.**

Without the changing detection, the code is here.
There is no dependencies.

```swift
class MyView: UIView {
  private struct State {
    var count: Int = 0
  }
  
  private var state: State {
    didSet {
      update(with: state)
    }
  }

  private func update(with state: State) {
    ...
  }
}
```

Next, we focus on `update(with:)` method.
Try to simulate updating the label's value.

```swift
private func update(with state: State) {
  myLabel.text = "\(state.count)"
}
```

As you can see, you will think you want to prevent updating the value until the value changed.

## Use Verge.Tiny module to prevent the duplicated updating.

With installing `Verge/Tiny` module, we can write up like followings.

```swift
private func update(with state: State) {
  associatedProperties.doIfChanged(state.count) { count in 
    myLabel.text = "\(count)"
  }
}
```

`associatedProperties` is a storage of the values that associated with its owner object(NSObject).

`doIfChanged` gets the location of the code that would be a unique key by composition in the storage.

With this functions, we can get a filter anywhere in the object.
However, this function might affect code readabilities in Swift. 
Please carefully using this.

We recommend you gather those operations into one place.
