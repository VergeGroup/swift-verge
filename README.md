<p align="center">
<img width="240" alt="Frame 8" src="https://user-images.githubusercontent.com/1888355/82828305-b6d2e880-9eeb-11ea-9c3b-7659da42b499.png">
</p>

<h1 align="center">Verge</h1>
<p align="center">
<sub>A performant state management library for iOS App - SwiftUI / UIKit</sub>
</p>

<p align="center">
<img alt="swift5.2" src="https://img.shields.io/badge/swift-5.2-ED523F.svg?style=flat"/>
<img alt="Tests" src="https://github.com/muukii/Verge/workflows/Tests/badge.svg"/>
<img alt="cocoapods" src="https://img.shields.io/cocoapods/v/Verge" />
</p>

<p align="center">
<img width="480px" src="https://user-images.githubusercontent.com/1888355/81477721-268e7580-9254-11ea-94fa-1c2135cdc16f.png"/>
</p>

## Overview - focusing on faster performance

> You can find fully documentation from [Here](#modules-overview)

The concept of Verge Store is inspired by [Redux](https://redux.js.org/), [Vuex](https://vuex.vuejs.org/) and [ReSwift](https://github.com/ReSwift/ReSwift).

Recenlty, [facebookexperimental/Recoil](https://github.com/facebookexperimental/Recoil) has been opened.  
Atoms and Selectors similar to ours `Derived`.

Plus, releasing from so many definition of the actions. (e.g. enum)<br>
To be more Swift's Style on the writing code.

We can do `store.myOperation()` instead of `store.dispatch(.myOperation)`

The characteristics are

* Functions that gains performance (Automatic / Manual - Memoization)
* Method based dispatching action
* Separating the code in a large app
* Emits any events that isolated from State It's for SwiftUI's onReceive\(:\)
* Logging \(Commit, Performance monitoring\)
* Binding with Combine and RxSwift
* Normalizing the state with ORM
* Multi-threading

<details><summary>✅ Differences between other Flux libraries in iOS</summary>
<p>

Firstly, Verge provides the functions to keep excellent performance in using Store-Pattern.

Verge focuses on using in the real-world.

For example, the application must have many features depends on its business.<br>
Such as the application might be getting complicated.

To solve this issue, we can choose Store-Pattern such as flux.

At a glance, Flux architecture is amazing.<br>
However, we have to follow the disadvantages behind it.

They are coming from the application runs with Data-Driven (Mostly).<br>
Data-Driven will cause some expensive calculations in the application that depends on the complexity of the application.<br>
Sometimes, we may face some performance issues we can't overlook it.

Redux and Vuex are already following that.

- Redux
  - reselect
  - ORM
- Vuex
  - Getters
  - ORM

Verge is trying to do that in iOS application with Swift.

Specifically:
- Derived (Similar to [facebookexperimental/Recoil](https://github.com/facebookexperimental/Recoil)'s Atom and Selector)
- ORM

</p>
</details>

<details><summary>💡 Example code</summary>
<p>

```swift
struct State: StateType {
  var name: String = ""
  var age: Int = 0
}

enum Activity {
  case somethingHappen
}

// 🌟with UIKit
class ViewController: UIViewController {
  
  ...  
  
  let store = Store<State, Activity>(initialState: .init(), logger: nil)
  
  ...
            
  func update(changes: Changes<State>) {
    
    changes.ifChanged(\.name) { (name) in
      nameLabel.text = name
    }
    
    changes.ifChanged(\.age) { (age) in
      ageLabel.text = age.description
    }
    
  }
}


// 🌟with SwiftUI
struct MyView: View {
  
  @EnvironmentObject var store: Store<State, Activity>
  
  var body: some View {
    Group {
      Text(store.state.name)
      Text(store.state.age)
    }
  }
}
```

</p>
</details>

# Roadmap - Enhancement Idee

- [ ] Improvement ORM
- [ ] Integrate with Realm to manage the State (like Facebook Messenger)

# Contents

<details><summary>🍐 Basic Usage</summary>


## 🍐 Basic Usage

To start to use Verge in our app, we use these domains:

* **State**
  * A type of state-tree that describes the data our feature needs.
* **Activity**
  * A type that describes an activity that happens during performs the action.
  * This instance won't be stored in anywhere. It would help us to perform something by event-driven.
  * Consider to use this depends on that if can be represented as a state.
  * For example, to present alert or notifcitaions by the action.
* **Action**
  * Just a method that a store or dispatcher defines.
* **Store**
  * A storage object to manage a state and emit activities by the action.
  * Store can dispatch actions to itself.
* **Dispatcher (Optional)**
  * A type to dispatch an action to specific store.
  * For a large application, to separate the logics each domain.
  
**Setup a Store**
  
Define a state
  
```swift
struct MyState {
  var count = 0
}
```

Define an activity

```swift
enum MyActivity {
  case countWasIncremented
}
```

Define a store that uses defined state and activity

```swift
class MyStore: Store<MyState, MyActivity> {

  init(dependency: Dependency) {
    super.init(initialState: .init(), logger: nil)
  }
  
}
```

We can create an instance from `Store` but we can put some dependencies (e.g. API client) with creating a sub-class of `Store`.

(If you don't need Activity, you can set `Never` there.)

And then, add an action in the store

```swift
class MyStore: Store<MyState, MyActivity> {

  init(dependency: Dependency) {
    super.init(initialState: .init(), logger: nil)
  }
  
  func incrementCount() {
    commit { 
      $0.count += 1
    }
  }
}
```

Yes, this point is most different with Redux. it's close to Vuex.<br>
Store knows what the application's needs.

For example, call that action.

```swift
let store = MyStore(...)
store.incrementCount()
```

There are some advantages:

- **Better Performance**
  - Swift can perform this action with Swift's method dispatching instead switch-case computing. 
- **Returns anything we need**
  - the action can return anything from that action (e.g. state or result)
  - If that action dispatch async operation, it can return `Future` object. (such as Vuex action)
  
Perform a commit asynchronously

```swift
func incrementCount() {
  DispatchQueue.main.async {
    commit { 
      $0.count += 1
    } 
  }
}
```

Send an activity from the action

```swift
func incrementCount() {
  commit { 
    $0.count += 1
  }
  send(.countWasIncremented)
}
```

**Use the store in SwiftUI**

(Currently, Verge's development is focusing on UIKit.)

```swift
struct MyView: View {
  
  @EnvironmentObject var store: MyStore
  
  var body: some View {
    Group {
      Text(store.state.name)
      Text(store.state.age)
    }
    .onReceive(session.store.activityPublisher) { (activity) in
      ...
    }
  }
}
```

**Use the store in UIKit**

In UIKit, UIKit doesn't work with differentiating.<br>
To keep better performance, we need to set a value if it's changed.

Verge publishes an object that contains previous state and latest state, Changes object would be so helpful to check if a value changed.

```swift
class ViewController: UIViewController {
    
  let store: MyStore
  
  var cancellable: VergeAnyCancellable?
  
  init(store: MyStore) {
    ...
    
    self.cancellable = store.sinkChanges { [weak self] changes in
      self?.update(changes: changes)
    }
    
  }
            
  private func update(changes: Changes<MyStore.State>) {
    
    changes.ifChanged(\.name) { (name) in
      nameLabel.text = name
    }
    
    changes.ifChanged(\.age) { (age) in
      ageLabel.text = age.description
    }
    
  }
}
```
</details>

<details><summary>☂️ Advanced Usage - to keep performance and scalability</summary>

## ☂️ Advanced Usage - to keep performance and scalability


**Adding a cachable computed property in a State**

We can add a computed property in a state to get a derived value with stored property,<br>
and that computed property works fine as well other stored property.

```swift
struct MyState {
  var items: [Item] = [] {
  
  var itemsCount: Int {
    items.count
  }
}
```

However, this patterns might cause an expensive cost of operation depends on how they computes. <br>
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

This defined computed array calculates only if changed specified value.<br>
That condition to re-calculate is defined with `.ifChanged` method in the example code.

And finally, it caches the result by first-time access and it returns cached value until if the source value changed.


**Making a slice of the state (Selector)**

We can create a slice object that derives a data from the state.

```swift
let derived: Derived<Int> = store.derived(.map(\.count))

// take a value
derived.value

// subscribe a value changes
derived.sinkChanges { (changes: Changes<Int>) in 
}
```

[Details here](https://muukii-app.gitbook.io/verge/docs-vergestore/derived-bindingderived)

**Creating a Dispatcher**

Store arrows us to define an action in itself, that might cause gain complexity in supporting a large application.<br>
To solve this, Verge offers us to create an object that dispatches an action to the store.<br>
We can separate the code of actions to keep maintainability.<br>
that also help us to manage a different type of dependencies.<br>

For example, the case of those dependencies different between logged-in and logged-out.

```swift
class MyDispatcher: MyStore.Dispatcher {
  func moreOperation() {
    commit {
      ...
    }
  }
}

let store: MyStore
let dispatcher = MyDispatcher(target: store)
```

Additionally, We can create a dispatcher that focuses the specified sub-tree of the state.<br>
You can check the detail of this from [our documentation](https://muukii-app.gitbook.io/verge/docs-vergestore/dispatcher).

</details>

# Docs

## 📦 VergeStore

It provides core functions of Store-pattern.

- State supports computed property with caching (like [Vuex's Getters](https://vuex.vuejs.org/guide/getters.html))
- Derived object to create derived data from state-tree with performant (like [redux/reselect](https://github.com/reduxjs/reselect))

<details><summary>🌑 Store - retains a state</summary>
<p>

**Store** 
-   a reference type object    
-   manages the state object that contains the application state    
-   commits **Mutation** to update the state

## Define a Store

```swift
struct State: StateType {
  var count: Int = 0
}

enum Activity {
  case happen
}

final class MyStore: Store<State, Activity> {
  
  init() {
    super.init(
      initialState: .init(),
      logger: DefaultStoreLogger.shared
    )
  }
   
}
```

## Add a Mutation

```swift
final class MyStore: Store<State, Activity> {

  func increment() {
    commit {
      $0.count += 0
    }
  }
  
}
```

## Commit the mutation

```swift
let store = MyStore()
store.increment()
```

</p>
</details>

<details><summary>☄️ Mutation - updates the state of the store</summary>
<p>

## What Mutation is
The only way to actually change state in a Store is by committing a mutation. 
Define a function that returns Mutation object. 
That expresses that function is Mutation

> Mutation does **NOT** allow to run asynchronous operation.

## To define mutations in the Store

```swift
struct MyState {
  var todos: [TODO] = []
}

class MyStore: Store<MyState, Never> {

  func addNewTodo(title: String) {
    commit { (state: inout MyState) in
      state.todos.append(Todo(title: title, hasCompleted: false))
    }
  }
  
}
```

## To run Mutation

```swift
let store = MyStore()
store.addNewTodo(title: "Create SwiftUI App")

print(store.state.todos)
// store.state.todos => [Todo(title: "Create SwiftUI App", hasCompleted: false)]
```

</p>
</details>

<details><summary>⚡️ Activity - a volatile event from an action</summary>
<p>

## What activity does
VergeStore supports send some events that won't be stored on state.
Even if an application runs with Data-Driven, it might have some issues that not easy to something with Data-Driven.
For example, something that would happen with the timer's trigger. This case is not easy with expressing state.
Activity helps that can do easily.
This means VergeStore can use Event-Driven from Data-Driven partially.
We think it's not so special concept. SwiftUI supports these use cases as well that using Combine's Publisher.

```swift
func onReceive<P>(_ publisher: P, perform action: @escaping (P.Output) -> Void) -> some View where P : Publisher, P.Failure == Never
```

[Apple's SwiftUI Ref]([https://developer.apple.com/documentation/swiftui/view/3365935-onreceive](https://developer.apple.com/documentation/swiftui/view/3365935-onreceive))

## Sends Activity

In sample code following this

```swift
final class MyStore: Store<State, Never>
```

`Never` means no activity.
To send activity to subscriber, starting from defining the Activity.

```swift
struct State {
    
}

enum Activity {
  case didSendMessage
}

final class MyStore: Store<State, Activity> {
    
  init() {
    super.init(initialState: .init(), logger: DefaultLogger.shared)
  }
  
  func sendMessage() {
    send(.didSendMessage)
  }
}
```

> In this sample, Store has DispatcherType. If you create the application not so much complicated, you don't need separate Store and Dispatcher.

```swift
let store = Store()

store
  .activityPublisher
  .sink { event in
    // do something
  }
  .store(in: &subscriptions)
```

</p>
</details>

<details><summary>🪐 State and shape</summary>
<p>

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

[About more Normalization and why we need to do this]([https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape/](https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape/))

</p>
</details>

<details><summary>🌟 Changes from State</summary>
<p>

## Update UI from State

In subscribing the state and binding UI, it's most important to reduce the meaningless time to update UI.

What things are the meaningless? that is the update UI which contains no updates.

Basically, we can do this like followings

```swift
func updateUI(newState: State) {
  if self.label.text != newState.name {
    self.label.text = newState.name
  }
}
```

Although, this approach make the code a little bit complicated by increasing the code to update UI.

## Update UI when only the state changed

Store provides Changes<State> object.
It provides some functions to get the value from state with condition.

```swift
let store: Store<MyState, Never>

let changes: Changes<MyState> = store.changes

changes.ifChanged(\.name) { name in
  // called only name changed
}
```

## Subscribing the state

```swift
class ViewController: UIViewController {

  var subscriptions = Set<UntilDeinitCancellable>()
  
  let store: MyStore<MyState, MyActivity> 

  override func viewDidLoad() { 
  
    super.viewDidLoad()
  
    store.sinkChanges { [weak self] (changes) in
      // it will be called on the thread which committed
      self?.update(changes: changes)
    }
    .store(in: &subscriptions)
  }
  
  private func update(changes: Changes<MyState> {
    changes.ifChanged(\.name) { name in
      // called only name changed
    }
    ...
  }
  
}
```

</p>
</details>

<details><summary>🛸 Extended Computed property on State</summary>
<p>

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

> Computed concept is inspired from Vuex Getters. [https://vuex.vuejs.org/guide/getters.html](https://vuex.vuejs.org/guide/getters.html)

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
-   ExtendedStateType    
-   ExtendedType
-   Field.Computed<T>
    
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

</p>
</details>

<details><summary>🌙 Derived - BindingDerived</summary>
<p>

> **Derived** is inspired by [redux/reselect](https://github.com/reduxjs/reselect).

Derived's functions are:
-   Computes the derived data from the state tree
-   Emit the updated data with updating Store
-   Supports subscribe the data
-   Supports Memoization

## Overview
### Setting up the Store

```swift
struct State {
  var title: String = ""
  var count: Int = 0
}

let store = StoreBase<State, Never>(initialState: .init(), logger: nil)
```

### Create a Derived object

```swift
let derived: Derived<Int> = store.derived(.map(\.count))

// we can write also this.
// However, we recommend do above way as possible
// because it enables cache.
let derived: Derived<Int> = store.derived(.map { $0.count })
```

Derived is an object (reference type). It provides a latest value from a store.
This supports getting the value ad-hoc or subscribing the value updating.

## Take a value
Derived allows us to take the latest value at the time.

```swift
let value: Int = derived.value
```

## Subscribe the latest value Derived provides

Derived allows us to subscribe to the updated value.

```swift
let cancellable = derived.sinkValue { (changes: Changes<Int>) in 
}
```

> ✅ 
> Please, carefully handle a cancellable object. A concealable object that returns that subscribe method is similar to AnyCancellable of Combine.framework. We need to retain that until we don't need to get the update event.

## Supports other Reactive Frameworks
We might need to use some Reactive framework to integrate other sequence. Derived allows us to make to a sequence from itself. Currently, it supports Combine.framework and RxSwift.framework.

### + Combine

```swift
derived
  .valuePublisher()
  .sink { (changes: Changes<Int>) in
  
  }
```

### + RxSwift

> 💡You need to install VergeRx module to use this.

```swift
derived.rx
  .changesObservable()
  .subscribe(onNext: { (changes: Changes<Int>) in
  
  })
```

## Memoization to keep good performance

Mostly Derived is used for projecting the specified shape from the source object. 
And some cases may contain an expensive operation. In that case, we can consider to tune Memoization up.​ 
We can see the detail of Memoization from below link.

[Wiki - Memoization]([https://en.wikipedia.org/wiki/Memoization](https://en.wikipedia.org/wiki/Memoization))

## Suppress the map operation that projects no changes

In create Derived method, we can get the detail that how we suppress the no need updating and updated event.

```swift
extension StoreType {

  public func derived<NewState>(
    _ memoizeMap: MemoizeMap<Changes<State>, NewState>,
    dropsOutput: @escaping (Changes<NewState>) -> Bool = { _ in false }
  ) -> Derived<NewState>
  
}
```

</p>
</details>

<details><summary>🚀 Dispatcher - perform Mutation</summary>
<p>

## What Dispatcher does

Dispatcher's needs is **to update the state that Store manages** and to **manage dependencies to create Mutation and Action.**

**Dispatcher does not have own state. Dispatcher runs with Store.**

**Example**

```swift
class MyDispatcher: MyStore.Dispatcher {

}

let store = MyStore()
let dispatcher = MyDispatcher(target: store)
```

> 💡 
> Actual type of MyStore.Dispatcher is DispatcherBase<State, Never> It is a typealias to write shortly.

Managing dependencies code

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

</details>

<details><summary>🔭 Logging</summary>

## Start logging from DefaultStoreLogger
DefaultStoreLogger is the pre-implemented logger that send the logs to OSLog.
To enable logging, set the logger instance to Store's initializer.

```swift
Store<MyState, MyActivity>.init(
  initialState: ...,
  logger: DefaultStoreLogger.shared // 🤩
)
```

Mainly, we can monitor log about commit in Xcode's console and Terminal.app

```
2020-05-25 23:47:06.884304+0900 VergeStoreDemoSwiftUI[84086:2813713] [Commit] {
  "store" : "VergeStore.Store<VergeStoreDemoSwiftUI.SessionState, Swift.Never>()",
  "tookMilliseconds" : 0.19299983978271484,
  "trace" : {
    "createdAt" : "2020-05-25T14:47:06Z",
    "file" : "\/Users\/muukii\/.ghq\/github.com\/muukii\/Verge\/worktree\/space1\/Sources\/VergeStoreDemoSwiftUI\/Session.swift",
    "function" : "submitNewPost(title:from:)",
    "line" : 129,
    "name" : ""
  },
  "type" : "commit"
}
```

## Creating a customized logger

If you need a customized logger, you can create that with `StoreLogger` protocol.

```swift
public protocol StoreLogger {
  
  func didCommit(log: CommitLog)
  
  func didCreateDispatcher(log: DidCreateDispatcherLog)
  func didDestroyDispatcher(log: DidDestroyDispatcherLog)
}
```

</details>

<details><summary>Utilities</summary>

## Fragment\<State>

## Fragment helps compare if state was updated without Equatable

‌In a single state tree, comparing for reducing the number of updates would be most important for keep performance. However, implementing Equatable is not easy basically. Instead, adding a like flag that indicates updated itself, it would be easy

## Actually, we need to get to flag that means different, it no need to be equal

Actually, we need to get to flag that means **different**, it no need to be **equal**.

## Fragment does embed state with flag‌

Now we can use Fragment struct that is a container for wrapping inside state up. With dynamicMemberLookup, we can access the properties without new property. Fragment has `UpdatedMarker`, we can compare if the state was updated with this.

```swift
struct YourState {
  var name: String = ...
}

struct AppState {

  @Fragment var yourState YourState = .init()
}

appState.yourState.name

// get unique value that indicates updated to compare with previous value.
// this value would be updated on every mutation of this tree.
appState.$yourState.counter.value 
```

</details>

<details><summary>🎛Optimization Tips</summary>

## Writing high-performance state-management

> WIP

* ExtendedComputedProperty

</details>

## 📦 VergeORM - Normalization

It provides the function that manages performant many entity objects.<br>
Technically, using Normalization.

In the application that uses many entity objects, we sure highly recommend using such as ORM using Normalization.

About more detail,
https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape

<details><summary>VergeORM Core Concepts</summary>
<p>

VergeORM is a library to manage Object-Relational Mapping in the value-type struct.

It provides to store with Normalization and accessing easier way.
Basically, If we do Normalization without any tool, accessing would be complicated.

The datastore can be stored anywhere because it's built by struct type.
It allows that to adapt to state-shape already exists.

```swift
struct YourAppState: StateType {
  
  // VergeORM's datastore 
  struct Database: DatabaseType {
  
    ...
    // We will explain this later.
  }
      
  // Put Database anywhere you'd like  
  var db: Database = .init()

  ... other states
}
```

## Stores data with normalization

Many applications manage a lot of entities. Single state-tree requires work similar to creating database schema. The state shape is most important, otherwise performance issue will appear when your application grows.

‌
To avoid this, we should do **Normalize** the State Shape. About Normalizing state shape, [Redux documentation](https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape) explains it so good. VergeORM provides several helper methods to normalize state shape.

-   Supports find, insert, delete with easy plain implementations.    
-   Supports batch update with context, anywhere it can abort and revert to current state.

</p>
</details>

<details><summary>Getting Started</summary>

## Create Database struct

**Database struct** contains the tables for each Entity. As a struct object, that allows to manage history and it can be embedded on the state that application uses.
‌
-   Database struct    
    -   Book entity        
    -   Author entity

## Add DatabaseType protocol to your database struct

```swift
struct Database: DatabaseType {
}
```

`DatabaseType` protocol has several constraints and provides functions with that. To satisfy those constraints, make it like following

```swift
struct Database: DatabaseType {

  struct Schema: EntitySchemaType {

  }

  struct Indexes: IndexesType {

  }

  var _backingStorage: BackingStorage = .init()
}
```

## Register EntityTable

As an example, suppose we have Book and Author entities.

```swift
struct Book: EntityType {

  typealias IdentifierType = String

  var entityID: EntityID {
    .init(rawID)
  }

  let rawID: String
}

struct Author: EntityType {

  typealias IdentifierType = String

  var entityID: EntityID {
    .init(rawID)
  }

  let rawID: String
}
```

By conforming to `EntityType` protocol, it can be used by Database as Entity. It needs `rawID` and you can set whatever type your Entity needs.

And then, add these entities to Schema object.

```swift
struct Database: DatabaseType {

  struct Schema: EntitySchemaType {
    let book = Book.EntityTableKey()
    let author = Book.EntityTableKey()
  }

  struct Indexes: IndexesType {
    // In this time, we don't touch here.
  }

  var _backingStorage: BackingStorage = .init()
}
```

Finally, you can use Database object like this.

```swift
let db = RootState.Database()

let bookEntityTable: EntityTable<Book, Read> = db.entities.book
```

You can get aEntityTable object for Book.
And then you can use these methods.

```swift
bookEntityTable.all()
bookEntityTable.find(by: <#T##VergeTypedIdentifier<Book>#>)
bookEntityTable.find(in: <#T##Sequence#>)
```

> 💡
> These syntax are realized by Swift's dynamicMemberLookup. If you have curiosity, please check out the source-code.

## Update Database

To update Database object(Insert, Update, Delete), use `performbatchUpdates` method.

```swift
db.performBatchUpdates { (context) in
  // Put the updating code here
}
```

Example:
```swift
db.performBatchUpdates { (context) in
  let book = Book(rawID: "some")
  context.book.insert(book)
}

// db.entities.book.count == 1
```

</details>

<details><summary>Index</summary>

## To find the entity faster, Index.

As shown in the Getting Started section, we can get entities by the following code.

```swift
let db =  RootState.Database()

db.bookEntityTable.all()

db.bookEntityTable.find(by: <#T##VergeTypedIdentifier<Book>#>)

db.bookEntityTable.find(in: <#T##Sequence#>)
```

To do this, we need to manage the Identifier of the entity and additionally, to get an array of entities, we need to manage the order of Identifier.

To do this, VergeORM provides Index feature. Index manages the set of identifiers in several structures.

> 💡
> Meaning of Index might be a bit different than RDB's Index. At least, Index manages identifiers to find the entity faster than linear search.

Currently, we have the following types,‌
-   **OrderedIDIndex**    
    -   [EntityID]        
    -   Manages identifiers in an ordered collection           
-   **GroupByEntityIndex**
    -   [EntityID : [EntityID]]
    -   Manages identifiers that are grouped by another identifier
-   **HashIndex**
	-  [Key : EntityID]
	-  Manages identifiers with hashable keys
-   **SetIndex**
    -   Set<EntityID>
-   **GroupByKeyIndex**    
    -   [Key : [EntityID]]
            
## Register Index

Let's take a look at how to register Index. The whole index is here.

```swift
struct Database: DatabaseType {

  struct Schema: EntitySchemaType {
    let book = Book.EntityTableKey()
    let author = Book.EntityTableKey()
  }

  struct Indexes: IndexesType {
    // 👋 Here!
  }

  var _backingStorage: BackingStorage = .init()
}
```

Indexes struct describes the set of indexes. All of the indexes managed by VergeORM would be here.

For now, we add a simple ordered index just like this.

```swift
struct Indexes: IndexesType {
  let allBooks = IndexKey<OrderedIDIndex<Schema, Book>>()
  // or OrderedIDIndex<Schema, Book>.Key()
}
```

With this, now we have index property on DatabaseType.indexes.

```swift
let allBooks = state.db.indexes.allBooks
// allBooks: OrderedIDIndex<Database.Schema, Book>
```

## Read Index

**Accessing indexes**

```swift
// Get the number of ids
allBooks.count

// Take all ids
allBooks.forEach { id in ... }

// Get the id with location
let id: Book.ID = allBooks[0]
```

Fetch the entities from index

```swift
let books: [Book] = state.db.entities.book.find(in: state.db.indexes.allBooks)
// This syntax looks is a bit verbose.
// We will take shorter syntax.
```

## Write Index

To write index is similar with updating entities. Using `performBatchUpdates` , add or delete index through the `context` .

```swift
state.db.performBatchUpdates { (context) -> Book in

  let book = Book(rawID: id.raw, authorID: Author.anonymous.id)
  context.insertsOrUpdates.book.insert(book)

  // Here 👋
  context.indexes.allBooks.append(book.id)

}
```

Since Index is updated manually here, you might want to manage it automatically.
Using **Middleware**, it's possible.

</details>

<details><summary>Middleware</summary>
## Perform any operation for each of all updates

Using Middleware, you can perform any operation for each of all updates.
‌
For example,
-   Manage Index according to updated entities, for each of all updates

## Register Middleware

In DatabaseType protocol, we can return the set of middlewares. This property would be called for each update.

```swift
struct Database: DatabaseType {

  ...

  var middlewares: [AnyMiddleware<RootState.Database>] {
    [
      // Here
    ]
  }  
}
```

We can return `MiddlewareType` object here. However since it's a generic protocol, it needs to wrap up with AnyMiddleware object to return as an array.

**struct AnyMiddleware**

```swift
public struct AnyMiddleware<Database> : MiddlewareType where Database : VergeORM.DatabaseType {

    public init<Base>(_ base: Base) where Database == Base.Database, Base : VergeORM.MiddlewareType

    public init(performAfterUpdates: @escaping (DatabaseBatchUpdateContext<Database>) -> ())

    public func performAfterUpdates(context: DatabaseBatchUpdateContext<Database>)
}
```

**To wrap your middleware up with AnyMiddleware**

```swift
public struct MyMiddleware<Database: DatabaseType>: MiddlewareType {
  ...
}

let middleware = MyMiddleware()
AnyMiddleware<Database>(middleware)
```

To create anonymous middleware using AnyMiddleware

```swift
AnyMiddleware<Database>(performAfterUpdates: { (context) in

  // ... any operation

})
```

## What middleware handles

-   performs any operation with context after updating of batch-updates completed.    
    -   `MiddlewareType.performAfterUpdates`
    
## Create Middleware

```swift
let autoIndex = AnyMiddleware<RootState.Database>(performAfterUpdates: { (context) in

  let ids = context.insertsOrUpdates.author.all().map { $0.id }
  context.indexes.bookMiddleware.append(contentsOf: ids)

})
```

This sample code adds identifier of Author that added on batch-updates.
This means it manages Index automatically.
Finally, returns this object on middlewares property.

```swift
let autoIndex = ...

struct Database: DatabaseType {

  ...

  var middlewares: [AnyMiddleware<RootState.Database>] {
    [
      autoIndex
    ]
  }  
}
```


</details>

<details><summary>Makes a Derived for a entity</summary>

## To create getter, Add DatabaseEmbedding protocol to your state-tree.

```swift
struct RootState: DatabaseEmbedding {

  static let getterToDatabase: (RootState) -> RootState.Database = { $0.db }

  struct Database: DatabaseType {
    ...       
  }

  var db = Database()
}
```

## Create getter from entity id

```swift
let id = Book.EntityID.init("some")

let derived: Book.Derived = storage.derived(from: id)
```

## Get entity from Getter

```swift
let entity: Book = getter.value.wrapped
```

VergeORM supports create MemoizeSelector from Storage or Store.

</details>

<details><summary>Tips</summary>

## Access to DB partially

We may want to create common accessing code with using protocol if we have multiple database object.

```swift
protocol Partial {
  var author: Author.EntityTableKey { get }
}

struct Database: DatabaseType {
  
  struct Schema: EntitySchemaType, Partial {
    let book = Book.EntityTableKey()
    let author = Author.EntityTableKey()
  }
  
  struct Indexes: IndexesType {
  }
    
  var _backingStorage: BackingStorage = .init()
}
```

```swift
func access<DB: DatabaseType>(db: DB) -> Int where DB.Schema : Partial {
  db.entities.author.all().count
}
```

Inside of access function, it supports only accessing to entity Partial protocol has.

</details>

## 📦 VergeRx

It provides several observable that compatible with RxSwift.

# Prepare moving to SwiftUI from now with Verge

SwiftUI's concept is similar to the concept of React, Vue, and Elm. <br>
Therefore, the concept of state management will become to be similar as well.

That is Redux or Vuex and more.

Now, almost of iOS Applications are developed on top of UIKit.<br>
And We can't say SwiftUI is ready for top production. <br>
However, it would change.

It's better to use the state management that fits SwiftUI from now. It's not only for that, current UIKit based applications can get more productivity as well.

# Installation

With Cocoapods,

VergeStore

```ruby
pod 'Verge/Store'
```

VergeORM

```ruby
pod 'Verge/ORM'
```

VergeRx

```ruby
pod 'Verge/Rx'
```

These are separated with subspecs in Podspec.<br>
After installed, these are merged into single module as `Verge`.

To use Verge in your code, define import decralation following.

```swift
import Verge
```

# Author

[muukii](https://github.com/muukii)

# License

Verge is released under the MIT license.


<!--stackedit_data:
eyJoaXN0b3J5IjpbMTU0NDcyOTA5MiwtNzE4NTYxMDYsNzczND
E3MTIwLC0yMTU4NDY5OTQsODY2MjcwNzg1LC0xODcyMTI3NzE3
LC0zODI2MDIyOSw3MjcxNTU2OTIsLTEzNTAyMjQzNjEsMTIzNj
c2NTM2LDc1ODk5OTkzMywxMDczNTQ2MjgxLDgxOTAyOTEyLDE5
ODQzNDQ2NjcsMTYyMDcyODMyLC0xMDE5MDgzMjk4LDgyMzk2NT
g5NCwtMTk4MjYxODI2MCwtMTIzNDIzNDgyOV19
-->