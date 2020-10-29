---
id: state
title: State - a data describes the current state of the app
sidebar_label: State
---

## Using single state tree (Not enforced)

VergeStore uses a **single state-tree. (Recommended)** That means an object contains all of the application's state. With this, we can get to achieve **"single source of truth"**

That state is managed by **Store**. It process updating the state and notify updated events to the subscribers.

:::info
💡 VergeStore DOES support multiple state-tree as well. Depending on the case, we can create another Store instance.
:::

## Add a computed property

```swift
struct State {

  var count: Int = 0

  var countText: String {
    return count.description
  }

}
```

:::tip To get better performance
As possible, it brings better performance with getting `Equatable` on the State.
:::

## Extending properties that computes a value from stored property.

Although in some of cases, the cost of computing might be higher which depends on how it create the value from stored properties.

There is `ExtendedStateType`.  
This provies us to get more stuff that **increases performance** and productivity.

## Attention to Normalization

**If you put the data that has relation-ship or complicated structure into state tree, it would be needed normalization to keep performance. Please check VergeORM module**

[About more Normalization and why we need to do this](https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape/)
