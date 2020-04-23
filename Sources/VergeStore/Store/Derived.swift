//
// Copyright (c) 2020 Hiroshi Kimura(Muukii) <muuki.app@gmail.com>
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

public class Derived<State> {
  
  public static func constant(_ value: State) -> Derived<State> {
    .init(constant: value)
  }
        
  /// A current state.
  public var state: State {
    innerStore.state
  }
  
  /// A current changes state.
  public var changes: Changes<State> {
    innerStore.changes
  }
  
  fileprivate let innerStore: Store<State, Never>
      
  fileprivate let _set: (State) -> Void
    
  private init(constant: State) {
    self.innerStore = .init(initialState: constant, logger: nil)
    self._set = { _ in }
    self.subscription = .init(onDeinit: {})
  }
  
  private let subscription: UntilDeinitCancellable
      
  public init<UpstreamState>(
    get: MemoizeMap<UpstreamState, State>,
    set: @escaping (State) -> Void,
    initialUpstreamState: UpstreamState,
    subscribeUpstreamState: (@escaping (UpstreamState) -> Void) -> CancellableType,
    retainsUpstream: AnyObject?
  ) {
    
    let store = Store<State, Never>.init(initialState: get.makeInitial(initialUpstreamState), logger: nil)
                     
    let s = subscribeUpstreamState { [weak store] value in
      let update = get.makeResult(value)
      switch update {
      case .noChanages:
        break
      case .updated(let newState):
        store?.commit {
          $0 = newState
        }
      }
    }
    
    self.subscription = UntilDeinitCancellable.init(s)
    self._set = set
    self.innerStore = store
  }

  deinit {
    
  }
    
  ///
  /// - Parameter postFilter: Returns the objects are equals
  /// - Returns:
  @discardableResult
  public func dropsOutput(_ dropsOutput: @escaping (Changes<State>) -> Bool) -> Self {
    innerStore.setNotificationFilter { changes in
      !dropsOutput(changes)
    }

    return self
  }
  
  /// Subscribe the state changes
  ///
  /// - Returns: Token to remove suscription if you need to do explicitly. Subscription will be removed automatically when Store deinit
  @discardableResult
  public func subscribeStateChanges(dropsFirst: Bool = false, _ receive: @escaping (Changes<State>) -> Void) -> ChangesSubscription {
    innerStore.subscribeStateChanges(dropsFirst: dropsFirst) { (changes) in
      receive(changes)
    }
  }
  
  public func chain<NewState>(_ map: MemoizeMap<Changes<State>, NewState>) -> Derived<NewState> {
    
    return .init(
      get: map,
      set: { _ in },
      initialUpstreamState: changes,
      subscribeUpstreamState: { callback in
        self.innerStore.subscribeStateChanges(dropsFirst: true, callback)
    }, retainsUpstream: self)
    
  }
  
}

#if canImport(Combine)

import Combine

@available(iOS 13, macOS 10.15, *)
extension Derived: ObservableObject {
  public var objectWillChange: ObservableObjectPublisher {
    innerStore.objectWillChange
  }
}

#endif

public final class BindingDerived<State>: Derived<State> {
  
  /// A current state.
  public override var state: State {
    get { innerStore.state }
    set { _set(newValue) }
  }
  
}

extension StoreType {
  
  public func derived<NewState>(
    _ memoizeMap: MemoizeMap<Changes<State>, NewState>,
    dropsOutput: (Changes<NewState>) -> Bool = { _ in false }
  ) -> Derived<NewState> {
    
    return .init(
      get: memoizeMap,
      set: { _ in
        
    },
      initialUpstreamState: asStore().changes,
      subscribeUpstreamState: { callback in
        asStore().subscribeStateChanges(dropsFirst: true, callback)
    }, retainsUpstream: nil)
  }
  
  public func derived<NewState: Equatable>(
    _ memoizeMap: MemoizeMap<Changes<State>, NewState>
  ) -> Derived<NewState> {
    derived(memoizeMap, dropsOutput: { $0.asChanges().noChanges(\.root) })
  }
  
  public func binding<NewState>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    get: MemoizeMap<Changes<State>, NewState>,
    dropsOutput: (Changes<NewState>) -> Bool = { _ in false },
    set: @escaping (inout State, NewState) -> Void
  ) -> BindingDerived<NewState> {
    
    return .init(
      get: get,
      set: { [weak self] state in
        self?.asStore().commit(name, file, function, line) {
          set(&$0, state)
        }
    },
      initialUpstreamState: asStore().changes,
      subscribeUpstreamState: { callback in
        asStore().subscribeStateChanges(dropsFirst: true, callback)
    }, retainsUpstream: nil)
    
  }
  
  public func binding<NewState: Equatable>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    get: MemoizeMap<Changes<State>, NewState>,
    set: @escaping (inout State, NewState) -> Void
  ) -> BindingDerived<NewState> {
    
    binding(
      name,
      file,
      function,
      line,
      get: get,
      dropsOutput: { $0.asChanges().noChanges(\.root) },
      set: set
    )
  }
  
}
