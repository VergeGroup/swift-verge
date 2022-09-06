
import XCTest
import Verge

final class PipelineTests: XCTestCase {
  
  func testSelect() {
    
    do {
      let store = Verge.Store<DemoState, Never>(initialState: .init())
      do {
        let d = store.derived2(.map(\.$onEquatable))
        XCTAssert((d as Any) is Derived<Edge<OnEquatable>>)
      }
      
      do {
        let d = store.derived2(.map(\.$nonEquatable))
        XCTAssert((d as Any) is Derived<Edge<NonEquatable>>)
      }
      
      do {
        let d = store.derived2(.map(\.onEquatable))
        XCTAssert((d as Any) is Derived<OnEquatable>)
      }
      
      do {
        let d = store.derived2(.map(\.nonEquatable))
        XCTAssert((d as Any) is Derived<NonEquatable>)
      }
      
      do {
        let d = store.derived2(.map(\.count))
        XCTAssert((d as Any) is Derived<Int>)
      }
      
      do {
        let d = store.derived2(.map { $0.count })
        XCTAssert((d as Any) is Derived<Int>)
      }
    }
    
    do {
      let store = Verge.Store<NonEquatableDemoState, Never>(initialState: .init())
      do {
        let d = store.derived2(.map(\.$onEquatable))
        XCTAssert((d as Any) is Derived<Edge<OnEquatable>>)
      }
      
      do {
        let d = store.derived2(.map(\.$nonEquatable))
        XCTAssert((d as Any) is Derived<Edge<NonEquatable>>)
      }
      
      do {
        let d = store.derived2(.map(\.onEquatable))
        XCTAssert((d as Any) is Derived<OnEquatable>)
      }
      
      do {
        let d = store.derived2(.map(\.nonEquatable))
        XCTAssert((d as Any) is Derived<NonEquatable>)
      }
      
      do {
        let d = store.derived2(.map(\.count))
        XCTAssert((d as Any) is Derived<Int>)
      }
      
      do {
        let d = store.derived2(.map { $0.count })
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
