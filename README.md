# Verge

![Data flow](.gitbook/assets/loop-2x.png)

**A Store-Pattern based data-flow architecture.**

Verge provides several packages each use-cases.

* VergeStore
* VergeViewModel
* VergeORM

The concept of VergeStore is inspired by [Redux](https://redux.js.org/) and [Vuex](https://vuex.vuejs.org/).

The characteristics are

* Creating one or more Dispatcher. \(Single store, multiple dispatcher\)
* A dispatcher can have dependencies service needs. \(e.g. API Client, DB\)
* No switch-case to reduce state
* Support Logging \(Commit, Action, Performance monitoring\)



