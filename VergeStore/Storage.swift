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

struct StorageSubscribeToken : Hashable {
  private let identifier = UUID().uuidString
}

@propertyWrapper
public final class Storage<Value> {
  
  private var subscribers: [StorageSubscribeToken : (Value) -> Void] = [:]
  
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
