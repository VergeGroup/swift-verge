import Combine
import Foundation
import SwiftUI

/**
 For SwiftUI - A View that reads a ``Store`` including ``Derived``.
 It updates its content when reading properties have been updated.

 Technically, it observes what properties used in making content closure as KeyPath.
 ``ReadTracker`` can get those using dynamicMemberLookup.
 Store emits events of updated state, StoreReader filters them with current using KeyPaths.
 Therefore functions of the state are not available in this situation.
 */
@available(iOS 14, watchOS 7.0, tvOS 14, *)
public struct StoreReader<StateType: Equatable, Content: View>: View {

  private let backing: _StoreReader<StateType, Content>
  private let identifier: ObjectIdentifier

  private init(
    identifier: ObjectIdentifier,
    node: @escaping @MainActor () -> StoreReaderComponents<StateType>.Node,
    content: @escaping @MainActor (inout StoreReaderComponents<StateType>.StateProxy) -> Content
  ) {
    self.identifier = identifier
    self.backing = _StoreReader(node: node, content: content)
  }

  public var body: some View {
    backing
      .id(identifier)
  }

  /// Initialize from `Store`
  ///
  /// - Parameters:
  ///   - store:
  ///   - content:
  public init<Driver: StoreDriverType>(
    debug: Bool = false,
    _ store: Driver,
    @ViewBuilder content: @escaping @MainActor (inout StoreReaderComponents<StateType>.StateProxy) -> Content
  ) where StateType == Driver.TargetStore.State {

    let store = store.store.asStore()

    self.init(
      identifier: ObjectIdentifier(store),
      node: {
        return .init(
          store: store,
          retainValues: [],
          debug: debug
        )
      },
      content: content
    )

  }

}

@available(iOS 14, watchOS 7.0, tvOS 14, *)
private struct _StoreReader<StateType: Equatable, Content: View>: View {

  @StateObject private var node: StoreReaderComponents<StateType>.Node

  private let content: @MainActor (inout StoreReaderComponents<StateType>.StateProxy) -> Content
  
  init(
    node: @escaping @MainActor () -> StoreReaderComponents<StateType>.Node,
    content: @escaping @MainActor (inout StoreReaderComponents<StateType>.StateProxy) -> Content
  ) {
    self._node = .init(wrappedValue: node())
    self.content = content
  }
  
  public var body: some View {
    node.makeContent(content)
  }

}

public enum StoreReaderComponents<StateType: Equatable> {

  // Proxy
  @MainActor
  @dynamicMemberLookup
  public struct StateProxy {
    
    typealias Detectors = [PartialKeyPath<StateType> : (Changes<StateType>) -> Bool]
    
    private let wrapped: StateType
    
    /// wrapped value itself
    public var primitive: StateType {
      mutating get {
        self[dynamicMember: \.self]
      }
    }
    
    private(set) var detectors: Detectors = [:]
    private weak var source: (any StoreDriverType<StateType>)?
    
    init(wrapped: StateType, source: (any StoreDriverType<StateType>)?) {
      self.wrapped = wrapped
      self.source = source
    }
    
    /**
     ✅ Equatable version
     */
    public subscript<T>(dynamicMember keyPath: KeyPath<StateType, T>) -> T where T : Equatable {
      mutating get {
        
        if detectors[keyPath as PartialKeyPath<StateType>] == nil {
          
          let maybeChanged: (Changes<StateType>) -> Bool = { changes in
            
            switch changes.modification {
            case .determinate(let keyPaths):
              
              /// modified but maybe value not changed.
              let mayHasChanges = keyPaths.contains(keyPath)
              
              if mayHasChanges {
                return true
              }
              
              return changes.hasChanges({ $0[keyPath: keyPath] })
              
            case .indeterminate:
              return true
            case nil:
              return changes.hasChanges({ $0[keyPath: keyPath] })
            }
            
          }
          
          detectors[keyPath] = maybeChanged
        }
        
        return wrapped[keyPath: keyPath]
      }
    }

    /**
     ⚠️ Not equatable version.
     */
    public subscript<T>(dynamicMember keyPath: KeyPath<StateType, T>) -> T {
      mutating get {
         
        if detectors[keyPath as PartialKeyPath<StateType>] == nil {
          
          let maybeChanged: (Changes<StateType>) -> Bool = { changes in
            
            return true
            
          }
          
          detectors[keyPath] = maybeChanged
        }
        
        return wrapped[keyPath: keyPath]
      }
            
    }

    /**
     ✅ Equatable version
     Make SwiftUI.Binding
     */
    public mutating func binding<T: Equatable>(_ keyPath: WritableKeyPath<StateType, T>) -> SwiftUI.Binding<T> {
      return .init { [value = self[dynamicMember: keyPath]] in
        return value
      } set: { [weak source = self.source] newValue, _ in
        source?.commit { state in
          state[keyPath: keyPath] = newValue
        }
      }
    }

    /**
     ⚠️ Not equatable version.
     Make SwiftUI.Binding
     */
    public mutating func binding<T>(_ keyPath: WritableKeyPath<StateType, T>) -> SwiftUI.Binding<T> {
      return .init { [value = self[dynamicMember: keyPath]] in
        return value
      } set: { [weak source = self.source] newValue, _ in
        source?.commit { state in
          state[keyPath: keyPath] = newValue
        }
      }
    }

  }
  
  @MainActor
  public final class Node: ObservableObject {
    
    nonisolated public var objectWillChange: ObservableObjectPublisher {
      _publisher
    }
    
    /// nil means not loaded first yet
    private var detectors: StateProxy.Detectors?

    private nonisolated let _publisher: ObservableObjectPublisher = .init()
    private var cancellable: StoreSubscription?
    private let retainValues: [AnyObject]
    
    private var currentValue: Changes<StateType>
    
    private let debug: Bool

    private weak var source: (any StoreDriverType<StateType>)?

    init(
      store: some StoreDriverType<StateType>,
      retainValues: [AnyObject],
      debug: Bool = false
    ) {

      self.source = store
      self.debug = debug
      self.retainValues = retainValues
      
      self.currentValue = store.state
      
      cancellable = store.sinkState(queue: .mainIsolated()) { [weak self] state in
        
        guard let self else { return }
        
        /// retain the latest one
        self.currentValue = state
        
        /// consider to trigger update
        let shouldUpdate: Bool = {
          
          guard let detectors = self.detectors else {
            // through this filter to make content as a first time.
            return true
          }
          
          let _shouldUpdate = detectors.contains {
            $0.value(state)
          }
                    
          return _shouldUpdate
          
        }()
        
        if shouldUpdate {
          self._publisher.send()
        }
      }
      
#if DEBUG
      if debug {
        Log.debug(.storeReader, "[Node] init \(self)")
      }
#endif
      
    }
    
    deinit {
      
#if DEBUG
      if debug {
        Log.debug(.storeReader, "[Node] deinit \(self)")
      }
#endif
    }
    
    func makeContent<Content: View>(@ViewBuilder _ make: @MainActor (inout StateProxy) -> Content)
    -> Content
    {

      var tracker = StateProxy(wrapped: currentValue.primitive, source: source)
      let content = make(&tracker)
            
      detectors = tracker.detectors
      
      return content
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

  final class ViewModel: StoreComponentType {

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
