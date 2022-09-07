
import XCTest
import Verge

final class PipelineTests: XCTestCase {
  
  func test_hoge() {
    
    let pipeline = Pipelines.SelectPipeline<Changes<DemoState>, _>.init(keyPath: \.count, additionalDropCondition: nil)
    
//    let initialState = Changes<DemoState>.init(old: nil, new: .init())
//
//    XCTAssertEqual(pipeline.yieldContinuously(initialState), .new(0))
   
    
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
        let d = store.derived(.map(\.nonEquatable))
        XCTAssert((d as Any) is Derived<NonEquatable>)
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
    
    do {
      let store = Verge.Store<NonEquatableDemoState, Never>(initialState: .init())
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
        let d = store.derived(.map(\.nonEquatable))
        XCTAssert((d as Any) is Derived<NonEquatable>)
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
