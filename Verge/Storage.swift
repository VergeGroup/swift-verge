
import Foundation

public protocol MutableStorageLogging {

  func didChange(root: Any)
  func didReplace(root: Any)
}

public struct StorageSubscribeToken : Hashable {

  public static func == (lhs: StorageSubscribeToken, rhs: StorageSubscribeToken) -> Bool {
    return lhs.identifier == rhs.identifier
  }

  private let identifier = UUID().uuidString
}

public class Storage<T> {

  public var value: T {
    return source.value
  }

  private let source: MutableStorage<T>

  public convenience init(_ value: T) {
    self.init(MutableStorage.init(value))
  }

  public init(_ source: MutableStorage<T>) {
    self.source = source
  }

  @discardableResult
  public func add(subscriber: @escaping (T) -> Void) -> StorageSubscribeToken {
    return source.add(subscriber: subscriber)
  }

  public func remove(subscriber token: StorageSubscribeToken) {
    source.remove(subscriber: token)
  }

  var mutableStateStorage: MutableStorage<T> {
    return source
  }
}

public final class MutableStorage<T> {

  public typealias Source = T

  private var subscribers: [StorageSubscribeToken : (T) -> Void] = [:]

  public var loggers: [MutableStorageLogging] = []

  private let lock: NSRecursiveLock = .init()

  public var value: T {
    lock.lock()
    let v = _value
    lock.unlock()
    return v
  }

  private var _value: T

  public init(_ value: T) {
    self._value = value
  }

  @discardableResult
  public func add(subscriber: @escaping (T) -> Void) -> StorageSubscribeToken {
    lock.lock(); defer { lock.unlock() }
    let token = StorageSubscribeToken()
    subscribers[token] = subscriber
    return token
  }

  public func remove(subscriber: StorageSubscribeToken) {
    lock.lock(); defer { lock.unlock() }
    subscribers.removeValue(forKey: subscriber)
  }

  public func update(_ update: (inout T) throws -> Void) rethrows {
    lock.lock()
    try update(&_value)
    let currentValue = _value
    lock.unlock()
    notify(value: currentValue)
  }

  public func replace(_ value: T) {
    lock.lock()
    _value = value
    let currentValue = _value
    lock.unlock()
    notify(value: currentValue)
  }

  @inline(__always)
  fileprivate func notify(value: T) {
    lock.lock()
    let subscribers: [StorageSubscribeToken : (T) -> Void] = self.subscribers
    lock.unlock()
    subscribers.forEach { $0.value(value) }
  }

  public func asStorage() -> Storage<T> {
    return Storage.init(self)
  }

}

