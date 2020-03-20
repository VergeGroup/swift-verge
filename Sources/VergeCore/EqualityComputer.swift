//
//  EqualityComputer.swift
//  VergeCore
//
//  Created by muukii on 2020/01/31.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import os.lock

fileprivate final class PreviousValueRef<T> {
  var value: T
  init(value: T) {
    self.value = value
  }
}

/// A Filter that compares with previous value.
public final class EqualityComputer<Input> {
  
  private let _isEqual: (Input) -> Bool
  
  private var lock = os_unfair_lock_s()
  
  private let valueRef: AnyObject?
  
  public init<Key>(
    selector: @escaping (Input) -> Key,
    comparer: Comparer<Key>
  ) {
    
    let ref = PreviousValueRef<Key?>(value: nil)
    
    self.valueRef = ref
    
    self._isEqual = { [weak ref] input in
      
      guard let ref = ref else {
        assertionFailure("Caught unexpected behavior")
        return false
      }
      
      let key = selector(input)
      defer {
        ref.value = key
      }
      if let previousValue = ref.value {
        return comparer.equals(previousValue: previousValue, newValue: key)
      } else {
        return false
      }
      
    }
    
  }
  
  public func equals(input: Input) -> Bool {
    os_unfair_lock_lock(&lock); defer { os_unfair_lock_unlock(&lock) }
    return _isEqual(input)
  }
  
  public func registerFirstValue(_ value: Input) {
    os_unfair_lock_lock(&lock); defer { os_unfair_lock_unlock(&lock) }
    _ = _isEqual(value)
  }
  
  public func asFunction() -> (Input) -> Bool {
    equals
  }
  
}

public struct EqualityComputerBuilder<Input, ComparingKey> {
  
  public static var noFilter: EqualityComputerBuilder<Input, Input> {
    .init(keySelector: { $0 }, comparer: .init { _, _ in false })
  }
  
  public let selector: (Input) -> ComparingKey
  public let comparer: Comparer<ComparingKey>
  
  public init(
    keySelector: @escaping (Input) -> ComparingKey,
    comparer: Comparer<ComparingKey>
  ) {
    self.selector = keySelector
    self.comparer = comparer
  }
  
  #if swift(<5.2)
  public init(
    keySelector: KeyPath<Input, ComparingKey>,
    comparer: Comparer<ComparingKey>
  ) {
    self.selector = { $0[keyPath: keySelector] }
    self.comparer = comparer
  }
  #endif
    
  public func build() -> EqualityComputer<Input> {
    .init(selector: selector, comparer: comparer)
  }
}

extension EqualityComputerBuilder where Input : Equatable, ComparingKey == Input {
  public init()  {
    self.selector = { $0 }
    self.comparer = .init(==)
  }
}

extension EqualityComputerBuilder where Input == ComparingKey {
  
  public init(comparer: Comparer<Input>) {
    self.init(keySelector: { $0 }, comparer: comparer)
  }
  
}
