import StateStruct
import SwiftUI

@propertyWrapper
public struct Reading<Driver: StoreDriverType>: @preconcurrency DynamicProperty
where Driver.TargetStore.State: TrackingObject {

  public enum ReferencingType {
    case strong
    case weak
  }

  private let stateObject: StateObject<Wrapper>
  private let instantiated: RetainBox?

  @StateObject private var coordinator = Coordinator()

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
  public var projectedValue: Driver {

    if let passed = instantiated?.value {
      return passed
    }

    return stateObject.wrappedValue.object!

    fatalError()
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
    self.instantiated = nil
    self.label = label
    self.file = file
    self.line = line
  }

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
    self.stateObject = .init(wrappedValue: .init(object: nil))
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

    coordinator.startTracking(using: projectedValue)
  }

  public final class Coordinator: ObservableObject {

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
      modification: InoutRef<Driver.TargetStore.State>.Modification?,
      publisher: sending ObjectWillChangePublisher
    ) {

      switch modification {
      case .graph(let writeGraph):

        guard let readGraph else {
          return
        }
        
        Log.reading.debug("Reading: \(readGraph.prettyPrint())")

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

  /// A wrapper for the `Store` that serves as a bridge to `ObservableObject`.
  private final class Wrapper: ObservableObject {

    let object: Driver?

    init(object: Driver?) {
      self.object = object
    }
  }

  private final class RetainBox {

    weak var value: Driver?
    let mode: ReferencingType

    init(mode: ReferencingType, object: Driver) {
      switch mode {
      case .strong:
        Unmanaged.passUnretained(object).retain()
      case .weak:
        break
      }
      self.value = object
      self.mode = mode
    }

    deinit {
      switch mode {
      case .strong:
        Unmanaged.passUnretained(value!).release()
      case .weak:
        break
      }
    }
  }

}
