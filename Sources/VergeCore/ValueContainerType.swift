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
     
}

extension Storage: ValueContainerType {
  
  public func lock() {
    _lock.lock()
  }

  public func unlock() {
    _lock.unlock()
  }
    
}
