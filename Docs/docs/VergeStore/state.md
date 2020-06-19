---
id: state
title: State - a data describes the current state of the app
sidebar_label: State
---

## Using single state tree (Not enforced)

VergeStore uses a **single state-tree. (Recommended)** That means an object contains all of the application's state. With this, we can get to achieve **"single source of truth"**

That state is managed by **Store**. It process updating the state and notify updated events to the subscribers.

> 💡 VergeStore does support multiple state-tree as well. Depending on the case, we can create another Store instance.

## Add a computed property

```swift
struct State: StateType {

  var count: Int = 0

  var countText: String {
    return count.description
  }

}
```

Although in some of cases, the cost of computing might be higher which depends on how it create the value from stored properties.

## StateType protocol helps to modify

VergeStore provides `StateType` protocol as a helper.

It will be used in State struct that Store uses. `StateType` protocol is just providing the extensions to mutate easily in the nested state.

```swift
public protocol StateType {
}

extension StateType {

  public mutating func update<T>(target keyPath: WritableKeyPath<Self, T>, update: (inout T.Wrapped) throws -> Void) rethrows where T : VergeStore._VergeStore_OptionalProtocol

  public mutating func update<T>(target keyPath: WritableKeyPath<Self, T>, update: (inout T) throws -> Void) rethrows

  public mutating func update(update: (inout Self) throws -> Void) rethrows
}
```

> There is `ExtendedStateType` from StateType.
> This provies us to get more stuff that increases performance and productivity.

## Normalization

**If you put the data that has relation-ship or complicated structure into state tree, it would be needed normalization to keep performance. Please check VergeORM module**

[About more Normalization and why we need to do this](<[https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape/](https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape/)>)
