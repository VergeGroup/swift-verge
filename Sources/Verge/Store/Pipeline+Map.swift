
import Foundation

extension Pipeline where Input : ChangesType {
  
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
  
}

extension Pipeline {
  
  public static func map(_ closure: @escaping @Sendable (Input) -> Output) -> Self where Input: ChangesType {
    fatalError()
  }
  
  public static func map(_ closure: @escaping @Sendable (Input) -> Output) -> Self where Input: ChangesType, Output: Equatable {
    fatalError()
  }
  
  public static func map(_ closure: @escaping @Sendable (Input) -> Output) -> Self where Input: ChangesType, Input.Value: Equatable {
    fatalError()
  }
  
  public static func map(_ closure: @escaping @Sendable (Input) -> Output) -> Self where Input: ChangesType, Input.Value: Equatable, Output: Equatable {
    fatalError()
  }
  
  public static func map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType {
    fatalError()
  }
  
  public static func map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType, Output: Equatable {
    fatalError()
  }
  
  public static func map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType, Input.Value: Equatable {
    fatalError()
  }
  
  public static func map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType, Input.Value: Equatable, Output: Equatable {
    fatalError()
  }
  
  public static func map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType, Output: EdgeType {
    fatalError()
  }
  
  public static func map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType, Output: EdgeType, Output.State : Equatable {
    fatalError()
  }
  
  public static func map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType, Input.Value: Equatable, Output: EdgeType {
    fatalError()
  }
  
  public static func map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType, Input.Value: Equatable, Output: EdgeType, Output.State : Equatable {
    fatalError()
  }
}
