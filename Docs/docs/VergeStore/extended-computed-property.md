---
id: extended-computed-property
title: Extended Computed property on the State - Memoization
sidebar_label: Memoization
---

## Overview

A declaration to add a computed-property into the state. It helps to add a property that does not need to be stored-property. It's like Swift's computed property like following:

```swift
struct State {
 var items: [Item] = [] {

 var itemsCount: Int {
   items.count
 }
}
```

However, this Swift's computed-property will compute the value every state changed. It might become a serious issue on performance.

Compared with Swift's computed property and this, this does not compute the value every state changes, It does compute depend on specified rules.
That rules mainly come from the concept of Memoization.

Example code:

```swift
struct State: ExtendedStateType {

 var name: String = ...
 var items: [Int] = []

 struct Extended: ExtendedType {

   static let instance = Extended()

   let filteredArray = Field.Computed<[Int]> {
     $0.items.filter { $0 > 300 }
   }
   .dropsInput {
     $0.noChanges(\.items)
   }
 }
}
```

```swift
let store: MyStore<State, Never> = ...

let state = store.state

let result: [Int] = state.computed.filteredArray
```

## Instruction

### Computed Property on State

States may have a property that actually does not need to be stored property. In that case, we can use computed property.

Although, we should take care of the cost of the computing to return value in that. What is that case? Followings explains that.

:::info
Computed concept is inspired from Vuex Getters. [https://vuex.vuejs.org/guide/getters.html](https://vuex.vuejs.org/guide/getters.html)
:::

For example, there is itemsCount.

```swift
struct State {
  var items: [Item] = []

  var itemsCount: Int = 0
}
```

In order to become itemsCount dynamic value, it needs to be updated with updating items like this.

```swift
struct State {
  var items: [Item] = [] {
    didSet {
      itemsCount = items.count
    }
  }

  var itemsCount: Int = 0
}
```

We got it, but we don't think it's pretty simple. Actually we can do this like this.

```swift
struct State {
  var items: [Item] = [] {

  var itemsCount: Int {
    items.count
  }
}
```

With this, it did get to be more simple.

```swift
struct State {
  var items: [Item] = []

  var processedItems: [ProcessedItem] {
    items.map { $0.doSomeExpensiveProcessing() }
  }
}
```

As an example, Item can be processed with the something operation that takes expensive cost. We can replace this example with filter function.

This code looks is very simple and it has got data from source of truth. Every time we can get correct data. However we can look this takes a lot of the computing resources. In this case, it would be better to use didSet and update data.

```swift
struct State {
  var items: [Item] = [] {
    didSet {
      processedItems = items.map { $0.doSomeExpensiveProcessing() }
    }
  }

  var processedItems: [ProcessedItem] = []
}
```

However, as we said, this approach is not simple. And this can not handle easily a case that combining from multiple stored property. Next introduces one of the solutions.

## Extended Computed Properties

VergeStore has a way of providing computed property with caching to reduce taking computing resource.

Keywords are:

- `ExtendedStateType`
- `ExtendedType`
- `Field.Computed<T>`

Above State code can be improved like following.

```swift
struct State: ExtendedStateType {

  var name: String = ...
  var items: [Int] = []

  struct Extended: ExtendedType {

    static let instance = Extended()

    let filteredArray = Field.Computed<[Int]> {
      $0.items.filter { $0 > 300 }
    }
    .dropsInput {
      $0.noChanges(\.items)
    }
  }
}
```

To access that computed property, we can do the followings:

```swift
let store: MyStore<State, Never> = ...

let state = store.state

let result: [Int] = state.computed.filteredArray
```

`store.computed.filteredArray` will be updated only when items updated. Since the results are stored as a cache, we can take value without computing.

Followings are the steps describes when it computes while paying the cost.

```swift
let store: MyStore<State, Never> = ...

// It computes
store.state.computed.filteredArray

// no computes because results cached with first-time access
store.state.computed.filteredArray

// State will change but no affects items
store.commit {
  $0.name = "Muukii"
}

// no computes because results cached with first-time access
store.state.computed.filteredArray

// State will change with it affects items
store.commit {
  $0.items.append(...)
}

// It computes new value
store.state.computed.filteredArray
```
