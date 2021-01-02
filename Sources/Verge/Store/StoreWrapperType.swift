//
// Copyright (c) 2020 Hiroshi Kimura(Muukii) <muukii.app@gmail.com>
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

/**
 A protocol that wraps Store inside and provides the functions of DispatcherType
 
 Especially, it would be helpful to migrate from Verge classic.
 
 ```
 final class MyViewModel: StoreComponentType {
 
   // Current restriction, you need put the typealias as Scope points to State.
   typealias Scope = State
   
   struct State {
     ...
   }

   // If you don't need Activity, you can remove it.
   enum Activity {
     ...
   }
   
   let store: DefaultStore
 
   init() {
     self.store = .init(initialState: .init(), logger: nil)
   }
 
 }
 ``` 
 */
public protocol StoreComponentType: StoreType, DispatcherType {
  
  associatedtype State = WrappedStore.State
  associatedtype Activity = WrappedStore.Activity
    
  associatedtype Scope
  var store: WrappedStore { get }
}

/// It would be deprecated in the future.
public typealias StoreWrapperType = StoreComponentType

extension StoreComponentType {
  public typealias DefaultStore = Store<State, Activity>
}

extension StoreComponentType where State == WrappedStore.State, Activity == WrappedStore.Activity {
  @inline(__always)
  public func asStore() -> Store<State, Activity> {
    store.asStore()
  }
}

extension StoreComponentType {

  /// Returns a current state with thread-safety.
  ///
  /// It causes locking and unlocking with a bit cost.
  /// It may cause blocking if any other is doing mutation or reading.
  public var state: Changes<WrappedStore.State> {
    store.asStore().state
  }

  @available(*, deprecated, renamed: "state")
  public var changes: Changes<WrappedStore.State> {
    store.asStore().changes
  }
  
  public var primitiveState: WrappedStore.State {
    store.primitiveState
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
    queue: TargetQueue = .mainIsolated(),
    receive: @escaping (Changes<WrappedStore.State>) -> Void
  ) -> VergeAnyCancellable {
    store.asStore().sinkState(dropsFirst: dropsFirst, queue: queue, receive: receive)
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
    scan: Scan<Changes<WrappedStore.State>, Accumulate>,
    dropsFirst: Bool = false,
    queue: TargetQueue = .mainIsolated(),
    receive: @escaping (Changes<WrappedStore.State>, Accumulate) -> Void
  ) -> VergeAnyCancellable {
    store.asStore().sinkState(scan: scan, dropsFirst: dropsFirst, queue: queue, receive: receive)
  }
  
  /// Subscribe the activity
  ///
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  public func sinkActivity(
    queue: TargetQueue = .mainIsolated(),
    receive: @escaping (WrappedStore.Activity) -> Void
  ) -> VergeAnyCancellable  {
    store.asStore().sinkActivity(queue: queue, receive: receive)
  }
 
}

#if canImport(Combine)

import Combine

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension StoreComponentType where State == WrappedStore.State, Activity == WrappedStore.Activity {
  
  public func statePublisher(startsFromInitial: Bool = true) -> AnyPublisher<Changes<State>, Never> {
    store.asStore().statePublisher(startsFromInitial: startsFromInitial)
  }
  
  @available(*, deprecated, renamed: "statePublisher")
  public func changesPublisher(startsFromInitial: Bool = true) -> AnyPublisher<Changes<State>, Never> {
    store.asStore().statePublisher(startsFromInitial: startsFromInitial)
  }
  
  public var activityPublisher: EventEmitter<Activity>.Publisher {
    store.asStore().activityPublisher
  }
  
}

#endif
