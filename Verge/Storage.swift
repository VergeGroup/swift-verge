
import Foundation

public struct StorageSubscribeToken : Hashable {
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
  
  public init(_ value: Value) {
    self.nonatomicValue = value
  }
  
  public func update(_ update: (inout Value) throws -> Void) rethrows {
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
  
  public func replace(_ value: Value) {
    lock.lock()
    nonatomicValue = value
    lock.unlock()
    notify(value: nonatomicValue)
  }
    
  @discardableResult
  public func add(subscriber: @escaping (Value) -> Void) -> StorageSubscribeToken {
    lock.lock(); defer { lock.unlock() }
    let token = StorageSubscribeToken()
    subscribers[token] = subscriber
    return token
  }
  
  public func remove(subscriber: StorageSubscribeToken) {
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
