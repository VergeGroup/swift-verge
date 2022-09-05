
import XCTest
import Verge

final class PipelineTests: XCTestCase {
  
  func testSelect() {
        
    let _ = Pipeline<Changes<DemoState>, _>.select(\.$nonEquatable)
    
    let _ = Pipeline<Changes<DemoState>, _>.map(\.$nonEquatable)
    
    let _ = Pipeline<Changes<DemoState>, _>.select(\.computed.nameCount)
        
  }
  
}
