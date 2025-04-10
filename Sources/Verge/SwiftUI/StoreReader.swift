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

  /// Needs to use Reading directly to provide the latest state when it's accessed. from escaping closure.
  private let content: (BindableReading<Reading<Driver>>) -> Content

  /// Initialize from `Store`
  ///
  /// - Parameters:
  ///   - store:
  ///   - content:
  public init(
    file: StaticString = #file,
    line: UInt = #line,
    label: StaticString? = nil,
    _ driver: Driver,
    @ViewBuilder content: @escaping (BindableReading<Reading<Driver>>) -> Content
  ) {
    self.file = file
    self.line = line
    self.storeReading = .init(
      file: file,
      line: line,
      label: label,
      driver
    )
    self.content = content

  }

  public var body: some View {    
    content(storeReading.projectedValue)
  }

}
