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

  @MainActor
  @preconcurrency
  public var wrappedValue: Driver.TargetStore.State {
    guard let value = projectedValue.store.asStore().trackingState(for: id) else {
      fatalError("State is not being tracked")
    }
    return value
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

  /// A trigger to update owning view
  @State private var version: Int64 = 0

  /// Recreated each time the view identity updates.
  @Namespace private var id
  
  private let label: StaticString?
    
  /**
   Creates a new instance of the model object only once during the
   lifetime of the container that declares
   */
  public nonisolated init(
    label: StaticString? = nil,
    _ driver: @escaping () -> Driver   
  ) {
    self.stateObject = .init(wrappedValue: .init(object: driver()))
    self.instantiated = nil
    self.label = label
  }
  
  /**
   Passing already owned by someone else and uses it.
   */
  public nonisolated init(
    label: StaticString? = nil,
    mode: ReferencingType = .strong,
    _ driver: Driver
  ) {
    self.stateObject = .init(wrappedValue: .init(object: nil))
    self.instantiated = .init(mode: mode, object: driver)
    self.label = label
  }
     
  public init(projectedValue: Reading<Driver>) {
    self = projectedValue
  }

  @MainActor
  @preconcurrency
  public mutating func update() {
    // trigger to subscribe
    _ = $version.wrappedValue
    
    let id = self.id

    projectedValue.store.asStore()
      .startTracking(
        for: id,
        label: label,
        onChange: { [v = $version] in
          v.wrappedValue += 1
        }
      )
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

