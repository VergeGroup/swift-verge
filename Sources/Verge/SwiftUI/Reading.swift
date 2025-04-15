import StateStruct
import SwiftUI

public protocol ReadingType: DynamicProperty {
  
  associatedtype Driver: StoreDriverType where Driver.TargetStore.State : TrackingObject 
  
  @MainActor
  @preconcurrency
  var wrappedValue: Driver.TargetStore.State { get }
  
  @MainActor
  @preconcurrency
  var driver: Driver { get }
}

/**
  A property wrapper that provides a state from a given store.
  It tracks which properties are accessed and updates the view when those properties change.
 */
@propertyWrapper
public struct Reading<Driver: StoreDriverType>: ReadingType, @preconcurrency DynamicProperty
where Driver.TargetStore.State: TrackingObject {

  public enum ReferencingType {
    case strong
    case unowned
  }

  private let instantiated: RetainBox

  @StateObject private var coordinator = Coordinator<Driver>()

  @MainActor
  @preconcurrency
  public var wrappedValue: Driver.TargetStore.State {

    guard let state = coordinator.currentState() else {
      fatalError("State is not being tracked")
    }
    return state
  }

  @MainActor
  @preconcurrency
  public var projectedValue: BindableReading<Self> {
    return .init(reading: self)
  }
  
  @MainActor
  @preconcurrency
  public var driver: Driver {
    instantiated.value
  }

  private let file: StaticString
  private let line: UInt
  private let label: StaticString?

  /**
   Passing already owned by someone else and uses it.
   */
  public nonisolated init(
    file: StaticString = #file,
    line: UInt = #line,
    label: StaticString? = nil,
    mode: ReferencingType = .strong,
    _ driver: Driver
  ) {
    self.instantiated = .init(mode: mode, object: driver)
    self.label = label
    self.file = file
    self.line = line
  }

  public init(projectedValue: Reading<Driver>) {
    self = projectedValue
  }

  @MainActor
  @preconcurrency
  public mutating func update() {

    coordinator.startTracking(using: driver)
  }

  private final class RetainBox: Equatable {
    
    static func == (lhs: RetainBox, rhs: RetainBox) -> Bool {
      return lhs === rhs
    }

    unowned let value: Driver
    let mode: ReferencingType

    init(mode: ReferencingType, object: Driver) {
      switch mode {
      case .strong:
        Unmanaged.passUnretained(object).retain()
      case .unowned:
        break
      }
      self.value = object
      self.mode = mode
    }

    deinit {
      switch mode {
      case .strong:
        Unmanaged.passUnretained(value).release()
      case .unowned:
        break
      }
    }
  }

}

/**
 A property wrapper that provides a state from a given store.
 It tracks which properties are accessed and updates the view when those properties change.
 Compared to ``Reading``, this property wrapper instantiates a store via a closure and retains it alongside the view.
 */
@propertyWrapper
public struct ReadingObject<Driver: StoreDriverType>: ReadingType, @preconcurrency DynamicProperty
where Driver.TargetStore.State: TrackingObject {

  private let stateObject: StateObject<Wrapper>
  
  @StateObject private var coordinator = Coordinator<Driver>()
  
  @MainActor
  @preconcurrency
  public var wrappedValue: Driver.TargetStore.State {
    
    guard let state = coordinator.currentState() else {
      fatalError("State is not being tracked")
    }
    return state
  }
  
  @MainActor
  @preconcurrency
  public var projectedValue: BindableReading<Self> {
    return .init(reading: self)
  }
  
  @MainActor
  @preconcurrency
  public var driver: Driver {        
    return stateObject.wrappedValue.object!        
  }
  
  private let file: StaticString
  private let line: UInt
  private let label: StaticString?
  
  /**
   Creates a new instance of the model object only once during the
   lifetime of the container that declares
   */
  public nonisolated init(
    file: StaticString = #file,
    line: UInt = #line,
    label: StaticString? = nil,
    _ driver: @escaping () -> Driver
  ) {
    self.stateObject = .init(wrappedValue: .init(object: driver()))
    self.label = label
    self.file = file
    self.line = line
  }
     
  public init(projectedValue: ReadingObject<Driver>) {
    self = projectedValue
  }
  
  @MainActor
  @preconcurrency
  public mutating func update() {
    
    coordinator.startTracking(using: driver)
  }
  
  /// A wrapper for the `Store` that serves as a bridge to `ObservableObject`.
  private final class Wrapper: ObservableObject, Equatable {
    
    static func == (lhs: Wrapper, rhs: Wrapper) -> Bool {
      return lhs === rhs
    }
    
    let object: Driver?
    
    init(object: Driver?) {
      self.object = object
    }
  }
  
}

private final class Coordinator<Driver: StoreDriverType>: ObservableObject, Equatable where Driver.TargetStore.State: TrackingObject {
  
  public static func == (lhs: Coordinator, rhs: Coordinator) -> Bool {
    return lhs === rhs
  }
  
  private weak var driver: Driver?
  private var _currentState: Driver.TargetStore.State?
  private var _currentStateVersion: UInt64?
  private var subscription: StoreStateSubscription?
  
  init() {
    //      Log.reading.debug("Init Coordinator")
  }
  
  deinit {
    //      Log.reading.debug("Deinit Coordinator")
  }
  
  /*
   func cleanup() {
   subscription?.cancel()
   _currentState = nil
   _currentStateVersion = nil
   driver = nil      
   }
   */
  
  @MainActor
  func startTracking(using driver: Driver) {
    
    setTargetDriver(driver)
    
    let store = driver.store.asStore()
    
    store.lock()
    defer {
      store.unlock()
    }
    
    let trackingState = store.nonatomicValue.primitive.tracked()
    let version = store.nonatomicValue.version
    
    self._currentState = trackingState
    self._currentStateVersion = version
  }
  
  @MainActor
  private func setTargetDriver(_ driver: Driver) {
    
    subscription?.cancel()
    
    self.driver = driver
    
    // pollMainLoop drops modification
    //      subscription = driver.store.asStore().pollMainLoop { [weak self] state in
    //        self?.onUpdateState(state)
    //      }
    
    let _publisher = publisher()
    
    subscription = driver.store.asStore()
      .sinkState { [weak self] state in
        guard let self else {
          return
        }
        Self.onUpdateState(
          readGraph: self._currentState?.trackingResult?.graph,
          modification: state.modification,
          publisher: _publisher
        )
      }
    
  }
  
  @MainActor
  private static func onUpdateState(
    readGraph: PropertyNode?,
    modification: Modification?,
    publisher: sending ObjectWillChangePublisher
  ) {
    
    switch modification {
    case .graph(let writeGraph):
      
      guard let readGraph else {
        return
      }
      
      //        Log.reading.debug("Reading: \(readGraph.prettyPrint())")
      
      let hasChanges = PropertyNode.hasChanges(
        writeGraph: consume writeGraph,
        readGraph: readGraph
      )
      
      guard hasChanges else {
        return
      }
      
    case .indeterminate:
      break
    case nil:
      return
    }
    
    // do
    
    publisher.send()
    //      if Thread.isMainThread {
    //        MainActor.assumeIsolated {
    //          publisher.send()          
    //        }
    //      } else {
    //        DispatchQueue.main.async {
    //          publisher.send()
    //        }
    //      }
    
  }
  
  nonisolated func publisher() -> sending ObjectWillChangePublisher {
    let workaround = { self.objectWillChange }
    let object = workaround()
    return object
  }
  
  func currentState() -> Driver.TargetStore.State? {
    
    guard let driver else {
      return nil
    }
    
    let store = driver.store.asStore()
    
    store.lock()
    defer {
      store.unlock()
    }
    
    guard var _currentState, let _currentStateVersion else {
      return nil
    }
    
    let version = store.nonatomicValue.version
    if _currentStateVersion != version {
      
      guard let ref = _currentState._tracking_context.trackingResultRef else {
        return nil
      }
      
      let latestState = store.nonatomicValue.primitive.tracked(using: ref.result.graph)
      
      self._currentState = latestState
      self._currentStateVersion = version
      
      return latestState
    } else {
      return _currentState
    }
    
  }
  
}


@propertyWrapper
@dynamicMemberLookup
public struct BindableReading<Source: ReadingType> {
  
  public let reading: Source
  
  @MainActor
  @preconcurrency
  public var wrappedValue: Source.Driver.TargetStore.State {
    reading.wrappedValue
  }
  
  public init(reading: Source) {
    self.reading = reading
  }
  
  public var projectedValue: BindableReading<Source> {
    self
  }
  
  public init(projectedValue: BindableReading<Source>) {
    self = projectedValue
  }
  
  @MainActor
  @preconcurrency
  public var driver: Source.Driver {
    reading.driver
  }
  
  @MainActor
  @preconcurrency
  public subscript<T>(dynamicMember keyPath: WritableKeyPath<Source.Driver.Scope, T>) -> Binding<T> {
    binding(keyPath)
  }
  
  @MainActor
  @preconcurrency
  public func binding<T>(_ keyPath: WritableKeyPath<Source.Driver.Scope, T>) -> SwiftUI.Binding<T> {
    return .init { [keyPath = reading.driver.scope.appending(path: keyPath)] in
      return reading.wrappedValue[keyPath: keyPath]
    } set: { [weak driver = reading.driver] newValue, _ in
      driver?.commit { [keyPath] state in
        state[keyPath: keyPath] = newValue
      }
    }
  }
  
  @MainActor
  public func binding<T: Sendable>(_ keyPath: WritableKeyPath<Source.Driver.Scope, T> & Sendable)
  -> SwiftUI.Binding<T>
  {        
    return .init { [keyPath = reading.driver.scope.appending(path: keyPath)] in
      return reading.wrappedValue[keyPath: keyPath]
    } set: { [weak driver = reading.driver] newValue, _ in
      driver?.commit { [keyPath] state in
        state[keyPath: keyPath] = newValue
      }
    }
  }

}
