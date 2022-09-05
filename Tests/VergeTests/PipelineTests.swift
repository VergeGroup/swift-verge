
import XCTest
import Verge

extension Pipeline {
  
  public static func _map(_ closure: @escaping @Sendable (Input) -> Output) -> Self where Input: ChangesType {
    fatalError()
  }
  
  public static func _map(_ closure: @escaping @Sendable (Input) -> Output) -> Self where Input: ChangesType, Output: Equatable {
    fatalError()
  }
  
  public static func _map(_ closure: @escaping @Sendable (Input) -> Output) -> Self where Input: ChangesType, Input.Value: Equatable {
    fatalError()
  }
  
  public static func _map(_ closure: @escaping @Sendable (Input) -> Output) -> Self where Input: ChangesType, Input.Value: Equatable, Output: Equatable {
    fatalError()
  }
  
  public static func _map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType {
    fatalError()
  }
    
  public static func _map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType, Output: Equatable {
    fatalError()
  }

  public static func _map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType, Input.Value: Equatable {
    fatalError()
  }
  
  public static func _map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType, Input.Value: Equatable, Output: Equatable {
    fatalError()
  }
  
  public static func _map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType, Output: EdgeType {
    fatalError()
  }
  
  public static func _map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType, Output: EdgeType, Output.State : Equatable {
    fatalError()
  }
  
  public static func _map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType, Input.Value: Equatable, Output: EdgeType {
    fatalError()
  }
  
  public static func _map(_ keyPath: KeyPath<Input, Output>) -> Self where Input: ChangesType, Input.Value: Equatable, Output: EdgeType, Output.State : Equatable {
    fatalError()
  }
}

final class PipelineTests: XCTestCase {
  
  func testSelect() {
    
    let _ = Pipeline<Changes<DemoState>, _>._map { $0.nonEquatable }
    
    let _ = Pipeline<Changes<DemoState>, _>._map { $0.count }
    
    let _ = Pipeline<Changes<DemoState>, _>._map(\.count)
    
    let _ = Pipeline<Changes<DemoState>, _>._map(\.nonEquatable)
            
    let _ = Pipeline<Changes<DemoState>, _>._map(\.$nonEquatable)
    
    let _ = Pipeline<Changes<DemoState>, _>._map(\.$onEquatable)
    
    let _ = Pipeline<Changes<DemoState>, _>._map(\.computed.nameCount)
    
    
    let _ = Pipeline<Changes<NonEquatableDemoState>, _>._map { $0.nonEquatable }
    
    let _ = Pipeline<Changes<NonEquatableDemoState>, _>._map { $0.count }
    
    let _ = Pipeline<Changes<NonEquatableDemoState>, _>._map(\.count)
    
    let _ = Pipeline<Changes<NonEquatableDemoState>, _>._map(\.nonEquatable)
    
    let _ = Pipeline<Changes<NonEquatableDemoState>, _>._map(\.$nonEquatable)
    
    let _ = Pipeline<Changes<NonEquatableDemoState>, _>._map(\.$onEquatable)
    
    let _ = Pipeline<Changes<NonEquatableDemoState>, _>._map(\.computed.nameCount)
        
  }
  
}
