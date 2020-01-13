//
// Copyright (c) 2019 muukii
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

#if !COCOAPODS
import VergeCore
#endif

/// A metadata object that indicates the name of the mutation and where it was caused.
public struct MutationMetadata {
  
  public let name: String
  public let file: StaticString
  public let function: StaticString
  public let line: UInt
  
  public init(name: String, file: StaticString, function: StaticString, line: UInt) {
    self.name = name
    self.file = file
    self.function = function
    self.line = line
  }
}

/// A metadata object that indicates the name of the action and where it was caused.
public struct ActionMetadata {
  
  public let name: String
  public let file: StaticString
  public let function: StaticString
  public let line: UInt
  
  public init(name: String, file: StaticString, function: StaticString, line: UInt) {
    self.name = name
    self.file = file
    self.function = function
    self.line = line
  }
}

/// A protocol to register logger and get the event VergeStore emits.
public protocol VergeStoreLogger {
  
  func willCommit(store: AnyObject, state: Any, mutation: MutationBaseType, context: Any?)
  func didCommit(store: AnyObject, state: Any, mutation: MutationBaseType, context: Any?, time: CFTimeInterval)
  func didDispatch(store: AnyObject, state: Any, action: ActionMetadata, context: Any?)
  
  func didCreateDispatcher(store: AnyObject, dispatcher: Any)
  func didDestroyDispatcher(store: AnyObject, dispatcher: Any)
}

public protocol VergeStoreType: AnyObject {
  associatedtype State
  associatedtype Activity  
}

public typealias NoActivityStoreBase<State> = StoreBase<State, Never>

/// A base object to create store.
/// You may create subclass of VergeDefaultStore
/// ```
/// final class MyStore: VergeDefaultStore<MyState> {
///   init() {
///     super.init(initialState: .init(), logger: nil)
///   }
/// }
/// ```
open class StoreBase<State, Activity>: CustomReflectable, VergeStoreType {
  
  public typealias Dispatcher = DispatcherBase<State, Activity>
  
  public typealias Value = State
    
  /// A current state.
  public var state: State {
    _backingStorage.value
  }

  /// A backing storage that manages current state.
  /// You shouldn't access this directly unless special case.
  public let _backingStorage: Storage<State>
  public let _eventEmitter: EventEmitter<Activity> = .init()
  
  public private(set) var logger: VergeStoreLogger?
    
  /// An initializer
  /// - Parameters:
  ///   - initialState:
  ///   - logger: You can also use `DefaultLogger.shared`.
  public init(
    initialState: State,
    logger: VergeStoreLogger?
  ) {
    
    self._backingStorage = .init(initialState)
    self.logger = logger
    
  }
  
  @inline(__always)
  func _receive<FromDispatcher: DispatcherType, Mutation: MutationType>(
    context: DispatcherContext<FromDispatcher>?,
    mutation: Mutation
  ) -> Mutation.Result where FromDispatcher.State == State, Mutation.State == State {
    
    logger?.willCommit(store: self, state: self.state, mutation: mutation, context: context)
    
    let startedTime = CFAbsoluteTimeGetCurrent()
    var currentState: State!
    
    let signpost = VergeSignpostTransaction("Store.commit")
    
    let returnValue = _backingStorage.update { (state) -> Mutation.Result in
      let r = mutation.mutate(state: &state)
      currentState = state
      return r
    }
    
    signpost.end()
    
    let elapsed = CFAbsoluteTimeGetCurrent() - startedTime
    
    logger?.didCommit(store: self, state: currentState!, mutation: mutation, context: context, time: elapsed)
    return returnValue
  }
  
  @inline(__always)
  func _send(activity: Activity) {
    
    _eventEmitter.accept(activity)
  }
     
  public var customMirror: Mirror {
    return Mirror(
      self,
      children: [
      ],
      displayStyle: .struct
    )
  }
      
}

#if canImport(Combine)

import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension StoreBase: ObservableObject {
  
  /// A Publisher to compatible SwiftUI
  public var objectWillChange: ObservableObjectPublisher {
    _backingStorage.objectWillChange
  }
    
}

@available(iOS 13.0, macOS 10.15, *)
extension StoreBase {
  
  public var didChangePublisher: AnyPublisher<State, Never> {
    _backingStorage.didChangePublisher
  }
  
  public var activityPublisher: EventEmitter<Activity>.Publisher {
    _eventEmitter.publisher
  }
  
  @available(iOS 13, macOS 10.15, *)
  public func getter<Output>(
    filter: @escaping (Value) -> Bool,
    map: @escaping (Value) -> Output
  ) -> GetterSource<Value, Output> {
    
    _backingStorage.getter(filter: filter, map: map)
    
  }
}

@available(iOS 13.0, macOS 10.15, *)
extension DispatcherBase: ObservableObject {

}

#endif
