# ``Verge/DispatcherType``

Dispatcher allows us to update the state of the Store from away the store and to manage dependencies to create Mutation.

- Dispatcher is
    - it is an object.
    - it does not have its own state.
    - it can run commit with specified store’s state.
    - it can have a temporary dependency to commit the mutation.
    - it can focus on specified tree of the state.

Here is an example store, in this section we create a dispatcher to commit the mutation into this Store:

```swift
struct State: StateType {
  var count: Int = 0
}

enum Activity {
  case happen
}

final class MyStore: Store<State, Activity> {
  ...
}
```

MyStore has a typealias to define a dispatcher:

```swift
MyStore.Dispatcher
```

<aside>
💡 Actual type of `MyStore.Dispatcher` is `DispatcherBase<State, Never>` It is a typealias to write shortly.

</aside>

## Define a dispatcher

Let’s take a look how we create a dispatcher with using the typealias:

```swift
final class MyDispatcher: MyStore.Dispatcher {

}
```

Now we can create an instance of `MyDispatcher`:

```swift
let store = MyStore()
let dispatcher = MyDispatcher(targetStore: store)
```

## Add an action to the dispatcher

Next, we add an action that commits a mutation:

```swift
final class MyDispatcher: MyStore.Dispatcher {
  func doSomething() {
    commit {
      $0.count = 100
    }
  }
}
```

```swift
let store: MyStore
let dispatcher: MyDispatcher

dispatcher.doSomething()

store.state.count == 100 // true
```

## Add a dependency to dispatch an action

In the case of large applications, we need to handle many dependencies to run the application.
For example, if we use multiple HTTP clients.

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
```

To use this:

```swift
let store = MyStore()
let apiClient = APIClient()
let dispatcher = MyDispatcher(apiClient: apiClient, target: store)

dispatcher.fetchData()
```

Now we can handle multiple kinds of dependencies each it fits itself life-time.
For example, if you have a restriction that some dependencies can be created only the user’s logging-in, you can create a dispatcher what is for.

Next section explains the detail.

## Create multiple Dispatcher

![https://user-images.githubusercontent.com/1888355/82821486-28586a00-9edf-11ea-8c98-062eafcc4f16.png](https://user-images.githubusercontent.com/1888355/82821486-28586a00-9edf-11ea-8c98-062eafcc4f16.png)

Creating a dispatcher does not have the restriction of the number of instances or types.
This means that it allows us to define a dispatcher and instantiate an instance of the dispatcher to fill the use-case.

For example, In case the timing of getting dependencies that to be needed by run Action or Mutation is different, it’s not easy to have them in the one dispatcher with type-safety. they must be optional types.

Using creating multiple dispatchers techniques solves this case by defines the dispatcher each the timing of getting dependencies.

```swift
class LoggedInDispatcher: MyStore.Dispatcher {

  let apiClientNeedsAuthToken: APIClient = ...
  ...
}

class LoggedOutDispatcher: MyStore.Dispatcher {

  let apiClientWithoutAuthToken: APIClient = ...
  ...
}
```

```swift
let store = MyStore()
let loggedInDispatcher = LoggedInDispatcher(...)
let loggedOutDispatcher = LoggedOutDispatcher(...)
```

The application will create `LoggedInDispatcher` when the user is logged-in and deinitialize `LoggedOutDispatcher`.

## Create scoped dispatcher

As another feature what Dispatcher provides, It supports to commit specified scope of the state which helps to mutate with focus on a part of the large state tree.

Here is a sample state that assuming a large app.

- AppState (MyStore)
    - db: Database
    - loggedIn: LoggedInState
        - myInfo: MyInfoState
    - loggedOut: LoggedOutState

We have `database`, `logged-in` and `logged-out state`. `database` means normalized state shape to manage many entities.

In previous section, that explained we can multiple dispatchers each the user’s state.
However, it needs to the full path to mutate where we need to mutate.

```swift
class LoggedInDispatcher: MyStore.Dispatcher {

  func performA() {
    commit {
      $0.loggedIn.xxx
    }
  }

  func performB() {
    commit {
      $0.loggedIn.xxx
    }
  }

  func performC() {
    commit {
      $0.loggedIn.xxx
    }
  }
}
```

LoggedInDispatcher will often dispatch some action for logged-in-state.
But it calls everytime `$0.loggedIn`, it seems a little bit verbosity.

That will be solved by `ScopedDispatcher`. It will move on target tree of the state when it dispatch the action.

The following code shows how we could create a `ScopedDispatcher`:

```swift
final class LoggedInService: MyStore.ScopedDispatcher<LoggedInState> {

  init(store: Store) {
    super.init(targetStore: store, scope: \.loggedIn)
  }

  func someOperation() {
    commit { (state: LoggedInState) in
      ...
    }
  }
}
```

In LoggedInService, commit mutates `LoggedInState` directly. Like this, we can create a dispatcher each use-cases.

### Detaching to other tree

Just in case, `ScopedDispatcher` supports also mutating on other state tree.

**Moving on more deeper**

```swift
final class LoggedInService: MyStore.ScopedDispatcher<LoggedInState> {

  func detachingOperation() {
    let myInfo = detached(by: \.myInfo)
    myInfo.commit { (state: MyInfo) in

    }
  }
}
```

**Detaches from root**

```swift
final class LoggedInService: MyStore.ScopedDispatcher<LoggedInState> {

  func detachingOperation() {
    let db = detached(from: \.db)
    db.commit { (state: Database) in

    }
  }
}
```
