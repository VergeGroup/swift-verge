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

@available(*, deprecated, renamed: "EdgeType")
public typealias FragmentType = EdgeType

@available(*, deprecated, renamed: "Edge")
public typealias Fragment = Edge

public protocol EdgeType : Equatable {
  associatedtype State
  var wrappedValue: State { get }
  var globalID: Int { get }
  var version: UInt64 { get }
}

private let _edge_global_counter = VergeConcurrency.AtomicInt(initialValue: 0)

/**
 A structure that manages sub-state-tree from root-state-tree.

 When you create derived data for this sub-tree, you may need to activate memoization.
 The reason why it needs memoization, the derived data does not need to know if other sub-state-tree updated.
 Better memoization must know owning state-tree has been updated at least.
 To get this done, it's not always we need to support Equatable.
 It's easier to detect the difference than detect equals.

 Edge is a wrapper structure and manages version number inside.
 It increments the version number each wrapped value updated.

 Memoization can use that version if it should pass new input.

 To activate this feature, you can check this method.
 `Pipeline.map(_ map: @escaping (Changes<Input.Value>) -> Edge<Output>) -> MemoizeMap<Input, Output>`
 */
@propertyWrapper
@dynamicMemberLookup
public struct Edge<Value: Sendable>: EdgeType, Sendable {

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

  public let globalID: Int
  
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

    self.globalID = _edge_global_counter.getAndIncrement()
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

extension Edge {
  
  /**
   Tuple binding initializer - S1
   It compares equality using `==` operator.
   */
  public init<S1: Equatable>(
    wrappedValue tuple: (S1),
    middleware: Middleware? = nil
  ) where Value == (S1) {
    self.init(wrappedValue: tuple, middleware: middleware, comparer: ==)
  }
  
  /**
   Tuple binding initializer - S1, S2
   It compares equality using `==` operator.
   */
  public init<S1: Equatable, S2: Equatable>(
    wrappedValue tuple: (S1, S2),
    middleware: Middleware? = nil
  ) where Value == (S1, S2) {
    self.init(wrappedValue: tuple, middleware: middleware, comparer: ==)
  }
  
  /**
   Tuple binding initializer - S1, S2, S3
   It compares equality using `==` operator.
   */
  public init<S1: Equatable, S2: Equatable, S3: Equatable>(
    wrappedValue tuple: (S1, S2, S3),
    middleware: Middleware? = nil
  ) where Value == (S1, S2, S3) {
    self.init(wrappedValue: tuple, middleware: middleware, comparer: ==)
  }
  
  /**
   Tuple binding initializer - S1, S2, S3, S4
   It compares equality using `==` operator.
   */
  public init<S1: Equatable, S2: Equatable, S3: Equatable, S4: Equatable>(
    wrappedValue tuple: (S1, S2, S3, S4),
    middleware: Middleware? = nil
  ) where Value == (S1, S2, S3, S4) {
    self.init(wrappedValue: tuple, middleware: middleware, comparer: ==)
  }
  
  /**
   Tuple binding initializer - S1, S2, S3, S4, S5
   It compares equality using `==` operator.
   */
  public init<S1: Equatable, S2: Equatable, S3: Equatable, S4: Equatable, S5: Equatable>(
    wrappedValue tuple: (S1, S2, S3, S4, S5),
    middleware: Middleware? = nil
  ) where Value == (S1, S2, S3, S4, S5) {
    self.init(wrappedValue: tuple, middleware: middleware, comparer: ==)
  }
  
  /**
   Tuple binding initializer - S1, S2, S3, S4, S5, S6
   It compares equality using `==` operator.
   */
  public init<S1: Equatable, S2: Equatable, S3: Equatable, S4: Equatable, S5: Equatable, S6: Equatable>(
    wrappedValue tuple: (S1, S2, S3, S4, S5, S6),
    middleware: Middleware? = nil
  ) where Value == (S1, S2, S3, S4, S5, S6) {
    self.init(wrappedValue: tuple, middleware: middleware, comparer: ==)
  }
   
}

extension Edge where Value : Equatable {
  public static func == (lhs: Edge<Value>, rhs: Edge<Value>) -> Bool {
    (lhs.globalID == rhs.globalID && lhs.version == rhs.version) || lhs.wrappedValue == rhs.wrappedValue
  }
}

extension Comparer where Input : EdgeType {

  public static func versionEquals() -> Comparer<Input> {
    Comparer<Input>.init { $0.globalID == $1.globalID && $0.version == $1.version }
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
    ) where C.Element == Middleware {

      self._onSet = { state in
        middlewares.forEach {
          $0._onSet(&state)
        }
      }

    }

    /// Raises an Swift.assertionFailure when its new value does not fit the condition.
    /// - Parameter condition:
    /// - Returns: A Middleware instance
    public static func assert(_ condition: @escaping (Value) -> Bool, _ failureReason: String? = nil) -> Self {
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
    public static func `do`(_ perform: @escaping (Value) -> Void) -> Self {
      return .init(onSet: { perform($0) })
    }

  }

}
