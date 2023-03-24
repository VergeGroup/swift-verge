<p align="center">
  <a href="https://vergegroup.org">
<img width="128" alt="VergeIcon" src="https://user-images.githubusercontent.com/1888355/85241314-5ac19c80-b476-11ea-9be6-e04ed3bc6994.png">
    </a>
</p>


<h1 align="center">Verge.swift</h1>
<p align="center">
  <b>📍An effective state management architecture for iOS - UIKit, SwiftUI📍</b><br/>
<sub>_ An easier way to get unidirectional data flow _</sub><br/>
<sub>_ Supports concurrent processing _</sub><br/>
</p>

- [Verge Docs](https://vergegroup.github.io/swift-Verge/Verge/documentation/verge/)
- [VergeORM Docs](https://vergegroup.github.io/swift-Verge/VergeORM/documentation/vergeorm/)


<p align="center">
<img alt="swift5.5" src="https://img.shields.io/badge/swift-5.5-ED523F.svg?style=flat"/>
<img alt="Tests" src="https://github.com/VergeGroup/Verge/workflows/Tests/badge.svg"/>
</p>

## Support this projects
<a href="https://www.buymeacoffee.com/muukii">
<img width="160" alt="yellow-button" src="https://user-images.githubusercontent.com/1888355/146226808-eb2e9ee0-c6bd-44a2-a330-3bbc8a6244cf.png">
</a>

# Verge: A High-Performance, Scalable State Management Library for SwiftUI and UIKit

Verge is a high-performance, scalable state management library for Swift, designed with real-world use cases in mind. It offers a lightweight and easy-to-use approach to managing your application state without the need for complex actions and reducers. This guide will walk you through the basics of using Verge in your Swift projects.

## Key Concepts and Motivations

Verge was designed with the following concepts in mind:

- Inspired by the Flux library, but with a focus on providing a store-pattern as the core concept.
- The store-pattern is a primitive concept found in Flux and Redux, focusing on sharing state between components using a single source of truth.
- Verge does not dictate how to manage actions to modify the state. Instead, it provides a simple `commit` function that accepts a closure describing how to change the state.
- Users can build additional layers on top of Verge, such as implementing enum-based actions for more structured state management.
- Verge supports multi-threading, ensuring fast, safe, and efficient operation.
- Compatible with both UIKit and SwiftUI.
- Includes APIs for handling real-world application development use cases, such as managing asynchronous operations.
- Addresses the complexity of updating state in large and complex applications.
- Provides an ORM for efficient management of a large number of entities.
- Designed for use in business-focused applications.

### Getting Started

## Getting Started

To use Verge, follow these steps:

1. Define a state struct that conforms to the `Equatable` protocol.
2. Instantiate a `Store` with your initial state.
3. Update the state using the `commit` method on the store instance.
4. Subscribe to state updates using the `sinkState` method.

## Defining Your State

Create a state struct that represents the state of your application. Your state struct should conform to the `Equatable` protocol. This allows Verge to detect changes in your state and trigger updates as necessary.

Example:

```swift
struct MyState: Equatable {
 var count: Int = 0 
}
```

## Instantiating a Store

Create a `Store` instance with the initial state of your application. The `Store` class takes two type parameters:

- The first type parameter represents the state of your application.
- The second type parameter represents any middleware you want to use with your store. If you don't need any middleware, use `Never`.

Example:

```swift
let store = Store<_, Never>(initialState: MyState())
```

## Updating the State

To update your application state, use the `commit` method on your `Store` instance. The `commit` method takes a closure with a single parameter, which is a mutable reference to your state. Inside the closure, modify the state as needed.

Example:

```swift
store.commit {   
  $0.count += 1 
}
```

## Subscribing to State Updates

To receive updates when the state changes, use the `sinkState` method on your `Store` instance. This method takes a closure that receives the updated state as its parameter. The closure will be called whenever the state changes.

Example:

```swift
store.sinkState { state in
  // Receives updates of the state
}
.storeWhileSourceActive()
```

The `storeWhileSourceActive()` call at the end is a method provided by Verge to automatically manage the lifetime of the subscription. It retains the subscription as long as the source (in this case, the `store` instance) is alive.

That's it! You now know the basics of using Verge to manage the state in your Swift applications. For more advanced use cases and additional features, please refer to the official Verge documentation and GitHub repository.

## Using Activity of Store for Event-Driven Programming

In certain scenarios, event-driven programming is essential for creating responsive and efficient applications. The Verge library's Activity of Store feature is designed to cater to this need, allowing developers to handle events seamlessly within their projects.

The Activity of Store comes into play when your application requires event-driven programming. It enables you to manage events and associated logic independently from the main store management, promoting a clean and organized code structure. This separation of concerns simplifies the overall development process and makes it easier to maintain and extend your application over time.

By leveraging the Activity of Store functionality, you can efficiently handle events within your application while keeping the store management intact. This ensures that your application remains performant and scalable, enabling you to build robust and reliable Swift applications using the Verge library.

Here's an example of using Activity of Store:

```swift
let store: Store<MyState, MyActivity>

store.send(MyActivity.somethingHappened)
```

```swift
store.sinkActivity { (activity: MyActivity) in
  // handle activities.
}
.storeWhileSourceActive()
```

## Using Verge with SwiftUI

To use Verge in SwiftUI, you can utilize the `StoreReader` to subscribe to state updates within your SwiftUI views. Here's an example of how to do this:

```swift
import SwiftUI
import Verge

struct ContentView: View {
  @StateObject private var viewModel = CounterViewModel()

  var body: some View {
    VStack {
      StoreReader(viewModel.store) { state in
        Text("Count: \(state.count)")
          .font(.largeTitle)
      }

      Button(action: {
        viewModel.increment()
      }) {
        Text("Increment")
      }
    }
  }
}

final class CounterViewModel: StoreComponentType {
  struct State: Equatable {
    var count: Int = 0
  }

  let store: Store<State, Never> = .init(initialState: .init())

  func increment() {
    commit {
      $0.count += 1
    }
  }
}
```

In this example, `StoreReader` is used to read the state from the `MyViewModel` store. This allows you to access and display the state within your SwiftUI view. Additionally, you can perform actions by calling methods on the store directly, as demonstrated with the button in the example.

This new section will help users understand how to use Verge with SwiftUI, allowing them to manage state effectively within their SwiftUI views. Let me know if you have any further suggestions or changes!

## Using Verge with UIKit

Here's a simple usage example of Verge with a UIViewController:

```swift
class MyViewController: UIViewController {
  
  private struct State: Equatable {
    var count: Int = 0
  }
  
  private let store: Store<State, Never> = .init(initialState: .init())
  
  private let label: UILabel = .init()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()
    
    // Subscribe to the store's state updates
    store.sinkState { [weak self] state in
      guard let self = self else { return }
      
      // Check if the value has been updated using ifChanged
      state.ifChanged(\.count) { count in
        self.label.text = "Count: \(count)"
      }
    }
    .storeWhileSourceActive()
  }
  
  private func setupUI() {
    // Omitted for brevity
  }
  
  private func incrementCount() {
    store.commit {
      $0.count += 1
    }
  }
}
```

## Efficient State Updates in UIKit using `sinkState`, `Changed<State>`, and `ifChanged`

In UIKit, which is event-driven, it's crucial to update components efficiently by only updating them as needed. The Verge library provides a way to achieve this using the `sinkState` method, the `Changed<State>` type, and the `ifChanged` method.

When you use the `sinkState` method, the closure you provide receives the latest state wrapped in a `Changed<State>` type. This wrapper also includes the previous state, allowing you to determine which properties have been updated using the `ifChanged` method.

Here's an example of using `sinkState` and `ifChanged` in UIKit to efficiently update components:

```swift
store.sinkState {
  $0.ifChanged(\.myProperty) { newValue in
    // Update the component only when myProperty has changed
  }
}
```

In this example, the component is updated only when `myProperty` has changed, ensuring efficient updates in the UIKit-based application.

Compared to UIKit, SwiftUI works with a declarative view structure, which means that there is less need to check for state changes to update the view. However, when working with UIKit, using `sinkState`, `Changed<State>`, and `ifChanged` helps maintain a performant and responsive application.

## Using TaskManager for Asynchronous Operations

Verge's Store includes a TaskManager that allows you to dispatch and manage asynchronous operations. This feature simplifies handling async tasks while keeping them associated with your Store.

### Basic usage

To use TaskManager, simply call the `task` method on your Store instance, and provide a closure that contains the asynchronous operation:

```swift
store.task {
  await runMyOperation()
}
```

### Task management with keys and modes

TaskManager also enables you to manage tasks based on keys and modes. You can assign a unique key to each task and specify a mode for its execution. This allows you to control the execution behavior of tasks based on their keys.

For example, you can use the `.dropCurrent` mode to drop any currently running tasks with the same key and run the new task immediately:

```swift
store.task(key: .init("MyOperation"), mode: .dropCurrent) {
  //
}
```

This functionality provides you with fine-grained control over how tasks are executed, ensuring that your application remains responsive and efficient, even when handling multiple asynchronous operations.

## Advanced Usage: Managing Multiple Stores for Complex Applications

In theory, managing your entire application state in a single store is ideal. However, in large and complex applications, the computational complexity can become significant, leading to performance issues and slow application responsiveness. In such cases, it's recommended to separate your state into multiple stores and integrate them as needed.

By dividing your state into multiple stores, you can reduce the complexity and overhead associated with state updates. Each store can manage a specific part of your application state, ensuring that updates are performed efficiently and quickly. This approach also promotes better organization and separation of concerns in your code, making it easier to maintain and extend your application over time.

To use multiple stores, create separate Store instances for different parts of your application state, and then connect them as needed. This may involve passing store instances to child components or sharing stores between sibling components. By structuring your application this way, you can ensure that each part of your application state is managed efficiently and effectively.

### Copying State Between Stores

To copy state between stores, you can use the `sinkState` method along with the `ifChanged` function to only trigger updates when the state has changed. Here's an example:

```swift
store.sinkState {
  $0.ifChanged(\\.myState) { value in
    otherStore.commit {
      $0.myState = value
    }
  }
}
```

In this example, when the state of `myState` changes in `store`, the new value is committed to `otherStore`. This approach allows you to synchronize state between multiple stores efficiently.

## Using Derived for Efficient Computed Properties

Verge's `Derived` feature allows you to create computed properties based on your store's state and efficiently subscribe to updates. This feature can help you optimize your application by reducing unnecessary computations and updates. Derived is inspired by the [reselect](https://github.com/reduxjs/reselect) library and provides similar functionality.

### Creating a Derived Property

To create a derived property, you'll use the `store.derived` method. This method takes a `Pipeline` object that describes how the derived data is generated:

```swift
let derived: Derived<Int> = store.derived(.select(\\.count))
```

You can use `select` or `map` to generate derived data. `select` is used to take a value directly from the state, while `map` can be used to generate new values based on the state, similar to a map function:

```swift
let derived: Derived<Int> = store.derived(.map { $0.count * 2 })
```

The `Pipeline` checks if the derived data has been updated from the previous value. If it hasn't changed, `Derived` won't publish any changes.

### Chaining Derived Instances

You can create another Derived instance from an existing Derived instance, effectively chaining them together:

```swift
let anotherDerived: Derived<String> = derived.derived(.map { $0.description })
```

### Subscribing to Derived Property Updates

To subscribe to updates of a derived property, you can use the `sinkState` method, just like with a store:

```swift
derived.sinkState { value in 
  // Handle updates of the derived property 
} 
.storeWhileSourceActive()
```

By using `Derived` for computed properties and subscribing to updates, you can ensure that your application remains efficient and performant, avoiding unnecessary computations and state updates.

## Installation

## SwiftPM

Verge supports SwiftPM.

## Demo applications

This repo has several demo applications in Demo directory.
And we're looking for your demo applications to list it here!
Please tell us from Issue!

## Thanks

- [Redux](https://redux.js.org/)
- [Vuex](https://vuex.vuejs.org/)
- [ReSwift](https://github.com/ReSwift/ReSwift)
- [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture)

## Author

[🇯🇵 Muukii (Hiroshi Kimura)](https://github.com/muukii)

## License

Verge is released under the MIT license.
