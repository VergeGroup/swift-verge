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
public struct StoreReader<Driver: StoreDriverType, Content: View>: View where Driver.TargetStore.State : TrackingObject {
  
  let storeReading: Reading<Driver>

  private let file: StaticString
  private let line: UInt

  private let content: @MainActor (Reading<Driver>) -> Content

  /// Initialize from `Store`
  ///
  /// - Parameters:
  ///   - store:
  ///   - content:
  public init(
    file: StaticString = #file,
    line: UInt = #line,
    _ driver: Driver,
    @ViewBuilder content: @escaping @MainActor (Reading<Driver>) -> Content
  ) {
    self.file = file
    self.line = line
    self.storeReading = .init(driver)
    self.content = content

  }

  public var body: some View {    
    content(storeReading)
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
