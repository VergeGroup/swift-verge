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

fileprivate final class NonatomicRef<Value> {
  var value: Value
  init(_ value: Value) {
    self.value = value
  }
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
public struct Changes<Value> {
  
  private struct InnerOld {
    
    let value: Value
    let cachedComputedValues: [AnyKeyPath : Any]
    
    init(value: Value) {
      self.value = value
      self.cachedComputedValues = [:]
    }
    
    private init(
      value: Value,
      cachedComputedValues: [AnyKeyPath : Any]
    ) {
      self.value = value
      self.cachedComputedValues = cachedComputedValues
    }
    
    init(from new: InnerCurrent) {
      self.value = new.value
      self.cachedComputedValues = new.cachedComputedValueStorage.value
    }
    
    public func map<U>(_ transform: (Value) throws -> U) rethrows -> Changes<U>.InnerOld {
      return .init(value: try transform(value), cachedComputedValues: cachedComputedValues)
    }
    
  }
  
  private struct InnerCurrent {
    
    let value: Value
    
    let cachedComputedValueStorage: NonatomicRef<[AnyKeyPath : Any]>
    
    init(value: Value) {
      self.value = value
      self.cachedComputedValueStorage = .init([:])
    }
    
    private init(
      value: Value,
      cachedComputedValueStorage: NonatomicRef<[AnyKeyPath : Any]>
    ) {
      self.value = value
      self.cachedComputedValueStorage = cachedComputedValueStorage
    }
    
    public func map<U>(_ transform: (Value) throws -> U) rethrows -> Changes<U>.InnerCurrent {
      return .init(value: try transform(value), cachedComputedValueStorage: cachedComputedValueStorage)
    }
  }
    
  private let sharedCacheComputedValueStorage: Storage<[AnyKeyPath : Any]>
      
  private var innerOld: InnerOld?
  private var innerCurrent: InnerCurrent
  
  public var old: Value? { _read { yield innerOld?.value } }
  public var current: Value { _read { yield innerCurrent.value } }
  
  public init(
    old: Value?,
    new: Value
  ) {
    self.innerOld = old.map(InnerOld.init(value: ))
    self.innerCurrent = .init(value: new)
    self.sharedCacheComputedValueStorage = .init([:])
  }
  
  private init(
    innerOld: InnerOld?,
    innerCurrent: InnerCurrent,
    sharedCacheStorage: Storage<[AnyKeyPath : Any]>
  ) {
    self.innerOld = innerOld
    self.innerCurrent = innerCurrent
    self.sharedCacheComputedValueStorage = sharedCacheStorage
  }
  
  public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
    _read {
      yield current[keyPath: keyPath]
    }
  }
  
  /// Returns boolean that indicates value specified by keyPath contains changes with compared old and new.
  ///
  @inline(__always)
  public func hasChanges<T: Equatable>(_ keyPath: KeyPath<Value, T>) -> Bool {
    guard let selectedOld = old?[keyPath: keyPath] else {
      return true
    }
    let selectedNew = current[keyPath: keyPath]
    
    return selectedOld != selectedNew
  }
  
  @inline(__always)
  public func hasChanges<T>(_ keyPath: KeyPath<Value, T>, _ comparer: (T, T) -> Bool) -> Bool {
    guard let selectedOld = old?[keyPath: keyPath] else {
      return true
    }
    let selectedNew = current[keyPath: keyPath]
    return !comparer(selectedOld, selectedNew)
  }
      
  /// Do a closure if value specified by keyPath contains changes.
  public func ifChanged<T: Equatable>(_ keyPath: KeyPath<Value, T>, _ perform: (T) throws -> Void) rethrows {
    
    guard hasChanges(keyPath) else { return }
    try perform(current[keyPath: keyPath])
  }
    
  public func ifChanged<T>(_ keyPath: KeyPath<Value, T>, _ comparer: (T, T) -> Bool, _ perform: (T) throws -> Void) rethrows {
    
    guard hasChanges(keyPath, comparer) else { return }
    try perform(current[keyPath: keyPath])
  }
  
  public func map<U>(_ transform: (Value) throws -> U) rethrows -> Changes<U> {
    .init(
      innerOld: try innerOld?.map(transform),
      innerCurrent: try innerCurrent.map(transform),
      sharedCacheStorage: sharedCacheComputedValueStorage
    )
  }
  
  public func makeNextChanges(with nextNewValue: Value) -> Changes<Value> {
    var _self = self
    _self.update(with: nextNewValue)
    return _self
  }
  
  public mutating func update(with nextNewValue: Value) {
    self.innerOld = .init(from: innerCurrent)
    self.innerCurrent = .init(value: nextNewValue)
  }
  
}

extension Changes where Value : CombinedStateType {
  
  @dynamicMemberLookup
  public struct ComputedProxy {
    let source: Changes<Value>
    
    public subscript<PreComparingKey, Output>(dynamicMember keyPath: KeyPath<Value.Getters, Value.Field.Computed.Components<PreComparingKey, Output>>) -> Output {
      take(with: keyPath)
    }
    
    @inline(__always)
    private func take<PreComparingKey, Output>(with keyPath: KeyPath<Value.Getters, Value.Field.Computed.Components<PreComparingKey, Output>>) -> Output {
      
      let components = Value.Getters()[keyPath: keyPath]
      components._onRead(source.current)
      
      return source.sharedCacheComputedValueStorage.update { _cahce in
        
        /* Begin lock scope */
        
        func preFilter() -> Bool {
          components._onPreFilter()
          return (source.old.map({ components.preFilter.isEqual(old: $0, new: source.current) }) ?? false)
        }
        
        if let computed = source.innerCurrent.cachedComputedValueStorage.value[keyPath] as? Output {
          return computed
        }
        
        if let cached = _cahce[keyPath] as? Output, preFilter() {
          
          source.innerCurrent.cachedComputedValueStorage.value[keyPath] = cached
          return cached
        }
                
        let newValue = components.transform(source.current)
        
        components._onTransform(newValue)
        
        _cahce[keyPath] = newValue
        source.innerCurrent.cachedComputedValueStorage.value[keyPath] = newValue
        
        return newValue
        
        /* End lock scope */
      }
      
    }
  }
  
  public var computed: ComputedProxy {
    .init(source: self)
  }
    
  @inline(__always)
  public func hasChanges<T>(computed keyPath: KeyPath<ComputedProxy, T>, _ comparer: (T, T) -> Bool) -> Bool {
    
    fatalError()
  }
  
  public func ifChanged<T: Equatable>(computed keyPath: KeyPath<ComputedProxy, T>, _ perform: (T) throws -> Void) rethrows {
    
    fatalError()
  }
      
}

extension Changes where Value : Equatable {
  
  public var hasChanges: Bool {
    old != current
  }
}


extension _GettersContainer {

  public enum Computed {
    
    public static func make() -> MethodChainMap {
      .init()
    }
    
    public struct MethodChainMap {
                     
      public func map<Output>(_ transform: @escaping (State) -> Output) -> MethodChainPreFilter<Output> {
        .init(transform: transform)
      }
    }
    
    public struct MethodChainPreFilter<Output> {
      
      public typealias Input = State
      
      let transform: (Input) -> Output
      
      func ifChanged<PreComparingKey>(
        filter: EqualityComputerBuilder<Input, PreComparingKey>
      ) -> Components<PreComparingKey, Output> {
        .init(preFilter: filter, transform: transform)
      }
      
      public func ifChanged<PreComparingKey>(
        keySelector: @escaping (Input) -> PreComparingKey,
        comparer: Comparer<PreComparingKey>
      ) -> Components<PreComparingKey, Output> {
        ifChanged(filter: .init(keySelector: keySelector, comparer: comparer))
      }
      
      public func ifChanged(
        comparer: Comparer<Input>
      ) -> Components<Input, Output> {
        ifChanged(keySelector: { $0 }, comparer: comparer)
      }
      
      public func ifChanged(
        _ equals: @escaping (Input, Input) -> Bool
      ) -> Components<Input, Output> {
        ifChanged(comparer: .init(equals))
      }
               
      public func ifChanged<T>(_ fragmentSelector: @escaping (Input) -> Fragment<T>) -> Components<Input, Output> {
        ifChanged(comparer: .init(selector: {
          fragmentSelector($0).counter.rawValue
        }))
      }
      
    }
        
    public struct Components<PreComparingKey, Output> {
      
      public typealias Input = State
      
      fileprivate var _onRead: (Input) -> Void = { _ in }
      fileprivate var _onPreFilter: () -> Void = {}
      fileprivate var _onTransform: (Output) -> Void = { _ in }
      
      public let preFilter: EqualityComputerBuilder<Input, PreComparingKey>
      public let transform: (Input) -> Output
      
      public init(
        preFilter: EqualityComputerBuilder<Input, PreComparingKey>,
        transform: @escaping (Input) -> Output
      ) {
                
        self.preFilter = preFilter
        self.transform = transform
        
      }
      
      public func onRead(_ onRead: @escaping (Input) -> Void) -> Self {
        
        var _self = self
        _self._onRead = onRead
        return _self
      }
      
      public func onTransform(_ onTransform: @escaping (Output) -> Void) -> Self {
        
        var _self = self
        _self._onTransform = onTransform
        return _self
      }
      
      public func onPreFilter(_ onPreFilter: @escaping () -> Void) -> Self {
        
        var _self = self
        _self._onPreFilter = onPreFilter
        return _self
      }
      
    }
    
  }
}

extension _GettersContainer.Computed.MethodChainPreFilter where Input : Equatable {
  
  /// Compare using Equatable
  ///
  /// Adding a filter to getter to map only when the input object changed.
  public func ifChanged() -> _GettersContainer.Computed.Components<Input, Output> {
    ifChanged(keySelector: { $0 }, comparer: .init(==))
  }
  
}
