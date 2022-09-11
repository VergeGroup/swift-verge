
import XCTest
import Verge

final class PipelineTests: XCTestCase {
  
  func test_select_pipeline() {
    
    let pipeline = Pipelines.SelectPipeline<DemoState, _>.init(keyPath: \.count, additionalDropCondition: nil)
    
    let initialState = Changes<DemoState>.init(old: nil, new: .init())

    XCTAssertEqual(pipeline.yieldContinuously(initialState), .new(0))
    
    XCTAssertEqual(
      pipeline.yieldContinuously(
        initialState.makeNextChanges(
          with: DemoState(count: 1),
          from: [],
          modification: .indeterminate
        )
      ),
      .new(1)
    )
    
    XCTAssertEqual(
      pipeline.yieldContinuously(
        initialState.makeNextChanges(
          with: DemoState(count: 1),
          from: [],
          modification: .indeterminate
        )
      ),
      .new(1)
    )
    
  }
  
  func test_select_pipeline_equatable() {
    
    let pipeline = Pipelines.SelectEquatableOutputPipeline<DemoState, _>.init(keyPath: \.count, additionalDropCondition: nil)
    
    let initialState = Changes<DemoState>.init(old: nil, new: .init())
    
    XCTAssertEqual(pipeline.yieldContinuously(initialState), .new(0))
    
    XCTAssertEqual(
      pipeline.yieldContinuously(
        initialState.makeNextChanges(
          with: DemoState(count: 1),
          from: [],
          modification: .indeterminate
        )
      ),
      .new(1)
    )
    
    XCTAssertEqual(
      pipeline.yieldContinuously(
        initialState.makeNextChanges(
          with: DemoState(count: 1),
          from: [],
          modification: .indeterminate
        )
      ),
      .new(1)
    )
    
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
 
}
