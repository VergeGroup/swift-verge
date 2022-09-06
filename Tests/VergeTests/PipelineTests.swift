
import XCTest
import Verge

final class PipelineTests: XCTestCase {
  
  func testSelect() {
    
    do {
      let any: Any = DemoStore().derived(.map(\.$onEquatable))
      XCTAssert(any is Derived<NonEquatable>)
    }
    
    DemoStore()
      .derived(.map(\.$nonEquatable))
      .sinkValue { c in
        c.id
      }
    
    DemoStore().derived(.map(\.count))
    
    let _ = Pipeline<Changes<DemoState>, _>.map { $0.nonEquatable }
    
    let _ = Pipeline<Changes<DemoState>, _>.map { $0.count }
    
    let _ = Pipeline<Changes<DemoState>, _>.map(\.count)
    
    let _ = Pipeline<Changes<DemoState>, _>.map(\.nonEquatable)
            
    let _ = Pipeline<Changes<DemoState>, _>.map(\.$nonEquatable)
    
    let _ = Pipeline<Changes<DemoState>, _>.map(\.$onEquatable)
    
    let _ = Pipeline<Changes<DemoState>, _>.map(\.computed.nameCount)
    
    
    let _ = Pipeline<Changes<NonEquatableDemoState>, _>.map { $0.nonEquatable }
    
    let _ = Pipeline<Changes<NonEquatableDemoState>, _>.map { $0.count }
    
    let _ = Pipeline<Changes<NonEquatableDemoState>, _>.map(\.count)
    
    let _ = Pipeline<Changes<NonEquatableDemoState>, _>.map(\.nonEquatable)
    
    let _ = Pipeline<Changes<NonEquatableDemoState>, _>.map(\.$nonEquatable)
    
    let _ = Pipeline<Changes<NonEquatableDemoState>, _>.map(\.$onEquatable)
    
    let _ = Pipeline<Changes<NonEquatableDemoState>, _>.map(\.computed.nameCount)
        
  }
  
  func testEdge() {
    
    do {
      
      let result = Pipeline.map(\Changes<DemoState>.$nonEquatable)
      let erased = result as Any
      XCTAssertTrue(erased is Pipeline<Changes<DemoState>, Edge<NonEquatable>>)
    }
    
    do {
      let result = Pipeline.map(\Changes<DemoState>.nonEquatable)
      let erased = result as Any
      XCTAssertTrue(erased is Pipeline<Changes<DemoState>, NonEquatable>)
    }
    
    do {
      let result = Pipeline.map(\Changes<DemoState>.$onEquatable)
      let erased = result as Any
      XCTAssertTrue(erased is Pipeline<Changes<DemoState>, Edge<OnEquatable>>)
    }
    
    do {
      let result = Pipeline.map(\Changes<DemoState>.onEquatable)
      let erased = result as Any
      XCTAssertTrue(erased is Pipeline<Changes<DemoState>, OnEquatable>)
    }
    
  }
}
