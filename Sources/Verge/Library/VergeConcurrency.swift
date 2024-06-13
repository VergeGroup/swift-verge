//
// Copyright (c) 2020 muukii
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

public enum VergeConcurrency {
  
  public final class RecursiveLock: NSRecursiveLock {
    
  }
  
  public struct UnfairLock: ~Copyable {
    private let _lock: os_unfair_lock_t
   
    public init() {
      _lock = .allocate(capacity: 1)
      _lock.initialize(to: os_unfair_lock())
    }

    public func lock() {
      os_unfair_lock_lock(_lock)
    }

    public func unlock() {
      os_unfair_lock_unlock(_lock)
    }

    public func `try`() -> Bool {
      return os_unfair_lock_trylock(_lock)
    }

    deinit {
      _lock.deinitialize(count: 1)
      _lock.deallocate()
    }
  }
  
  /// An atomic variable.
  public final class RecursiveLockAtomic<Value>: @unchecked Sendable {
    
    public var unsafelyWrappedValue: Value {
      _read { yield _value }
    }
    
    private let lock: RecursiveLock
    private var _value: Value
    
    /// Atomically get or set the value of the variable.
    public var value: Value {
      get {
        return withValue { $0 }
      }
      
      set(newValue) {
        swap(newValue)
      }
    }
    
    /// Initialize the variable with the given initial value.
    ///
    /// - parameters:
    ///   - value: Initial value for `self`.
    public init(_ value: Value) {
      _value = value
      lock = .init()
    }
    
    /// Atomically modifies the variable.
    ///
    /// - parameters:
    ///   - action: A closure that takes the current value.
    ///
    /// - returns: The result of the action.
    @discardableResult
    public func modify<Result>(_ action: (inout Value) throws -> Result) rethrows -> Result {
      lock.lock()
      defer { lock.unlock() }
      
      return try action(&_value)
    }
    
    /// Atomically perform an arbitrary action using the current value of the
    /// variable.
    ///
    /// - parameters:
    ///   - action: A closure that takes the current value.
    ///
    /// - returns: The result of the action.
    @discardableResult
    public func withValue<Result>(_ action: (Value) throws -> Result) rethrows -> Result {
      lock.lock()
      defer { lock.unlock() }
      
      return try action(_value)
    }
    
    /// Atomically replace the contents of the variable.
    ///
    /// - parameters:
    ///   - newValue: A new value for the variable.
    ///
    /// - returns: The old value.
    @discardableResult
    public func swap(_ newValue: Value) -> Value {
      return modify { (value: inout Value) in
        let oldValue = value
        value = newValue
        return oldValue
      }
    }
  }
    
  /// An atomic variable.
  @propertyWrapper
  public final class UnfairLockAtomic<Value>: @unchecked Sendable {
    
    public var unsafelyWrappedValue: Value {
      _read { yield _value }
    }
    
    private let lock: UnfairLock
    private var _value: Value
    
    /// Atomically get or set the value of the variable.
    public var value: Value {
      get {
        return withValue { $0 }
      }
      set(newValue) {
        swap(newValue)
      }
    }

    public var wrappedValue: Value {
      get {
        return withValue { $0 }
      }
      set(newValue) {
        swap(newValue)
      }
    }

    /// Initialize the variable with the given initial value.
    ///
    /// - parameters:
    ///   - value: Initial value for `self`.
    public init(_ wrappedValue: Value) {
      _value = wrappedValue
      lock = .init()
    }

    public init(wrappedValue: Value) {
      _value = wrappedValue
      lock = .init()
    }

    public var projectedValue: UnfairLockAtomic<Value> { self }

    /// Atomically modifies the variable.
    ///
    /// - parameters:
    ///   - action: A closure that takes the current value.
    ///
    /// - returns: The result of the action.
    @discardableResult
    public func modify<Result>(_ action: (inout Value) throws -> Result) rethrows -> Result {
      lock.lock()
      defer { lock.unlock() }
      
      return try action(&_value)
    }
    
    /// Atomically perform an arbitrary action using the current value of the
    /// variable.
    ///
    /// - parameters:
    ///   - action: A closure that takes the current value.
    ///
    /// - returns: The result of the action.
    @discardableResult
    public func withValue<Result>(_ action: (Value) throws -> Result) rethrows -> Result {
      lock.lock()
      defer { lock.unlock() }
      
      return try action(_value)
    }
    
    /// Atomically replace the contents of the variable.
    ///
    /// - parameters:
    ///   - newValue: A new value for the variable.
    ///
    /// - returns: The old value.
    @discardableResult
    public func swap(_ newValue: Value) -> Value {
      return modify { (value: inout Value) in
        let oldValue = value
        value = newValue
        return oldValue
      }
    }
  }

  /// A container that initializes value when it needs.
  ///
  /// Supports multi-threading.
  @propertyWrapper
  public final class AtomicLazy<T>: @unchecked Sendable {

    private enum State {
      case initialized(T)
      case notInitialized
    }

    public typealias Initializer = () -> T

    private var _onInitialized: (T) -> Void = { _ in }

    private let lock: UnfairLock = .init()

    public var wrappedValue: T {

      lock.lock()
      defer {
        lock.unlock()
      }

      return unsafeValue
    }

    public var projectedValue: AtomicLazy<T> {
      self
    }

    @discardableResult
    public func modify<Result>(_ action: (inout T) throws -> Result) rethrows -> Result {
      lock.lock()
      defer { lock.unlock() }

      var new = unsafeValue
      let result = try action(&new)
      self._synchronized_state = .initialized(new)
      return consume result
    }

    private var _synchronized_state: State = .notInitialized

    private var unsafeValue: T {
      get {
        switch _synchronized_state {
        case .notInitialized:
          let value = initializer()
          _onInitialized(value)
          self._synchronized_state = .initialized(value)
          self.initializer = nil
          return value
        case .initialized(let value):
          return value
        }
      }
    }

    private var initializer: Initializer!

    public init(_ initializer: @escaping Initializer) {
      self.initializer = initializer
    }

    public init(wrappedValue initializer: @autoclosure @escaping Initializer) {
      self.initializer = initializer
    }

    /// Set closure on value initialized.
    /// the closure would be called on thread which value initialized.
    @discardableResult
    public func onInitialized(_ perform: @escaping (T) -> Void) -> Self {
      _onInitialized = perform
      return self
    }
  }


}

@inline(__always)
func withUncheckedSendable<T>(_ body: () throws -> T) rethrows -> T {
  try body()
}
