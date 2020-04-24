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

/// Details in CancellableType's docs
public struct ChangesSubscription: CancellableType {
  let token: EventEmitterCancellable
 
  public func cancel() {
    token.cancel()
  }
}

/// Details in CancellableType's docs
public struct ActivitySusbscription: CancellableType {
  let token: EventEmitterCancellable
  
  public func cancel() {
    token.cancel()
  }
}

public protocol StoreType: AnyObject {
  associatedtype State
  associatedtype Activity = Never
  
  func asStore() -> Store<State, Activity>
  
  var state: State { get }
}

public typealias NoActivityStoreBase<State: StateType> = Store<State, Never>

@available(*, deprecated, renamed: "Store")
public typealias StoreBase<State, Activity> = Store<State, Activity>

/// A base object to create store.
/// You may create subclass of VergeDefaultStore
/// ```
/// final class MyStore: StoreBase<MyState> {
///   init() {
///     super.init(initialState: .init(), logger: nil)
///   }
/// }
/// ```
open class Store<State, Activity>: CustomReflectable, StoreType, DispatcherType {
  
  public var scope: WritableKeyPath<State, State> = \State.self
    
  public typealias Scope = State
    
  public typealias Dispatcher = DispatcherBase<State, Activity>
  public typealias ScopedDispatcher<Scope> = ScopedDispatcherBase<State, Activity, Scope>
  
  public typealias Value = State
  
  public var store: Store<State, Activity> { self }
  
  public let metadata: DispatcherMetadata
    
  /// A current state.
  public var state: State {
    _backingStorage.value.current
  }
  
  /// A current changes state.
  public var changes: Changes<State> {
    _backingStorage.value
  }
  
  public var __backingStorage: UnsafeMutableRawPointer {    
    Unmanaged.passUnretained(_backingStorage).toOpaque()
  }
  
  public var __activityEmitter: UnsafeMutableRawPointer {
    Unmanaged.passUnretained(_activityEmitter).toOpaque()
  }

  /// A backing storage that manages current state.
  /// You shouldn't access this directly unless special case.
  private let _backingStorage: StateStorage<Changes<State>>
  private let _activityEmitter: EventEmitter<Activity> = .init()
  
  public private(set) var logger: StoreLogger?
    
  /// An initializer
  /// - Parameters:
  ///   - initialState:
  ///   - logger: You can also use `DefaultLogger.shared`.
  public init(
    initialState: State,
    logger: StoreLogger?
  ) {
    self._backingStorage = .init(.init(old: nil, new: initialState))
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
      var current = state.current
      let r = try mutation(&current)
      state.update(with: current)
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
    
    _activityEmitter.accept(activity)
  }
  
  func setNotificationFilter(_ filter: @escaping (Changes<State>) -> Bool) {
    self._backingStorage.setNotificationFilter(filter)
  }
     
  public var customMirror: Mirror {
    return Mirror(
      self,
      children: [
      ],
      displayStyle: .struct
    )
  }
  
  public func asStore() -> Store<State, Activity> {
    self
  }
  
  /// Subscribe the state changes
  ///
  /// - Returns: Token to remove suscription if you need to do explicitly. Subscription will be removed automatically when Store deinit
  public func subscribeStateChanges(
    dropsFirst: Bool = false,
    _ receive: @escaping (Changes<State>) -> Void
  ) -> ChangesSubscription {

    if !dropsFirst {
      receive(_backingStorage.value)
    }
    
    let token = _backingStorage.addDidUpdate { newValue in
      receive(newValue)
    }
    
    return .init(token: token)
  }
  
  /// Subscribe the activity
  ///
  /// - Returns: Token to remove suscription if you need to do explicitly. Subscription will be removed automatically when Store deinit
  public func subscribeActivity(_ receive: @escaping (Activity) -> Void) -> ActivitySusbscription  {
    let token = _activityEmitter.add(receive)
    return .init(token: token)
  }
   
  public func removeStateChangesSubscription(_ subscription: ChangesSubscription) {
    _backingStorage.remove(subscription.token)
  }
  
  public func removeActivitySubscription(_ subscription: ActivitySusbscription) {
    _activityEmitter.remove(subscription.token)
  }
          
}

#if canImport(Combine)

import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension Store: ObservableObject {
  
  /// A Publisher to compatible SwiftUI
  public var objectWillChange: ObservableObjectPublisher {
    _backingStorage.objectWillChange
  }
    
}

@available(iOS 13.0, macOS 10.15, *)
extension Store {
  
  public var statePublisher: AnyPublisher<State, Never> {
    _backingStorage.valuePublisher.map(\.current).eraseToAnyPublisher()
  }
  
  public var changesPublisher: AnyPublisher<Changes<State>, Never> {
    _backingStorage.valuePublisher
  }
  
  public var activityPublisher: EventEmitter<Activity>.Publisher {
    _activityEmitter.publisher
  }
   
}

@available(iOS 13.0, macOS 10.15, *)
extension DispatcherBase: ObservableObject {

}

#endif
