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
  
  public final class UnfairLock {
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
  public final class RecursiveLockAtomic<Value> {
    
    public var unsafelyWrappedValue: Value {
      _read { yield _value }
    }
    
    private let lock: NSRecursiveLock
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
  public final class UnfairLockAtomic<Value> {
    
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
  
}
