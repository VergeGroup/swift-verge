import Verge
import XCTest
import SwiftUI

final class PropertyWrapperTests: XCTestCase {
  
  @UIState var isOn = false
  
  func testFoo() {
    
    let store: UIStateStore<_, _> = $isOn
    
    print(store)
    
    let binding: SwiftUI.Binding<_> = $isOn.binding()
    
    binding.wrappedValue = true
    
    XCTAssertEqual(isOn, true)
    XCTAssertEqual(store.state.primitive, true)
    
  }
  
}
