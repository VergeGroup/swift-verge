//
//  EqualityComputer.swift
//  VergeCore
//
//  Created by muukii on 2020/01/31.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

fileprivate final class PreviousValueRef<T> {
  var value: T?
  init() {}
}

/// A Filter that compares with previous value.
public final class EqualityComputer<Input> {
  
  private let _isEqual: (Input) -> Bool
  
  public init<Key, C: Comparer>(
    selector: @escaping (Input) -> Key,
    comparer: C
  ) where C.Input == Key {
    
    let ref = PreviousValueRef<Key>()
    
    self._isEqual = { input in
      
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
    _isEqual(input)
  }
  
  public func registerFirstValue(_ value: Input) {
    _ = _isEqual(value)
  }
  
  public func asFunction() -> (Input) -> Bool {
    equals
  }
  
}

public struct EqualityComputerBuilder<Input, ComparingKey> {
  
  public static var alwaysDifferent: EqualityComputerBuilder<Input, Input> {
    .init(keySelector: { $0 }, comparer: { _, _ in false })
  }
  
  let selector: (Input) -> ComparingKey
  let predicate: (ComparingKey, ComparingKey) -> Bool
  
  public init(
    keySelector: @escaping (Input) -> ComparingKey,
    comparer: @escaping (ComparingKey, ComparingKey) -> Bool
  ) {
    self.selector = keySelector
    self.predicate = comparer
  }
  
  public func build() -> EqualityComputer<Input> {
    .init(selector: selector, comparer: AnyComparer.init(predicate))
  }
}

extension EqualityComputerBuilder where Input : Equatable {
  
  public static func make() -> EqualityComputerBuilder<Input, Input> {
    .init(keySelector: { $0 }, comparer: ==)
  }
  
}
