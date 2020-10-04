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

/// A protocol that indicates itself is a reference-type and can convert to concrete Store type.
public protocol StoreType: AnyObject {
  associatedtype State
  associatedtype Activity = Never
  
  func asStore() -> Store<State, Activity>
  
  var primitiveState: State { get }
}

public typealias NoActivityStoreBase<State: StateType> = Store<State, Never>

@available(*, deprecated, renamed: "Store")
public typealias StoreBase<State, Activity> = Store<State, Activity>

/// An object that retains a latest state value and receives mutations that modify itself state.
/// Those updates would be shared all of the subscribers these are sink(s), Derived(s)
///
/// You may create subclass of VergeDefaultStore
/// ```
/// final class MyStore: Store<MyState> {
///   init() {
///     super.init(initialState: .init(), logger: nil)
///   }
/// }
/// ```
/// You may use also `StoreWrapperType` to define State and Activity as inner types.
///
open class Store<State, Activity>: _VergeObservableObjectBase, CustomReflectable, StoreType, DispatcherType {

  public typealias Scope = State
  public typealias Dispatcher = DispatcherBase<State, Activity>
  public typealias ScopedDispatcher<Scope> = ScopedDispatcherBase<State, Activity, Scope>
  public typealias Value = State

  #if canImport(Combine)
  /// A Publisher to compatible SwiftUI
  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  public final override var objectWillChange: ObservableObjectPublisher {
    _backingStorage.objectWillChange
  }
  #endif
  
  public var scope: WritableKeyPath<State, State> = \State.self
  
  public var store: Store<State, Activity> { self }
      
  /// A current state.
  ///
  /// It causes locking and unlocking with a bit cost.
  /// It may cause blocking if any other is doing mutation or reading.
  public var primitiveState: State {
    _backingStorage.value.primitive
  }

  /// Returns a current state with thread-safety.
  ///
  /// It causes locking and unlocking with a bit cost.
  /// It may cause blocking if any other is doing mutation or reading.
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
  ///   - initialState: A state instance that will be modified by the first commit.
  ///   - backingStorageRecursiveLock: A lock instance for mutual exclusion.
  ///   - logger: You can also use `DefaultLogger.shared`.
  public init(
    initialState: State,
    backingStorageRecursiveLock: VergeAnyRecursiveLock? = nil,
    logger: StoreLogger? = nil
  ) {

    self._backingStorage = .init(
      .init(old: nil, new: initialState),
      recursiveLock: backingStorageRecursiveLock ?? NSRecursiveLock().asAny()
    )

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
    logger?.didCommit(log: log, sender: self)
    return returnValue
  }
 
  @inline(__always)
  func _send(
    activity: Activity,
    trace: ActivityTrace
  ) {
    
    _activityEmitter.accept(activity)
    
    let log = ActivityLog(store: self, trace: trace)
    logger?.didSendActivity(log: log, sender: self)
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
  ///   - scheduler: Specify a queue to receive changes object.
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  public func sinkState(
    dropsFirst: Bool = false,
    scheduler: Scheduler = .asyncMain,
    receive: @escaping (Changes<State>) -> Void
  ) -> VergeAnyCancellable {

    let execute = scheduler.executor()

    /// Firstly, it registers a closure to make sure that it receives all of the updates, even updates inside the first call.
    let cancellable = _backingStorage.addDidUpdate { newValue in
      execute {
        receive(newValue)
      }
    }

    if !dropsFirst {
      let value = _backingStorage.value.droppedPrevious()
      execute {
        /// this closure might contains some mutations.
        ///  It depends outside usages.
        receive(value)
      }
    }

    return .init(cancellable)

  }

  /// Subscribe the state changes
  ///
  /// First object always returns true from ifChanged / hasChanges / noChanges unless dropsFirst is true.
  ///
  /// - Parameters:
  ///   - scan: Accumulates a specified type of value over receiving updates.
  ///   - dropsFirst: Drops the latest value on started. if true, receive closure will call from next state updated.
  ///   - scheduler: Specify a queue to receive changes object.
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  public func sinkState<Accumulate>(
    scan: Scan<Changes<State>, Accumulate>,
    dropsFirst: Bool = false,
    scheduler: Scheduler = .asyncMain,
    receive: @escaping (Changes<State>, Accumulate) -> Void
  ) -> VergeAnyCancellable {

    sinkState(
      dropsFirst: dropsFirst,
      scheduler: scheduler
    ) { (changes) in

      let accumulate = scan.accumulate(changes)
      receive(changes, accumulate)
    }

  }

}
