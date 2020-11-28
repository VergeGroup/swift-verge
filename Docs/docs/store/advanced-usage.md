---
id: advanced-usage
title: Advanced usage
sidebar_label: Advanced usage
---

## To keep performance and scalability

## Adding a cachable computed property in a State

We can add a computed property in a state to get a derived value with stored property,  
and that computed property works fine as well other stored property.

```swift
struct MyState {
  var items: [Item] = [] {

  var itemsCount: Int {
    items.count
  }
}
```

However, this patterns might cause an expensive cost of operation depends on how they computes.  
To solve it, Verge arrows us to define the computed property with another approach.

```swift
struct MyState: ExtendedStateType {

  var name: String = ...
  var items: [Int] = []

  struct Extended: ExtendedType {
    let filteredArray = Field.Computed<[Int]> {
      $0.items.filter { $0 > 300 }
    }
    .ifChanged(selector: \.largeArray)
  }
}
```

```swift
let store: MyStore

store.changes.computed.filteredArray
```

This defined computed array calculates only if changed specified value.  
That condition to re-calculate is defined with `.ifChanged` method in the example code.

And finally, it caches the result by first-time access and it returns cached value until if the source value changed.

## Making a slice of the state (Selector)

We can create a slice object that derives a data from the state.

```swift
let derived: Derived<Int> = store.derived(.map(\.count))

// take a value
derived.value

// subscribe a value changes
derived.sinkChanges { (changes: Changes<Int>) in
}
```

## Creating a Dispatcher

Store arrows us to define an action in itself, that might cause gain complexity in supporting a large application.  
To solve this, Verge offers us to create an object that dispatches an action to the store.  
We can separate the code of actions to keep maintainability.  
that also help us to manage a different type of dependencies.

For example, the case of those dependencies different between logged-in and logged-out.

```swift
class MyDispatcher: MyStore.Dispatcher {
  func moreOperation() {
    commit {
      ...
    }
  }
}
```

```swift
let store: MyStore
let dispatcher = MyDispatcher(target: store)

dispatcher.moreOperation()
```
