---
id: dispatcher
title: Dispatcher - performs a mutation from away the store
sidebar_label: Dispatcher
---

## What Dispatcher does

Dispatcher allows us to update the state of the Store from away the store and to manage dependencies to create Mutation.

**Dispatcher does not have own state. Dispatcher runs with Store.**

**Example**

```swift
final class MyDispatcher: MyStore.Dispatcher {

}

let store = MyStore()
let dispatcher = MyDispatcher(targetStore: store)
```

> 💡
> Actual type of MyStore.Dispatcher is DispatcherBase<State, Never> It is a typealias to write shortly.

Managing dependencies code

```swift
final class MyDispatcher: MyStore.Dispatcher {

  let apiClient: APIClient

  init(apiClient: APIClient, targetStore: Store<RootState>) {
    self.apiClient = apiClient
    super.init(targetStore: targetStore)
  }

  // an example of fetching data and commit
  func fetchData() {
    apiClient.fetchData { [weak self] result in
      switch result {
      case .success(let data):
        let items = data.encode(...)
        self?.commit {
          $0.fetchedItems = items
        }
      case .failure(let error):
      // handles error
      }
    }
  }
}

let store = MyStore()
let apiClient = APIClient()
let dispatcher = MyDispatcher(apiClient: apiClient, target: store)

dispatcher.fetchData()
```

## Create multiple Dispatcher

![image](https://user-images.githubusercontent.com/1888355/82821486-28586a00-9edf-11ea-8c98-062eafcc4f16.png)

We can create multiple Dispatcher each use-cases.

For example, In case the timing of getting dependencies that to be needed by run Action or Mutation is different, it will not be easy to define in the one dispatcher. We will have the optional properties in there.

In this case, creating multiple dispatchers will help us. Define the dispatcher each the timing of getting dependencies.

```swift
class LoggedInDispatcher: MyStore.Dispatcher {

  let apiClientNeedsAuthToken = ...
  ...
}

class LoggedOutDispatcher: DispatcherBase<RootState> {

  let apiClientWithoutAuthToken = ...
  ...
}

let store = MyStore()
let loggedInDispatcher = LoggedInDispatcher(...)
let loggedOutDispatcher = LoggedOutDispatcher(...)
```

## Create scoped dispatcher

`Dispatcher` supports to commit specified scope of the state.
It helps to mutate with focused on a part of the large state tree.

Here is a sample state that assuming a large app.

- AppState - db: Database - loggedIn: LoggedInState - myInfo: MyInfoState - loggedOut: LoggedOutState

We have `database`, `logged-in` and `logged-out state`.
`database` means normalized state shape to manage many entities.

And then let's think about the case of creating a dispatcher focuses on the logged-in state.

```swift
final class LoggedInService: Store.ScopedDispatcher<LoggedInState> {

  init(store: Store) {
    super.init(targetStore: store, scope: \.loggedIn)
  }

  func someOperation() {
    commit { (state: LoggedInState) in

    }
  }
}
```

In LoggedInService, commit mutates `LoggedInState` directly.
Like this, we can create a dispatcher each use-cases.

### Detaching to other tree

Just in case, ScopedDispatcher supports also mutating on other state tree.

**Moving on more deeper**

```swift
final class LoggedInService: Store.ScopedDispatcher<LoggedInState> {

  func detachingOperation() {
    let myInfo = detached(by: \.myInfo)
    myInfo.commit { (state: MyInfo) in

    }
  }
}
```

**Detaches from root**

```swift
final class LoggedInService: Store.ScopedDispatcher<LoggedInState> {

  func detachingOperation() {
    let db = detached(from: \.db)
    db.commit { (state: Database) in

    }
  }
}
```
