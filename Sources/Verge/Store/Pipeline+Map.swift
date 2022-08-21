
import Foundation

extension Pipeline where Input : ChangesType {
  
  /// Projects a value of Fragment structure from Input with memoized by the version of Fragment.
  ///
  /// - Complexity: ✅ Active Memoization with Fragment's version
  /// - Parameter map:
  /// - Returns:
  @available(*, renamed: "map(edge:)")
  public static func map<_Edge: EdgeType>(_ map: @escaping @Sendable (Input) -> _Edge) -> Pipeline<Input, _Edge.State> where Output == _Edge.State {
    .map(edge: map)
  }
  
  /// Projects a value of Fragment structure from Input with memoized by the version of Fragment.
  ///
  /// - Complexity: ✅ Active Memoization with Fragment's version
  /// - Parameter map:
  /// - Returns:
  public static func map<_Edge: EdgeType>(edge map: @escaping @Sendable (Input) -> _Edge) -> Pipeline<Input, _Edge.State> where Output == _Edge.State {
    
    return .init(
      makeInitial: {
        
        map($0).wrappedValue
        
      }, update: { changes in
        
        guard let previous = changes.previous else {
          return .new(map(changes).wrappedValue)
        }
        
        guard map(changes).version != map(previous).version else {
          return .noUpdates
        }
        
        return .new(map(changes).wrappedValue)
        
      })
  }
  
  /// Projects a value of Fragment structure from Input with memoized by the version of Fragment.
  ///
  /// - Complexity: ✅ Active Memoization with Fragment's version
  /// - Parameter map:
  /// - Returns:
  @available(*, renamed: "map(edge:)")
  public static func map<_Edge: EdgeType>(_ keyPath: KeyPath<Input, _Edge>) -> Pipeline<Input, _Edge.State> where Output == _Edge.State {
    .map(edge: keyPath)
  }
  
  /// Projects a value of Fragment structure from Input with memoized by the version of Fragment.
  ///
  /// - Complexity: ✅ Active Memoization with Fragment's version
  /// - Parameter map:
  /// - Returns:
  public static func map<_Edge: EdgeType>(edge keyPath: KeyPath<Input, _Edge>) -> Pipeline<Input, _Edge.State> where Output == _Edge.State {
    
    var instance = Pipeline.map({ $0[keyPath: keyPath] })
    
    // set an identifier according to the keypath
    Static.modifyIdentifier(
      on: Static.cache1,
      for: &instance,
      keyPath: keyPath
    )
    
    return instance
  }
  
  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ⚠️ No memoization, additionally you need to call `dropsInput` to get memoization.
  ///
  /// - Parameter map:
  /// - Returns:
  public static func map(_ map: @escaping @Sendable (Input) -> Output) -> Pipeline<Input, Output> {
    .init(map: map)
  }
  
  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ⚠️ No memoization, additionally you need to call `dropsInput` to get memoization.
  ///
  /// - Parameter map:
  /// - Returns:
  public static func map(_ keyPath: KeyPath<Input, Output>) -> Pipeline<Input, Output> {
    
    var instance = map({ $0[keyPath: keyPath] })
    
    Static.modifyIdentifier(
      on: Static.cache4,
      for: &instance,
      keyPath: keyPath
    )
    
    return instance
  }
  
  /// Makes an instance that computes value from derived value
  /// - Complexity: ✅ Active Memoization with Derived parameter
  ///
  /// - Parameters:
  ///   - derive: A closure to create value from the state to put into the compute closure.
  ///   - dropsDerived:
  ///     A predicate to drop a duplicated value, closure gets an old value and a new value.
  ///     If return true, drops the value.
  ///   - compute: A closure to compose a computed value from the derived value.
  public static func map<Derived>(
    derive: @escaping @Sendable (Changes<Input.Value>) -> Derived,
    dropsDerived: @escaping @Sendable (Derived, Derived) -> Bool,
    compute: @escaping @Sendable (Derived) -> Output
  ) -> Pipeline<Input, Output> {
    
    .init(
      makeInitial: { input in
        compute(derive(input.asChanges()))
      }) { input in
        
        let result = input.asChanges().ifChanged(derive, .init(dropsDerived)) { (derived) in
          compute(derived)
        }
        
        switch result {
        case .none:
          return .noUpdates
        case .some(let wrapped):
          return .new(wrapped)
        }
      }
  }
  
  /// Makes an instance that computes value from derived value
  /// Drops duplicated derived value with Equatable of Derived type.
  /// - Complexity: ✅ Active Memoization with Derived parameter
  ///
  /// - Parameters:
  ///   - derive: A closure to create value from the state to put into the compute closure.
  ///   - compute: A closure to compose a computed value from the derived value.
  public static func map<Derived: Equatable>(
    derive: @escaping @Sendable (Changes<Input.Value>) -> Derived,
    compute: @escaping @Sendable (Derived) -> Output
  ) -> Pipeline<Input, Output> {
    
    self.map(derive: derive, dropsDerived: { $0 == $1 }, compute: compute)
  }
  
}

extension Pipeline where Input : ChangesType, Input.Value : Equatable {
  
  public init(
    makeInitial: @escaping @Sendable (Input) -> Output,
    update: @escaping @Sendable (Input) -> ContinuousResult
  ) {
    
    self.init(
      makeOutput: { makeInitial($0) },
      dropInput: { $0.asChanges().noChanges(\.root) },
      makeContinuousOutput: { update($0) }
    )
    
  }
  
  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ✅ Using implicit drop-input with Equatable
  /// - Parameter map:
  public init(
    map: @escaping @Sendable (Input) -> Output
  ) {
    
    self.init(
      makeOutput: map,
      dropInput: { $0.asChanges().noChanges(\.root) },
      makeContinuousOutput: { .new(map($0)) }
    )
  }
  
  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ✅ Using implicit drop-input with Equatable
  /// - Parameter map:
  public static func map(_ map: @escaping @Sendable (Input) -> Output) -> Pipeline<Input, Output> {
    .init(map: map)
  }
  
  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ✅ Using implicit drop-input with Equatable
  /// - Parameter map:
  public static func map(_ keyPath: KeyPath<Input, Output>) -> Pipeline<Input, Output> {
    var instance = Pipeline.map({ $0[keyPath: keyPath] })
    
    Static.modifyIdentifier(
      on: Static.cache2,
      for: &instance,
      keyPath: keyPath
    )
    
    return instance
  }
}

extension Pipeline {
  
  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ⚠️ No memoization, additionally you need to call `dropsInput` to get memoization.
  ///
  /// - Parameter map:
  /// - Returns:
  public static func map(_ map: @escaping @Sendable (Input) -> Output) -> Self {
    .init(dropInput: { _ in false }, map: map)
  }
  
  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ⚠️ No memoization, additionally you need to call `dropsInput` to get memoization.
  ///
  /// - Parameter map:
  /// - Returns:
  public static func map(_ keyPath: KeyPath<Input, Output>) -> Self {
    
    var instance = map({ $0[keyPath: keyPath] })
    
    Static.modifyIdentifier(
      on: Static.cache3,
      for: &instance,
      keyPath: keyPath
    )
    
    return instance
  }
  
}

/**
 Manages identifiers for each KeyPath locally.
 */
enum KeyPathIdentifierStore {
  
  private static var counter = NonAtomicCounter()
  
  static var cache: VergeConcurrency.UnfairLockAtomic<[AnyKeyPath : UInt64]> = .init([:])
  
  static func getLocalIdentifier(_ keyPath: AnyKeyPath) -> UInt64 {
    cache.modify { cache -> UInt64 in
      if let value = cache[keyPath] {
        return value
      } else {
        counter.increment()
        let v = counter.value
        cache[keyPath] = v
        return v
      }
    }
  }
  
}

extension AnyKeyPath {
  
  @inline(__always)
  fileprivate func _getIdentifier() -> UInt64 {
    KeyPathIdentifierStore.getLocalIdentifier(self)
  }
  
}

fileprivate enum Static {
  
  typealias Storage<T> = VergeConcurrency.RecursiveLockAtomic<T>
  
  static let cache1: Storage<[String : Int]> = .init([:])
  static let cache2: Storage<[String : Int]> = .init([:])
  static let cache3: Storage<[String : Int]> = .init([:])
  static let cache4: Storage<[String : Int]> = .init([:])
  
  static func modifyIdentifier<I, O>(
    on storage: Storage<[String : Int]>,
    for pipeline: inout Pipeline<I, O>,
    keyPath: AnyKeyPath
  ) {
    
    storage.modify { cache in
      
      let combinedKey = "\(ObjectIdentifier(I.self))\(ObjectIdentifier(O.self))\(keyPath._getIdentifier())"
      
      if let id = cache[combinedKey] {
        pipeline.identifier = id
      } else {
        cache[combinedKey] = pipeline.identifier
      }
    }
  }
  
}
