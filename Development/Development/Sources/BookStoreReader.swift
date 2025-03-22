import SwiftUI
import Verge

struct StoreReaderProblem: View {

  @State private var items: [ItemKind] = [
    .first,
    .second,
    .third,
  ]

  let store = Store<MyState, Never>(initialState: .init())

  init() {
    print("init")
  }

  var body: some View {
    StoreReader(store) { $state in
      Text("Value: \(state.value)")
      ItemDetail(name: "A", items: items) { /* escaping closure */ item in
        switch item {
        case .first:
          Text("A : \(state.a)")
            .onTapGesture {
              store.commit {
                $0.a += 1
              }
            }
        case .second:
          Text("B : \(state.b)")
            .onTapGesture {
              store.commit {
                $0.b += 1
              }
            }
        case .third:
          Text("C : \(state.c)")
            .onTapGesture {
              store.commit {
                $0.c += 1
              }
            }
        }
      }
    }
  }

}

#Preview {
  StoreReaderProblem()
}
