import Foundation

extension Pipeline {

  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ✅ It drops inputs by comparing Edge's version changes.
//  public static func map(_ keyPath: KeyPath<Input, Edge<Output>>) -> Pipeline<Input, Output> where Input: ChangesType {
//    .init(
//      makeOutput: { $0[keyPath: keyPath].wrappedValue },
//      dropInput: {
//
//        guard let previous = $0.previous else {
//          return false
//        }
//
//        guard $0[keyPath: keyPath].version == previous[keyPath: keyPath].version else {
//          return false
//        }
//
//        return true
//      },
//      makeContinuousOutput: {
//        .new($0[keyPath: keyPath].wrappedValue)
//      }
//    )
//  }
  
//  /// Projects a specified shape from Input.
//  ///
//  /// - Complexity: ✅ It drops inputs by comparing Edge's version changes.
//  public static func map(_ keyPath: KeyPath<Input, Edge<Output>>) -> Pipeline<Input, Output> where Input: ChangesType, Output: Equatable {
//    .init(
//      makeOutput: { $0[keyPath: keyPath].wrappedValue },
//      dropInput: {
//        
//        guard let previous = $0.previous else {
//          return false
//        }
//        
//        guard $0[keyPath: keyPath].version == previous[keyPath: keyPath].version else {
//          return false
//        }
//        
//        guard $0[keyPath: keyPath] == previous[keyPath: keyPath] else {
//          return false
//        }
//        
//        return true
//      },
//      makeContinuousOutput: {
//        .new($0[keyPath: keyPath].wrappedValue)
//      }
//    )
//  }

  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ☁️ Detects changes by Changes.modification, which depends on how the state modified
//  public static func map(_ keyPath: KeyPath<Input.Value, Output>) -> Self
//  where Input: ChangesType {
//    self.init(
//      makeOutput: { $0.asChanges()[dynamicMember: keyPath] },
//      dropInput: {
//        
//        guard let _ = $0.previous else {
//          return false
//        }
//        
//        guard let modification = $0.modification else {
//          return false
//        }
//        
//        guard modification[dynamicMember: keyPath] == false else {
//          return false
//        }
//                
//        return true
//      },
//      makeContinuousOutput: { .new($0.asChanges()[dynamicMember: keyPath]) }
//    )
//  }
  
  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ☁️ Detects changes by Changes.modification, which depends on how the state modified
//  public static func map(_ keyPath: KeyPath<Input.Value, Output>) -> Self
//  where Input: ChangesType, Output: Equatable {
//    self.init(
//      makeOutput: { $0.asChanges()[dynamicMember: keyPath] },
//      dropInput: {
//
//        guard let previous = $0.previous else {
//          return false
//        }
//
//        guard let modification = $0.modification else {
//          return false
//        }
//
//        guard modification[dynamicMember: keyPath] == false else {
//          return false
//        }
//
//        guard $0.asChanges()[dynamicMember: keyPath] == previous.asChanges()[dynamicMember: keyPath] else {
//          return false
//        }
//
//        return true
//      },
//      makeContinuousOutput: { .new($0.asChanges()[dynamicMember: keyPath]) }
//    )
//  }

  /// Projects a specified shape from Input.
  ///
  /// This variant is for `.computed.property`
  /// - Complexity: ❓ depends
//  public static func map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType {
//    self.init(
//      makeOutput: { $0[keyPath: keyPath] },
//      dropInput: { _ in false },
//      makeContinuousOutput: { .new($0[keyPath: keyPath]) }
//    )
//  }
  
  /// Projects a specified shape from Input.
  ///
  /// This variant is for `.computed.property`
  /// - Complexity: ❓ depends
//  public static func map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType, Output: Equatable {
//    self.init(
//      makeOutput: { $0[keyPath: keyPath] },
//      dropInput: {
//        guard let previous = $0.previous else {
//          return false
//        }
//
//        guard $0[keyPath: keyPath] == previous[keyPath: keyPath] else {
//          return false
//        }
//
//        return true
//      },
//      makeContinuousOutput: { .new($0[keyPath: keyPath]) }
//    )
//  }

}

extension Pipeline {

  /// Projects a specified shape from Input.
  ///
  /// - Complexity: ✅ Using implicit drop-input with Equatable
//  public static func map(_ keyPath: KeyPath<Input.Value, Output>) -> Self where Input: ChangesType, Input.Value: Equatable {
//    self.init(
//      makeOutput: { $0.asChanges()[dynamicMember: keyPath] },
//      dropInput: {
//
//        if let modification = $0.modification, modification[dynamicMember: keyPath] == false {
//          return true
//        }
//
//        return $0.asChanges().noChanges(\.root)
//      },
//      makeContinuousOutput: { .new($0.asChanges()[dynamicMember: keyPath]) }
//    )
//  }

  /// Projects a specified shape from Input.
  ///
  /// This variant is for `.computed.property`
  /// - Complexity: ✅ Using implicit drop-input with Equatable
//  public static func map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType, Input.Value: Equatable {
//    self.init(
//      makeOutput: { $0[keyPath: keyPath] },
//      dropInput: {
//        $0.asChanges().noChanges(\.root)
//      },
//      makeContinuousOutput: { .new($0[keyPath: keyPath]) }
//    )
//  }
//
//  public static func map<EdgeValue>(_ keyPath: KeyPath<Input, Edge<EdgeValue>>) -> Self where Input: ChangesType, Input.Value: Equatable, Output == Edge<EdgeValue> {
//    fatalError()
//  }

}
