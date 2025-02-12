import Combine
import Foundation
import SwiftUI
import StateStruct

/**
 For SwiftUI - A View that reads a ``Store`` including ``Derived``.
 It updates its content when reading properties have been updated.

 Technically, it observes what properties used in making content closure as KeyPath.
 ``ReadTracker`` can get those using dynamicMemberLookup.
 Store emits events of updated state, StoreReader filters them with current using KeyPaths.
 Therefore functions of the state are not available in this situation.
 */
@available(iOS 14, watchOS 7.0, tvOS 14, *)
public struct StoreReader<State: TrackingObject, Activity: Sendable, Content: View>: View {
    
  private let store: Store<State, Activity>
  
  @SwiftUI.State private var version: UInt64 = 0

  private let file: StaticString
  private let line: UInt

  private let content: @MainActor (State) -> Content
  
  /// Initialize from `Store`
  ///
  /// - Parameters:
  ///   - store:
  ///   - content:
  public init<Driver: StoreDriverType>(
    file: StaticString = #file,
    line: UInt = #line,
    _ store: Driver,
    @ViewBuilder content: @escaping @MainActor (State) -> Content
  ) where State == Driver.TargetStore.State, Activity == Driver.TargetStore.Activity {
    
    let store = store.store.asStore()
    
    self.init(
      file: file,
      line: line,
      store: store,
      content: content
    )
    
  }
  
  private init(
    file: StaticString,
    line: UInt,
    store: Store<State, Activity>,
    content: @escaping @MainActor (State) -> Content
  ) {
    self.file = file
    self.line = line
    self.store = store
    self.content = content
  }
  
  public var body: some View {
    
    // trigger to subscribe
    let _ = $version.wrappedValue
    
    let _content = store.tracking(content, onChange: {    
      ImmediateMainActorTargetQueue.main.execute {
        version &+= 1
      }
    })
    
    _content
  }

}

public enum StoreReaderComponents<StateType: Equatable> {

  // Proxy
  @dynamicMemberLookup
  public struct StateProxy: ~Copyable {

    typealias Detectors = [PartialKeyPath<StateType> : (Changes<StateType>) -> Bool]
    
    private let wrapped: ReadonlyBox<StateType>
    
    private(set) var detectors: Detectors = [:]
    private weak var source: (any StoreDriverType<StateType>)?
    
    init(
      wrapped: ReadonlyBox<StateType>,
      source: (any StoreDriverType<StateType>)?
    ) {
      self.wrapped = wrapped
      self.source = source
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<StateType, T>) -> Binding<T> {
      binding(keyPath)
    }

    public func binding<T>(_ keyPath: WritableKeyPath<StateType, T>) -> SwiftUI.Binding<T> {
      return .init { [value = self.wrapped.value[keyPath: keyPath]] in
        return value
      } set: { [weak source = self.source, keyPath] newValue, _ in
        source?.commit { [keyPath] state in
          state[keyPath: keyPath] = newValue
        }
      }
    }

  }
  
}

#if DEBUG

@available(iOS 14, watchOS 7.0, tvOS 14, *)
enum Preview_StoreReader: PreviewProvider {

  static var previews: some View {

    Group {
      Content()
    }

  }

  struct Content: View {

    @StoreObject var viewModel_1: ViewModel = .init()
    @StoreObject var viewModel_2: ViewModel = .init()

    @State var flag = false

    var body: some View {

      VStack {

        let store = flag ? viewModel_1 : viewModel_2

        StoreReader(store) { state in
          Text(state.count.description)
        }

        Button("up") {
          store.increment()
        }

        Button("swap") {
          flag.toggle()
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
