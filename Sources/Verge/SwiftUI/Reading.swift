import StateStruct
import SwiftUI

@propertyWrapper
public struct Reading<Driver: StoreDriverType>: @preconcurrency DynamicProperty
where Driver.TargetStore.State: TrackingObject {
  
  private let stateObject: StateObject<Wrapper>
  private let instantiated: Driver?

  @MainActor
  @preconcurrency
  public var wrappedValue: Driver {    

    if let passed = instantiated {
      return passed
    }

    return stateObject.wrappedValue.object!
        
    fatalError()
  }

  @MainActor
  @preconcurrency
  public var projectedValue: Driver.TargetStore.State {
    guard let value = wrappedValue.store.asStore().trackingState(for: id) else {
      fatalError("State is not being tracked")
    }
    return value
  }

  /// A trigger to update owning view
  @State private var version: Int64 = 0

  /// Recreated each time the view identity updates.
  @Namespace private var id
  
  public nonisolated init(wrappedValue: @escaping () -> Driver) {
    self.stateObject = .init(wrappedValue: .init(object: wrappedValue()))
    self.instantiated = nil
  }
  
  public nonisolated init(wrappedValue: Driver) {
    self.stateObject = .init(wrappedValue: .init(object: nil))
    self.instantiated = wrappedValue
  }
     
//  public init(projectedValue: Reading<Driver>) {
//    self = projectedValue
//  }

  @MainActor
  @preconcurrency
  public mutating func update() {
    // trigger to subscribe
    _ = $version.wrappedValue
    
    let id = self.id

    wrappedValue.store.asStore().startTracking(
      for: id,
      onChange: { [v = $version] in
        v.wrappedValue += 1
      })
  }
  
  /// A wrapper for the `Store` that serves as a bridge to `ObservableObject`.
  private final class Wrapper: ObservableObject {
    
    let object: Driver?
    
    init(object: Driver?) {
      self.object = object
    }
  }
}
