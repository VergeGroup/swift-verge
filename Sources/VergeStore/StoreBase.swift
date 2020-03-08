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
@_exported import VergeCore
#endif

public protocol StoreType: AnyObject {
  associatedtype State: StateType
  associatedtype Activity
  
  func asStoreBase() -> StoreBase<State, Activity>
}

public typealias NoActivityStoreBase<State: StateType> = StoreBase<State, Never>

/// A base object to create store.
/// You may create subclass of VergeDefaultStore
/// ```
/// final class MyStore: VergeDefaultStore<MyState> {
///   init() {
///     super.init(initialState: .init(), logger: nil)
///   }
/// }
/// ```
open class StoreBase<State: StateType, Activity>: CustomReflectable, StoreType, DispatcherType {
  
  public var scope: WritableKeyPath<State, State> = \State.self
    
  public typealias Scope = State
    
  public typealias Dispatcher = DispatcherBase<State, Activity>
  public typealias ScopedDispatcher<Scope> = ScopedDispatcherBase<State, Activity, Scope>
  
  public typealias Value = State
  
  public var target: StoreBase<State, Activity> { self }
  
  public let metadata: DispatcherMetadata
    
  /// A current state.
  public var state: State {
    _backingStorage.value
  }

  /// A backing storage that manages current state.
  /// You shouldn't access this directly unless special case.
  public let _backingStorage: Storage<State>
  public let _eventEmitter: EventEmitter<Activity> = .init()
  
  public private(set) var logger: StoreLogger?
    
  /// An initializer
  /// - Parameters:
  ///   - initialState:
  ///   - logger: You can also use `DefaultLogger.shared`.
  public init(
    initialState: State,
    logger: StoreLogger?
  ) {
    
    self._backingStorage = .init(initialState)
    self.logger = logger
    self.metadata = .init(fromAction: nil)
    
  }
  
  @inline(__always)
  func _receive<Result>(
    metadata: MutationMetadata,
    mutation: (inout State) throws -> Result
  ) rethrows -> Result {
                
    let signpost = VergeSignpostTransaction("Store.commit")
    var elapsed: CFTimeInterval = 0
    
    let returnValue = try _backingStorage.update { (state) -> Result in
      let startedTime = CFAbsoluteTimeGetCurrent()
      let r = try mutation(&state)
      elapsed = CFAbsoluteTimeGetCurrent() - startedTime
      return r
    }
    
    signpost.end()
    
    let log = CommitLog(store: self, mutation: metadata, time: elapsed)
    logger?.didCommit(log: log)
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
  
  public func asStoreBase() -> StoreBase<State, Activity> {
    self
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
  public func makeGetter<PreComparingKey, Output, PostComparingKey>(
    from builder: GetterBuilder<State, PreComparingKey, Output, PostComparingKey>
  ) -> GetterSource<State, Output> {
    _backingStorage.makeGetter(from: builder)
  }
   
}

@available(iOS 13.0, macOS 10.15, *)
extension DispatcherBase: ObservableObject {

}

#endif
