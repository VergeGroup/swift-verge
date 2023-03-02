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
public struct StoreReader<StateType: Equatable, Content: View>: View {
  
  @_StateObject private var node: StoreReaderComponents<StateType>.Node
  
  public typealias ContentMaker = @MainActor (inout StoreReaderComponents<StateType>.ReadTracker) -> Content
  
  private let content: ContentMaker
  
  private init(
    node: @autoclosure @escaping () -> StoreReaderComponents<StateType>.Node,
    content: @escaping ContentMaker
  ) {
    self._node = .init(wrappedValue: node())
    self.content = content
  }
  
  public var body: some View {
    node.makeContent(content)
  }
  
  /// Initialize from `Store`
  ///
  /// - Parameters:
  ///   - store:
  ///   - content:
  public init<Store: StoreType>(
    debug: Bool = false,
    _ store: Store,
    @ViewBuilder content: @escaping ContentMaker
  ) where StateType == Store.State {
    
    let store = store.asStore()
    
    self.init(node: .init(store: store, retainValues: [], debug: debug), content: content)
    
  }

}

public enum StoreReaderComponents<StateType: Equatable> {
  
  @MainActor
  @dynamicMemberLookup
  public struct ReadTracker {
    
    typealias Detectors = [PartialKeyPath<StateType> : (Changes<StateType>) -> Bool]
    
    private let wrapped: StateType
    
    /// wrapped value itself
    public var primitive: StateType {
      mutating get {
        self[dynamicMember: \.self]
      }
    }
    
    private(set) var detectors: Detectors = [:]
    
    init(wrapped: StateType) {
      self.wrapped = wrapped
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
              return true
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
       
  }
  
  @MainActor
  public final class Node: ObservableObject {
    
    nonisolated public var objectWillChange: ObservableObjectPublisher {
      _publisher
    }
    
    /// nil means not loaded first yet
    private var detectors: ReadTracker.Detectors?
    
    private let _publisher: ObservableObjectPublisher = .init()
    private var cancellable: VergeAnyCancellable?
    private let retainValues: [AnyObject]
    
    private var currentValue: Changes<StateType>
    
    private let debug: Bool
    
    init<Activity>(
      store: Store<StateType, Activity>,
      retainValues: [AnyObject],
      debug: Bool = false
    ) {
      
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
    
    func makeContent<Content: View>(@ViewBuilder _ make: @MainActor (inout ReadTracker) -> Content)
    -> Content
    {
      var tracker = ReadTracker(wrapped: currentValue.primitive)
      let content = make(&tracker)
            
      detectors = tracker.detectors
      
      return content
    }
    
  }
}

@_spi(Internal)
@available(iOS, deprecated: 14.0)
@propertyWrapper
public struct _StateObject<Wrapped>: DynamicProperty where Wrapped: ObservableObject {
  
  /// keep internal due to vanishing symbol in -O compilation.
  @_spi(Internal)
  public final class Wrapper: ObservableObject {
    
    var value: Wrapped? {
      didSet {
        guard let value else { return }
        cancellable = value.objectWillChange
          .sink { [weak self] _ in
            self?.objectWillChange.send()
          }
      }
    }
    
    private var cancellable: AnyCancellable?
  }
  
  public var wrappedValue: Wrapped {
    if let object = state.value {
      return object
    } else {
      let object = thunk()
      state.value = object
      return object
    }
  }
  
  public var projectedValue: ObservedObject<Wrapped>.Wrapper {
    return ObservedObject(wrappedValue: wrappedValue).projectedValue
  }
  
  @State private var state = Wrapper()
  @ObservedObject private var observedObject = Wrapper()
  
  private let thunk: () -> Wrapped
  
  public init(wrappedValue thunk: @autoclosure @escaping () -> Wrapped) {
    self.thunk = thunk
  }
  
  public mutating func update() {
    if state.value == nil {
      state.value = thunk()
    }
    if observedObject.value !== state.value {
      observedObject.value = state.value
    }
  }
}
