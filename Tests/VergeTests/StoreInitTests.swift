
import XCTest
import Verge

final class StoreInitTests: XCTestCase {
  
  class RefState {
    
  }
  
  class RefViewModel: StoreComponentType {
    
    class State {
      
      init() {}
    }
    
    let store: DefaultStore
    
    init() {
      
      self.store = DefaultStore(initialState: .init())
    }
  }
  
  class StructViewModel: StoreComponentType {
    
    struct State {
      
      init() {}
    }
    
    let store: DefaultStore
    
    init() {
      
      self.store = DefaultStore(initialState: .init())
    }
  }
    
  func testInitWithReferenceTypeState() {
    
    Store<RefState, Never>(initialState: .init())
    
  }
  
}
