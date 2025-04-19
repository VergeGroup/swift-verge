import XCTest
@testable import Verge

final class PipelineTests: XCTestCase {
  
  func test_MapPipeline() {
            
    let pipeline = Pipelines.ChangesSelectPipeline<DemoState, Int>.init(selector: \.count, additionalDropCondition: nil)   
            
    var storage: Int? = nil
    
    do {
      _ = pipeline.yield(StateWrapper<DemoState>.init(state: .init()), storage: &storage)
    }
    
    XCTAssert(storage == 0)
    
    do {
            
      XCTAssertEqual(
        pipeline.yieldContinuously(
          StateWrapper<DemoState>.init(state: .init()),          
          storage: &storage
        ),
        .noUpdates
      )
      
    }
    
    do {
      
      XCTAssertEqual(
        pipeline.yieldContinuously(
          StateWrapper<DemoState>.init(state: .init(name: "", count: 2)),          
          storage: &storage
        ),
        .new(2)
      )
            
    }
    
  }
   
  func testSelect() {
    
    do {
      let store = Verge.Store<DemoState, Never>(initialState: .init())
//      do {
//        let d = store.derived(.map(\.nonEquatable))
//        XCTAssert((d as Any) is Derived<Edge<OnEquatable>>)
//      }
//      
//      do {
//        let d = store.derived(.map(\.nonEquatable))
//        XCTAssert((d as Any) is Derived<Edge<NonEquatable>>)
//      }
      
      do {
        let d = store.derived(.map(\.onEquatable))
        XCTAssert((d as Any) is Derived<OnEquatable>)
      }
            
      do {
        let d = store.derived(.map(\.count))
        XCTAssert((d as Any) is Derived<Int>)
      }
      
      do {
        let d = store.derived(.map { @Sendable in $0.count })
        XCTAssert((d as Any) is Derived<Int>)
      }
    }
       
  }
 
}
