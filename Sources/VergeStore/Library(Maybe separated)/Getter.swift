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
  
  private let willUpdateEmitter = EventEmitter<Void>()
  private let didUpdateEmitter = EventEmitter<Destination>()
  
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
  
  func accept(_ value: Source) {
    guard !checker(value) else { return }
    willUpdateEmitter.accept(())
    let newValue = selector(value)
    computedValue = newValue
    didUpdateEmitter.accept(newValue)
  }
  
  /// Register observer with closure.
  /// Storage tells got a newValue.
  /// - Returns: Token to stop subscribing. (Optional) You may need to retain somewhere. But subscription will be disposed when Storage was destructed.
  @discardableResult
  public func addWillUpdate(subscriber: @escaping () -> Void) -> EventEmitterSubscribeToken {
    willUpdateEmitter.add(subscriber)
  }
  
  /// Register observer with closure.
  /// Storage tells got a newValue.
  /// - Returns: Token to stop subscribing. (Optional) You may need to retain somewhere. But subscription will be disposed when Storage was destructed.
  @discardableResult
  public func addDidUpdate(subscriber: @escaping (Destination) -> Void) -> EventEmitterSubscribeToken {
    didUpdateEmitter.add(subscriber)
  }
  
}

#if canImport(Combine)

import Combine

fileprivate var _willChangeAssociated: Void?
fileprivate var _didChangeAssociated: Void?

@available(iOS 13.0, macOS 10.15, *)
extension MemoizeGetter: ObservableObject {
  
  public var objectWillChange: ObservableObjectPublisher {
    if let associated = objc_getAssociatedObject(self, &_willChangeAssociated) as? ObservableObjectPublisher {
      return associated
    } else {
      let associated = ObservableObjectPublisher()
      objc_setAssociatedObject(self, &_willChangeAssociated, associated, .OBJC_ASSOCIATION_RETAIN)
      
      addWillUpdate {
        if Thread.isMainThread {
          associated.send()
        } else {
          DispatchQueue.main.async {
            associated.send()
          }
        }
      }
      
      return associated
    }
  }
  
  public var didChangePublisher: AnyPublisher<Destination, Never> {
    
    if let associated = objc_getAssociatedObject(self, &_didChangeAssociated) as? PassthroughSubject<Destination, Never> {
      return associated.eraseToAnyPublisher()
    } else {
      let associated = PassthroughSubject<Destination, Never>()
      objc_setAssociatedObject(self, &_didChangeAssociated, associated, .OBJC_ASSOCIATION_RETAIN)
      
      addDidUpdate { s in
        if Thread.isMainThread {
          associated.send(s)
        } else {
          DispatchQueue.main.async {
            associated.send(s)
          }
        }
      }
      
      return associated.eraseToAnyPublisher()
    }
  }
  
}

#endif

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
        
    backingStorage.makeMemoizeGetter(equality: equality, selector: selector)
  }
  
}
