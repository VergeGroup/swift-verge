import StateStruct
import SwiftUI

@propertyWrapper
public struct Reading<Store: StoreType>: DynamicProperty
where Store.State: TrackingObject {

  public var wrappedValue: Store

  public var projectedValue: Store.State {
    guard let value = wrappedValue.asStore().trackingState(for: id) else {
      fatalError("State is not being tracked")
    }
    return value
  }

  @State var version: Int64 = 0

  @Namespace private var id

  public init<Driver: StoreDriverType>(wrappedValue: Driver)
  where
    Store == Driver.TargetStore,
    Driver.Scope == Driver.TargetStore.State
  {
    self.wrappedValue = wrappedValue.store
  }

  public init(wrappedValue: Store) {
    self.wrappedValue = wrappedValue
  }

  public func update() {
    // trigger to subscribe
    _ = $version.wrappedValue

    wrappedValue.asStore().resetTracking(
      for: id,
      onChange: { [v = $version] in
        v.wrappedValue += 1
      })
  }
}

#if DEBUG

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
          Text(String(describing: item))
            .padding()
            .background(Color.blue)
            .onTapGesture {
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

    init() {
      print("init")
    }

    var body: some View {
      VStack {        
        Solution()
          .id(id)

        Button("New") {
          id += 1
        }
      }
    }

    private struct Solution: View {

      @State private var items: [ItemKind] = [
        .first,
        .second,
        .third,
      ]

      @Reading var store: Store<MyState, Never> = .init(initialState: .init())

      init() {
        print("init")
      }

      var body: some View {

        Text("Value: \($store.value)")
        ItemDetail(items: items) { item in
          switch item {
          case .first:
            Text("A : \($store.a)")
              .onTapGesture {
                print("Tapped \(store.state.a)")
                store.commit {
                  $0.a += 1
                }
              }
          case .second:
            Text("B : \($store.b)")
              .onTapGesture {
                store.commit {
                  $0.b += 1
                }
              }
          case .third:
            Text("C : \($store.c)")
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

  private struct StoreReaderProblem: View {

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
      StoreReader(store) { state in
        Text("Value: \(state.value)")
        ItemDetail(items: items) { item in
          switch item {
          case .first:
            Text("A : \(state.a)")
              .onTapGesture {
                print("Tapped \(store.state.a)")
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

  #Preview("Reading solution") {
    ReadingSolution()
  }

  #Preview("StoreReaderProblem") {

    StoreReaderProblem()

  }

#endif
