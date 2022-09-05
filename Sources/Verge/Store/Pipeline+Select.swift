
import Foundation

extension Pipeline where Input : ChangesType {
  
  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ✅ It drops inputs by comparing Edge's version changes.
  public static func select(_ keyPath: KeyPath<Input, Edge<Output>>) -> Self {
    self.init(
      makeOutput: { $0[keyPath: keyPath].wrappedValue },
      dropInput: {
        guard let previous = $0.previous else {
          return false
        }
        
        guard $0.version == previous.version else {
          return false
        }

        return true
      },
      makeContinuousOutput: {
        .new($0[keyPath: keyPath].wrappedValue)
      }
    )
  }
  
  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ☁️ Detects changes by Changes.modification, which depends on how the state modified
  @_disfavoredOverload // prioritize `Edge` binding
  public static func select(_ keyPath: KeyPath<Input.Value, Output>) -> Self {
    self.init(
      makeOutput: { $0.asChanges()[dynamicMember: keyPath] },
      dropInput: {
        guard let modification = $0.modification else {
          return false
        }
        return modification[dynamicMember: keyPath] == false
      },
      makeContinuousOutput: { .new($0.asChanges()[dynamicMember: keyPath]) }
    )
  }
  
  /// Projects a specified shape from Input.
  ///
  /// This variant is for `.computed.property`
  /// - Complexity: ❓ depends
  @_disfavoredOverload // prioritize `Edge` binding
  public static func select(_ keyPath: KeyPath<Input, Output>) -> Self {
    self.init(
      makeOutput: { $0[keyPath: keyPath] },
      dropInput: { _ in false },
      makeContinuousOutput: { .new($0[keyPath: keyPath]) }
    )
  }
       
}
  
extension Pipeline where Input : ChangesType, Input.Value : Equatable {
 
  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ✅ Using implicit drop-input with Equatable
  @_disfavoredOverload // prioritize `Edge` binding
  public static func select(_ keyPath: KeyPath<Input.Value, Output>) -> Self {
    self.init(
      makeOutput: { $0.asChanges()[dynamicMember: keyPath] },
      dropInput: {

        if let modification = $0.modification, modification[dynamicMember: keyPath] == false {
          return true
        }

        return $0.asChanges().noChanges(\.root)
      },
      makeContinuousOutput: { .new($0.asChanges()[dynamicMember: keyPath]) }
    )
  }

  /// Projects a specified shape from Input.
  ///
  /// This variant is for `.computed.property`
  /// - Complexity: ✅ Using implicit drop-input with Equatable
  @_disfavoredOverload // prioritize `Edge` binding
  public static func select(_ keyPath: KeyPath<Input, Output>) -> Self {
    self.init(
      makeOutput: { $0[keyPath: keyPath] },
      dropInput: {
        $0.asChanges().noChanges(\.root)
      },
      makeContinuousOutput: { .new($0[keyPath: keyPath]) }
    )
  }
  
}

