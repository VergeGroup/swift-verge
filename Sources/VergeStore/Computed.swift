//
//  Computed.swift
//  VergeCore
//
//  Created by muukii on 2020/03/29.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import os.lock

#if !COCOAPODS
import VergeCore
#endif

@dynamicMemberLookup
public struct GetterProxy<Store: StoreType> where Store.State : _StateType {
  
  public let store: Store
  
  init(store: Store) {
    self.store = store
  }
  
}
extension GetterProxy {
  
  @available(iOS 13, *)
  public subscript<T>(dynamicMember keyPath: KeyPath<Store.State.Getters, Store.State.Field.GetterProperty<T>>) -> GetterSource<Store.State, T> {
        
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

@dynamicMemberLookup
public struct ComputedProxy<Store: StoreType> where Store.State : _StateType {
  
  public let store: Store
  
  init(store: Store) {
    self.store = store
  }
}

extension ComputedProxy {
  
  @available(iOS 13, *)
  public subscript<T>(dynamicMember keyPath: KeyPath<Store.State.Getters, Store.State.Field.GetterProperty<T>>) -> T {
    
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

public enum GetterContainer<State: _StateType> {
  
  @available(iOS 13, *)
  public struct GetterProperty<T> {
    
    private let _make: (GetterBuilderMethodChain<GetterBuilderTrait.Combine, Storage<State>, State>) -> GetterSource<State, T>
        
    public init(make: @escaping (GetterBuilderMethodChain<GetterBuilderTrait.Combine, Storage<State>, State>) -> GetterSource<State, T>) {
      self._make = make
    }
    
    func make(_ chain: GetterBuilderMethodChain<GetterBuilderTrait.Combine, Storage<State>, State>) -> GetterSource<State, T> {
      _make(chain)
    }
      
  }
}

extension _StateType {
  
  public typealias Field = GetterContainer<Self>
}

extension StoreType where State : _StateType  {
  
  public var getters: GetterProxy<Self> {
    .init(store: self)
  }
  
  public var computed: ComputedProxy<Self> {
    .init(store: self)
  }
}

