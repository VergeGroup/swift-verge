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

// It would be renamed as StoreContextType
public protocol DispatcherType<Scope>: AnyObject where State == WrappedStore.State, Activity == WrappedStore.Activity {

  associatedtype WrappedStore: StoreType
  associatedtype Scope: Equatable = WrappedStore.State

  associatedtype State = WrappedStore.State
  associatedtype Activity = WrappedStore.Activity

  var store: WrappedStore { get }
  var scope: WritableKeyPath<WrappedStore.State, Scope> { get }
  var state: Changes<Scope> { get }
}

extension DispatcherType {
  /// A state that cut out from root-state with the scope key path.
  public nonisolated var state: Changes<Scope> {
    store.state.map { $0[keyPath: scope] }
  }
}

extension DispatcherType where Scope == State {
  public var scope: WritableKeyPath<WrappedStore.State, WrappedStore.State> {
    \WrappedStore.State.self
  }
}

extension DispatcherType where Scope == State {

  // MARK: - Subscribings

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
    queue: some TargetQueueType,
    receive: @escaping (Changes<State>) -> Void
  ) -> StoreSubscription {
    store.asStore()._primitive_sinkState(dropsFirst: dropsFirst, queue: queue, receive: receive)
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
    queue: MainActorTargetQueue = .mainIsolated(),
    receive: @escaping @MainActor (Changes<State>) -> Void
  ) -> StoreSubscription {
    store.asStore()._mainActor_sinkState(dropsFirst: dropsFirst, queue: queue, receive: receive)
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
  @_disfavoredOverload
  public func sinkState<Accumulate>(
    scan: Scan<Changes<State>, Accumulate>,
    dropsFirst: Bool = false,
    queue: some TargetQueueType,
    receive: @escaping (Changes<State>, Accumulate) -> Void
  ) -> StoreSubscription {
    store.asStore()._primitive_scan_sinkState(scan: scan, dropsFirst: dropsFirst, queue: queue, receive: receive)
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
  @discardableResult
  public func sinkState<Accumulate>(
    scan: Scan<Changes<State>, Accumulate>,
    dropsFirst: Bool = false,
    queue: MainActorTargetQueue = .mainIsolated(),
    receive: @escaping @MainActor (Changes<State>, Accumulate) -> Void
  ) -> StoreSubscription {
    store.asStore()._mainActor_scan_sinkState(scan: scan, dropsFirst: dropsFirst, queue: queue, receive: receive)
  }

  /// Subscribe the activity
  ///
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  @_disfavoredOverload
  public func sinkActivity(
    queue: some TargetQueueType,
    receive: @escaping (Activity) -> Void
  ) -> StoreSubscription {

    store.asStore()._primitive_sinkActivity(queue: queue, receive: receive)

  }

  /// Subscribe the activity
  ///
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  public func sinkActivity(
    queue: MainActorTargetQueue = .mainIsolated(),
    receive: @escaping @MainActor (Activity) -> Void
  ) -> StoreSubscription {

    store.asStore()._mainActor_sinkActivity(queue: queue) { activity in
      thunkToMainActor {
        receive(activity)
      }
    }

  }

}

extension DispatcherType {

  /**
    Subscribe the state that scoped

    First object always returns true from ifChanged / hasChanges / noChanges unless dropsFirst is true.

    - Parameters:
      - dropsFirst: Drops the latest value on started. if true, receive closure will call from next state updated.
      - queue: Specify a queue to receive changes object.
    - Returns: A subscriber that performs the provided closure upon receiving values.
   */
  @_disfavoredOverload
  public func sinkState(
    dropsFirst: Bool = false,
    queue: some TargetQueueType,
    receive: @escaping (Changes<Scope>) -> Void
  ) -> StoreSubscription {
    let _scope = scope

    return store.asStore().sinkState(dropsFirst: dropsFirst, queue: queue) { state in
      receive(state.map { $0[keyPath: _scope] })
    }
  }
  
  /**
    Subscribe the state that scoped

    First object always returns true from ifChanged / hasChanges / noChanges unless dropsFirst is true.

    - Parameters:
      - dropsFirst: Drops the latest value on started. if true, receive closure will call from next state updated.
      - queue: Specify a queue to receive changes object.
    - Returns: A subscriber that performs the provided closure upon receiving values.
   */
  @_disfavoredOverload
  public func sinkState(
    dropsFirst: Bool = false,
    queue: MainActorTargetQueue = .mainIsolated(),
    receive: @escaping @MainActor (Changes<Scope>) -> Void
  ) -> StoreSubscription {
    let _scope = scope

    return store.asStore().sinkState(dropsFirst: dropsFirst, queue: queue) { @MainActor state in
      receive(state.map { $0[keyPath: _scope] })
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
  @_disfavoredOverload
  public func sinkState<Accumulate>(
    scan: Scan<Changes<Scope>, Accumulate>,
    dropsFirst: Bool = false,
    queue: some TargetQueueType,
    receive: @escaping (Changes<Scope>, Accumulate) -> Void
  ) -> StoreSubscription {
    sinkState(dropsFirst: dropsFirst, queue: queue) { (changes) in
      let accumulate = scan.accumulate(changes)
      receive(changes, accumulate)
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
  @_disfavoredOverload
  public func sinkState<Accumulate>(
    scan: Scan<Changes<Scope>, Accumulate>,
    dropsFirst: Bool = false,
    queue: MainActorTargetQueue = .mainIsolated(),
    receive: @escaping @MainActor (Changes<Scope>, Accumulate) -> Void
  ) -> StoreSubscription {
    sinkState(dropsFirst: dropsFirst, queue: queue) { @MainActor changes in
      let accumulate = scan.accumulate(changes)
      receive(changes, accumulate)
    }
  }


  /// Send activity
  /// - Parameter activity:
  public func send(
    _ name: String = "",
    _ activity: WrappedStore.Activity,
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line
  ) {
    let trace = ActivityTrace(
      name: name,
      file: file.description,
      function: function.description,
      line: line
    )

    store.asStore()._send(activity: activity, trace: trace)
  }

  /// Send activity
  /// - Parameter activity:
  public func send(
    _ activity: WrappedStore.Activity,
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line
  ) {
    send("", activity, file, function, line)
  }

  /// Run Mutation that created inline
  ///
  /// Throwable
  public func commit<Result>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    mutation: (inout InoutRef<Scope>) throws -> Result
  ) rethrows -> Result {
    let trace = MutationTrace(
      name: name,
      file: file,
      function: function,
      line: line
    )

    return try store.asStore()._receive(
      mutation: { state -> Result in
        try state.map(keyPath: scope) { (ref: inout InoutRef<Scope>) -> Result in
          ref.append(trace: trace)
          return try mutation(&ref)
        }
      }
    )
  }

  /// Run Mutation that created inline
  ///
  /// Throwable
  public func commit<Result>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    mutation: (inout InoutRef<Scope>) throws -> Result
  ) rethrows -> Result where Scope == WrappedStore.State {
    let trace = MutationTrace(
      name: name,
      file: file,
      function: function,
      line: line
    )
    return try self._commit(trace: trace, mutation: mutation)
  }

  /// Run Mutation that created inline
  ///
  /// Throwable
  @inline(__always)
  func _commit<Result>(
    trace: MutationTrace,
    mutation: (inout InoutRef<Scope>) throws -> Result
  ) rethrows -> Result where Scope == WrappedStore.State {
    return try store.asStore()._receive(
      mutation: { ref -> Result in
        ref.append(trace: trace)
        return try mutation(&ref)
      }
    )
  }

  public func detached<NewScope: Equatable>(from newScope: WritableKeyPath<WrappedStore.State, NewScope>)
  -> DetachedDispatcher<WrappedStore.State, WrappedStore.Activity, NewScope> {
    .init(targetStore: store.asStore(), scope: newScope)
  }

  public func detached<NewScope: Equatable>(by appendingScope: WritableKeyPath<Scope, NewScope>)
  -> DetachedDispatcher<WrappedStore.State, WrappedStore.Activity, NewScope> {
    .init(targetStore: store.asStore(), scope: scope.appending(path: appendingScope))
  }
}
