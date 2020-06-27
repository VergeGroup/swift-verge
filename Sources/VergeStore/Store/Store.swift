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

#if canImport(Combine)
import Combine
#endif

public protocol StoreType: AnyObject {
  associatedtype State
  associatedtype Activity = Never
  
  func asStore() -> Store<State, Activity>
  
  var primitiveState: State { get }
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
open class Store<State, Activity>: _VergeObservableObjectBase, CustomReflectable, StoreType, DispatcherType {

  public typealias Scope = State
  public typealias Dispatcher = DispatcherBase<State, Activity>
  public typealias ScopedDispatcher<Scope> = ScopedDispatcherBase<State, Activity, Scope>
  public typealias Value = State

  #if canImport(Combine)
  /// A Publisher to compatible SwiftUI
  @available(iOS 13.0, macOS 10.15, *)
  public final override var objectWillChange: ObservableObjectPublisher {
    _backingStorage.objectWillChange
  }
  #endif
  
  public var scope: WritableKeyPath<State, State> = \State.self
  
  public var store: Store<State, Activity> { self }
      
  /// A current state.
  public var primitiveState: State {
    _backingStorage.value.primitive
  }
  
  public var state: Changes<State> {
    _backingStorage.value
  }
  
  /// A current changes state.
  @available(*, deprecated, renamed: "state")
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
  let _backingStorage: StateStorage<Changes<State>>
  let _activityEmitter: EventEmitter<Activity> = .init()
    
  /// Cache for derived object each method. Don't share it with between methods.
  let derivedCache1 = VergeConcurrency.UnfairLockAtomic(NSMapTable<NSString, AnyObject>.strongToWeakObjects())
  
  /// Cache for derived object each method. Don't share it with between methods.
  let derivedCache2 = VergeConcurrency.UnfairLockAtomic(NSMapTable<NSString, AnyObject>.strongToWeakObjects())
  
  public private(set) var logger: StoreLogger?

  private var sinkCancellable: VergeAnyCancellable? = nil
    
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

    super.init()

    sinkCancellable = sinkState { [weak self] state in
      self?.receive(state: state)
    }

  }

  /**
   Handles a updated state
   */
  open func receive(state: Changes<State>) {

  }

  @inline(__always)
  func _receive<Result>(
    mutation: (inout State) throws -> Result,
    trace: MutationTrace
  ) rethrows -> Result {
                
    let signpost = VergeSignpostTransaction("Store.commit")
    defer {
      signpost.end()
    }
    
    var elapsed: CFTimeInterval = 0
    
    let returnValue = try _backingStorage.update { (state) -> Result in
      let startedTime = CFAbsoluteTimeGetCurrent()
      var current = state.primitive
      let r = try mutation(&current)
      state = state.makeNextChanges(with: current)
      elapsed = CFAbsoluteTimeGetCurrent() - startedTime
      return r
    }
       
    let log = CommitLog(store: self, trace: trace, time: elapsed)
    logger?.didCommit(log: log)
    return returnValue
  }
 
  @inline(__always)
  func _send(
    activity: Activity,
    trace: ActivityTrace
  ) {
    
    _activityEmitter.accept(activity)
    
    let log = ActivityLog(store: self, trace: trace)
    logger?.didSendActivity(log: log)
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

  @inline(__always)
  public func asStore() -> Store<State, Activity> {
    self
  }
  
  /// Subscribe the state changes
  ///
  /// First object always returns true from ifChanged / hasChanges / noChanges unless dropsFirst is true.
  ///
  /// - Parameters:
  ///   - dropsFirst: Drops the latest value on started. if true, receive closure will call from next state updated.
  ///   - queue: Specify a queue to receive changes object.
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  public func sinkState(
    dropsFirst: Bool = false,
    queue: TargetQueue? = nil,
    receive: @escaping (Changes<State>) -> Void
  ) -> VergeAnyCancellable {
    
    if let execute = queue?.executor() {
      
      if !dropsFirst {
        let value = _backingStorage.value.droppedPrevious()
        execute {
          receive(value)
        }
      }
      
      let cancellable = _backingStorage.addDidUpdate { newValue in
        execute {
          receive(newValue)
        }
      }
      
      return .init(cancellable)
      
    } else {

      if !dropsFirst {
        receive(_backingStorage.value.droppedPrevious())
      }
      
      let cancellable = _backingStorage.addDidUpdate { newValue in
        receive(newValue)
      }
      
      return .init(cancellable)
    }
    
  }

  /// Subscribe the state changes
  ///
  /// First object always returns true from ifChanged / hasChanges / noChanges unless dropsFirst is true.
  ///
  /// - Parameters:
  ///   - scan: Accumulates a specified type of value over receiving updates.
  ///   - dropsFirst: Drops the latest value on started. if true, receive closure will call from next state updated.
  ///   - queue: Specify a queue to receive changes object.
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  public func sinkState<Accumulate>(
    scan: Scan<Changes<State>, Accumulate>,
    dropsFirst: Bool = false,
    queue: TargetQueue? = nil,
    receive: @escaping (Changes<State>, Accumulate) -> Void
  ) -> VergeAnyCancellable {

    sinkState(dropsFirst: dropsFirst, queue: queue) { (changes) in

      let accumulate = scan.accumulate(changes)
      receive(changes, accumulate)
    }

  }

  /// Subscribe the state changes
  ///
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  @available(*, deprecated, renamed: "sinkState")
  public func sinkChanges(
    dropsFirst: Bool = false,
    queue: TargetQueue? = nil,
    receive: @escaping (Changes<State>) -> Void
  ) -> VergeAnyCancellable {
    sinkState(dropsFirst: dropsFirst, queue: queue, receive: receive)
  }
  
  /// Subscribe the state changes
  ///
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  @available(*, deprecated, renamed: "sinkState")
  public func subscribeChanges(
    dropsFirst: Bool = false,
    queue: TargetQueue? = nil,
    receive: @escaping (Changes<State>) -> Void
  ) -> VergeAnyCancellable {
    sinkState(dropsFirst: dropsFirst, queue: queue, receive: receive)
  }
  
  /// Subscribe the activity
  ///
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  public func sinkActivity(
    queue: TargetQueue? = nil,
    receive: @escaping (Activity) -> Void
  ) -> VergeAnyCancellable {
    
    if let execute = queue?.executor() {
      let cancellable = _activityEmitter.add { (activity) in
        execute {
          receive(activity)
        }
      }
      return .init(cancellable)
    } else {
      //      let lock = NSRecursiveLock()
      let cancellable = _activityEmitter.add { activity in
        //        lock.lock(); defer { lock.unlock() }
        receive(activity)
      }
      return .init(cancellable)
    }
    
  }
  
  /// Subscribe the activity
  ///
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  @available(*, deprecated, renamed: "sinkActivity")
  public func subscribeActivity(
    queue: TargetQueue? = nil,
    receive: @escaping (Activity) -> Void
  ) -> VergeAnyCancellable {
    sinkActivity(queue: queue, receive: receive)
  }
             
}
