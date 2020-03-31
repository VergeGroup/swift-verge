//
//  Computed+Rx.swift
//  VergeRx
//
//  Created by muukii on 2020/03/31.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

#if !COCOAPODS
import VergeStore
#endif

extension GetterContainer {
  
  public struct RxGetterProperty<T> {
    
    public typealias Chain = GetterBuilderMethodChain<GetterBuilderTrait.Rx, Storage<State>, State>
    
    public typealias Make = (Chain) -> RxGetterSource<State, T>
    
    private let _make: Make
    
    public init(make: @escaping Make) {
      self._make = make
    }
    
    func make(_ chain :Chain) -> RxGetterSource<State, T> {
      _make(chain)
    }
    
  }
}

extension GetterProxy {
  
  public subscript<T>(dynamicMember keyPath: KeyPath<Store.State.Getters, Store.State.Field.RxGetterProperty<T>>) -> RxGetterSource<Store.State, T> {
    
    let storeBase = store.asStoreBase()
    
    return storeBase._getterStorage.update { value in
      guard let getter = value[keyPath] as? RxGetterSource<Store.State, T> else {
        
        let storage = storeBase._backingStorage
        let newGetter = Store.State.Getters()[keyPath: keyPath].make(storage.rx.getterBuilder())
        value[keyPath] = newGetter
        return newGetter
      }
      
      return getter
    }
   
  }
  
}

extension ComputedProxy {
  
  public subscript<T>(dynamicMember keyPath: KeyPath<Store.State.Getters, Store.State.Field.RxGetterProperty<T>>) -> T {
            
    let storeBase = store.asStoreBase()
    
    return storeBase._getterStorage.update { value in
      guard let getter = value[keyPath] as? RxGetterSource<Store.State, T> else {
        
        let storage = storeBase._backingStorage
        let newGetter = Store.State.Getters()[keyPath: keyPath].make(storage.rx.getterBuilder())
        value[keyPath] = newGetter
        return newGetter.value
      }
      
      return getter.value
    }
  }
  
}

