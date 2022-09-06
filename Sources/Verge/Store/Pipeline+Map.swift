import Foundation

extension Pipeline where Input: ChangesType {

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

extension Pipeline where Input: ChangesType, Input.Value: Equatable {

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

}

extension Pipeline {
  
  /**
   Closure based map
   - Input: ChangesType
   - Output: Any
   */
  public static func map(_ closure: @escaping @Sendable (Input) -> Output) -> Pipeline<
    Input, Output
  > where Input: ChangesType {
    
    .init(
      makeOutput: closure,
      dropInput: { changes in
        guard let previous = changes.previous else {
          return false
        }
        
        guard previous.version == changes.version else {
          return false
        }
        
        return true
      },
      makeContinuousOutput: { .new(closure($0)) }
    )
    
  }

  /**
   Closure based map
   - Input: ChangesType
   - Output: Equatable
   */
  public static func map(_ closure: @escaping @Sendable (Input) -> Output) -> Pipeline<
    Input, Output
  > where Input: ChangesType, Output: Equatable {

    .init(
      makeOutput: closure,
      dropInput: { changes in
        
        guard let previous = changes.previous else {
          return false
        }
        
        guard previous.version == changes.version else {
          return false
        }
        
        // Do not compare outputs due to we don't know how much the closure takes costs.
        
        return true
      },
      makeContinuousOutput: { .new(closure($0)) }
    )
    
  }

  /**
   Closure based map
   - Input: ChangesType, Input.Value: Equatable
   - Output: Any
   */
  public static func map(_ closure: @escaping @Sendable (Input) -> Output) -> Pipeline<
    Input, Output
  > where Input: ChangesType, Input.Value: Equatable {
    
    .init(
      makeOutput: closure,
      dropInput: { changes in
        
        guard let previous = changes.previous else {
          return false
        }
                
        guard previous.version == changes.version else {
          return false
        }
                
        // Input.Value : Equatable
        guard changes.asChanges().noChanges(\.root) else {
          return false
        }
        
        // Do not compare outputs due to we don't know how much the closure takes costs.
        
        return true
      },
      makeContinuousOutput: { .new(closure($0)) }
    )
    
  }

  /**
   Closure based map
   - Input: ChangesType, Input.Value: Equatable
   - Output: Equatable
   */
  public static func map(_ closure: @escaping @Sendable (Input) -> Output) -> Pipeline<
    Input, Output
  > where Input: ChangesType, Input.Value: Equatable, Output: Equatable {
    .init(
      makeOutput: closure,
      dropInput: { changes in
        
        guard let previous = changes.previous else {
          return false
        }
        
        guard previous.version == changes.version else {
          return false
        }
        
        // Input.Value : Equatable
        guard changes.asChanges().noChanges(\.root) else {
          return false
        }
        
        // Do not compare outputs due to we don't know how much the closure takes costs.
        
        return true
      },
      makeContinuousOutput: { .new(closure($0)) }
    )
  }

  public static func map(_ keyPath: KeyPath<Input, Output>) -> Pipeline<Input, Output>
  where Input: ChangesType {

    .init(
      makeOutput: { $0[keyPath: keyPath] },
      dropInput: { changes in
        
        guard let previous = changes.previous else {
          return false
        }
        
        guard previous.version == changes.version else {
          return false
        }
            
        return true
      },
      makeContinuousOutput: { .new($0[keyPath: keyPath]) }
    )
    
  }

  public static func map(_ keyPath: KeyPath<Input, Output>) -> Pipeline<Input, Output>
  where Input: ChangesType, Output: Equatable {
    .init(
      makeOutput: { $0[keyPath: keyPath] },
      dropInput: { changes in
        
        guard let previous = changes.previous else {
          return false
        }
        
        guard previous.version == changes.version else {
          return false
        }
            
        guard previous[keyPath: keyPath] == changes[keyPath: keyPath] else {
          return false
        }
        
        return true
      },
      makeContinuousOutput: { .new($0[keyPath: keyPath]) }
    )
  }

  public static func map(_ keyPath: KeyPath<Input, Output>) -> Pipeline<Input, Output>
  where Input: ChangesType, Input.Value: Equatable {
    .init(
      makeOutput: { $0[keyPath: keyPath] },
      dropInput: { changes in
        
        guard let previous = changes.previous else {
          return false
        }
        
        guard previous.version == changes.version else {
          return false
        }
        
        // Input.Value : Equatable
        guard changes.asChanges().noChanges(\.root) else {
          return false
        }
                     
        return true
      },
      makeContinuousOutput: { .new($0[keyPath: keyPath]) }
    )
  }

  public static func map(_ keyPath: KeyPath<Input, Output>) -> Pipeline<Input, Output>
  where Input: ChangesType, Input.Value: Equatable, Output: Equatable {
    .init(
      makeOutput: { $0[keyPath: keyPath] },
      dropInput: { changes in
        
        guard let previous = changes.previous else {
          return false
        }
        
        guard previous.version == changes.version else {
          return false
        }
        
        // Input.Value : Equatable
        guard changes.asChanges().noChanges(\.root) else {
          return false
        }
        
        guard previous[keyPath: keyPath] == changes[keyPath: keyPath] else {
          return false
        }
        
        return true
      },
      makeContinuousOutput: { .new($0[keyPath: keyPath]) }
    )
  }

  /// For Edge
  public static func map(_ keyPath: KeyPath<Input, Output>) -> Pipeline<Input, Output.State>
  where Input: ChangesType, Output: EdgeType {
    .init(
      makeOutput: { $0[keyPath: keyPath].wrappedValue },
      dropInput: { changes in
        
        guard let previous = changes.previous else {
          return false
        }
        
        guard previous.version == changes.version else {
          return false
        }
        
        guard previous[keyPath: keyPath].version == changes[keyPath: keyPath].version else {
          return false
        }
         
        return true
      },
      makeContinuousOutput: { .new($0[keyPath: keyPath].wrappedValue) }
    )
  }

  public static func map(_ keyPath: KeyPath<Input, Output>) -> Pipeline<Input, Output.State>
  where Input: ChangesType, Output: EdgeType, Output.State: Equatable {
    .init(
      makeOutput: { $0[keyPath: keyPath].wrappedValue },
      dropInput: { changes in
        
        guard let previous = changes.previous else {
          return false
        }
        
        guard previous.version == changes.version else {
          return false
        }
        
        guard previous[keyPath: keyPath].version == changes[keyPath: keyPath].version else {
          return false
        }
        
        guard previous[keyPath: keyPath].wrappedValue == changes[keyPath: keyPath].wrappedValue else {
          return false
        }
        
        return true
      },
      makeContinuousOutput: { .new($0[keyPath: keyPath].wrappedValue) }
    )
  }

  public static func map(_ keyPath: KeyPath<Input, Output>) -> Pipeline<Input, Output.State>
  where Input: ChangesType, Input.Value: Equatable, Output: EdgeType {
    .init(
      makeOutput: { $0[keyPath: keyPath].wrappedValue },
      dropInput: { changes in
        
        guard let previous = changes.previous else {
          return false
        }
        
        guard previous.version == changes.version else {
          return false
        }
        
        guard previous[keyPath: keyPath].version == changes[keyPath: keyPath].version else {
          return false
        }
            
        return true
      },
      makeContinuousOutput: { .new($0[keyPath: keyPath].wrappedValue) }
    )
  }

  public static func map(_ keyPath: KeyPath<Input, Output>) -> Pipeline<Input, Output.State>
  where Input: ChangesType, Input.Value: Equatable, Output: EdgeType, Output.State: Equatable {
    .init(
      makeOutput: { $0[keyPath: keyPath].wrappedValue },
      dropInput: { changes in
        
        guard let previous = changes.previous else {
          return false
        }
        
        guard previous.version == changes.version else {
          return false
        }
        
        guard previous[keyPath: keyPath].version == changes[keyPath: keyPath].version else {
          return false
        }
        
        guard previous[keyPath: keyPath].wrappedValue == changes[keyPath: keyPath].wrappedValue else {
          return false
        }
                   
        return true
      },
      makeContinuousOutput: { .new($0[keyPath: keyPath].wrappedValue) }
    )
  }
}
