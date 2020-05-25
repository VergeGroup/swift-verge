# Verge - A performant state management library for iOS App - SwiftUI / UIKit

[![Swift 5.2](https://img.shields.io/badge/swift-5.2-ED523F.svg?style=flat)](https://swift.org/download/)
![Tests](https://github.com/muukii/Verge/workflows/Tests/badge.svg)
![cocoapods](https://img.shields.io/cocoapods/v/Verge)


<sub>A Store-Pattern based data-flow architecture. Highly inspired by Vuex</sub><br>

<img width="480px" src="https://user-images.githubusercontent.com/1888355/81477721-268e7580-9254-11ea-94fa-1c2135cdc16f.png"/>

## Overview - focusing on faster performance

The concept of Verge Store is inspired by [Redux](https://redux.js.org/), [Vuex](https://vuex.vuejs.org/) and [ReSwift](https://github.com/ReSwift/ReSwift).

Recenlty, [facebookexperimental/Recoil](https://github.com/facebookexperimental/Recoil) has been opened.  
Atoms and Selectors similar to `Derived`.

Plus, releasing from so many definition of the actions.<br>
To be more Swift's Style on the writing code.

`store.myOperation()` instead of `store.dispatch(.myOperation)`

The characteristics are

* Method based dispatching action
* Separating the code in a large app
* Emits any events that isolated from State It's for SwiftUI's onReceive\(:\)
* Logging \(Commit, Performance monitoring\)
* Binding with Combine and RxSwift
* Normalizing the state with ORM
* Multi-threading

<details><summary>🌟 Differences between other Flux libraries in iOS</summary>
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

<details><summary>🌟 Example code</summary>
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


## Modules overview

### 📦 VergeStore

It provides core functions of Store-pattern.

- State supports computed property with caching (like [Vuex's Getters](https://vuex.vuejs.org/guide/getters.html))
- Derived object to create derived data from state-tree with performant (like [redux/reselect](https://github.com/reduxjs/reselect))

## 🌑 Store

<details><summary>Open</summary>
<p>

**Store** 
-   a reference type object    
-   manages the state object that contains the application state    
-   commits **Mutation** to update the state

## Defines Store

```swift
struct State: StateType {
  var count: Int = 0
}

enum Activity {
  case happen
}

final class MyStore: StoreBase<State, Activity> {
  
  init() {
    super.init(
      initialState: .init(),
      logger: DefaultStoreLogger.shared
    )
  }
   
}
```

## Adds Mutation

```swift
final class MyStore: StoreBase<State, Activity> {

  func increment() {
    commit {
      $0.count += 0
    }
  }
  
}
```

## Commit mutation

```swift
let store = MyStore()
store.increment()
```

</p>
</details>

## ☄️ Mutation

<details><summary>Open</summary>
<p>

## What Mutation is
The only way to actually change state in a Store is by committing a mutation. 
Define a function that returns Mutation object. 
That expresses that function is Mutation

> Mutation does **NOT** allow to run asynchronous operation.

## To define mutations in the Store

```swift
class MyDispatcher: MyStore.Dispatcher {

  func addNewTodo(title: String) {
    commit { (state: inout RootState) in
      state.todos.append(Todo(title: title, hasCompleted: false))
    }
  }
  
}
```

## To run Mutation

```swift
let store = MyStore()
let dispatcher = MyDispatcher(target: store)

dispatcher.addNewTodo(title: "Create SwiftUI App")

print(store.state.todos)
// store.state.todos => [Todo(title: "Create SwiftUI App", hasCompleted: false)]
```

</p>
</details>

## ⚡️ Activity

<details><summary>Open</summary>
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
final class MyStore: StoreBase<State, Never>
```

`Never` means no activity.
To send activity to subscriber, starting from defining the Activity.

```swift
struct State {
    
}

enum Activity {
  case didSendMessage
}

final class Store: StoreBase<State, Activity>, DispatcherType {
  
  var target: StoreBase<State, Activity> { self }
  
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

## 🪐 State and shape

<details><summary>Open</summary>
<p>

## Using single state tree (Not enforced)

VergeStore uses a **single state-tree. (Recommended)** That means an object contains all of the application's state. With this, we can get to achieve **"single source of truth"**

That state is managed by **Store**. It process updating the state and notify updated events to the subscribers.

> 💡 VergeStore does support multiple state-tree as well. Depending on the case, we can create another Store instance.

## Add computed property

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

## Normalization

**If you put the data that has relation-ship or complicated structure into state tree, it would be needed normalization to keep performance. Please check VergeORM module**

[About more Normalization and why we need to do this]([https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape/](https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape/))

</p>
</details>

## 🌟 Changes from State

<details><summary>Open</summary>
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

## 🛸 Computed property on State

<details><summary>Open</summary>
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

</p>
</details>

## 🌙 Derived - BindingDerived

<details><summary>Open</summary>
<p>

</p>
</details>

## 🚀 Dispatcher - perform Mutation

<details><summary>Open</summary>
<p>

</p>
</details>

## 🔭 Logging

<details><summary>Open</summary>
<p>

</p>
</details>

### 📦 VergeORM

It provides the function that manages performant many entity objects.<br>
Technically, using Normalization.

In the application that uses many entity objects, we sure highly recommend using such as ORM using Normalization.

About more detail,
https://redux.js.org/recipes/structuring-reducers/normalizing-state-shape

### 📦 VergeRx

It provides several observable that compatible with RxSwift.

## More Documentations

[**🔗 You can see more detail of Verge on Documentation**](https://muukii-app.gitbook.io/verge/)

## Prepare moving to SwiftUI from now with Verge

SwiftUI's concept is similar to the concept of React, Vue, and Elm. <br>
Therefore, the concept of state management will become to be similar as well.

That is Redux or Vuex and more.

Now, almost of iOS Applications are developed on top of UIKit.<br>
And We can't say SwiftUI is ready for top production. <br>
However, it would change.

It's better to use the state management that fits SwiftUI from now. It's not only for that, current UIKit based applications can get more productivity as well.

## Installation

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

## Author

[muukii](https://github.com/muukii)

## License

Verge is released under the MIT license.


<!--stackedit_data:
eyJoaXN0b3J5IjpbLTIwMDY0MDg2NzEsODIzOTY1ODk0LC0xOT
gyNjE4MjYwLC0xMjM0MjM0ODI5XX0=
-->