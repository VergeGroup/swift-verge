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

  private let backgroundWritingQueueKey = DispatchSpecificKey<Void>()

  private let backgroundWritingQueue = DispatchQueue(
    label: "org.verge.background.commit",
    qos: .default,
    attributes: [],
    autoreleaseFrequency: .workItem,
    target: nil
  )

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

    backgroundWritingQueue.setSpecific(key: backgroundWritingQueueKey, value: ())

  }

  /**
   Handles a updated state
   */
  open func receive(state: Changes<State>) {

  }

  @inline(__always)
  func _async_receive<ReturnType>(
    mutation: @escaping (inout State) throws -> ReturnType,
    trace: MutationTrace,
    completion: @escaping (Result<ReturnType, Error>) -> Void
  ) {

    backgroundWritingQueue.async { [weak self] in
      guard let self = self else {
        return
      }

      do {
        let result = try self._receive(trace: trace, mutation: mutation)
        completion(.success(result))
      } catch {
        completion(.failure(error))
      }
    }

  }

  @inline(__always)
  func _receive<Result>(
    trace: MutationTrace,
    mutation: (inout State) throws -> Result
  ) rethrows -> Result {

    func work() throws -> Result {
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

    if DispatchQueue.getSpecific(key: backgroundWritingQueueKey) == nil {
      return try backgroundWritingQueue.sync(execute: work)
    } else {
      return try work()
    }

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
  ///   - queue: Specify a queue to receive changes object.
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  public func sinkState(
    dropsFirst: Bool = false,
    queue: TargetQueue? = nil,
    receive: @escaping (Changes<State>) -> Void
  ) -> VergeAnyCancellable {
    
    if let execute = queue?.executor() {

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
      
    } else {

      /// Firstly, it registers a closure to make sure that it receives all of the updates, even updates inside the first call.
      let cancellable = _backingStorage.addDidUpdate { newValue in
        receive(newValue)
      }

      if !dropsFirst {
        /// this closure might contains some mutations.
        ///  It depends outside usages.
        receive(_backingStorage.value.droppedPrevious())
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
