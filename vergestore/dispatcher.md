# Dispatcher - Perform Mutation / Action

Dispatcher's needs is **to update the state that Store manages** and to **manage dependencies to create Mutation and Action**

**Simple example**

```swift
class MyDispatcher: MyStore.Dispatcher {

}

let store = MyStore()
let dispatcher = MyDispatcher(target: store)
```

{% hint style="info" %}
`Actual type of MyStore.Dispatcher` is `DispatcherBase<State, Never>` 

It is a typealias to write shortly.
{% endhint %}

**Managing dependencies code**

```swift
class MyDispatcher: MyStore.Dispatcher {

  let apiClient: APIClient

  init(apiClient: APIClient, target store: StoreBase<RootState>) {
    self.apiClient = apiClient
    super.init(target: store)
  }
}

let store = MyStore()
let apiClient = APIClient()
let dispatcher = MyDispatcher(apiClient: apiClient, target: store)
```

### Create multiple Dispatcher

![](../.gitbook/assets/image%20%283%29.png)

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

