@_spi(EventEmitter) import Verge
import XCTest

final class EmitterTests: XCTestCase {
  
  func testOrder() {
    
    let emitter = EventEmitter<Int>()
    
    var results_1 = [Int]()
    emitter.addEventHandler { value in
      results_1.append(value)
      
      if value == 1 {
        emitter.accept(2)
      }
    }
    
    var results_2 = [Int]()
    emitter.addEventHandler { value in
      results_2.append(value)
    }
    
    emitter.accept(1)
    
    XCTAssertEqual(results_1, [1, 2])
    XCTAssertEqual(results_2, [1, 2])
    
  }
  
  func testEmitsAll() {
    
    let emitter = EventEmitter<Int>()
    
    emitter.addEventHandler { value in
    }
    
    let outputs = VergeConcurrency.UnfairLockAtomic.init([Int]())
    emitter.addEventHandler { value in
      outputs.modify({
        $0.append(value)
      })
    }
    
    let inputs = VergeConcurrency.UnfairLockAtomic.init([Int]())
    DispatchQueue.concurrentPerform(iterations: 500) { i in
      inputs.modify {
        $0.append(i)
      }
      emitter.accept(i)
    }
    
    XCTAssertEqual(outputs.value.count, 500)
    
  }

}
