
import Foundation

extension Pipeline where Input : ChangesType {
  
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
  
  @_disfavoredOverload
  public static func select(_ keyPath: KeyPath<Input, Output>) -> Self {
    self.init(
      makeOutput: { $0[keyPath: keyPath] },
      dropInput: { _ in false },
      makeContinuousOutput: { .new($0[keyPath: keyPath]) }
    )
  }
  
}
  
extension Pipeline where Input : ChangesType, Input.Value : Equatable {
  
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
    
  @_disfavoredOverload
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
