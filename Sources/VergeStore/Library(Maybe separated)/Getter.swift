//
//  Getter.swift
//  VergeStore
//
//  Created by muukii on 2019/12/09.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public final class MemoizeGetter<Source, Destination> {
  
  let source: Source
  let selector: (Source) -> Destination
  private var computedValue: Destination
  private let checker: (Source) -> Bool
  
  public init<Key>(
    source: Source,
    equality: EqualityComputer<Source, Key>,
    selector: @escaping (Source) -> Destination
  ) {
    self.source = source
    self.selector = selector
    self.checker = equality.input
    
    self.computedValue = selector(source)
  }
  
  public var value: Destination {
    computedValue
  }
  
  public func accept(_ value: Source) {
    guard !checker(value) else { return }
    let newValue = selector(value)
    computedValue = newValue
  }
}

public final class EqualityComputer<Value, Key> {
  
  private let selector: (Value) -> Key
  private let equals: (Key, Key) -> Bool
  
  private var previousValue: Key?
  
  public init(
    selector: @escaping (Value) -> Key,
    equals: @escaping (Key, Key) -> Bool
  ) {
    
    self.selector = selector
    self.equals = equals
    
  }
     
  func input(value: Value) -> Bool {
    
    let key = selector(value)
    
    if let previousValue = previousValue {
      return equals(previousValue, key)
    } else {
      previousValue = key
      return false
    }
    
  }
}

extension EqualityComputer where Key : Equatable {
  public convenience init(selector: @escaping (Value) -> Key) {
    self.init(selector: selector, equals: ==)
  }
}

extension EqualityComputer where Value == Key {
  
  public convenience init(equals: @escaping (Key, Key) -> Bool) {
    self.init(selector: { $0 }, equals: equals)
  }
}

extension EqualityComputer where Key : Equatable, Value == Key {
    
  public convenience init() {
    self.init(equals: ==)
  }
}

extension Storage {
  
  public func makeMemoizeGetter<Key, Destination>(
    equality: EqualityComputer<Value, Key>,
    selector: @escaping (Value) -> Destination
  ) -> MemoizeGetter<Value, Destination> {
    
    let getter = MemoizeGetter(
      source: value,
      equality: equality,
      selector: selector
    )
    
    addDidUpdate { (newValue) in
      getter.accept(newValue)
    }
    
    return getter
    
  }
}

extension StoreBase {
  
  public func makeMemoizeGetter<Key, Destination>(
    equality: EqualityComputer<State, Key>,
    selector: @escaping (State) -> Destination
  ) -> MemoizeGetter<State, Destination> {
    
    let getter = MemoizeGetter(
      source: state,
      equality: equality,
      selector: selector
    )
    
    backingStorage.addDidUpdate { (newValue) in
      getter.accept(newValue)
    }
    
    return getter
    
  }
  
}
