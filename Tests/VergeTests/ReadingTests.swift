import ViewInspe
import Testing
import Verge
import SwiftUI

@Tracking
private struct MyState {
  
  var value: Int = 0
  
  var a: Int = 0
  var b: Int = 0
  var c: Int = 0
}

enum ItemKind: Identifiable {
  case first
  case second
  case third
  var id: String {
    switch self {
    case .first: return "first"
    case .second: return "second"
    case .third: return "third"
    }
  }
}

struct ItemDetail<Item: Identifiable, Content: View>: View {
  
  let items: [Item]
  let content: (Item) -> Content
  
  @State var selectedItem: Item?
  
  init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
    self.items = items
    self.content = content
    
  }
  
  var body: some View {
    VStack {
      ForEach(items) { item in
        Button(String(describing: item)) {
          selectedItem = item
        }          
      }
      
      if let item = selectedItem {
        content(item)
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
  
  private struct Solution: View {
    
    let items: [ItemKind] = [
      .first,
      .second,
      .third,
    ]
    
    @Reading var store: Store<MyState, Never>
    
    private let outerValue: Int
    
    init(outerValue: Int) {
      self._store = .init(wrappedValue: { 
        Store<_, Never>.init(initialState: MyState())
      })
      self.outerValue = outerValue
    }
    
    var body: some View {
      HStack {
        VStack {
          Text("Using Store holding")
          Button("Up") {
            store.commit {
              $0.value += 1
            }
          }
          Text("Value: \($store.value)")
          Text("Outer: \(outerValue)")
          ItemDetail(items: items) { item in
            switch item {
            case .first:
              Button.init("A : \($store.a)") {             
                store.commit {
                  $0.a += 1
                }
              }
            case .second:
              Button.init("B : \($store.b)") {             
                store.commit {
                  $0.b += 1
                }
              }        
            case .third:
              Button.init("C : \($store.c)") {             
                store.commit {
                  $0.c += 1
                }
              }              
            }
            
          }
          .padding()
          .background(Color.yellow)
        }
        Passed(store: store)
      }
    }
  }
  
  private struct Passed: View {
    
    let items: [ItemKind] = [
      .first,
      .second,
      .third,
    ]
    
    @Reading var store: Store<MyState, Never>
    
    init(store: Store<MyState, Never>) {
      self._store = .init(wrappedValue: store)
    }
    
    var body: some View {
      VStack {
        Text("Using Store passed")
        Button("Up") {
          store.commit {
            $0.value += 1
          }
        }
        Text("Value: \($store.value)")
        ItemDetail(items: items) { item in
          switch item {
          case .first:
            Button.init("A : \($store.a)") {             
              store.commit {
                $0.a += 1
              }
            }
          case .second:
            Button.init("B : \($store.b)") {             
              store.commit {
                $0.b += 1
              }
            }        
          case .third:
            Button.init("C : \($store.c)") {             
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
