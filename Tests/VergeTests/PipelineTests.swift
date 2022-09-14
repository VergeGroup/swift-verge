
import XCTest
import Verge

final class PipelineTests: XCTestCase {
 
  func testIntermediate() {
    
    var mapCounter = NonAtomicCounter()
    
    let pipeline = Pipelines.MapPipeline<DemoState, _, _>(
      intermediate: {
        $0.name
      },
      map: {
        mapCounter.increment()
        return $0.count
      },
      additionalDropCondition: nil
    )
    
    let inputChanges = Changes<DemoState>.init(
      old: .init(name: "A", count: 1),
      new: .init(name: "A", count: 2)
    )
    
    XCTAssertEqual(pipeline.yieldContinuously(inputChanges), .noUpdates)
    XCTAssertEqual(mapCounter.value, 0)
    
  }
  
  func testSelect() {
    
    do {
      let store = Verge.Store<DemoState, Never>(initialState: .init())
      do {
        let d = store.derived(.map(\.$onEquatable))
        XCTAssert((d as Any) is Derived<Edge<OnEquatable>>)
      }
      
      do {
        let d = store.derived(.map(\.$nonEquatable))
        XCTAssert((d as Any) is Derived<Edge<NonEquatable>>)
      }
      
      do {
        let d = store.derived(.map(\.onEquatable))
        XCTAssert((d as Any) is Derived<OnEquatable>)
      }
            
      do {
        let d = store.derived(.map(\.count))
        XCTAssert((d as Any) is Derived<Int>)
      }
      
      do {
        let d = store.derived(.map { $0.count })
        XCTAssert((d as Any) is Derived<Int>)
      }
    }
       
  }
 
}
