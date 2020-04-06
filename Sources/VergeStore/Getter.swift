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

import os.lock

#if !COCOAPODS
import VergeCore
#endif

public enum _GettersContainer<State: CombinedStateType> {
}

@dynamicMemberLookup
public struct GetterProxy<Store: StoreType> where Store.State : CombinedStateType {
  
  public let store: Store
  
  init(store: Store) {
    self.store = store
  }
  
}

@dynamicMemberLookup
public struct ComputedProxy<Store: StoreType> where Store.State : CombinedStateType {
  
  public let store: Store
  
  init(store: Store) {
    self.store = store
  }
}

#if canImport(Combine)

extension GetterProxy {
  
  @available(iOS 13, macOS 10.15, *)
  public subscript<T>(dynamicMember keyPath: KeyPath<Store.State.Getters, Store.State.Field.Getter<T>>) -> GetterSource<Store.State, T> {
    
    let storeBase = store.asStoreBase()
    
    return storeBase._getterStorage.update { value in
      
      guard let getter = value[keyPath] as? GetterSource<Store.State, T> else {
        
        let storage = storeBase._backingStorage
        let newGetter = Store.State.Getters()[keyPath: keyPath].make(storage.getterBuilder())
        value[keyPath] = newGetter
        return newGetter
      }
      
      return getter
    }
    
  }
  
}

extension ComputedProxy {
  
  @available(iOS 13, macOS 10.15, *)
  public subscript<T>(dynamicMember keyPath: KeyPath<Store.State.Getters, Store.State.Field.Getter<T>>) -> T {
    
    let storeBase = store.asStoreBase()
    
    return storeBase._getterStorage.update { value in
      
      guard let getter = value[keyPath] as? GetterSource<Store.State, T> else {
        
        let storage = storeBase._backingStorage
        let newGetter = Store.State.Getters()[keyPath: keyPath].make(storage.getterBuilder())
        value[keyPath] = newGetter
        return newGetter.value
      }
      
      return getter.value
    }
    
  }
  
}

extension _GettersContainer {
    
  /// An object to define how to create Getter with filter to be performant.
  @available(iOS 13, macOS 10.15, *)
  public struct Getter<T> {
    
    private let _make: (GetterBuilderMethodChain<GetterBuilderTrait.Combine, Storage<State>, State>) -> GetterSource<State, T>
        
    /// Initializer
    /// - Parameter make: it makes GetterSource. make closure would be called only once to create and retain Getter in Store when first-time access.
    public init(make: @escaping (GetterBuilderMethodChain<GetterBuilderTrait.Combine, Storage<State>, State>) -> GetterSource<State, T>) {
      self._make = make
    }
    
    func make(_ chain: GetterBuilderMethodChain<GetterBuilderTrait.Combine, Storage<State>, State>) -> GetterSource<State, T> {
      _make(chain)
    }
    
  }
  

}

#else

extension GetterProxy {
  
  @available(*, unavailable)
  public subscript<T>(dynamicMember keyPath: KeyPath<Store.State.Getters, T>) -> Never {
    fatalError()
  }
  
}

extension ComputedProxy {
  
  
  @available(*, unavailable)
  public subscript<T>(dynamicMember keyPath: KeyPath<Store.State.Getters, T>) -> Never {
    fatalError()
  }
     
}


#endif

extension CombinedStateType {
  
  public typealias Field = _GettersContainer<Self>
}

extension StoreType where State : CombinedStateType  {
  
  public var getters: GetterProxy<Self> {
    .init(store: self)
  }
  
  public var computed: ComputedProxy<Self> {
    .init(store: self)
  }
}

