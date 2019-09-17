//
//  Storage.swift
//  VergeNeue
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

struct StorageSubscribeToken : Hashable {
  private let identifier = UUID().uuidString
}

final class Storage<Value> {
  
  private var subscribers: [StorageSubscribeToken : (Value) -> Void] = [:]
  
  var value: Value {
    lock.lock()
    defer {
      lock.unlock()
    }
    return nonatomicValue
  }
  
  private var nonatomicValue: Value
  
  private let lock = NSLock()
  
  init(_ value: Value) {
    self.nonatomicValue = value
  }
  
  func update(_ update: (inout Value) throws -> Void) rethrows {
    lock.lock()
    do {
      try update(&nonatomicValue)
    } catch {
      lock.unlock()
      throw error
    }
    lock.unlock()
    notify(value: nonatomicValue)
  }
  
  
  @discardableResult
  func add(subscriber: @escaping (Value) -> Void) -> StorageSubscribeToken {
    lock.lock(); defer { lock.unlock() }
    let token = StorageSubscribeToken()
    subscribers[token] = subscriber
    return token
  }
  
  func remove(subscriber: StorageSubscribeToken) {
    lock.lock(); defer { lock.unlock() }
    subscribers.removeValue(forKey: subscriber)
  }
  
  @inline(__always)
  fileprivate func notify(value: Value) {
    lock.lock()
    let subscribers: [StorageSubscribeToken : (Value) -> Void] = self.subscribers
    lock.unlock()
    subscribers.forEach { $0.value(value) }
  }
  
}
