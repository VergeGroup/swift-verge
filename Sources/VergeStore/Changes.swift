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

public protocol ChangesType {
  associatedtype Value
  var old: Value? { get }
  var current: Value { get }
  
  func hasChanges(compare: (Value, Value) -> Bool) -> Bool
}

/**
 
 An object that contains 2 instances (old, new)
 Use-case is to know how it did change.
 
 ```
 struct MyState {
 var name: String
 var age: String
 var height: String
 }
 ```
 
 ```
 let changes: Changes<MyState>
 ```
 
 It can be accessed with properties of MyState by dynamicMemberLookup
 ```
 changes.name
 ```
 
 It would be helpful to update UI partially
 ```
 func updateUI(changes: Changes<MyState>) {
 
 changes.ifChanged(\.name) { name in
 // update UI
 }
 
 changes.ifChanged(\.age) { age in
 // update UI
 }
 
 changes.ifChanged(\.height) { height in
 // update UI
 }
 }
 ```
 */
@dynamicMemberLookup
public struct Changes<Value>: ChangesType {
  
  indirect enum PreviousWrapper {
    case wrapped(Changes<Value>)
    var value: Changes<Value> {
      switch self {
      case .wrapped(let value):
        return value
      }
    }
  }
    
  private struct InnerCurrent {
    
    let value: Value
    
    let cachedComputedValueStorage: VergeConcurrency.Atomic<[AnyKeyPath : Any]>
    
    init(value: Value) {
      self.value = value
      self.cachedComputedValueStorage = .init([:])
    }
    
    private init(
      value: Value,
      cachedComputedValueStorage: VergeConcurrency.Atomic<[AnyKeyPath : Any]>
    ) {
      self.value = value
      self.cachedComputedValueStorage = cachedComputedValueStorage
    }
    
    public func map<U>(_ transform: (Value) throws -> U) rethrows -> Changes<U>.InnerCurrent {
      return .init(value: try transform(value), cachedComputedValueStorage: cachedComputedValueStorage)
    }
  }
  
  private let sharedCacheComputedValueStorage: VergeConcurrency.Atomic<[AnyKeyPath : Any]>
  
  internal private(set) var previous: PreviousWrapper?
  private var innerCurrent: InnerCurrent
    
  public var old: Value? { _read { yield previous?.value.current } }
  public var current: Value { _read { yield innerCurrent.value } }
  
  private(set) public var version: UInt64
  
  public init(
    old: Value?,
    new: Value
  ) {
    self.previous = nil
    self.innerCurrent = .init(value: new)
    self.sharedCacheComputedValueStorage = .init([:])
    self.version = 0
  }
  
  private init(
    previous: PreviousWrapper?,
    innerCurrent: InnerCurrent,
    sharedCacheStorage: VergeConcurrency.Atomic<[AnyKeyPath : Any]>,
    version: UInt64
  ) {
    
    self.previous = previous
    self.innerCurrent = innerCurrent
    self.sharedCacheComputedValueStorage = sharedCacheStorage
    self.version = version
  }
  
  @inlinable
  public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
    _read {
      yield current[keyPath: keyPath]
    }
  }
  
  @inline(__always)
  @inlinable
  public func hasChanges(compare: (Value, Value) -> Bool) -> Bool {
    guard let old = old else {
      return true
    }
    return !compare(old, current)
  }
  
  /// Returns boolean that indicates value specified by keyPath contains changes with compared old and new.
  ///
  @inline(__always)
  @inlinable
  public func hasChanges<T: Equatable>(_ keyPath: KeyPath<Value, T>) -> Bool {
    hasChanges(keyPath, ==)
  }
  
  /// Returns boolean that indicates value specified by keyPath contains changes with compared old and new.
  ///
  @inlinable
  @inline(__always)
  public func hasChanges<T>(_ keyPath: KeyPath<Value, T>, _ compare: (T, T) -> Bool) -> Bool {
    guard let selectedOld = old?[keyPath: keyPath] else {
      return true
    }
    let selectedNew = current[keyPath: keyPath]
    return !compare(selectedOld, selectedNew)
  }
  
  /// Do a closure if value specified by keyPath contains changes.
  @inlinable
  public func ifChanged<T: Equatable>(_ keyPath: KeyPath<Value, T>, _ perform: (T) throws -> Void) rethrows {
    
    guard hasChanges(keyPath) else { return }
    try perform(current[keyPath: keyPath])
  }
  
  @inlinable
  public func ifChanged<T>(_ keyPath: KeyPath<Value, T>, _ comparer: (T, T) -> Bool, _ perform: (T) throws -> Void) rethrows {
    
    guard hasChanges(keyPath, comparer) else { return }
    try perform(current[keyPath: keyPath])
  }
  
  public func ifChanged<Composed>(
    compose: (Composing) -> Composed,
    comparer: (Composed, Composed) -> Bool,
    perform: (Composed) -> Void) {
    
    let current = Composing(source: self)
    
    guard let previousValue = previous?.value else {
      perform(compose(.init(source: self)))
      return
    }
    
    let old = Composing(source: previousValue)
    
    let composedOld = compose(old)
    let composedNew = compose(current)
    
    guard !comparer(composedOld, composedNew) else {
      return
    }
    
    perform(composedNew)
  }
  
  
  public func map<U>(_ transform: (Value) throws -> U) rethrows -> Changes<U> {
    Changes<U>(
      previous: try previous.map { try Changes<U>.PreviousWrapper.wrapped($0.value.map(transform)) },
      innerCurrent: try innerCurrent.map(transform),
      sharedCacheStorage: sharedCacheComputedValueStorage,
      version: version
    )
  }
  
  public func makeNextChanges(with nextNewValue: Value) -> Changes<Value> {
    var _self = self
    _self.update(with: nextNewValue)
    return _self
  }
  
  public mutating func update(with nextNewValue: Value) {
    
    var previous = self
    previous.previous = nil
    
    self.previous = .wrapped(previous)
    self.innerCurrent = .init(value: nextNewValue)
    self.version &+= 1
  }
  
}

extension Changes {
  
  @dynamicMemberLookup
  public struct Composing {
    
    private let source: Changes<Value>
    
    public var current: Value {
      source.current
    }
    
    fileprivate init(source: Changes<Value>) {
      self.source = source
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
      _read {
        yield source[dynamicMember: keyPath]
      }
    }
        
  }
}

extension Changes.Composing where Value : ExtendedStateType {
  public var computed: Changes.ComputedProxy {
    .init(source: source)
  }
}

extension Changes where Value : ExtendedStateType {
  
  @dynamicMemberLookup
  public struct ComputedProxy {
    let source: Changes<Value>
    
    public subscript<Output>(dynamicMember keyPath: KeyPath<Value.Extended, Value.Field.Computed<Output>>) -> Output {
      take(with: keyPath)
    }
    
    @inline(__always)
    private func take<Output>(with keyPath: KeyPath<Value.Extended, Value.Field.Computed<Output>>) -> Output {
      return source._takeFromCacheOrCreate(keyPath: keyPath)
    }
  }
  
  public var computed: ComputedProxy {
    .init(source: self)
  }
  
  @inline(__always)
  public func hasChanges<Output: Equatable>(computed keyPath: KeyPath<Value.Extended, Value.Field.Computed<Output>>) -> Bool {
    hasChanges(computed: keyPath, ==)
  }
  
  @inline(__always)
  public func hasChanges<Output>(computed keyPath: KeyPath<Value.Extended, Value.Field.Computed<Output>>, _ comparer: (Output, Output) -> Bool) -> Bool {
    
    let current = _takeFromCacheOrCreate(keyPath: keyPath)
    
    guard let previous = previous?.value else {
      return true
    }
            
    guard let oldComputedValue = previous.innerCurrent.cachedComputedValueStorage.unsafelyWrappedValue[keyPath] as? Output else {
      return true
    }
        
    guard !comparer(oldComputedValue, current) else {
      return false
    }
    
    return true
  }
  
  public func ifChanged<Output: Equatable>(computed keyPath: KeyPath<Value.Extended, Value.Field.Computed<Output>>, _ perform: (Output) throws -> Void) rethrows {
        
    let current = _takeFromCacheOrCreate(keyPath: keyPath)
  
    guard let previous = previous?.value else {
      try perform(current)
      return
    }

    guard let oldComputedValue = previous.innerCurrent.cachedComputedValueStorage.unsafelyWrappedValue[keyPath] as? Output else {
      try perform(current)
      return
    }
    
    guard oldComputedValue != current else {
      return
    }
    
    try perform(current)
    
  }
  
  @inline(__always)
  private func _takeFromCacheOrCreate<Output>(
    keyPath: KeyPath<Value.Extended, Value.Field.Computed<Output>>
  ) -> Output {
    
    let components = Value.Extended()[keyPath: keyPath]
    
    components._onRead(current)
        
    returnCachedValue: do {
      if let computed = innerCurrent.cachedComputedValueStorage.value[keyPath] as? Output {
        components._onHitCache()
        // if cached, take value withoud shared lock
        return computed
      }
    }
               
    // lock the shared lock
    return sharedCacheComputedValueStorage.modify { _cahce in
            
      /* Begin lock scope */
      
      if let computed = innerCurrent.cachedComputedValueStorage.value[keyPath] as? Output {
        components._onHitCache()
        // if cached, take value withoud shared lock
        return computed
      }
          
      func preFilter() -> Bool {
        components._onPreFilter()
        return (old.map({ components.preFilter.equals($0, current) }) ?? false)
      }
                 
      if let cached = _cahce[keyPath] as? Output, preFilter() {
        components._onHitSharedCache()
        innerCurrent.cachedComputedValueStorage.modify {
          $0[keyPath] = cached
        }
        return cached
      }
      
      let newValue = components.compute(current)
      
      components._onTransform(newValue)
      
      _cahce[keyPath] = newValue
      
      innerCurrent.cachedComputedValueStorage.modify {
        $0[keyPath] = newValue
      }
      
      return newValue
      
      /* End lock scope */
    }
    
  }
  
}

extension Changes where Value : Equatable {
  
  public var hasChanges: Bool {
    old != current
  }
}


extension _StateTypeContainer {
        
  public struct Computed<Output> {
    
    public typealias Input = State
    
    @usableFromInline
    fileprivate(set) var _onRead: (Input) -> Void = { _ in }
    
    @usableFromInline
    fileprivate(set) var _onHitCache: () -> Void = {}
    
    @usableFromInline
    fileprivate(set) var _onHitSharedCache: () -> Void = {}
    
    @usableFromInline
    fileprivate(set) var _onPreFilter: () -> Void = {}
    
    @usableFromInline
    fileprivate(set) var _onTransform: (Output) -> Void = { _ in }
    
    @usableFromInline
    let preFilter: Comparer<Input>
    @usableFromInline
    let compute: (Input) -> Output
    
    public init(_ compute: @escaping (State) -> Output) {
      self.init(preFilter: .init { _, _ in false }, transform: compute)
    }
        
    @usableFromInline
    init(
      preFilter: Comparer<Input>,
      transform: @escaping (Input) -> Output
    ) {
                  
      self.preFilter = preFilter
      self.compute = transform
      
    }
    
    @inlinable
    @inline(__always)
    public func ifChanged(
      comparer: Comparer<Input>
    ) -> Self {
      .init(preFilter: comparer, transform: compute)
    }
    
    @inlinable
    @inline(__always)
    public func ifChanged<PreComparingKey>(
      selector: @escaping (Input) -> PreComparingKey,
      comparer: Comparer<PreComparingKey>
    ) -> Self {
      ifChanged(comparer: .init(selector: selector, comparer: comparer))
    }
    
    @inlinable
    @inline(__always)
    public func ifChanged<PreComparingKey>(
      selector: @escaping (Input) -> PreComparingKey,
      compare: @escaping (PreComparingKey, PreComparingKey) -> Bool
    ) -> Self {
      ifChanged(comparer: .init(selector: selector, comparer: .init(compare)))
    }
    
    @inlinable
    @inline(__always)
    public func ifChanged<PreComparingKey: Equatable>(
      selector: @escaping (Input) -> PreComparingKey
    ) -> Self {
      ifChanged(selector: selector, compare: ==)
    }
    
    @inlinable
    @inline(__always)
    public func ifChanged(
      compare: @escaping (Input, Input) -> Bool
    ) -> Self {
      ifChanged(comparer: .init(compare))
    }
    
    @inlinable
    @inline(__always)
    public func ifChanged<T>(fragmentSelector: @escaping (Input) -> Fragment<T>) -> Self {
      ifChanged(comparer: .init(selector: {
        fragmentSelector($0).counter.rawValue
      }))
    }
        
    @inlinable
    @inline(__always)
    public func onRead(_ clsoure: @escaping (Input) -> Void) -> Self {
      
      var _self = self
      _self._onRead = clsoure
      return _self
    }
    
    @inlinable
    @inline(__always)
    public func onTransform(_ closure: @escaping (Output) -> Void) -> Self {
      
      var _self = self
      _self._onTransform = closure
      return _self
    }
    
    @inlinable
    @inline(__always)
    public func onPreFilter(_ closure: @escaping () -> Void) -> Self {
      
      var _self = self
      _self._onPreFilter = closure
      return _self
    }
    
    @inlinable
    @inline(__always)
    public func onHitCache(_ closure: @escaping () -> Void) -> Self {
      
      var _self = self
      _self._onHitCache = closure
      return _self
    }
    
    @inlinable
    @inline(__always)
    public func onHitSharedCache(_ closure: @escaping () -> Void) -> Self {
      
      var _self = self
      _self._onHitSharedCache = closure
      return _self
    }
    
  }
}

extension _StateTypeContainer.Computed where Input : Equatable {
  
  /// Compare using Equatable
  ///
  /// Adding a filter to getter to map only when the input object changed.
  public func ifChanged() -> Self {
    ifChanged(compare: ==)
  }
  
}
