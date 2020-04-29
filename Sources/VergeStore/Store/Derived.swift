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

public protocol DerivedType {
  associatedtype Value
  
  func asDerived() -> Derived<Value>
}

/// A container object that provides the current value and changes from the source Store.
public class Derived<Value>: DerivedType {
  
  public static func constant(_ value: Value) -> Derived<Value> {
    .init(constant: value)
  }
  
  /// A current state.
  public var value: Value {
    innerStore.state
  }
  
  /// A current changes state.
  public var changes: Changes<Value> {
    innerStore.changes
  }
  
  fileprivate let innerStore: Store<Value, Never>
  
  public var _innerStore: UnsafeMutableRawPointer {
    Unmanaged.passUnretained(innerStore).toOpaque()
  }
      
  fileprivate let _set: (Value) -> Void
  
  private let subscription: VergeAnyCancellable
  private let retainsUpstream: Any?
  
  // MARK: - Initializers
      
  private init(constant: Value) {
    self.innerStore = .init(initialState: constant, logger: nil)
    self._set = { _ in }
    self.subscription = .init(onDeinit: {})
    self.retainsUpstream = nil
  }
        
  public init<UpstreamState>(
    get: MemoizeMap<UpstreamState, Value>,
    set: @escaping (Value) -> Void,
    initialUpstreamState: UpstreamState,
    subscribeUpstreamState: (@escaping (UpstreamState) -> Void) -> CancellableType,
    retainsUpstream: Any?
  ) {
    
    let store = Store<Value, Never>.init(initialState: get.makeInitial(initialUpstreamState), logger: nil)
                     
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
    
    self.retainsUpstream = retainsUpstream
    self.subscription = VergeAnyCancellable.init(s)
    self._set = set
    self.innerStore = store
  }

  deinit {
    
  }
  
  // MARK: - Functions
  
  public func asDerived() -> Derived<Value> {
    self
  }
    
  ///
  /// - Parameter postFilter: Returns the objects are equals
  /// - Returns:
  @discardableResult
  fileprivate func setDropsOutput(_ dropsOutput: @escaping (Changes<Value>) -> Bool) -> Self {
    innerStore.setNotificationFilter { changes in
      !dropsOutput(changes)
    }

    return self
  }
  
  /// Subscribe the state changes
  ///
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  public func subscribeChanges(
    dropsFirst: Bool = false,
    queue: DispatchQueue? = nil,
    receive: @escaping (Changes<Value>) -> Void
  ) -> VergeAnyCancellable {
    
    innerStore.subscribeChanges(
    dropsFirst: dropsFirst,
    queue: queue
    ) { (changes) in
      withExtendedLifetime(self) {}
      receive(changes)
    }
    .asAutoCancellable()
  }
    
  /// Make a new Derived object that projects the specified shape of the object from the object itself projects.
  /// - Parameters:
  ///   - queue: a queue to receive object
  ///   - map:
  ///   - dropsOutput: a condition to drop a duplicated(no-changes) object. (Default: no drops)
  /// - Returns:
  public func chain<NewState>(
    _ map: MemoizeMap<Changes<Value>, NewState>,
    dropsOutput: @escaping (Changes<NewState>) -> Bool = { _ in false },
    queue: DispatchQueue? = nil
    ) -> Derived<NewState> {
        
    let d = Derived<NewState>(
      get: map,
      set: { _ in },
      initialUpstreamState: changes,
      subscribeUpstreamState: { callback in
        self.innerStore.subscribeChanges(
          dropsFirst: true,
          queue: queue,
          receive: callback
        )
    },
      retainsUpstream: self
    )
    
    d.setDropsOutput(dropsOutput)
    
    return d
    
  }
  
}

extension Derived where Value == Any {
    
  /// Make Derived that projects combined value from specified source Derived objects.
  ///
  /// It retains specified Derived objects as data source until itself deallocated
  ///
  /// - Parameters:
  ///   - s0:
  ///   - s1:
  /// - Returns:
  public static func combined<S0, S1>(_ s0: Derived<S0>, _ s1: Derived<S1>) -> Derived<(S0, S1)> {
    
    typealias Shape = (S0, S1)
    
    let initial = (s0.value, s1.value)
    
    let buffer = VergeConcurrency.Atomic<Shape>.init(initial)
    
    return Derived<Shape>(
      get: MemoizeMap<Shape, Shape>.init(map: { $0 }),
      set: { _, _ in },
      initialUpstreamState: initial,
      subscribeUpstreamState: { callback in
                
        let _s0 = s0.subscribeChanges(dropsFirst: true, queue: nil) { (s0) in
          buffer.modify { value in
            value.0 = s0.current
            callback(value)
          }
        }
        
        let _s1 = s1.subscribeChanges(dropsFirst: true, queue: nil) { (s1) in
          buffer.modify { value in
            value.1 = s1.current
            callback(value)
          }
        }
        
        return VergeAnyCancellable(onDeinit: {
          _s0.cancel()
          _s1.cancel()
        })
        
    },
      retainsUpstream: [s0, s1]
    )
    
  }
    
  /// Make Derived that projects combined value from specified source Derived objects.
  ///
  /// It retains specified Derived objects as data source until itself deallocated
  ///
  /// - Parameters:
  ///   - s0:
  ///   - s1:
  ///   - s2:
  /// - Returns:
  public static func combined<S0, S1, S2>(_ s0: Derived<S0>, _ s1: Derived<S1>, _ s2: Derived<S2>) -> Derived<(S0, S1, S2)> {
    
    typealias Shape = (S0, S1, S2)
    
    let initial = (s0.value, s1.value, s2.value)
    
    let buffer = VergeConcurrency.Atomic<Shape>.init(initial)
    
    return Derived<Shape>(
      get: MemoizeMap<Shape, Shape>.init(map: { $0 }),
      set: { _, _, _ in },
      initialUpstreamState: initial,
      subscribeUpstreamState: { callback in
        
        let _s0 = s0.subscribeChanges(dropsFirst: true, queue: nil) { (s0) in
          buffer.modify { value in
            value.0 = s0.current
            callback(value)
          }
        }
        
        let _s1 = s1.subscribeChanges(dropsFirst: true, queue: nil) { (s1) in
          buffer.modify { value in
            value.1 = s1.current
            callback(value)
          }
        }
        
        let _s2 = s2.subscribeChanges(dropsFirst: true, queue: nil) { (s2) in
          buffer.modify { value in
            value.2 = s2.current
            callback(value)
          }
        }
        
        return VergeAnyCancellable(onDeinit: {
          _s0.cancel()
          _s1.cancel()
          _s2.cancel()
        })
        
    },
      retainsUpstream: [s0, s1]
    )
    
  }
  
}

#if canImport(Combine)

import Combine

@available(iOS 13, macOS 10.15, *)
extension Derived: ObservableObject {
  public var objectWillChange: ObservableObjectPublisher {
    innerStore.objectWillChange
  }
  
  /// A publisher that repeatedly emits the current state when state updated
  ///
  /// Guarantees to emit the first event on started subscribing.
  public var valuePublisher: AnyPublisher<Value, Never> {
    innerStore.statePublisher
      .handleEvents(receiveCancel: {
        withExtendedLifetime(self) {}
      })
      .eraseToAnyPublisher()
  }
  
  /// A publisher that repeatedly emits the changes when state updated
  ///
  /// Guarantees to emit the first event on started subscribing.
  ///
  /// - Parameter startsFromInitial: Make the first changes object's hasChanges always return true.
  /// - Returns:
  public func changesPublisher(startsFromInitial: Bool = true) -> AnyPublisher<Changes<Value>, Never> {
    innerStore.changesPublisher(startsFromInitial: startsFromInitial)
      .handleEvents(receiveCancel: {
        withExtendedLifetime(self) {}
      })
      .eraseToAnyPublisher()
  }
}

#endif

@propertyWrapper
public final class BindingDerived<State>: Derived<State> {
  
  /// A current state.
  public override var value: State {
    get { innerStore.state }
    set { _set(newValue) }
  }
  
  public var wrappedValue: State {
    get { value }
    set { value = newValue }
  }
  
  public var projectedValue: Self {
    self
  }
    
}

extension StoreType {
  
  /// Returns Dervived object with making
  ///
  /// - Parameter
  ///   - memoizeMap:
  ///   - dropsOutput: Predicate to drops object if found a duplicated output
  /// - Returns:
  public func derived<NewState>(
    _ memoizeMap: MemoizeMap<Changes<State>, NewState>,
    dropsOutput: @escaping (Changes<NewState>) -> Bool = { _ in false }
  ) -> Derived<NewState> {
    
    let derived = Derived<NewState>(
      get: memoizeMap,
      set: { _ in
        
    },
      initialUpstreamState: asStore().changes,
      subscribeUpstreamState: { callback in
        asStore().subscribeChanges(dropsFirst: true, queue: nil, receive: callback)
    },
      retainsUpstream: nil
    )
    
    derived.setDropsOutput(dropsOutput)
    
    return derived
  }
    
  /// Returns Dervived object with making
  ///
  /// ✅ Drops duplicated the output with Equatable comparison.
  ///
  /// - Parameter memoizeMap:
  /// - Returns:
  public func derived<NewState: Equatable>(
    _ memoizeMap: MemoizeMap<Changes<State>, NewState>
  ) -> Derived<NewState> {
    derived(memoizeMap, dropsOutput: { $0.asChanges().noChanges(\.root) })
  }
    
  /// Returns Binding Derived object
  /// - Parameters:
  ///   - name:
  ///   - get:
  ///   - dropsOutput: Predicate to drops object if found a duplicated output
  ///   - set:
  /// - Returns:
  public func binding<NewState>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    get: MemoizeMap<Changes<State>, NewState>,
    dropsOutput: @escaping (Changes<NewState>) -> Bool = { _ in false },
    set: @escaping (inout State, NewState) -> Void
  ) -> BindingDerived<NewState> {
    
    let derived = BindingDerived<NewState>.init(
      get: get,
      set: { [weak self] state in
        self?.asStore().commit(name, file, function, line) {
          set(&$0, state)
        }
    },
      initialUpstreamState: asStore().changes,
      subscribeUpstreamState: { callback in
        asStore().subscribeChanges(dropsFirst: true, queue: nil, receive: callback)
    }, retainsUpstream: nil)
    
    derived.setDropsOutput(dropsOutput)
    
    return derived
  }
  
  /// Returns Binding Derived object
  ///
  /// ✅ Drops duplicated the output with Equatable comparison.
  /// - Parameters:
  ///   - name:
  ///   - get:
  ///   - set:
  /// - Returns:
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
