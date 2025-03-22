import StateStruct
import SwiftUI

@propertyWrapper
public struct Reading<Driver: StoreDriverType>: @preconcurrency DynamicProperty
where Driver.TargetStore.State: TrackingObject {
  
  private let stateObject: StateObject<Wrapper>
  private let instantiated: Driver?

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

    if let passed = instantiated {
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
    
  public nonisolated init(_ driver: @escaping () -> Driver, label: StaticString? = nil) {
    self.stateObject = .init(wrappedValue: .init(object: driver()))
    self.instantiated = nil
    self.label = label
  }
  
  public nonisolated init(_ driver: Driver, label: StaticString? = nil) {
    self.stateObject = .init(wrappedValue: .init(object: nil))
    self.instantiated = driver
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
}
