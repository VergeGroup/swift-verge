import Verge
import SwiftUI

struct BookReading: View {
  
  var body: some View {
    ReadingSolution()
  }
  
}

@Tracking
struct MyState {
  
  var value: Int = 0
  
  var a: Int = 0
  var b: Int = 0
  var c: Int = 0
}

extension Store where State == MyState {
  
  func backgroundUpdate() {
    Task {
      await self.backgroundCommit { 
        $0.value += 1
        $0.a += 1
        $0.b += 1
        $0.c += 1      
      }
    }
  }
  
}

enum ItemKind: Identifiable {
  case first
  case second
  case third
  var id: String {
    switch self {
    case .first: return "1"
    case .second: return "2"
    case .third: return "3"
    }
  }
}

struct ItemDetail<Item: Identifiable, Content: View>: View {
  
  let items: [Item]
  let content: (Item) -> Content
  
  @State var selectedItem: Item?
  private let name: String
  
  init(
    name: String,
    items: [Item],
    @ViewBuilder content: @escaping (Item) -> Content
  ) {
    self.name = name
    self.items = items
    self.content = content    
  }
  
  var body: some View {
    VStack {
      ForEach(items) { item in
        Button("\(name).\(item.id)") {
          selectedItem = item
        }          
      }
            
      if let item = selectedItem {
        content(item)
          .padding()
          .background(Color.orange)
      }
    }
  }
  
}

private struct ReadingSolution: View {
  
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
    
    @Reading<Store<MyState, Never>> var state: MyState
    
    private let outerValue: Int
    
    init(outerValue: Int) {
      self._state = .init(
        label: "A", { 
          Store<_, Never>.init(initialState: MyState())
        }
      )
      self.outerValue = outerValue
    }
    
    var body: some View {
      HStack {
        VStack {
          Text("Using Store holding")
          Button("async up") {
            $state.backgroundUpdate()
          }
          Button("A Up") {
            $state.commit {
              $0.value += 1
            }
          }
          Text("A Value: \(state.value)")
          Text("Outer: \(outerValue)")
          ItemDetail(name: "A", items: items) { item in
            switch item {
            case .first:
              Button.init("A.1.a: \(state.a)") {             
                $state.commit {
                  $0.a += 1
                }
              }
            case .second:
              Button.init("A.1.b: \(state.b)") {             
                $state.commit {
                  $0.b += 1
                }
              }        
            case .third:
              Button.init("A.1.c: \(state.c)") {             
                $state.commit {
                  $0.c += 1
                }
              }              
            }
            
          }
          .padding()
          .background(Color.yellow)
        }
        Passed(store: $state)
      }
    }
  }
  
  struct Passed: View {
    
    let items: [ItemKind] = [
      .first,
      .second,
      .third,
    ]
    
    @Reading<Store<MyState, Never>> var state: MyState
    
    init(
      store: Store<MyState, Never>
    ) {
      self._state = .init(label: "B", store)
    }
    
    var body: some View {
      VStack {
        Text("Using Store passed")
        Button("B Up") {
          $state.commit {
            $0.value += 1
          }
        }
        Text("B Value: \(state.value)")
        ItemDetail(name: "B",items: items) { item in
          switch item {
          case .first:
            Button.init("B.1.a: \(state.a)") {             
              $state.commit {
                $0.a += 1
              }
            }
          case .second:
            Button.init("B.1.b: \(state.b)") {             
              $state.commit {
                $0.b += 1
              }
            }        
          case .third:
            Button.init("B.1.c: \(state.c)") {             
              $state.commit {
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

struct PassedContainer: View {
  
  private let store: Store<MyState, Never> = .init(initialState: MyState())
  @State var count: Int = 0
  
  var body: some View {
    VStack {
      Button("Outer Up \(count)") {
        count += 1
      }
      ReadingSolution.Passed(store: store)
    }
  }
  
}

#Preview("Reading solution") {
  ReadingSolution()
}

#Preview("Passed solution") {
  PassedContainer()
}
