# VergeStore Core Concepts

![](../.gitbook/assets/loop-2x%20%281%29.png)

**A Store-Pattern based data-flow architecture.**

The concept of VergeStore is inspired by [Redux](https://redux.js.org/) and [Vuex](https://vuex.vuejs.org/).

The characteristics are

* **Creates one or more Dispatcher. \(Single store, multiple dispatcher\)**
* **A dispatcher can have dependencies service needs. \(e.g. API Client, DB\)**
* **No switch-case to handle Mutation and Action**
* **Emits any events that isolated from State It's for SwiftUI's onReceive\(:\)**
* **Supports Logging \(Commit, Action, Performance monitoring\)**
* **Supports Middleware**

