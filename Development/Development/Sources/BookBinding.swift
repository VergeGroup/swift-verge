
import SwiftUI
import Verge

struct BookBindingUsingReading: View {
  
  @Reading<Store<BookBindingState, Never>> var state: BookBindingState
  
  init() {
    self._state = .init({
      .init(initialState: .init())
    })
  }
  
  var body: some View {
    Counter(value: $state.value)
  }
  
  struct Counter: View {
    
    @Binding var value: Int
    
    var body: some View {
      VStack {
        Text("\(value)")
        Button {
          value += 1
        } label: {
          Text("Increment")
        }
      }
    }
  }
  
}

struct BookBindingUsingStoreReader: View {
  
  let store: Store<BookBindingState, Never> = .init(initialState: .init())
  
  init() {
  }
  
  var body: some View {
    StoreReader(store) { $state in      
      Counter(value: $state.value)
    }
  }
  
  struct Counter: View {
    
    @Binding var value: Int
    
    var body: some View {
      VStack {
        Text("\(value)")
        Button {
          value += 1
        } label: {
          Text("Increment")
        }
      }
    }
  }
  
}

@Tracking
struct BookBindingState {
  
  var value: Int = 0
  
}

#Preview("Binding Reading") {
  BookBindingUsingReading()
}

#Preview("Binding StoreReader") {
  BookBindingUsingStoreReader()
}
