//
//  Storage.swift
//  Cycler
//
//  Created by muukii on 12/15/17.
//  Copyright © 2017 muukii. All rights reserved.
//

import Foundation

public protocol MutableStorageLogging {

  func didChange(value: Any, for keyPath: AnyKeyPath, root: Any)
  func didReplace(root: Any)
}

public class Storage<T> {

  public struct Token : Hashable {

    public static func == (lhs: Token, rhs: Token) -> Bool {
      return lhs.identifier == rhs.identifier
    }

    public var hashValue: Int {
      return identifier.hashValue
    }

    private let identifier = UUID().uuidString
  }

  private let lock: NSRecursiveLock = .init()

  private var subscribers: [Token : (T) -> Void] = [:]

  public var value: T {
    lock.lock(); defer { lock.unlock() }
    return _value
  }

  fileprivate var _value: T

  public init(_ value: T) {
    self._value = value
  }

  @discardableResult
  public func add(subscriber: @escaping (T) -> Void) -> Token {
    lock.lock(); defer { lock.unlock() }
    let token = Token()
    subscribers[token] = subscriber
    return token
  }

  public func remove(subscriber: Token) {
    lock.lock(); defer { lock.unlock() }
    subscribers.removeValue(forKey: subscriber)
  }

  fileprivate func notify() {
    lock.lock(); defer { lock.unlock() }
    subscribers.forEach { $0.value(_value) }
  }

  func asMutableStateStorage() -> MutableStorage<T> {
    return self as! MutableStorage<T>
  }
}

public final class MutableStorage<T> : Storage<T> {

  public typealias Source = T

  public var loggers: [MutableStorageLogging] = []

  private let lock: NSRecursiveLock = .init()

  private var isInBatchUpdating: Bool = false

  public func replace(_ value: T) {
    lock.lock(); defer { lock.unlock() }
    _value = value
    notifyIfNotBatchUpdating()
  }

  public func batchUpdate(_ update: (MutableStorage<T>) -> Void) {
    lock.lock(); defer { lock.unlock() }
    enterBatchUpdating()
    update(self)
    leaveBatchUpdating()
    notifyIfNotBatchUpdating()

    loggers.forEach { $0.didReplace(root: value as Any) }
  }

  public func update<E>(_ value: E?, _ keyPath: WritableKeyPath<T, E?>) {

    lock.lock(); defer { lock.unlock() }

    _value[keyPath: keyPath] = value

    notifyIfNotBatchUpdating()

    loggers.forEach { $0.didChange(value: value as Any, for: keyPath, root: _value) }
  }

  public func update<E>(_ value: E, _ keyPath: WritableKeyPath<T, E>) {

    lock.lock(); defer { lock.unlock() }

    _value[keyPath: keyPath] = value

    notifyIfNotBatchUpdating()

    loggers.forEach { $0.didChange(value: value as Any, for: keyPath, root: _value) }
  }

  public func updateIfChanged<E>(_ value: E?, _ keyPath: WritableKeyPath<T, E?>, comparer: (E?, E?) -> Bool) {

    lock.lock(); defer { lock.unlock() }

    guard comparer(_value[keyPath: keyPath], value) == false else { return }
    _value[keyPath: keyPath] = value

    notifyIfNotBatchUpdating()

    loggers.forEach { $0.didChange(value: value as Any, for: keyPath, root: _value) }
  }

  public func updateIfChanged<E: Equatable>(_ value: E?, _ keyPath: WritableKeyPath<T, E?>, comparer: (E?, E?) -> Bool = { $0 == $1 }) {

    lock.lock(); defer { lock.unlock() }

    guard comparer(_value[keyPath: keyPath], value) == false else { return }
    _value[keyPath: keyPath] = value

    notifyIfNotBatchUpdating()

    loggers.forEach { $0.didChange(value: value as Any, for: keyPath, root: _value) }
  }

  public func updateIfChanged<E>(_ value: E, _ keyPath: WritableKeyPath<T, E>, comparer: (E, E) -> Bool) {

    lock.lock(); defer { lock.unlock() }

    guard comparer(_value[keyPath: keyPath], value) == false else { return }
    _value[keyPath: keyPath] = value

    notifyIfNotBatchUpdating()

    loggers.forEach { $0.didChange(value: value as Any, for: keyPath, root: _value) }
  }

  public func updateIfChanged<E : Equatable>(_ value: E, _ keyPath: WritableKeyPath<T, E>, comparer: (E, E) -> Bool = { $0 == $1 }) {

    lock.lock(); defer { lock.unlock() }

    guard comparer(_value[keyPath: keyPath], value) == false else { return }
    _value[keyPath: keyPath] = value

    notifyIfNotBatchUpdating()

    loggers.forEach { $0.didChange(value: value as Any, for: keyPath, root: _value) }
  }

  public func asStorage() -> Storage<T> {
    return self as Storage<T>
  }

  private func enterBatchUpdating() {
    isInBatchUpdating = true
  }

  private func leaveBatchUpdating() {
    isInBatchUpdating = false
  }

  private func notifyIfNotBatchUpdating() {

    guard isInBatchUpdating == false else { return }
    notify()
  }
}
