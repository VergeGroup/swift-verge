//
//  Computed.swift
//  VergeCore
//
//  Created by muukii on 2020/03/29.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import os.lock

import VergeCore

public enum GetterContainer<Store: StoreType> {
  
}

extension GetterContainer {
  
  @available(iOS 13, *)
  @propertyWrapper
  public struct Computed<T> {
          
    private final class Inner {
      var getter: Getter<T>?
      var lock = os_unfair_lock_s()
    }
    
    @available(*, unavailable)
    public var wrappedValue: T {
      get { fatalError() }
      set { fatalError() }
    }
    
    @available(*, unavailable)
    public var projectedValue: Getter<T> {
      get { fatalError() }
      set { fatalError() }
    }

    private let make: (GetterBuilderMethodChain<GetterBuilderTrait.Combine, Store>) -> Getter<T>
    
    private let inner: Inner = .init()
            
    public init(make: @escaping (GetterBuilderMethodChain<GetterBuilderTrait.Combine, Store>) -> Getter<T>) {
      self.make = make
    }
          
    public static subscript(
      _enclosingInstance instance: Store,
      wrapped wrappedKeyPath: KeyPath<Store, T>,
      storage storageKeyPath: KeyPath<Store, Self>
    ) -> T {
      get {
                      
        let inner = instance[keyPath: storageKeyPath].inner
        
        os_unfair_lock_lock(&inner.lock)
        defer {
          os_unfair_lock_unlock(&inner.lock)
        }
                
        guard let getter = inner.getter else {
          let new = instance[keyPath: storageKeyPath].make(instance.getterBuilder())
          inner.getter = new
          return new.value
        }
        
        return getter.value
      }
      set {
        
      }
    }
    
    public static subscript(
      _enclosingInstance instance: Store,
      projected wrappedKeyPath: KeyPath<Store, Getter<T>>,
      storage storageKeyPath: KeyPath<Store, Self>
    ) -> Getter<T> {
      get {
        
        let inner = instance[keyPath: storageKeyPath].inner
        
        os_unfair_lock_lock(&inner.lock)
        defer {
          os_unfair_lock_unlock(&inner.lock)
        }
        
        guard let getter = inner.getter else {
          let new = instance[keyPath: storageKeyPath].make(instance.getterBuilder())
          inner.getter = new
          return new
        }
        
        return getter
      }
      set {
        
      }
    }
    
  }
  
}


@available(iOS 13, *)
extension StoreType {
  public typealias Field = GetterContainer<Self>
}

