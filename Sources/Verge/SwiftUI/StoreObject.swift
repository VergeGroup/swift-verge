import SwiftUI

/**
 A property wrapper that instantiates a `Store` for the view lifecycle.

 This property wrapper is designed to manage a `Store` object for the view lifecycle without making the view reactive to `Store` changes, which is the behavior of `@StateObject` with `ObservableObject`. This is because `Store` updates can be handled through `StoreReader`, and it's often undesirable to have the entire view refreshed whenever the `Store` updates.

 - Note: The `Store` is a type that conforms to `StoreDriverType`.

 - Warning: This property wrapper should only be used for store objects that are expected to have a lifetime matching the lifetime of the view.
 */
@available(iOS 14, watchOS 7.0, tvOS 14, *)
@MainActor
@propertyWrapper
public struct StoreObject<Store: StoreDriverType>: DynamicProperty {

  @StateObject private var backing: Wrapper

  /// The current value of the store object.
  public var wrappedValue: Store {
    self.backing.object
  }

  /// Creates a new store object.
  ///
  /// - Parameter thunk: A closure that creates the initial store.
  public init(wrappedValue thunk: @autoclosure @escaping () -> Store) {
    self._backing = .init(wrappedValue: .init(object: thunk()))
  }

  /// A wrapper for the `Store` that serves as a bridge to `ObservableObject`.
  private final class Wrapper: ObservableObject {
    let object: Store

    init(object: Store) {
      self.object = object
    }
  }
}

#if DEBUG

@available(iOS 14, watchOS 7.0, tvOS 14, *)
enum Preview_StoreObject: PreviewProvider {

  static var previews: some View {

    Group {
      Container()
    }

  }

  struct Container: View {

    @State var count = 0

    var body: some View {

      VStack {
        Button("Reset") {
          count += 1
        }
        Child()
          .id(count)
      }

    }

  }

  struct Child: View {

    @StoreObject var store: ViewModel = .init()

    var body: some View {
      let _ = print("render")
      VStack {
        Text("here is child")
        StoreReader(store) { $state in
          Text("count: \(state.count)")
          Text(state.count.description)
        }
        Button("up") {
          store.increment()
        }
        Button("up dummy") {
          store.incrementDummy()
        }
      }
      
    }
  }

  final class ViewModel: StoreDriverType {

    @Tracking
    struct State: Equatable {
      var count: Int = 0
      var count_dummy: Int = 0
    }

    let store: Store<State, Never>

    init() {
      self.store = .init(initialState: .init())
      print("Init")
    }

    func increment() {
      commit {
        $0.count += 1
      }
    }

    func incrementDummy() {
      commit {
        $0.count_dummy += 1
      }
    }

    deinit {
      print("deinit")
    }
  }

}

#endif
