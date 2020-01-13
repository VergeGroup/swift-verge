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
  
  #if canImport(Combine)
     
  @available(iOS 13, macOS 10.15, *)
  func makeGetter<Output>(
    filter: @escaping (Value) -> Bool,
    map: @escaping (Value) -> Output
  ) -> GetterSource<Value, Output>
  
  #endif
}

extension Storage: ValueContainerType {
  
  public func lock() {
    _lock.lock()
  }

  public func unlock() {
    _lock.unlock()
  }
    
}
