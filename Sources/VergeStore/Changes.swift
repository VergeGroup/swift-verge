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
  
  private let cacheStorage: Storage<[AnyKeyPath : Any]>
  
  private var computedFlags: Storage<[AnyKeyPath : Bool]>
  
  public private(set) var old: Value?
  public private(set) var new: Value
  
  public init(
    old: Value?,
    new: Value
  ) {
    self.old = old
    self.new = new
    self.cacheStorage = .init([:])
    self.computedFlags = .init([:])
  }
  
  private init(
    old: Value?,
    new: Value,
    cacheStorage: Storage<[AnyKeyPath : Any]>,
    computedFlags: Storage<[AnyKeyPath : Bool]>
  ) {
    self.old = old
    self.new = new
    self.cacheStorage = cacheStorage
    self.computedFlags = computedFlags
  }
  
  public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
    _read {
      yield new[keyPath: keyPath]
    }
  }
  
  /// Returns boolean that indicates value specified by keyPath contains changes with compared old and new.
  ///
  @inline(__always)
  public func hasChanges<T: Equatable>(_ keyPath: KeyPath<Value, T>) -> Bool {
    guard let selectedOld = old?[keyPath: keyPath] else {
      return true
    }
    let selectedNew = new[keyPath: keyPath]
    
    return selectedOld != selectedNew
  }
  
  @inline(__always)
  public func hasChanges<T>(_ keyPath: KeyPath<Value, T>, _ comparer: (T, T) -> Bool) -> Bool {
    guard let selectedOld = old?[keyPath: keyPath] else {
      return true
    }
    let selectedNew = new[keyPath: keyPath]
    return !comparer(selectedOld, selectedNew)
  }
  
  /// Do a closure if value specified by keyPath contains changes.
  public func ifChanged<T: Equatable>(_ keyPath: KeyPath<Value, T>, _ perform: (T) throws -> Void) rethrows {
    
    guard hasChanges(keyPath) else { return }
    try perform(new[keyPath: keyPath])
  }
    
  public func ifChanged<T>(_ keyPath: KeyPath<Value, T>, _ comparer: (T, T) -> Bool, _ perform: (T) throws -> Void) rethrows {
    
    guard hasChanges(keyPath, comparer) else { return }
    try perform(new[keyPath: keyPath])
  }
  
  public func map<U>(_ transform: (Value) throws -> U) rethrows -> Changes<U> {
    .init(
      old: try old.map(transform),
      new: try transform(new),
      cacheStorage: cacheStorage,
      computedFlags: computedFlags
    )
  }
  
  public func makeNextChanges(with nextNewValue: Value) -> Changes<Value> {
    .init(
      old: self.new,
      new: nextNewValue,
      cacheStorage: cacheStorage,
      computedFlags: .init([:])
    )
  }
  
  public mutating func update(with nextNewValue: Value) {
    self.old = self.new
    self.new = nextNewValue
    self.computedFlags = .init([:])
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
      components._onRead(source.new)
      
      return source.cacheStorage.update { _cahce in
        
        /* Begin lock scope */
        
        if let cached = _cahce[keyPath] as? Output,
          source.computedFlags.value[keyPath, default: false] == true ||
          (source.old.map({ components.preFilter.isEqual(old: $0, new: source.new) }) ?? false) {
          return cached
        }
        
        source.computedFlags.update { $0[keyPath] = true }
        
        let newValue = components.transform(source.new)
        
        components._onTransform(newValue)
        
        _cahce[keyPath] = newValue
        
        return newValue
        
        /* End lock scope */
      }
      
    }
  }
  
  public var computed: ComputedProxy {
    .init(source: self)
  }
      
}

extension Changes where Value : Equatable {
  
  public var hasChanges: Bool {
    old != new
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
        .init(preFilter: filter, transform: transform, onRead: { _ in }, onTransform: { _ in })
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
      
      fileprivate var _onRead: ((Input) -> Void)
      fileprivate var _onTransform: ((Output) -> Void)
      
      public let preFilter: EqualityComputerBuilder<Input, PreComparingKey>
      public let transform: (Input) -> Output
      
      public init(
        preFilter: EqualityComputerBuilder<Input, PreComparingKey>,
        transform: @escaping (Input) -> Output,
        onRead: @escaping ((Input) -> Void),
        onTransform: @escaping ((Output) -> Void)
      ) {
        
        self._onRead = onRead
        self._onTransform = onTransform
        
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
