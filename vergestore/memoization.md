# Selector and Memoization

## MemoizeSelector

Memoization will be needed in some cases.

* The cost of computing value from State is expensive.

```swift
public final class MemoizeSelector<Input, Output>
```

```swift
struct State {
       
  var count: Int = 0

}
  
let selector = store.selector(
  equality: .init(selector: { $0.count },
  equals: ==)
  ) { (state) -> Int in
  
  state.count * 2
  
}

selector.value
```

## AnySelector

AnySelector erases Input type and displays only Output type.

```swift
let selector: MemoizeSelector<Input, Output>

let anySelector: AnySelector<Output> = selector.asAny()
```

