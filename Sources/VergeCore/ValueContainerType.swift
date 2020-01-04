//
//  ValueContainerType.swift
//  VergeCore
//
//  Created by muukii on 2019/12/16.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public protocol ValueContainerType: AnyObject {
  associatedtype Value
  
  var wrappedValue: Value { get }
  
  func lock()
  func unlock()
    
  func getter<Output>(
    filter: EqualityComputer<Value>,
    map: @escaping (Value) -> Output
  ) -> Getter<Value, Output>
}

extension Storage: ValueContainerType {
  
  public func lock() {
    _lock.lock()
  }

  public func unlock() {
    _lock.unlock()
  }
    
  public func getter<Output>(
    filter: EqualityComputer<Value>,
    map: @escaping (Value) -> Output
  ) -> Getter<Value, Output> {
    
    var token: EventEmitterSubscribeToken?
    
    let getter = Getter(input: value, filter: filter, map: map, upstreams: [self])
    
    getter.onDeinit = { [weak self] in
      guard let token = token else {
        assertionFailure()
        return
      }
      self?.remove(subscribe: token)
    }
           
    token = addDidUpdate { [weak getter] (newValue) in
      getter?._receive(newValue: newValue)
    }
    
    return getter
  }
  
}
