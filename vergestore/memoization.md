# Selector and Memoization

Memoization will be needed in some cases.

* The cost of computing value from State is expensive.

```swift
public final class MemoizeGetter<Source, Destination>
```

```swift
struct State {

  var count: Int = 0

}

let getter = store.makeMemoizeGetter(
  equality: .init(selector: { $0.count },
  equals: ==)
  ) { (state) -> Int in

  state.count * 2

}

getter.value
```

