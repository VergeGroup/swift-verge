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

#if !COCOAPODS
#endif

private let changesDeallocationQueue = BackgroundDeallocationQueue()

public protocol AnyChangesType: AnyObject {
  
  var traces: [MutationTrace] { get }
  var version: UInt64 { get }
}

public protocol ChangesType: AnyChangesType {
  associatedtype Value
  var previousPrimitive: Value? { get }
  var primitive: Value { get }

  var previous: Self? { get }

  func asChanges() -> Changes<Value>
}

/**
 An immutable data object to achieve followings:
 - To know a property has been modified. (It contains 2 instances (old, new))
 - To avoid copying cost with wrapping reference type - So, you can embed this object on the other state.

 ```
 struct MyState {
   var name: String
   var age: String
   var height: String
 }
 ```

 ```
 let changes: Changes<MyState>
 ```

 It can be accessed with properties of MyState by dynamicMemberLookup
 ```
 changes.name
 ```

 It would be helpful to update UI partially
 ```
 func updateUI(changes: Changes<MyState>) {

   changes.ifChanged(\.name) { name in
   // update UI
   }

   changes.ifChanged(\.age) { age in
   // update UI
   }

   changes.ifChanged(\.height) { height in
   // update UI
   }
 }
 ```

 - Attention: Equalities calculates with pointer-personality basically, if the Value type compatibles `Equatable`, it does using also Value's equalities.
 This means Changes will return equals if different pointer but the value is the same.
 */
@dynamicMemberLookup
public final class Changes<Value>: ChangesType, Equatable, HasTraces {
  public typealias ChangesKeyPath<T> = KeyPath<Changes, T>

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

  /// Returns a value as primitive
  /// We can't access `.computed` from this.
  ///
  /// - Important: a returns value won't change against pointer-personality
  public var root: Value { _read { yield innerBox.value } }

  public let traces: [MutationTrace]
  public let modification: InoutRef<Value>.Modification?

  // MARK: - Initializers

  public convenience init(
    old: Value?,
    new: Value
  ) {
    self.init(
      previous: old.map { .init(old: nil, new: $0) },
      innerBox: .init(value: new),
      version: 0,
      traces: [],
      modification: nil
    )
  }

  private init(
    previous: Changes<Value>?,
    innerBox: InnerBox,
    version: UInt64,
    traces: [MutationTrace],
    modification: InoutRef<Value>.Modification?
  ) {
    self.previous = previous
    self.innerBox = innerBox
    self.version = version
    self.traces = traces
    self.modification = modification

    vergeSignpostEvent("Changes.init", label: "\(type(of: self))")
  }

  deinit {
    vergeSignpostEvent("Changes.deinit", label: "\(type(of: self))")

    changesDeallocationQueue.releaseObjectInBackground(object: innerBox)
  }

  @inline(__always)
  private func cloneWithDropsPrevious() -> Changes<Value> {
    return .init(
      previous: nil,
      innerBox: innerBox,
      version: version,
      traces: traces,
      modification: nil
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
  public func map<U>(_ transform: (Value) throws -> U) rethrows -> Changes<U> {
    let signpost = VergeSignpostTransaction("Changes.map")
    defer {
      signpost.end()
    }

    return Changes<U>(
      previous: try previous.map { try $0.map(transform) },
      innerBox: try innerBox.map(transform),
      version: version,
      traces: traces,
      modification: nil
    )
  }
  
  public func _beta_map<U>(_ keyPath: KeyPath<Value, U?>) -> Changes<U>? {
    
    guard self[dynamicMember: keyPath] != nil else {
      return nil
    }
           
    return Changes<U>(
      previous: previous.flatMap { $0._beta_map(keyPath) },
      innerBox: innerBox.map { $0[keyPath: keyPath]! },
      version: version,
      traces: traces,
      modification: nil
    )
    
  }

  public func makeNextChanges(
    with nextNewValue: Value,
    from traces: [MutationTrace],
    modification: InoutRef<Value>.Modification
  ) -> Changes<Value> {
    let previous = cloneWithDropsPrevious()
    let nextVersion = previous.version &+ 1
    return Changes<Value>.init(
      previous: previous,
      innerBox: .init(value: nextNewValue),
      version: nextVersion,
      traces: traces,
      modification: modification
    )
  }
  
  public func _read(perform: (ReadRef<Value>) -> Void) {
    innerBox._read(perform: perform)
  }
  
}

// MARK: - Primitive methods

extension Changes {
  
  /// Takes a composed value if it's changed from old value.
  @inline(__always)
  public func takeIfChanged<Composed>(
    _ compose: (Changes) throws -> Composed,
    _ comparer: Comparer<Composed>
  ) rethrows -> Composed? {
    let signpost = VergeSignpostTransaction("Changes.takeIfChanged(compose:comparer:)")
    defer {
      signpost.end()
    }

    let current = self

    guard let previousValue = previous else {
      return try compose(current)
    }

    let old = previousValue
    let compare = comparer.curried()

    let composedFromCurrent = try compose(current)
    guard !compare(try compose(old), composedFromCurrent) else {
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
    _ compose: (Changes) -> Composed,
    _ comparer: Comparer<Composed>,
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
    _ compose: (Changes) throws -> Composed
  ) rethrows -> Composed? {
    try takeIfChanged(compose, .usingEquatable)
  }

  /**
   Performs a closure if the selected value changed from the previous one.
   */
  public func ifChanged<T, Result>(
    _ selector: ChangesKeyPath<T>,
    _ comparer: Comparer<T>,
    _ perform: (T) throws -> Result
  ) rethrows -> Result? {
    guard let value = takeIfChanged({ $0[keyPath: selector] }, comparer) else {
      return nil
    }
    return try perform(value)
  }

  /**
   Performs a closure if the selected value changed from the previous one.
   */
  public func ifChanged<Composed: Equatable, Result>(
    _ compose: (Changes) -> Composed,
    _ perform: (Composed) throws -> Result
  ) rethrows -> Result? {
    try ifChanged(compose, .usingEquatable, perform)
  }

  /**
   Performs a closure if the selected value changed from the previous one.
   */
  @inline(__always)
  public func ifChanged<T: Equatable, Result>(
    _ keyPath: ChangesKeyPath<T>,
    _ perform: (T) throws -> Result
  ) rethrows -> Result? {
    try ifChanged(keyPath, .usingEquatable, perform)
  }

  /**
   Performs a closure if the selected value changed from the previous one.
   Selected multiple value would be packed as tuple.
   */
  @inline(__always)
  public func ifChanged<T0: Equatable, T1: Equatable, Result>(
    _ keyPath0: ChangesKeyPath<T0>,
    _ keyPath1: ChangesKeyPath<T1>,
    _ perform: ((T0, T1)) throws -> Result
  ) rethrows -> Result? {
    try ifChanged({ ($0[keyPath: keyPath0], $0[keyPath: keyPath1]) }, .init(==), perform)
  }

  /**
   Performs a closure if the selected value changed from the previous one.
   Selected multiple value would be packed as tuple.
   */
  @inline(__always)
  public func ifChanged<T0: Equatable, T1: Equatable, T2: Equatable, Result>(
    _ keyPath0: ChangesKeyPath<T0>,
    _ keyPath1: ChangesKeyPath<T1>,
    _ keyPath2: ChangesKeyPath<T2>,
    _ perform: ((T0, T1, T2)) throws -> Result
  ) rethrows -> Result? {
    try ifChanged(
      { ($0[keyPath: keyPath0], $0[keyPath: keyPath1], $0[keyPath: keyPath2]) },
      .init(==),
      perform
    )
  }

  /**
   Performs a closure if the selected value changed from the previous one.
   Selected multiple value would be packed as tuple.
   */
  @inline(__always)
  public func ifChanged<T0: Equatable, T1: Equatable, T2: Equatable, T3: Equatable, Result>(
    _ keyPath0: ChangesKeyPath<T0>,
    _ keyPath1: ChangesKeyPath<T1>,
    _ keyPath2: ChangesKeyPath<T2>,
    _ keyPath3: ChangesKeyPath<T3>,
    _ perform: ((T0, T1, T2, T3)) throws -> Result
  ) rethrows -> Result? {
    try ifChanged(
      {
        (
          $0[keyPath: keyPath0],
          $0[keyPath: keyPath1],
          $0[keyPath: keyPath2],
          $0[keyPath: keyPath3]
        ) },
      .init(==),
      perform
    )
  }

  /**
   Performs a closure if the selected value changed from the previous one.
   Selected multiple value would be packed as tuple.
   */
  @inline(__always)
  public func ifChanged<
    T0: Equatable,
    T1: Equatable,
    T2: Equatable,
    T3: Equatable,
    T4: Equatable,
    Result
  >(
    _ keyPath0: ChangesKeyPath<T0>,
    _ keyPath1: ChangesKeyPath<T1>,
    _ keyPath2: ChangesKeyPath<T2>,
    _ keyPath3: ChangesKeyPath<T3>,
    _ keyPath4: ChangesKeyPath<T4>,
    _ perform: ((T0, T1, T2, T3, T4)) throws -> Result
  ) rethrows -> Result? {
    try ifChanged(
      { (
        $0[keyPath: keyPath0],
        $0[keyPath: keyPath1],
        $0[keyPath: keyPath2],
        $0[keyPath: keyPath3],
        $0[keyPath: keyPath4]
      ) },
      .init(==),
      perform
    )
  }
}

// MARK: - Has changes

extension Changes {
  /// Returns boolean that indicates value specified by keyPath contains changes with compared old and new.
  @inline(__always)
  public func hasChanges<T: Equatable>(_ keyPath: ChangesKeyPath<T>) -> Bool {
    hasChanges(keyPath, .usingEquatable)
  }

  /// Returns boolean that indicates value specified by keyPath contains changes with compared old and new.
  @inline(__always)
  public func hasChanges<T>(
    _ keyPath: ChangesKeyPath<T>,
    _ comparer: Comparer<T>
  ) -> Bool {
    hasChanges({ $0[keyPath: keyPath] }, comparer)
  }

  @inline(__always)
  public func hasChanges<Composed: Equatable>(
    _ compose: (Changes) -> Composed
  ) -> Bool {
    hasChanges(compose, .usingEquatable)
  }

  @inline(__always)
  public func hasChanges<Composed>(
    _ compose: (Changes) -> Composed,
    _ comparer: Comparer<Composed>
  ) -> Bool {
    takeIfChanged(compose, comparer) != nil
  }

}

// MARK: - NoChanges

extension Changes {
  /// Returns boolean that indicates value specified by keyPath contains **NO** changes with compared old and new.
  @inline(__always)
  public func noChanges<T: Equatable>(_ keyPath: ChangesKeyPath<T>) -> Bool {
    !hasChanges(keyPath, .usingEquatable)
  }

  /// Returns boolean that indicates value specified by keyPath contains **NO** changes with compared old and new.
  @inline(__always)
  public func noChanges<T>(_ keyPath: ChangesKeyPath<T>, _ comparer: Comparer<T>) -> Bool {
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
  private final class InnerBox {
    
    var value: Value

    let cachedComputedValueStorage: VergeConcurrency.RecursiveLockAtomic<[AnyKeyPath: Any]>

    init(value: Value) {
      self.value = value
      cachedComputedValueStorage = .init([:])
    }

    private init(
      value: Value,
      cachedComputedValueStorage: VergeConcurrency.RecursiveLockAtomic<[AnyKeyPath: Any]>
    ) {
      self.value = value
      self.cachedComputedValueStorage = cachedComputedValueStorage
    }

    deinit {}

    func map<U>(_ transform: (Value) throws -> U) rethrows -> Changes<U>.InnerBox {
      return .init(
        value: try transform(value),
        cachedComputedValueStorage: cachedComputedValueStorage
      )
    }
     
    @inline(__always)
    func _read(perform: (ReadRef<Value>) -> Void) {
      withUnsafePointer(to: &value) { (pointer) -> Void in
        let ref = ReadRef<Value>.init(pointer)
        perform(ref)
      }
    }
    
  }
}

extension Changes where Value: ExtendedStateType {
  @dynamicMemberLookup
  public struct ComputedProxy {
    let source: Changes<Value>

    public subscript<Output>(dynamicMember keyPath: KeyPath<
      Value.Extended,
      Value.Field.Computed<Output>
    >) -> Output {
      take(with: keyPath)
    }

    @inline(__always)
    private func take<Output>(with keyPath: KeyPath<Value.Extended, Value.Field.Computed<Output>>)
    -> Output {
      return source._synchronized_takeFromCacheOrCreate(keyPath: keyPath)
    }
  }

  public var computed: ComputedProxy {
    .init(source: self)
  }

  @inline(__always)
  private func _synchronized_takeFromCacheOrCreate<Output>(
    keyPath: KeyPath<Value.Extended, Value.Field.Computed<Output>>
  ) -> Output {
    let components = Value.Extended.instance[keyPath: keyPath]

    components._onRead()

    // TODO: tune-up concurrency performance

    /**
     Start locking inner-box's caching container to calculate a computed value and stores as a cache.
     */
    return innerBox.cachedComputedValueStorage.modify { cache -> Output in

      if let computed = cache[keyPath] as? Output {
        /**
         Which means, previously accessed this property, then we can return the cached value.
         */
        components._onHitCache()
        return computed
      }

      /**
       We couldn't find a cached value, then continue to next step.
       */

      if let previous = previous {
        /**
         Itself has the previous instance, we start locking in that instance.
         */

        return previous.innerBox.cachedComputedValueStorage.modify { previousCache -> Output in

          /**
           - Warnings: DO NOT MODIFY PreviousCache.
           */

          if let previousCachedValue = previousCache[keyPath] as? Output {
            /**
             We found a cached value from the previous instance.
             Now we check if that value is reusable.
             */

            components._onHitPreviousCache()

            switch components.pipeline.makeResult(self) {
            case .noUpdates:

              // No changes
              components._onHitPreFilter()
              cache[keyPath] = previousCachedValue
              return previousCachedValue

            case let .new(newValue):

              // Update
              components._onTransform()
              cache[keyPath] = newValue
              return newValue
            }
          } else {
            /**
             We don't have a cached value even from the previous instance.
             We need to create a new value from scratch.
             */

            components._onTransform()

            let initialValue = components.pipeline.makeInitial(self)
            cache[keyPath] = initialValue
            return initialValue
          }
        }

      } else {
        /**
         We don't have previous instance.
         We need to create a new value from scratch.
         */

        components._onTransform()

        let initialValue = components.pipeline.makeInitial(self)
        cache[keyPath] = initialValue
        return initialValue
      }
    }
  }
}

extension Changes where Value: Equatable {
  public var hasChanges: Bool {
    previousPrimitive != primitive
  }

  public func ifChanged(_ perform: (Value) throws -> Void) rethrows {
    try ifChanged(\.root, perform)
  }
}

extension Changes: Sequence where Value: Sequence {
  public __consuming func makeIterator() -> Value.Iterator {
    root.makeIterator()
  }

  public typealias Element = Value.Element
  public typealias Iterator = Value.Iterator
}

extension Changes: Collection where Value: Collection {
  public subscript(position: Value.Index) -> Value.Element {
    _read {
      yield root[position]
    }
  }

  public var startIndex: Value.Index {
    root.startIndex
  }

  public var endIndex: Value.Index {
    root.endIndex
  }

  public func index(after i: Value.Index) -> Value.Index {
    root.index(after: i)
  }

  public typealias Index = Value.Index
}

extension Changes: BidirectionalCollection where Value: BidirectionalCollection {
  public func index(before i: Value.Index) -> Value.Index {
    root.index(before: i)
  }
}

extension Changes: RandomAccessCollection where Value: RandomAccessCollection {
  public func index(before i: Value.Index) -> Value.Index {
    root.index(before: i)
  }
}

extension _StateTypeContainer {
  /**
   A declaration to add a computed-property into the state.
   It helps to add a property that does not need to be stored-property.
   It's like Swift's computed property like following:

   ```swift
   struct State {
     var items: [Item] = [] {

     var itemsCount: Int {
       items.count
     }
   }
   ```
   However, this Swift's computed-property will compute the value every state changed. It might become a serious issue on performance.

   Compared with Swift's computed property and this,  this does not compute the value every state changes, It does compute depend on specified rules.
   That rules mainly come from the concept of Memoization.

   Example code:

   ```swift
   struct State: ExtendedStateType {

     var name: String = ...
     var items: [Int] = []

     struct Extended: ExtendedType {

       static let instance = Extended()

       let filteredArray = Field.Computed<[Int]> {
         $0.items.filter { $0 > 300 }
       }
       .dropsInput {
         $0.noChanges(\.items)
       }
     }
   }
   ```

   ```swift
   let store: MyStore<State, Never> = ...

   let state = store.state

   let result: [Int] = state.computed.filteredArray
   ```
   */
  public struct Computed<Output> {
    public typealias Input = Changes<State>

    @usableFromInline
    fileprivate(set) var _onRead: () -> Void = {}

    @usableFromInline
    fileprivate(set) var _onHitCache: () -> Void = {}

    @usableFromInline
    fileprivate(set) var _onHitPreviousCache: () -> Void = {}

    @usableFromInline
    fileprivate(set) var _onHitPreFilter: () -> Void = {}

    @usableFromInline
    fileprivate(set) var _onTransform: () -> Void = {}

    @usableFromInline
    let pipeline: Pipeline<Input, Output>

    @usableFromInline
    init(_ pipeline: Pipeline<Input, Output>) {
      self.pipeline = pipeline
    }

    public init(
      makeInitial: @escaping (Input) -> Output,
      update: @escaping (Input) -> Pipeline<Input, Output>.ContinuousResult
    ) {
      self.init(Pipeline<Input, Output>.init(makeInitial: makeInitial, update: update))
    }

    public init(_ compute: @escaping (Input) -> Output) {
      self.init(.map(compute))
    }

    /// Initialize Computed property that computes value from derived value
    /// Drops duplicated derived value with Equatable of Derived type.
    ///
    /// - Complexity: ✅ Drops duplicated derived values.
    /// - Parameters:
    ///   - derive: A closure to create value from the state to put into the compute closure.
    ///   - compute: A closure to compose a computed value from the derived value.
    public init<Derived: Equatable>(
      derive: @escaping (Input) -> Derived,
      compute: @escaping (Derived) -> Output
    ) {
      self.init(derive: derive, dropsDerived: ==, compute: compute)
    }

    /// Initialize Computed property that computes value from derived value
    ///
    /// - Complexity:
    ///   - ✅ Drops duplicated derived values
    ///   - 💡 depends on dropsDerived closure
    /// - Parameters:
    ///   - derive: A closure to create value from the state to put into the compute closure.
    ///   - dropsDerived:
    ///     A predicate to drop a duplicated value, closure gets an old value and a new value.
    ///     If return true, drops the value.
    ///   - compute: A closure to compose a computed value from the derived value.
    public init<Derived>(
      derive: @escaping (Input) -> Derived,
      dropsDerived: @escaping (Derived, Derived) -> Bool,
      compute: @escaping (Derived) -> Output
    ) {
      self.init(.map(derive: derive, dropsDerived: dropsDerived, compute: compute))
    }

    /**
     Adds a rule to drop input value from the root state changed.
     */
    @inlinable
    @inline(__always)
    public func dropsInput(while predicate: @escaping (Input) -> Bool) -> Self {
      modified {
        $0.dropsInput(while: predicate)
      }
    }

    @inlinable
    @inline(__always)
    public func modified(_ modifier: (Pipeline<Input, Output>) -> Pipeline<Input, Output>)
    -> Self {
      .init(modifier(pipeline))
    }

    /**
     Registers callback-closure that will call when accessed the computed property
     */
    @inlinable
    @inline(__always)
    public func onRead(_ clsoure: @escaping () -> Void) -> Self {
      var _self = self
      _self._onRead = clsoure
      return _self
    }

    /**
     Registers callback-closure that will call when compute the value
     */
    @inlinable
    @inline(__always)
    public func onTransform(_ closure: @escaping () -> Void) -> Self {
      var _self = self
      _self._onTransform = closure
      return _self
    }

    /**
     Registers callback-closure that will call when hit the pre-filter
     */
    @inlinable
    @inline(__always)
    public func onHitPreFilter(_ closure: @escaping () -> Void) -> Self {
      var _self = self
      _self._onHitPreFilter = closure
      return _self
    }

    /**
     Registers callback-closure that will call when hit the cached value
     */
    @inlinable
    @inline(__always)
    public func onHitCache(_ closure: @escaping () -> Void) -> Self {
      var _self = self
      _self._onHitCache = closure
      return _self
    }

    /**
     Registers callback-closure that will call when hit the cached value
     */
    @inlinable
    @inline(__always)
    public func onHitPreviousCache(_ closure: @escaping () -> Void) -> Self {
      var _self = self
      _self._onHitPreviousCache = closure
      return _self
    }
  }
}
