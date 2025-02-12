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
@_spi(Internal) import TypedComparator
import StateStruct

private let _shared_changesDeallocationQueue = BackgroundDeallocationQueue()

public protocol AnyChangesType: AnyObject, Sendable {

  var traces: [MutationTrace] { get }
  var version: UInt64 { get }
}

public protocol ChangesType<Value>: AnyChangesType {
  
  associatedtype Value: Equatable
  
  var previousPrimitive: Value? { get }
  var primitive: Value { get }

  var previous: Self? { get }
  
  var modification: PropertyNode? { get }

  func asChanges() -> Changes<Value>
}

/// An immutable data object to achieve followings:
/// - To know a property has been modified. (It contains 2 instances (old, new))
/// - To avoid copying cost with wrapping reference type - So, you can embed this object on the other state.
///
/// ```swift
/// struct MyState: Equatable {
///   var name: String
///   var age: String
///   var height: String
/// }
/// ```
///
/// ```swift
/// let changes: Changes<MyState>
/// ```
///
/// It can be accessed with properties of MyState by dynamicMemberLookup
/// ```swift
/// changes.name
/// ```
///
/// It would be helpful to update UI partially
/// ```swift
/// func updateUI(changes: Changes<MyState>) {
///
///   changes.ifChanged(\.name) { name in
///   // update UI
///   }
///
///   changes.ifChanged(\.age) { age in
///   // update UI
///   }
///
///   changes.ifChanged(\.height) { height in
///   // update UI
///   }
/// }
/// ```
///
/// - Attention: Equalities calculates with pointer-personality basically, if the Value type compatibles `Equatable`, it does using also Value's equalities.
/// This means Changes will return equals if different pointer but the value is the same.
@dynamicMemberLookup
public final class Changes<Value: Equatable>: @unchecked Sendable, ChangesType, Equatable, HasTraces {
  public typealias ChangesKeyPath<T> = KeyPath<Value, T>

  public static func == (lhs: Changes<Value>, rhs: Changes<Value>) -> Bool {
    lhs === rhs
  }

  // MARK: - Stored Properties

  public let previous: Changes<Value>?
  private let innerBox: InnerBox
  public private(set) var version: UInt64

  // MARK: - Computed Properties

  @available(*, deprecated, renamed: "previousPrimitive")
  public var old: Value? { previousPrimitive }

  @available(*, deprecated, renamed: "primitive")
  public var current: Value { primitive }

  /// Returns a previous value as primitive
  /// We can't access `.computed` from this.
  ///
  /// - Important: a returns value won't change against pointer-personality
  public var previousPrimitive: Value? { _read { yield previous?.primitive } }

  /// Returns a value as primitive
  /// We can't access `.computed` from this.
  ///
  /// - Important: a returns value won't change against pointer-personality
  public var primitive: Value { _read { yield innerBox.value } }

  var primitiveBox: ReadonlyBox<Value> { innerBox }

  /// Returns a value as primitive
  /// We can't access `.computed` from this.
  ///
  /// - Important: a returns value won't change against pointer-personality
  public var root: Value { _read { yield innerBox.value } }

  public let traces: [MutationTrace]
  
  public let modification: PropertyNode?
  
  public var writeGraph: PropertyNode? {
    modification
  }
  
  public let _transaction: Transaction

  // MARK: - Initializers

  public convenience init(
    old: consuming Value?,
    new: consuming Value
  ) {
    self.init(
      previous: old.map { .init(old: nil, new: $0) },
      innerBox: .init(value: consume new),
      version: 0,
      traces: [],
      modification: nil,
      transaction: .init()
    )
  }

  private init(
    previous: Changes<Value>?,
    innerBox: InnerBox,
    version: UInt64,
    traces: [MutationTrace],
    modification: consuming PropertyNode?,
    transaction: Transaction
  ) {
    self.previous = previous
    self.innerBox = innerBox
    self.version = version
    self.traces = traces
    self.modification = modification
    self._transaction = transaction

    vergeSignpostEvent("Changes.init", label: "\(type(of: self))")
  }

  deinit {
    vergeSignpostEvent("Changes.deinit", label: "\(type(of: self))")
    
    let unsafeBox = UnsafeSendableStruct(innerBox)
    
    Task {
      await _shared_changesDeallocationQueue.releaseObjectInBackground(object: unsafeBox.value)
    }
  }

  @inline(__always)
  private func cloneWithDropsPrevious() -> Changes<Value> {
    return .init(
      previous: nil,
      innerBox: innerBox,
      version: version,
      traces: traces,
      modification: nil,
      transaction: _transaction
    )
  }

  func replacePrevious(_ previous: Changes<Value>) -> Changes<Value> {
    return .init(
      previous: previous,
      innerBox: innerBox,
      version: version,
      traces: traces,
      modification: nil,
      transaction: _transaction
    )
  }

  @inlinable
  public func asChanges() -> Changes<Value> {
    self
  }

  /// Returns a Changes object that dropped previous value.
  /// It returns always true in `ifChanged`
  public func droppedPrevious() -> Changes<Value> {
    cloneWithDropsPrevious()
  }

  @inlinable
  public subscript<T>(dynamicMember keyPath: KeyPath<Value, T>) -> T {
    _read {
      yield primitive[keyPath: keyPath]
    }
  }

  /// Returns a new instance that projects value by transform closure.
  ///
  /// - Warning: modification would be dropped.
  public func map<U>(_ transform: (borrowing Value) throws -> U) rethrows -> Changes<U> {
    let signpost = VergeSignpostTransaction("Changes.map")
    defer {
      signpost.end()
    }

    return Changes<U>(
      previous: try previous.map { try $0.map(transform) },
      innerBox: try innerBox.map(transform),
      version: version,
      traces: traces,
      modification: nil,
      transaction: _transaction
    )
  }

  /**
   Returns an ``Changes`` containing the value of mapping the given key path over the root value if value present.
   */
  public func mapIfPresent<U>(_ keyPath: KeyPath<Value, U?>) -> Changes<U>? {

    guard self[dynamicMember: keyPath] != nil else {
      return nil
    }

    return Changes<U>(
      previous: previous.flatMap { $0.mapIfPresent(keyPath) },
      innerBox: innerBox.map { $0[keyPath: keyPath]! },
      version: version,
      traces: traces,
      modification: nil,
      transaction: _transaction
    )

  }

  /**
   Returns an ``Changes`` containing the value of mapping the given key path over the root value if value present.
   */
  @available(*, deprecated, renamed: "mapIfPresent")
  public func _beta_map<U>(_ keyPath: KeyPath<Value, U?>) -> Changes<U>? {
    mapIfPresent(keyPath)
  }

  public func makeNextChanges(
    with nextNewValue: Value,
    modification: PropertyNode?,
    transaction: Transaction
  ) -> Changes<Value> {
    let previous = cloneWithDropsPrevious()
    let nextVersion = previous.version &+ 1
    return Changes<Value>.init(
      previous: previous,
      innerBox: .init(value: nextNewValue),
      version: nextVersion,
      traces: traces,
      modification: modification,
      transaction: transaction
    )
  }

  @discardableResult
  public func _read<Return>(perform: (borrowing Value) -> Return) -> Return {
    innerBox._read(perform: perform)
  }

}

// MARK: - Primitive methods

extension Changes {
  
  /// Takes a composed value if it's changed from old value.
  @inline(__always)
  public func takeIfChanged<Composed>(
    _ compose: (Value) throws -> Composed,
    _ comparer: some TypedComparator<Composed>
  ) rethrows -> Composed? {
    try _takeIfChanged(compose, comparer)
  }

  @inline(__always)
  fileprivate func _takeIfChanged<each Element>(
    _ compose: (Value) throws -> (repeat each Element),
    _ comparer: consuming some TypedComparator<(repeat each Element)>
  ) rethrows -> (repeat each Element)? {

    let current = self.primitive

    guard let previousValue = previous else {
      return try compose(consume current)
    }

    let old = previousValue.primitive

    let composedFromCurrent = try compose(consume current)
    guard !comparer(try compose(consume old), composedFromCurrent) else {
      return nil
    }

    return composedFromCurrent

  }

  @inline(__always)
  fileprivate func _takeIfChanged_packed<each Element: Equatable>(
    _ compose: (Value) throws -> (repeat each Element)
  ) rethrows -> (repeat each Element)? {

    let current = self.primitive

    guard let previousValue = previous else {
      return try compose(consume current)
    }

    let old = previousValue.primitive

    let composedFromCurrent = try compose(consume current)
    let composedFromOld = try compose(old)

    guard !areEqual(
      (repeat each composedFromOld),
      (repeat each composedFromCurrent)
    ) else {
      return nil
    }

    return composedFromCurrent

  }

  @inline(__always)
  fileprivate func _takeIfChanged_packed_nonEquatable<each Element>(
    _ compose: (Value) throws -> (repeat each Element),
    comparator: some TypedComparator<(repeat each Element)>
  ) rethrows -> (repeat each Element)? {

    let current = self.primitive

    guard let previousValue = previous else {
      return try compose(consume current)
    }

    let old = previousValue.primitive

    let composedFromCurrent = try compose(consume current)
    let composedFromOld = try compose(old)

    let isEqual = comparator(composedFromOld, composedFromCurrent)

    guard isEqual == false else {
      return nil
    }

    return composedFromCurrent

  }

  /// Performs a closure if the selected value changed from the previous one.
  ///
  /// - Parameters:
  ///   - compose: A closure that projects a composed value from self. that executes with both of value(new and old).
  ///   - comparer: A Comparer that checks if the composed values are different between current and old.
  ///   - perform: A closure that executes any operation if composed value changed.
  ///
  /// - Returns: An instance that returned from the perform closure if performed.
  @inline(__always)
  public func ifChanged<Composed, Result>(
    _ compose: (Value) -> Composed,
    _ comparer: some TypedComparator<Composed>,
    _ perform: (Composed) throws -> Result
  ) rethrows -> Result? {
    guard let result = takeIfChanged(compose, comparer) else {
      return nil
    }

    return try perform(result)
  }
}

// MARK: - Convenience methods

extension Changes {
  /// Takes a composed value if it's changed from old value.
  @inline(__always)
  public func takeIfChanged<Composed: Equatable>(
    _ compose: (Value) throws -> Composed
  ) rethrows -> Composed? {
    try takeIfChanged(compose, .equality())
  }

  public func ifChanged<Composed: Equatable>(
    _ compose: (Value) -> Composed
  ) -> IfChangedBox<Value, Composed> {
    guard let result = takeIfChanged(compose) else {
      return .init()
    }

    return .init(value: consume result, source: innerBox)
  }

  /**
   Packed

   ```
   state.ifChanged({ $0.name }).do { value in
     ...
   }
   ```
   */
  public borrowing func ifChanged<each Element: Equatable>(
    _ compose: (borrowing Value) -> (repeat each Element)
  ) -> IfChangedBox<Value, (repeat each Element)> {
    guard let result = _takeIfChanged_packed(compose) else {
      return .init()
    }

    return .init(value: (repeat each result), source: innerBox)
  }

  public borrowing func ifChanged<each Element>(
    _ compose: (borrowing Value) -> (repeat each Element),
    comparator: some TypedComparator<(repeat each Element)>
  ) -> IfChangedBox<Value, (repeat each Element)> {
    guard let result = _takeIfChanged_packed_nonEquatable(compose, comparator: comparator) else {
      return .init()
    }

    return .init(value: (repeat each result), source: innerBox)
  }

  /**
   singular variant
   */
  public func ifChanged<T: Equatable>(
    _ keyPath: KeyPath<Value, T>
  ) -> IfChangedBox<Value, T> {
    ifChanged({ $0[keyPath: keyPath] })
  }

  /**
   multiple variant
   */
  public func ifChanged<each T: Equatable>(
    _ keyPaths: repeat KeyPath<Value, each T>
  ) -> IfChangedBox<Value, (repeat each T)> {
    ifChanged({ (repeat $0[keyPath: each keyPaths]) })
  }
 
}

// MARK: - Has changes

extension Changes {
  /// Returns boolean that indicates value specified by keyPath contains changes with compared old and new.
  @inline(__always)
  public func hasChanges<T: Equatable>(_ keyPath: ChangesKeyPath<T>) -> Bool {
    hasChanges(keyPath, EqualityComparator())
  }

  /// Returns boolean that indicates value specified by keyPath contains changes with compared old and new.
  @inline(__always)
  public func hasChanges<T>(
    _ keyPath: ChangesKeyPath<T>,
    _ comparer: some TypedComparator<T>
  ) -> Bool {
    hasChanges({ $0[keyPath: keyPath] }, comparer)
  }

  @inline(__always)
  public func hasChanges<Composed: Equatable>(
    _ compose: (Value) -> Composed
  ) -> Bool {
    hasChanges(compose, EqualityComparator())
  }

  @inline(__always)
  public func hasChanges<Composed>(
    _ compose: (Value) -> Composed,
    _ comparer: some TypedComparator<Composed>
  ) -> Bool {
    takeIfChanged(compose, comparer) != nil
  }

}

// MARK: - NoChanges

extension Changes {
  /// Returns boolean that indicates value specified by keyPath contains **NO** changes with compared old and new.
  @inline(__always)
  public func noChanges<T: Equatable>(_ keyPath: ChangesKeyPath<T>) -> Bool {
    !hasChanges(keyPath, EqualityComparator())
  }

  /// Returns boolean that indicates value specified by keyPath contains **NO** changes with compared old and new.
  @inline(__always)
  public func noChanges<T>(_ keyPath: ChangesKeyPath<T>, _ comparer: some TypedComparator<T>) -> Bool {
    !hasChanges(keyPath, comparer)
  }
}

extension Changes: CustomReflectable {
  public var customMirror: Mirror {
    Mirror(
      self,
      children: [
        "version": version,
        "previous": previous as Any,
        "primitive": primitive,
        "transaction": _transaction,
        "traces": traces,
        "modification": modification as Any,
      ],
      displayStyle: .struct,
      ancestorRepresentation: .generated
    )
  }
}

// MARK: - Nested Types

extension Changes {

  private typealias InnerBox = ReadonlyBox<Value>

}

extension Changes where Value: Equatable {
  public var hasChanges: Bool {
    previousPrimitive != primitive
  }

  public func ifChanged() -> IfChangedBox<Value, Value> {
    ifChanged({ $0 })
  }

}

public struct IfChangedBox<Source, T>: ~Copyable {

  public let value: T?
  
  @usableFromInline
  let source: ReadonlyBox<Source>?

  init(value: consuming T, source: ReadonlyBox<Source>) {
    self.value = consume value
    self.source = source
  }

  init() {
    self.value = nil  
    self.source = nil
  }

  @discardableResult
  @inlinable
  public consuming func `do`<Return>(_ perform: (consuming T) throws -> Return) rethrows -> Return? {
    if let value {
      return try perform(consume value)
    }
    return nil
  }
  
  @discardableResult
  @inlinable
  public consuming func doWithSource<Return>(_ perform: (consuming ReadonlyBox<Source>) throws -> Return) rethrows -> Return? {
    if let source {
      return try perform(source)
    }
    return nil
  }
}

