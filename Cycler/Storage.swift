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

public struct StorageSubscribeToken : Hashable {

  public static func == (lhs: StorageSubscribeToken, rhs: StorageSubscribeToken) -> Bool {
    return lhs.identifier == rhs.identifier
  }

  public var hashValue: Int {
    return identifier.hashValue
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

  func asMutableStateStorage() -> MutableStorage<T> {
    return source
  }
}

public final class MutableStorage<T> {

  public typealias Source = T

  private var subscribers: [StorageSubscribeToken : (T) -> Void] = [:]

  public var loggers: [MutableStorageLogging] = []

  private let lock: NSRecursiveLock = .init()

  private var isInBatchUpdating: Bool = false

  public var value: T {
    lock.lock(); defer { lock.unlock() }
    return _value
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

  fileprivate func notify() {
    lock.lock(); defer { lock.unlock() }
    subscribers.forEach { $0.value(_value) }
  }

  public func replace(_ value: T) {
    lock.lock(); defer { lock.unlock() }
    _value = value
    notifyIfNotBatchUpdating()
  }

  public func batchUpdate(_ update: (MutableStorage<T>) throws -> Void) rethrows {

    lock.lock(); defer { lock.unlock() }
    enterBatchUpdating()
    try update(self)
    leaveBatchUpdating()
    notifyIfNotBatchUpdating()

    loggers.forEach { $0.didReplace(root: _value as Any) }
  }

  public func update<E>(_ value: E?, _ keyPath: WritableKeyPath<T, E?>, ifChanged comparer: ((E?, E?) -> Bool)? = nil) {

    lock.lock(); defer { lock.unlock() }

    if let comparer = comparer, comparer(_value[keyPath: keyPath], value) {
      return
    }

    _value[keyPath: keyPath] = value

    notifyIfNotBatchUpdating()

    loggers.forEach { $0.didChange(value: value as Any, for: keyPath, root: _value) }
  }

  public func update<E>(_ value: E, _ keyPath: WritableKeyPath<T, E>, ifChanged comparer: ((E, E) -> Bool)? = nil) {

    lock.lock(); defer { lock.unlock() }

    if let comparer = comparer, comparer(_value[keyPath: keyPath], value) {
      return
    }

    _value[keyPath: keyPath] = value

    notifyIfNotBatchUpdating()

    loggers.forEach { $0.didChange(value: value as Any, for: keyPath, root: _value) }
  }

  @available(*, deprecated, message: "Use update(_ value, _ keyPath, ifChanged)")
  public func updateIfChanged<E>(_ value: E?, _ keyPath: WritableKeyPath<T, E?>, comparer: (E?, E?) -> Bool) {

    lock.lock(); defer { lock.unlock() }

    guard comparer(_value[keyPath: keyPath], value) == false else { return }
    _value[keyPath: keyPath] = value

    notifyIfNotBatchUpdating()

    loggers.forEach { $0.didChange(value: value as Any, for: keyPath, root: _value) }
  }

  @available(*, deprecated, message: "Use update(_ value, _ keyPath, ifChanged)")
  public func updateIfChanged<E: Equatable>(_ value: E?, _ keyPath: WritableKeyPath<T, E?>, comparer: (E?, E?) -> Bool = { $0 == $1 }) {

    lock.lock(); defer { lock.unlock() }

    guard comparer(_value[keyPath: keyPath], value) == false else { return }
    _value[keyPath: keyPath] = value

    notifyIfNotBatchUpdating()

    loggers.forEach { $0.didChange(value: value as Any, for: keyPath, root: _value) }
  }

  @available(*, deprecated, message: "Use update(_ value, _ keyPath, ifChanged)")
  public func updateIfChanged<E>(_ value: E, _ keyPath: WritableKeyPath<T, E>, comparer: (E, E) -> Bool) {

    lock.lock(); defer { lock.unlock() }

    guard comparer(_value[keyPath: keyPath], value) == false else { return }
    _value[keyPath: keyPath] = value

    notifyIfNotBatchUpdating()

    loggers.forEach { $0.didChange(value: value as Any, for: keyPath, root: _value) }
  }

  @available(*, deprecated, message: "Use update(_ value, _ keyPath, ifChanged)")
  public func updateIfChanged<E : Equatable>(_ value: E, _ keyPath: WritableKeyPath<T, E>, comparer: (E, E) -> Bool = { $0 == $1 }) {

    lock.lock(); defer { lock.unlock() }

    guard comparer(_value[keyPath: keyPath], value) == false else { return }
    _value[keyPath: keyPath] = value

    notifyIfNotBatchUpdating()

    loggers.forEach { $0.didChange(value: value as Any, for: keyPath, root: _value) }
  }

  public func asStorage() -> Storage<T> {
    return Storage.init(self)
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
