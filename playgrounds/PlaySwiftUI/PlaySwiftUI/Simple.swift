import SwiftUI
import Verge

private struct _Book: View {
  
  @Tracking
  struct State {
    var count: Int = 0
    
    @Tracking
    struct NestedState {
      var isActive: Bool = false
      var message: String = "Hello, Verge!"
    }
    
    var nestedState: NestedState = NestedState()
  }
  
  let store = Store<_, Never>(initialState: State())
  
  var body: some View {
    StoreReader(store) { state in
      VStack {
        Text("Count: \(state.count)")
        Button("Increment") {
          store.commit {
            $0.count += 1
          }
        }
        Text("Is Active: \(state.nestedState.isActive)")
        Text("Message: \(state.nestedState.message)")
        Button("Toggle Active") {
          store.commit {
            $0.nestedState.isActive.toggle()
          }
        }
      }
    }
  }
}

#Preview("Simple") {
  _Book()
}
