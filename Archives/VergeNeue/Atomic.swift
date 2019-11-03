//
//  Atomic.swift
//  VergeNeue
//
//  Created by muukii on 2019/09/22.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

@propertyWrapper
final class _Atomic<T> {
  
  private let lock: NSLock = .init()
  
  public var wrappedValue: T {
    get {
      lock.lock(); defer { lock.unlock() }
      return _value
    }
    set {
      lock.lock(); defer { lock.unlock() }
      _value = newValue
    }
  }
  
  private var _value: T
  
  public init(wrappedValue value: T) {
    self._value = value
  }
}
