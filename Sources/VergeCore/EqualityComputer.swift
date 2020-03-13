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
  
  public init<Key>(
    selector: @escaping (Input) -> Key,
    comparer: Comparer<Key>
  ) {
    
    let ref = Storage<Key?>.init(nil)
    
    self._isEqual = { input in
      
      let key = selector(input)
      defer {
        ref.update {
          $0 = key
        }
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
