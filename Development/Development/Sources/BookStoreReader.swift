import SwiftUI
import Verge

struct StoreReaderSolution: View {
  @State var id: Int = 0
  @State var outerValue: Int = 0
  
  init() {
    print("init")
  }
  
  var body: some View {
    VStack {   
      Button("New") {
        id += 1
      }
      Button("Up Outer") {
        outerValue += 1
      }
      Solution(outerValue: outerValue)
        .id(id)
        .padding()
        .background(Color.green)
    }
  }
  
  struct Solution: View {
    let items: [ItemKind] = [
      .first,
      .second,
      .third,
    ]
    
    @StoreObject var store = Store<MyState, Never>(initialState: .init())
    private let outerValue: Int
    
    init(outerValue: Int) {
      self.outerValue = outerValue
    }
    
    var body: some View {
      HStack {
        VStack {
          Text("Using Store holding")
          StoreReader(store) { $state in
            VStack {
              Button("A Up") {
                store.commit {
                  $0.value += 1
                }
              }
              Text("A Value: \(state.value)")
              Text("Outer: \(outerValue)")
              ItemDetail(name: "A", items: items) { item in
                switch item {
                case .first:
                  Button("A.1.a: \(state.a)") {
                    store.commit {
                      $0.a += 1
                    }
                  }
                case .second:
                  Button("A.1.b: \(state.b)") {
                    store.commit {
                      $0.b += 1
                    }
                  }
                case .third:
                  Button("A.1.c: \(state.c)") {
                    store.commit {
                      $0.c += 1
                    }
                  }
                }
              }
              .padding()
              .background(Color.yellow)
            }
          }
        }
        Passed(store: store)
      }
    }
  }
  
  struct Passed: View {
    let items: [ItemKind] = [
      .first,
      .second,
      .third,
    ]
    
    private let store: Store<MyState, Never>
    
    init(store: Store<MyState, Never>) {
      self.store = store
    }
    
    var body: some View {
      VStack {
        Text("Using Store passed")
        StoreReader(store) { $state in
          VStack {
            Button("B Up") {
              store.commit {
                $0.value += 1
              }
            }
            Text("B Value: \(state.value)")
            ItemDetail(name: "B", items: items) { item in
              switch item {
              case .first:
                Button("B.1.a: \(state.a)") {
                  store.commit {
                    $0.a += 1
                  }
                }
              case .second:
                Button("B.1.b: \(state.b)") {
                  store.commit {
                    $0.b += 1
                  }
                }
              case .third:
                Button("B.1.c: \(state.c)") {
                  store.commit {
                    $0.c += 1
                  }
                }
              }
            }
            .padding()
            .background(Color.yellow)
          }
        }
      }
    }
  }
}


#Preview("Reading solution") {
  StoreReaderSolution()
}
