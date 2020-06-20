---
id: utilities
title: Utilities
sidebar_label: Utilities
---

## `Fragment<State>`

### Fragment helps compare if state was updated without Equatable

‌In a single state tree, comparing for reducing the number of updates would be most important for keep performance. However, implementing Equatable is not easy basically. Instead, adding a like flag that indicates updated itself, it would be easy

### Actually, we need to get to flag that means different, it no need to be equal

Actually, we need to get to flag that means **different**, it no need to be **equal**.

### Fragment does embed state with versioning

`Fragment` manages the version of itself, the version will increment each modification. however, it can't get how exactly modified from the modification. and Fragment returns equality by comparing their version.
That is the reason why Fragment may return boolean that false negative.
If Fragment returns equality false, it may be actually equals.

```swift
struct YourState {
  var name: String = ...
}

struct AppState: Equatable {

  @Fragment var yourState YourState = .init()
}

> Since `Fragment` enables `Equatable` in yourState, AppState can be Equatable with synthesizing.

appState.yourState.name

// get unique value that indicates updated to compare with previous value.
// this value would be updated on every mutation of this tree.
appState.$yourState.version
```

## assign - assignee

In specific cases, it needs to projects value from others into the Store.

- Having multiple stores and needs to be integrated with each other.
- Having other reactive streams and needs to be stored the value in the Store

In these cases, `assign` and `assignee` operators help.

Assigns the value from other Store's state to Store's state.

```swift
let store1 = Store()
let store2 = Store()

store1
  .derived(.map(\.count))
  .assign(to: store2.assignee(\.count))
```

Assigns the value from the Publisher to Store's state.

```swift
let publisher: Combine.Publisher<Int>
let store2 = Store()

publisher
  .assign(to: store2.assignee(\.count))
```
