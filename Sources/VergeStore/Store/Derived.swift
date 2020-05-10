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
///
/// Conforms to Equatable that compares pointer personality.
public class Derived<Value>: DerivedType {
  
  public static func constant(_ value: Value) -> Derived<Value> {
    .init(constant: value)
  }
  
  /// A current state.
  public var primitiveValue: Value {
    innerStore.primitiveState
  }
  
  /// A current changes state.
  public var value: Changes<Value> {
    innerStore.state
  }
  
  /// A current changes state.
  public var changes: Changes<Value> {
    innerStore.state
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
  fileprivate func setDropsOutput(_ dropsOutput: @escaping (Changes<Value>) -> Bool){
    innerStore.setNotificationFilter { changes in
      !dropsOutput(changes)
    }
  }
  
  /// Subscribe the state changes
  ///
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  public func sinkValue(
    dropsFirst: Bool = false,
    queue: TargetQueue? = nil,
    receive: @escaping (Changes<Value>) -> Void
  ) -> VergeAnyCancellable {
    
    innerStore.sinkChanges(
      dropsFirst: dropsFirst,
      queue: queue
    ) { (changes) in
      withExtendedLifetime(self) {}
      receive(changes)
    }
    .asAutoCancellable()
  }
  
  /// Subscribe the state changes
  ///
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  @available(*, deprecated, renamed: "sinkValue")
  public func sinkChanges(
    dropsFirst: Bool = false,
    queue: TargetQueue? = nil,
    receive: @escaping (Changes<Value>) -> Void
  ) -> VergeAnyCancellable {    
    sinkValue(dropsFirst: dropsFirst, queue: queue, receive: receive)
  }
    
  /// Subscribe the state changes
  ///
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  @available(*, deprecated, renamed: "sinkState")
  public func subscribeChanges(
    dropsFirst: Bool = false,
    queue: TargetQueue? = nil,
    receive: @escaping (Changes<Value>) -> Void
  ) -> VergeAnyCancellable {
    sinkChanges(dropsFirst: dropsFirst, queue: queue, receive: receive)
  }
  
  fileprivate func _makeChain<NewState>(
    _ map: MemoizeMap<Changes<Value>, NewState>,
    queue: TargetQueue? = nil
  ) -> Derived<NewState> {
    
    vergeSignpostEvent("Derived.chain.new", label: "\(type(of: Value.self)) -> \(type(of: NewState.self))")
    
    let d = Derived<NewState>(
      get: .init(makeInitial: {
        map.makeInitial($0)
      }, update: {
        switch map.makeResult($0) {
        case .noChanages: return .noChanages
        case .updated(let s): return .updated(s)
        }
      }),
      set: { _ in },
      initialUpstreamState: changes,
      subscribeUpstreamState: { callback in
        self.innerStore.sinkChanges(
          dropsFirst: true,
          queue: queue,
          receive: callback
        )
    },
      retainsUpstream: self
    )
        
    return d
    
  }
    
  /// Make a new Derived object that projects the specified shape of the object from the object itself projects.
  /// - Parameters:
  ///   - queue: a queue to receive object
  ///   - map:
  ///   - dropsOutput: a condition to drop a duplicated(no-changes) object. (Default: no drops)
  /// - Returns: Derived object that cached depends on the specified parameters
  public func chain<NewState>(
    _ map: MemoizeMap<Changes<Value>, NewState>,
    dropsOutput: ((Changes<NewState>) -> Bool)? = nil,
    queue: TargetQueue? = nil
    ) -> Derived<NewState> {
        
    let derived = chainCahce2.withValue { cache -> Derived<NewState> in
      
      let identifier = "\(map.identifier)\(String(describing: queue?.identifier))" as NSString
      
      guard let cached = cache.object(forKey: identifier) as? Derived<NewState> else {
        let instance = _makeChain(map, queue: queue)
        cache.setObject(instance, forKey: identifier)
        return instance
      }
      
      vergeSignpostEvent("Derived.chain.reuse", label: "\(type(of: Value.self)) -> \(type(of: NewState.self))")
      return cached
    }
    
    if let dropsOutput = dropsOutput {
      
      let chained: Derived<NewState> = derived._makeChain(.map(\.root), queue: queue)
      chained.setDropsOutput(dropsOutput)
      
      return chained
      
    } else {
      return derived
    }
        
  }
  
  /// Make a new Derived object that projects the specified shape of the object from the object itself projects.
  ///
  /// Drops output value if no changes with Equatable
  ///
  /// - Parameters:
  ///   - queue: a queue to receive object
  ///   - map:
  /// - Returns: Derived object that cached depends on the specified parameters
  public func chain<NewState: Equatable>(
    _ map: MemoizeMap<Changes<Value>, NewState>,
    queue: TargetQueue? = nil
  ) -> Derived<NewState> {
    
    return chainCahce1.withValue { cache in
      
      let identifier = "\(map.identifier)\(String(describing: queue?.identifier))" as NSString
      
      guard let cached = cache.object(forKey: identifier) as? Derived<NewState> else {
        let instance = _makeChain(map, queue: queue)
        instance.setDropsOutput({ !$0.hasChanges })
        cache.setObject(instance, forKey: identifier)
        return instance
      }
      
      vergeSignpostEvent("Derived.chain.reuse", label: "\(type(of: Value.self)) -> \(type(of: NewState.self))")
      return cached
    }
          
  }
  
  private let chainCahce1 = VergeConcurrency.UnfairLockAtomic(NSMapTable<NSString, AnyObject>.strongToWeakObjects())
  private let chainCahce2 = VergeConcurrency.UnfairLockAtomic(NSMapTable<NSString, AnyObject>.strongToWeakObjects())

}

extension Derived: CustomReflectable {
  public var customMirror: Mirror {
    Mirror.init(self, children: ["changes" : changes], displayStyle: .struct, ancestorRepresentation: .generated)
  }
}

extension Derived : Equatable {
  public static func == (lhs: Derived<Value>, rhs: Derived<Value>) -> Bool {
    lhs === rhs
  }
}

extension Derived : Hashable {
  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }
}

extension Derived where Value : Equatable {
  
  /// Subscribe the state changes
  ///
  /// Receives a value only changed
  ///
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  public func sinkChangedPrimitiveValue(
    dropsFirst: Bool = false,
    queue: TargetQueue? = nil,
    receive: @escaping (Value) -> Void
  ) -> VergeAnyCancellable {
    sinkValue(dropsFirst: dropsFirst, queue: queue) { (changes) in
      changes.ifChanged { value in
        receive(value)
      }
    }
  }
  
  /// Subscribe the state changes
  ///
  /// Receives a value only changed
  ///
  /// - Returns: A subscriber that performs the provided closure upon receiving values.
  @available(*, deprecated, renamed: "sinkChangedPrimitiveValue")
  public func sinkChangedValue(
    dropsFirst: Bool = false,
    queue: TargetQueue? = nil,
    receive: @escaping (Value) -> Void
  ) -> VergeAnyCancellable {
    sinkChangedPrimitiveValue(dropsFirst: dropsFirst, queue: queue, receive: receive)
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
    
    let initial = (s0.primitiveValue, s1.primitiveValue)
    
    let buffer = VergeConcurrency.RecursiveLockAtomic<Shape>.init(initial)
    
    return Derived<Shape>(
      get: MemoizeMap<Shape, Shape>.init(map: { $0 }),
      set: { _, _ in },
      initialUpstreamState: initial,
      subscribeUpstreamState: { callback in
                
        let _s0 = s0.sinkValue(dropsFirst: true, queue: nil) { (s0) in
          buffer.modify { value in
            value.0 = s0.primitive
            callback(value)
          }
        }
        
        let _s1 = s1.sinkValue(dropsFirst: true, queue: nil) { (s1) in
          buffer.modify { value in
            value.1 = s1.primitive
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
    
    let initial = (s0.primitiveValue, s1.primitiveValue, s2.primitiveValue)
    
    let buffer = VergeConcurrency.RecursiveLockAtomic<Shape>.init(initial)
    
    return Derived<Shape>(
      get: MemoizeMap<Shape, Shape>.init(map: { $0 }),
      set: { _, _, _ in },
      initialUpstreamState: initial,
      subscribeUpstreamState: { callback in
        
        let _s0 = s0.sinkValue(dropsFirst: true, queue: nil) { (s0) in
          buffer.modify { value in
            value.0 = s0.primitive
            callback(value)
          }
        }
        
        let _s1 = s1.sinkValue(dropsFirst: true, queue: nil) { (s1) in
          buffer.modify { value in
            value.1 = s1.primitive
            callback(value)
          }
        }
        
        let _s2 = s2.sinkValue(dropsFirst: true, queue: nil) { (s2) in
          buffer.modify { value in
            value.2 = s2.primitive
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
   
  /// A publisher that repeatedly emits the changes when state updated
  ///
  /// Guarantees to emit the first event on started subscribing.
  ///
  /// - Parameter startsFromInitial: Make the first changes object's hasChanges always return true.
  /// - Returns:
  public func valuePublisher(startsFromInitial: Bool = true) -> AnyPublisher<Changes<Value>, Never> {
    innerStore.statePublisher(startsFromInitial: startsFromInitial)
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
  @available(*, deprecated, renamed: "valuePublisher")
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
  public override var primitiveValue: State {
    get { innerStore.primitiveState }
    set { _set(newValue) }
  }
  
  public var wrappedValue: State {
    get { primitiveValue }
    set { primitiveValue = newValue }
  }
  
  public var projectedValue: Self {
    self
  }
    
}

extension StoreType {
  
  private func _makeDerived<NewState>(
    _ memoizeMap: MemoizeMap<Changes<State>, NewState>,
    queue: TargetQueue? = nil
  ) -> Derived<NewState> {
    
    vergeSignpostEvent("Store.derived.new", label: "\(type(of: State.self)) -> \(type(of: NewState.self))")
    let derived = Derived<NewState>(
      get: memoizeMap,
      set: { _ in
        
    },
      initialUpstreamState: asStore().state,
      subscribeUpstreamState: { callback in
        asStore().sinkChanges(dropsFirst: true, queue: queue, receive: callback)
    },
      retainsUpstream: nil
    )
    return derived
  }
  
  /// Returns Dervived object with making
  ///
  /// - Parameter
  ///   - memoizeMap:
  ///   - dropsOutput: Predicate to drops object if found a duplicated output
  /// - Returns: Derived object that cached depends on the specified parameters
  public func derived<NewState>(
    _ memoizeMap: MemoizeMap<Changes<State>, NewState>,
    dropsOutput: ((Changes<NewState>) -> Bool)? = nil,
    queue: TargetQueue? = nil
  ) -> Derived<NewState> {
        
    let derived = asStore().derivedCache2.withValue { cache -> Derived<NewState> in
      
      let identifier = "\(memoizeMap.identifier)\(String(describing: queue?.identifier))" as NSString
      
      guard let cached = cache.object(forKey: identifier) as? Derived<NewState> else {
        let instance = _makeDerived(memoizeMap, queue: queue)
        cache.setObject(instance, forKey: identifier)
        return instance
      }
      
      vergeSignpostEvent("Store.derived.reuse", label: "\(type(of: State.self)) -> \(type(of: NewState.self))")
      
      return cached
      
    }
    
    if let dropsOutput = dropsOutput {
            
      let chained = derived._makeChain(.map(\.root), queue: queue)
      chained.setDropsOutput(dropsOutput)
            
      return chained
      
    } else {

      return derived
      
    }
       
  }
    
  /// Returns Dervived object with making
  ///
  /// - Complexity: ✅ Drops duplicated the output with Equatable comparison.
  ///
  /// - Parameter memoizeMap:
  /// - Returns: Derived object that cached depends on the specified parameters
  public func derived<NewState: Equatable>(
    _ memoizeMap: MemoizeMap<Changes<State>, NewState>,
    queue: TargetQueue? = nil
  ) -> Derived<NewState> {
    
    return asStore().derivedCache1.withValue { cache in
      
      let identifier = "\(memoizeMap.identifier)\(String(describing: queue?.identifier))" as NSString
      
      guard let cached = cache.object(forKey: identifier) as? Derived<NewState> else {
        let instance = _makeDerived(memoizeMap, queue: queue)
        instance.setDropsOutput({ $0.asChanges().noChanges(\.root) })
        cache.setObject(instance, forKey: identifier)
        return instance
      }
      
      vergeSignpostEvent("Store.derived.reuse", label: "\(type(of: State.self)) -> \(type(of: NewState.self))")
            
      return cached

    }
                
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
      initialUpstreamState: asStore().state,
      subscribeUpstreamState: { callback in
        asStore().sinkChanges(dropsFirst: true, queue: nil, receive: callback)
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
