# Verge - Store (SwiftUI / UIKit) (Planning v6.0.0)

Latest released Verge => [`master` branch](https://github.com/muukii/Verge/tree/master)

<img src="VergeStore@2x.png" width=966/>

## Concept

The concept of VergeStore is inspired by [Redux](https://redux.js.org/) and [Vuex](https://vuex.vuejs.org/).

The characteristics are

- Creating one or more Dispatcher.
- A dispatcher can have dependencies service needs. (e.g. API Client, DB)

### Store

### Mutation

The only way to actually change state in a Verge store is by committing a mutation.
Define a function that returns Mutation object. That expresses that function is Mutation

Mutation object is simple struct that has a closure what passes current state to change it.

> Mutation does not run asynchronous operation.

### Action

Action is similar to Mutation.
Action can contain arbitrary asynchronous operations.

To commit Mutations inside Action, Use context.commit.

### Dispatcher

## Utils

## References

## Normalized State Shape

[https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape](https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape)

## Installation

Currently it supports only CocoaPods.

In Podfile

```
pod 'VergeStore'
```

## Author

Hiroshi Kimura (Muukii) <muukii.app@gmail.com>
