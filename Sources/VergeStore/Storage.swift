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
public class Storage<Value>: CustomReflectable {
  
  private var willUpdateSubscribers: [StorageSubscribeToken : (Value) -> Void] = [:]
  private var didUpdateSubscribers: [StorageSubscribeToken : (Value) -> Void] = [:]
  
  public var wrappedValue: Value {
    return value
  }
  
  public var projectedValue: Storage<Value> {
    self
  }
  
  public var value: Value {
    os_unfair_lock_lock(&unfairLock)
    defer {
      os_unfair_lock_unlock(&unfairLock)
    }
    return nonatomicValue
  }
  
  private var nonatomicValue: Value
  
  private var unfairLock = os_unfair_lock_s()
  
  public init(_ value: Value) {
    self.nonatomicValue = value
  }
  
  @discardableResult
  @inline(__always)
  public func update(_ update: (inout Value) throws -> Void) rethrows -> Value {
    do {
      let notifyValue: Value
      os_unfair_lock_lock(&unfairLock)
      notifyValue = nonatomicValue
      os_unfair_lock_unlock(&unfairLock)
      notifyWillUpdate(value: notifyValue)
    }
    
    os_unfair_lock_lock(&unfairLock)
    do {
      try update(&nonatomicValue)
      let notifyValue = nonatomicValue
      os_unfair_lock_unlock(&unfairLock)
      notifyDidUpdate(value: notifyValue)
      return notifyValue
    } catch {
      os_unfair_lock_unlock(&unfairLock)
      throw error
    }
  }
  
  public func replace(_ value: Value) {
    do {
      let notifyValue: Value
      os_unfair_lock_lock(&unfairLock)
      notifyValue = nonatomicValue
      os_unfair_lock_unlock(&unfairLock)
      notifyWillUpdate(value: notifyValue)
    }
    
    do {
      os_unfair_lock_lock(&unfairLock)
      nonatomicValue = value
      let notifyValue = nonatomicValue
      os_unfair_lock_unlock(&unfairLock)
      notifyDidUpdate(value: notifyValue)
    }
  }
  
  @discardableResult
  public func addWillUpdate(subscriber: @escaping (Value) -> Void) -> StorageSubscribeToken {
    os_unfair_lock_lock(&unfairLock)
    defer { os_unfair_lock_unlock(&unfairLock) }
    
    let token = StorageSubscribeToken()
    willUpdateSubscribers[token] = subscriber
    return token
  }
  
  @discardableResult
  public func addDidUpdate(subscriber: @escaping (Value) -> Void) -> StorageSubscribeToken {
    os_unfair_lock_lock(&unfairLock)
    defer { os_unfair_lock_unlock(&unfairLock) }
    
    let token = StorageSubscribeToken()
    didUpdateSubscribers[token] = subscriber
    return token
  }
  
  public func remove(subscriber: StorageSubscribeToken) {
    os_unfair_lock_lock(&unfairLock)
    defer { os_unfair_lock_unlock(&unfairLock) }
    
    didUpdateSubscribers.removeValue(forKey: subscriber)
    willUpdateSubscribers.removeValue(forKey: subscriber)
  }
    
  @inline(__always)
  fileprivate func notifyWillUpdate(value: Value) {
    os_unfair_lock_lock(&unfairLock)
    let subscribers: [StorageSubscribeToken : (Value) -> Void] = self.willUpdateSubscribers
    os_unfair_lock_unlock(&unfairLock)
    
    subscribers.forEach { $0.value(value) }
  }
  
  @inline(__always)
  fileprivate func notifyDidUpdate(value: Value) {
    os_unfair_lock_lock(&unfairLock)
    let subscribers: [StorageSubscribeToken : (Value) -> Void] = self.didUpdateSubscribers
    os_unfair_lock_unlock(&unfairLock)
    
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
