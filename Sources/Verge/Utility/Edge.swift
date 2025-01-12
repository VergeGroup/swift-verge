//
// Copyright (c) 2020 Hiroshi Kimura(Muukii) <muukii.app@gmail.com>
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
import Atomics

public protocol EdgeType : Equatable {
  associatedtype State
  var wrappedValue: State { get }
}

private let _edge_global_counter = ManagedAtomic<UInt64>.init(0)

/**
 A wrapper structure provides equatability as False-negative.
 Helpful in adding members which can’t conform to Equatable into a state due to the state of Store requiring Equatable.
 
 This structure holds two identifiers inside, a unique identifier (global-id) and a version number incrementally.
 the global id will be issued distinct each initialization.
 the version will increment each modification.
 
 If the wrapped type does not conform to Equatable, it compares using those identifiers. It will be `true` if they have not changed.
 But if `false`,  it might be false-negative because it can’t compare wrapped values.
 
 If the wrapped type conforms to Equatable, it compares using those identifiers and wrapped values. The result would be fully correct.
 Even in this case, using this structure works useful if comparing wrapped values takes much more expensive.
 
 Warnings: Do not assign a reference type object. It does not completely work.
 */
@propertyWrapper
@dynamicMemberLookup
public struct Edge<Value>: EdgeType {

  public static func == (lhs: Edge<Value>, rhs: Edge<Value>) -> Bool {
    lhs.globalID == rhs.globalID && lhs.version == rhs.version || lhs.comparerForNonEquatable(lhs.wrappedValue, rhs.wrappedValue)
  }
  
  public subscript <U>(dynamicMember keyPath: KeyPath<Value, U>) -> U {
    _read { yield wrappedValue[keyPath: keyPath] }
  }
  
  public subscript <U>(dynamicMember keyPath: KeyPath<Value, U?>) -> U? {
    _read { yield wrappedValue[keyPath: keyPath] }
  }
  
  public subscript <U>(dynamicMember keyPath: WritableKeyPath<Value, U>) -> U {
    _read { yield wrappedValue[keyPath: keyPath] }
    _modify { yield &wrappedValue[keyPath: keyPath] }
  }
  
  public subscript <U>(dynamicMember keyPath: WritableKeyPath<Value, U?>) -> U? {
    _read { yield wrappedValue[keyPath: keyPath] }
    _modify { yield &wrappedValue[keyPath: keyPath] }
  }

  /// A number value that indicates how many times State was updated.
  public var version: UInt64 {
    _read {
      yield counter.value
    }
  }

  public let globalID: UInt64
  
  private(set) public var counter: NonAtomicCounter = .init()
  private let middleware: Middleware?
  
  private let comparerForNonEquatable: @Sendable (Value, Value) -> Bool
     
  public func next(_ value: Value) -> Self {
    var copy = self
    copy.counter.increment()
    copy.wrappedValue = value
    return copy
  }

  @_disfavoredOverload
  public init(
    wrappedValue: Value,
    middleware: Middleware? = nil,
    comparer: @escaping @Sendable (Value, Value) -> Bool = { @Sendable _, _ in false }
  ) {
    
    self.globalID = _edge_global_counter.loadThenWrappingIncrement(ordering: .relaxed)
    self.middleware = middleware
    self.comparerForNonEquatable = comparer

    if let middleware = middleware {
      var mutable = wrappedValue
      middleware._onSet(&mutable)
      _wrappedValue = mutable
    } else {
      _wrappedValue = wrappedValue
    }

  }

  /// A value that wrapped with Edge.
  public var wrappedValue: Value {
    get {
      _wrappedValue
    }
    set {
      if let middleware = middleware {
        var mutable = newValue
        middleware._onSet(&mutable)
        _wrappedValue = mutable
      } else {
        _wrappedValue = newValue
      }
    }
  }

  private var _wrappedValue: Value {
    didSet {
      counter.increment()
    }
  }

  public var projectedValue: Edge<Value> {
    get {
      self
    }
    set {
      self = newValue
    }
  }

}

extension Edge : Sendable where Value : Sendable {
  
}

extension Edge {
  
  /**
   Tuple binding initializer - S1
   It compares equality using `==` operator.
   */
  public init(
    wrappedValue tuple: (Value),
    middleware: Middleware? = nil
  ) where Value : Equatable {
    self.init(wrappedValue: tuple, middleware: middleware, comparer: { @Sendable in $0 == $1 })
  }
  
  /**
   Tuple binding initializer - S1, S2
   It compares equality using `==` operator.
   */
  public init<S1: Equatable, S2: Equatable>(
    wrappedValue tuple: (S1, S2),
    middleware: Middleware? = nil
  ) where Value == (S1, S2) {
    self.init(wrappedValue: tuple, middleware: middleware, comparer: { @Sendable in $0 == $1 })
  }
  
  /**
   Tuple binding initializer - S1, S2, S3
   It compares equality using `==` operator.
   */
  public init<S1: Equatable, S2: Equatable, S3: Equatable>(
    wrappedValue tuple: (S1, S2, S3),
    middleware: Middleware? = nil
  ) where Value == (S1, S2, S3) {
    self.init(wrappedValue: tuple, middleware: middleware, comparer: { @Sendable in $0 == $1 })
  }
  
  /**
   Tuple binding initializer - S1, S2, S3, S4
   It compares equality using `==` operator.
   */
  public init<S1: Equatable, S2: Equatable, S3: Equatable, S4: Equatable>(
    wrappedValue tuple: (S1, S2, S3, S4),
    middleware: Middleware? = nil
  ) where Value == (S1, S2, S3, S4) {
    self.init(wrappedValue: tuple, middleware: middleware, comparer: { @Sendable in $0 == $1 })
  }
  
  /**
   Tuple binding initializer - S1, S2, S3, S4, S5
   It compares equality using `==` operator.
   */
  public init<S1: Equatable, S2: Equatable, S3: Equatable, S4: Equatable, S5: Equatable>(
    wrappedValue tuple: (S1, S2, S3, S4, S5),
    middleware: Middleware? = nil
  ) where Value == (S1, S2, S3, S4, S5) {
    self.init(wrappedValue: tuple, middleware: middleware, comparer: { @Sendable in $0 == $1 })
  }
  
  /**
   Tuple binding initializer - S1, S2, S3, S4, S5, S6
   It compares equality using `==` operator.
   */
  public init<S1: Equatable, S2: Equatable, S3: Equatable, S4: Equatable, S5: Equatable, S6: Equatable>(
    wrappedValue tuple: (S1, S2, S3, S4, S5, S6),
    middleware: Middleware? = nil
  ) where Value == (S1, S2, S3, S4, S5, S6) {
    self.init(wrappedValue: tuple, middleware: middleware, comparer: { @Sendable in $0 == $1 })
  }
   
}

extension Edge where Value : Equatable {
  public static func == (lhs: Edge<Value>, rhs: Edge<Value>) -> Bool {
    (lhs.globalID == rhs.globalID && lhs.version == rhs.version) || lhs.wrappedValue == rhs.wrappedValue
  }
}

extension Edge {

  public struct VersionComparison: TypedComparator {

    public func callAsFunction(_ lhs: Edge, _ rhs: Edge) -> Bool {
      lhs.globalID == rhs.globalID && lhs.version == rhs.version
    }
  }

}

extension TypedComparator {

  public static func versionEquals<T>() -> Self where Self == Edge<T>.VersionComparison {
    .init()
  }
}

extension Edge {

  /**
   A handler that can modify a new state.

   ```swift
   @Edge(middleware: .assert { $0 >= 0 }) var count: Int = 0
   ```
   */
  public struct Middleware: Sendable {

    let _onSet: @Sendable (inout Value) -> Void

    /// Initialize a instance that performs multiple middlewares from start index
    /// - Parameter onSet: It can access a new value and modify to validate something.
    public init(
      onSet: @escaping @Sendable (inout Value) -> Void
    ) {
      self._onSet = onSet
    }

    /// Initialize a instance that performs multiple middlewares from start index
    /// - Parameter middlewares:
    public init<C: Collection>(
      _ middlewares: C
    ) where C.Element == Middleware, C : Sendable {

      self._onSet = { state in
        middlewares.forEach {
          $0._onSet(&state)
        }
      }

    }

    /// Raises an Swift.assertionFailure when its new value does not fit the condition.
    /// - Parameter condition:
    /// - Returns: A Middleware instance
    public static func assert(_ condition: @escaping @Sendable (Value) -> Bool, _ failureReason: String? = nil) -> Self {
      #if DEBUG
      return .init(onSet: { state in
        let message = failureReason ?? "[Verge] \(Edge<Value>.self) raised a failure in the assertion. \(state)"
        Swift.assert(condition(state), message)
      })
      #else
      return empty()
      #endif
    }

    /// Returns a Middleware instance that does nothing.
    /// - Returns: A Middleware instance
    public static func empty() -> Self {
      return .init(onSet: { _ in })
    }

    /// Returns a Middleware that perform a closure
    /// It won't mutate the value
    ///
    /// - Returns: A Middleware instance
    public static func `do`(_ perform: @escaping @Sendable (Value) -> Void) -> Self {
      return .init(onSet: { perform($0) })
    }

  }

}
