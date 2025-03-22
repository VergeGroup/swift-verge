import Combine
import Foundation
import StateStruct
import SwiftUI

/**
 A view that reads the state from Store and displays content according to the state.
 The view subscribes to the state updates and updates the content when the state changes.

 The state requires `@Tracking` macro to be used.

 ```swift
 @Tracking
 struct State {
   var count: Int = 0
 }
 ```

 If you have nested types, you can use `@Tracking` macro to the nested types.
 Then the StoreReader can track through the nested types.

 ```swift
 @Tracking
 struct Nested {
   var count: Int = 0
 }

 @Tracking
 struct State {
   var nested: Nested = .init()
 }
 
 ## How to make Binding

 Use ``StoreBindable`` to make binding.

 ```swift
 @StoreBindable var store = store
 $store.count
 ```
 */
@available(iOS 14, watchOS 7.0, tvOS 14, *)
public struct StoreReader<State: TrackingObject, Activity: Sendable, Content: View>: View {

  private let store: Store<State, Activity>

  @SwiftUI.State private var version: UInt64 = 0

  private let file: StaticString
  private let line: UInt

  private let content: @MainActor (State) -> Content

  /// Initialize from `Store`
  ///
  /// - Parameters:
  ///   - store:
  ///   - content:
  public init<Driver: StoreDriverType>(
    file: StaticString = #file,
    line: UInt = #line,
    _ store: Driver,
    @ViewBuilder content: @escaping @MainActor (State) -> Content
  ) where State == Driver.TargetStore.State, Activity == Driver.TargetStore.Activity {

    let store = store.store.asStore()

    self.init(
      file: file,
      line: line,
      store: store,
      content: content
    )

  }

  private init(
    file: StaticString,
    line: UInt,
    store: Store<State, Activity>,
    content: @escaping @MainActor (State) -> Content
  ) {
    self.file = file
    self.line = line
    self.store = store
    self.content = content
  }

  public var body: some View {

    // trigger to subscribe
    let _ = $version.wrappedValue

    let _content = store.tracking(
      content,
      onChange: {
        ImmediateMainActorTargetQueue.main.execute {
          version &+= 1
        }
      })

    _content
  }

}

@propertyWrapper
@dynamicMemberLookup
public struct StoreBindable<StoreDriver: StoreDriverType & Sendable> {

  private let storeDriver: StoreDriver

  public init(
    wrappedValue: StoreDriver
  ) {
    self.storeDriver = wrappedValue
  }

  public var wrappedValue: StoreDriver {
    storeDriver
  }

  public var projectedValue: Self {
    self
  }

  public subscript<T>(dynamicMember keyPath: WritableKeyPath<StoreDriver.Scope, T>) -> Binding<T> {
    binding(keyPath)
  }

  public func binding<T>(_ keyPath: WritableKeyPath<StoreDriver.Scope, T>) -> SwiftUI.Binding<T> {
    let currentValue = storeDriver.state.primitive[keyPath: keyPath]
    return .init {
      return currentValue
    } set: { [weak storeDriver] newValue, _ in
      storeDriver?.commit { [keyPath] state in
        state[keyPath: keyPath] = newValue
      }
    }
  }

  public func binding<T: Sendable>(_ keyPath: WritableKeyPath<StoreDriver.Scope, T> & Sendable)
    -> SwiftUI.Binding<T>
  {        
    return .init { [currentValue = storeDriver.state.primitive[keyPath: keyPath]] in
      return currentValue
    } set: { [weak storeDriver] newValue, _ in
      storeDriver?.commit { [keyPath] state in
        state[keyPath: keyPath] = newValue
      }
    }
  }

}

#if DEBUG

  @available(iOS 14, watchOS 7.0, tvOS 14, *)
  enum Preview_StoreReader: PreviewProvider {

    static var previews: some View {

      Group {
        Content()
      }

    }

    struct Content: View {

      @StoreObject var viewModel_1: ViewModel = .init()
      @StoreObject var viewModel_2: ViewModel = .init()

      @State var flag = false

      var body: some View {

        VStack {

          let store = flag ? viewModel_1 : viewModel_2

          StoreReader(store) { state in
            Text(state.count.description)
          }

          Button("up") {
            store.increment()
          }

          Button("swap") {
            flag.toggle()
          }

        }
      }
    }

    final class ViewModel: StoreDriverType {

      @Tracking
      struct State: Equatable {
        var count: Int = 0
        var count_dummy: Int = 0
      }

      let store: Store<State, Never>

      init() {
        self.store = .init(initialState: .init())
      }

      func increment() {
        commit {
          $0.count += 1
        }
      }

      func incrementDummy() {
        commit {
          $0.count_dummy += 1
        }
      }

      deinit {
        print("deinit")
      }
    }

  }

#endif
