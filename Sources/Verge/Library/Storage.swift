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

public protocol _VergeRecursiveLockType {
  func lock()
  func unlock()

  init()
}

extension _VergeRecursiveLockType {

  public func asAny() -> VergeAnyRecursiveLock {
    .init(lock: lock, unlock: unlock)
  }
}

extension _VergeRecursiveLockType where Self == VergeAnyRecursiveLock {

  func asAny() -> VergeAnyRecursiveLock {
    self
  }

}

extension NSRecursiveLock: _VergeRecursiveLockType {

}

public struct VergeNoLock: _VergeRecursiveLockType {

  public func lock() {}

  public func unlock() {}

  public init() {}
}

public struct VergeAnyRecursiveLock: _VergeRecursiveLockType {

  let _lock: () -> Void
  let _unlock: () -> Void

  public init() {
    _lock = {}
    _unlock = {}
  }

  init(lock: @escaping () -> Void, unlock: @escaping () -> Void) {
    self._lock = lock
    self._unlock = unlock
  }

  public func lock() {
    _lock()
  }

  public func unlock() {
    _unlock()
  }

}

open class ReadonlyStorage<Value>: CustomReflectable {
    
  private let willUpdateEmitter = EventEmitter<Void>()
  private let didUpdateEmitter = EventEmitter<Value>()
  private let deinitEmitter = EventEmitter<Void>()

  /// Returns a current value with thread-safety.
  ///
  /// It causes locking and unlocking with a bit cost.
  /// It may cause blocking if any other is doing mutation or reading.
  public final var wrappedValue: Value {
    return value
  }

  /// Returns a current value with thread-safety.
  ///
  /// It causes locking and unlocking with a bit cost.
  /// It may cause blocking if any other is doing mutation or reading.
  public final var value: Value {
    _lock.lock()
    defer {
      _lock.unlock()
    }
    return nonatomicValue
  }
  
  fileprivate var nonatomicValue: Value
  
  private let _lock: VergeAnyRecursiveLock
  
  fileprivate let upstreams: [AnyObject]

  public convenience init(
    _ value: Value,
    upstreams: [AnyObject] = []
  ) {
    self.init(value, recursiveLock: NSRecursiveLock(), upstreams: upstreams)
  }
  
  public init<RecursiveLock: _VergeRecursiveLockType>(
    _ value: Value,
    recursiveLock: RecursiveLock,
    upstreams: [AnyObject] = []
  ) {

    self._lock = recursiveLock.asAny()
    self.nonatomicValue = value
    self.upstreams = upstreams
    
    willUpdateEmitter.add {
      vergeSignpostEvent("Storage.willUpdate")
    }
  }
  
  deinit {
    deinitEmitter.accept(())
  }
  
  public func lock() {
    _lock.lock()
  }
  
  public func unlock() {
    _lock.unlock()
  }
    
  /// Register observer with closure.
  /// Storage tells got a newValue.
  /// - Returns: Token to stop subscribing. (Optional) You may need to retain somewhere. But subscription will be disposed when Storage was destructed.
  @discardableResult
  public final func addWillUpdate(subscriber: @escaping () -> Void) -> EventEmitterCancellable {
    willUpdateEmitter.add(subscriber)
  }
  
  /// Register observer with closure.
  /// Storage tells got a newValue.
  /// - Returns: Token to stop subscribing. (Optional) You may need to retain somewhere. But subscription will be disposed when Storage was destructed.
  @discardableResult
  public final func addDidUpdate(subscriber: @escaping (Value) -> Void) -> EventEmitterCancellable {
    didUpdateEmitter.add(subscriber)
  }
  
  @discardableResult
  public final func addDeinit(subscriber: @escaping () -> Void) -> EventEmitterCancellable {
    deinitEmitter.add(subscriber)
  }
    
  @inline(__always)
  fileprivate func notifyWillUpdate(value: Value) {
    willUpdateEmitter.accept(())
  }
  
  @inline(__always)
  fileprivate func notifyDidUpdate(value: Value) {
    didUpdateEmitter.accept(value)
  }
  
  public var customMirror: Mirror {
    Mirror(
      self,
      children: ["value": value],
      displayStyle: .struct
    )
  }
  
}

open class Storage<Value>: ReadonlyStorage<Value> {
  
  private var notificationFilter: (Value) -> Bool = { _ in true }

  public enum UpdateResult {
    case updated
    case nothingUpdates
  }

  @inline(__always)
  public final func _update(_ update: (inout Value) throws -> UpdateResult) rethrows {

    let signpost = VergeSignpostTransaction("Storage.update")
    defer {
      signpost.end()
    }

    lock()
    do {

      let previousValue = nonatomicValue

      let result = try update(&nonatomicValue)

      switch result {
      case .nothingUpdates:
        unlock()
      case .updated:
        let afterValue = nonatomicValue
        unlock()

        if notificationFilter(previousValue) {
          notifyWillUpdate(value: previousValue)
        }
        // TODO: cause cracking the order of event
        if notificationFilter(afterValue) {
          notifyDidUpdate(value: afterValue)
        }
      }

    } catch {
      unlock()
      throw error
    }
  }
  
  @discardableResult
  @inline(__always)
  public final func update<Result>(_ update: (inout Value) throws -> Result) rethrows -> Result {
    let signpost = VergeSignpostTransaction("Storage.update")
    defer {
      signpost.end()
    }
    do {
      let notifyValue: Value
      lock()
      notifyValue = nonatomicValue
      unlock()
      if notificationFilter(notifyValue) {
        notifyWillUpdate(value: notifyValue)
      }
    }
    
    lock()
    do {
      let r = try update(&nonatomicValue)
      let notifyValue = nonatomicValue
      unlock()
      // TODO: cause cracking the order of event
      if notificationFilter(notifyValue) {
        notifyDidUpdate(value: notifyValue)
      }
      return r
    } catch {
      unlock()
      throw error
    }
  }
    
  /// Filter to supress update notifications
  /// - Parameter filter: Return true, notification will emit.
  public final func setNotificationFilter(_ filter: @escaping (Value) -> Bool) {
    notificationFilter = filter
  }
     
}

public final class StateStorage<Value>: Storage<Value> {

}

extension ReadonlyStorage {
  
  /// Transform value with filtering.
  /// - Attention: Retains upstream storage
  public func map<U>(
    filter: @escaping (Value) -> Bool = { _ in false },
    transform: @escaping (Value) -> U
  ) -> ReadonlyStorage<U> {
    
    let initialValue = transform(value)
    let newStorage = Storage<U>.init(
      initialValue,
      recursiveLock: _lock,
      upstreams: [self]
    )
    
    let token = addDidUpdate { [weak newStorage] (newValue) in
      guard !filter(newValue) else {
        return
      }
      newStorage?.update {
        $0 = transform(newValue)
      }
    }
    
    newStorage.addDeinit {
      token.cancel()
    }
    
    return newStorage
  }
}

#if canImport(Combine)

import Combine

// MARK: - Integrate with Combine

fileprivate var _willChangeAssociated: Void?
fileprivate var _didChangeAssociated: Void?

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension ReadonlyStorage: ObservableObject {
  
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
  
  public var objectDidChange: AnyPublisher<Value, Never> {
    valuePublisher.dropFirst().eraseToAnyPublisher()
  }
  
  public var valuePublisher: AnyPublisher<Value, Never> {
    
    if let associated = objc_getAssociatedObject(self, &_didChangeAssociated) as? CurrentValueSubject<Value, Never> {
      return associated.eraseToAnyPublisher()
    } else {
      let associated = CurrentValueSubject<Value, Never>(value)
      objc_setAssociatedObject(self, &_didChangeAssociated, associated, .OBJC_ASSOCIATION_RETAIN)
      
      addDidUpdate { s in
        associated.send(s)
      }
      
      return associated.eraseToAnyPublisher()
    }
  }
    
}

#endif
