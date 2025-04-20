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
  
  public final class RecursiveLock: NSRecursiveLock, @unchecked Sendable {
    
  }
  
  public struct UnfairLock: ~Copyable, @unchecked Sendable {
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
  
  // From: https://github.com/apple/swift-async-algorithms/blob/4c3ea81f81f0a25d0470188459c6d4bf20cf2f97/Sources/AsyncAlgorithms/Locking.swift#L131 
  struct ManagedCriticalState<State>: @unchecked Sendable {
    
    private final class LockedBuffer: ManagedBuffer<State, Lock.Primitive> {
      deinit {
        withUnsafeMutablePointerToElements { Lock.deinitialize($0) }
      }
    }
    
    private let buffer: ManagedBuffer<State, Lock.Primitive>
    
    init(_ initial: State) {
      buffer = LockedBuffer.create(minimumCapacity: 1) { buffer in
        buffer.withUnsafeMutablePointerToElements { Lock.initialize($0) }
        return initial
      }
    }
    
    func withCriticalRegion<R>(_ critical: (inout State) throws -> R) rethrows -> R {
      try buffer.withUnsafeMutablePointers { header, lock in
        Lock.lock(lock)
        defer { Lock.unlock(lock) }
        return try critical(&header.pointee)
      }
    }
  }
  
  internal struct Lock {
#if canImport(Darwin)
    typealias Primitive = os_unfair_lock
#elseif canImport(Glibc) || canImport(Musl) || canImport(Bionic)
    typealias Primitive = pthread_mutex_t
#elseif canImport(WinSDK)
    typealias Primitive = SRWLOCK
#else
#error("Unsupported platform")
#endif
    
    typealias PlatformLock = UnsafeMutablePointer<Primitive>
    let platformLock: PlatformLock
    
    private init(_ platformLock: PlatformLock) {
      self.platformLock = platformLock
    }
    
    fileprivate static func initialize(_ platformLock: PlatformLock) {
#if canImport(Darwin)
      platformLock.initialize(to: os_unfair_lock())
#elseif canImport(Glibc) || canImport(Musl) || canImport(Bionic)
      let result = pthread_mutex_init(platformLock, nil)
      precondition(result == 0, "pthread_mutex_init failed")
#elseif canImport(WinSDK)
      InitializeSRWLock(platformLock)
#else
#error("Unsupported platform")
#endif
    }
    
    fileprivate static func deinitialize(_ platformLock: PlatformLock) {
#if canImport(Glibc) || canImport(Musl) || canImport(Bionic)
      let result = pthread_mutex_destroy(platformLock)
      precondition(result == 0, "pthread_mutex_destroy failed")
#endif
      platformLock.deinitialize(count: 1)
    }
    
    fileprivate static func lock(_ platformLock: PlatformLock) {
#if canImport(Darwin)
      os_unfair_lock_lock(platformLock)
#elseif canImport(Glibc) || canImport(Musl) || canImport(Bionic)
      pthread_mutex_lock(platformLock)
#elseif canImport(WinSDK)
      AcquireSRWLockExclusive(platformLock)
#else
#error("Unsupported platform")
#endif
    }
    
    fileprivate static func unlock(_ platformLock: PlatformLock) {
#if canImport(Darwin)
      os_unfair_lock_unlock(platformLock)
#elseif canImport(Glibc) || canImport(Musl) || canImport(Bionic)
      let result = pthread_mutex_unlock(platformLock)
      precondition(result == 0, "pthread_mutex_unlock failed")
#elseif canImport(WinSDK)
      ReleaseSRWLockExclusive(platformLock)
#else
#error("Unsupported platform")
#endif
    }
    
    static func allocate() -> Lock {
      let platformLock = PlatformLock.allocate(capacity: 1)
      initialize(platformLock)
      return Lock(platformLock)
    }
    
    func deinitialize() {
      Lock.deinitialize(platformLock)
      platformLock.deallocate()
    }
    
    func lock() {
      Lock.lock(platformLock)
    }
    
    func unlock() {
      Lock.unlock(platformLock)
    }
    
    /// Acquire the lock for the duration of the given block.
    ///
    /// This convenience method should be preferred to `lock` and `unlock` in
    /// most situations, as it ensures that the lock will be released regardless
    /// of how `body` exits.
    ///
    /// - Parameter body: The block to execute while holding the lock.
    /// - Returns: The value returned by the block.
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
      self.lock()
      defer {
        self.unlock()
      }
      return try body()
    }
    
    // specialise Void return (for performance)
    func withLockVoid(_ body: () throws -> Void) rethrows -> Void {
      try self.withLock(body)
    }
  }

}

@inline(__always)
func withUncheckedSendable<T>(_ body: () throws -> T) rethrows -> T {
  try body()
}
