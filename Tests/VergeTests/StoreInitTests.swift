
import XCTest
import Verge

final class StoreInitTests: XCTestCase {
  
  class RefState {
    
  }
 /*
  class RefViewModel: StoreComponentType {
    
    class State: Equatable {
      static func == (lhs: StoreInitTests.RefViewModel.State, rhs: StoreInitTests.RefViewModel.State) -> Bool {
        true
      }
      
      init() {}
    }
    
    let store: DefaultStore
    
    init() {
      
      // it raises a warning
      self.store = DefaultStore(initialState: .init())
    }
  }
  */
  
  class StructViewModel: StoreDriverType {
    
    struct State: Equatable {
      
      init() {}
    }
    
    let store: Store<State, Never>
    
    init() {
      
      self.store = .init(initialState: .init())
    }
  }
      
}
