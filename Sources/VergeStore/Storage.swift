//
// Copyright (c) 2019 muukii
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import Foundation
import os

public struct StorageSubscribeToken : Hashable {
  private let identifier = UUID().uuidString
}

@propertyWrapper
public final class Storage<Value>: CustomReflectable {
  
  private var willUpdateSubscribers: [StorageSubscribeToken : (Value) -> Void] = [:]
  private var didUpdateSubscribers: [StorageSubscribeToken : (Value) -> Void] = [:]
  
  public var wrappedValue: Value {
    return value
  }
  
  public var projectedValue: Storage<Value> {
    self
  }
  
  public var value: Value {
    lock.lock()
    defer {
      lock.unlock()
    }
    return nonatomicValue
  }
  
  private var nonatomicValue: Value
  
  private let lock = NSRecursiveLock()
  
  public init(_ value: Value) {
    self.nonatomicValue = value
  }
  
  @discardableResult
  @inline(__always)
  public func update(_ update: (inout Value) throws -> Void) rethrows -> Value {
    do {
      let notifyValue: Value
      lock.lock()
      notifyValue = nonatomicValue
      lock.unlock()
      notifyWillUpdate(value: notifyValue)
    }
    
    lock.lock()
    do {
      try update(&nonatomicValue)
      let notifyValue = nonatomicValue
      lock.unlock()
      notifyDidUpdate(value: notifyValue)
      return notifyValue
    } catch {
      lock.unlock()
      throw error
    }
  }
  
  public func replace(_ value: Value) {
    do {
      let notifyValue: Value
      lock.lock()
      notifyValue = nonatomicValue
      lock.unlock()
      notifyWillUpdate(value: notifyValue)
    }
    
    do {
      lock.lock()
      nonatomicValue = value
      let notifyValue = nonatomicValue
      lock.unlock()
      notifyDidUpdate(value: notifyValue)
    }
  }
  
  /// Register observer with closure.
  /// Storage tells got a newValue.
  /// - Returns: Token to stop subscribing. (Optional) You may need to retain somewhere. But subscription will be disposed when Storage was destructed.
  @discardableResult
  public func addWillUpdate(subscriber: @escaping (Value) -> Void) -> StorageSubscribeToken {
    lock.lock()
    defer { lock.unlock() }
    
    let token = StorageSubscribeToken()
    willUpdateSubscribers[token] = subscriber
    return token
  }
  
  /// Register observer with closure.
  /// Storage tells got a newValue.
  /// - Returns: Token to stop subscribing. (Optional) You may need to retain somewhere. But subscription will be disposed when Storage was destructed.
  @discardableResult
  public func addDidUpdate(subscriber: @escaping (Value) -> Void) -> StorageSubscribeToken {
    lock.lock()
    defer { lock.unlock() }
    
    let token = StorageSubscribeToken()
    didUpdateSubscribers[token] = subscriber
    return token
  }
  
  public func remove(subscriber: StorageSubscribeToken) {
    lock.lock()
    defer { lock.unlock() }
    
    didUpdateSubscribers.removeValue(forKey: subscriber)
    willUpdateSubscribers.removeValue(forKey: subscriber)
  }
    
  @inline(__always)
  fileprivate func notifyWillUpdate(value: Value) {
    lock.lock()
    let subscribers: [StorageSubscribeToken : (Value) -> Void] = self.willUpdateSubscribers
    lock.unlock()
    
    subscribers.forEach { $0.value(value) }
  }
  
  @inline(__always)
  fileprivate func notifyDidUpdate(value: Value) {
    lock.lock()
    let subscribers: [StorageSubscribeToken : (Value) -> Void] = self.didUpdateSubscribers
    lock.unlock()
    
    subscribers.forEach { $0.value(value) }
  }
  
  public var customMirror: Mirror {
    Mirror(
      self,
      children: ["value": value],
      displayStyle: .struct
    )
  }
  
}

extension Storage {
  
  public func map<U>(selector: @escaping (Value) -> U) -> Storage<U> {
    let initialValue = selector(value)
    let newStorage = Storage<U>.init(initialValue)
    self.addDidUpdate { (newValue) in
      newStorage.replace(selector(newValue))
    }
    return newStorage
  }
}
