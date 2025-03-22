import StateStruct
import SwiftUI

@propertyWrapper
public struct Reading<Store: StoreType>: @preconcurrency DynamicProperty
where Store.State: TrackingObject {
  
  private let stateObject: StateObject<Wrapper>
  private let instantiated: Store?

  @MainActor
  @preconcurrency
  public var wrappedValue: Store {    

    if let passed = instantiated {
      return passed
    }

    return stateObject.wrappedValue.object!
        
    fatalError()
  }

  @MainActor
  @preconcurrency
  public var projectedValue: Store.State {
    guard let value = wrappedValue.asStore().trackingState(for: id) else {
      fatalError("State is not being tracked")
    }
    return value
  }

  /// A trigger to update owning view
  @State var version: Int64 = 0

  /// Recreated each time the view identity updates.
  @Namespace private var id
  
  private var token: _Token?

  public nonisolated init<Driver: StoreDriverType>(wrappedValue: @escaping () -> Driver)
  where
    Store == Driver.TargetStore,
    Driver.Scope == Driver.TargetStore.State
  {
    self.stateObject = .init(wrappedValue: .init(object: wrappedValue().store))
    self.instantiated = nil
  }

  public nonisolated init(wrappedValue: @escaping () -> Store) {
    self.stateObject = .init(wrappedValue: .init(object: wrappedValue()))
    self.instantiated = nil
  }
  
  public nonisolated init<Driver: StoreDriverType>(wrappedValue: Driver)
  where
  Store == Driver.TargetStore,
  Driver.Scope == Driver.TargetStore.State
  {
    self.stateObject = .init(wrappedValue: .init(object: nil))
    self.instantiated = wrappedValue.store
  }
  
  public nonisolated init(wrappedValue: Store) {
    self.stateObject = .init(wrappedValue: .init(object: nil))
    self.instantiated = wrappedValue
  }

  @MainActor
  @preconcurrency
  public mutating func update() {
    // trigger to subscribe
    _ = $version.wrappedValue
    
    let id = self.id

    wrappedValue.asStore().startTracking(
      for: id,
      onChange: { [v = $version] in
        v.wrappedValue += 1
      })
  }
  
  /// A wrapper for the `Store` that serves as a bridge to `ObservableObject`.
  private final class Wrapper: ObservableObject {
    
    let object: Store?
    
    init(object: Store?) {
      self.object = object
    }
  }
}

private final class _Token {
  
  private let onDeinit: @Sendable () -> Void
  
  init(onDeinit: @Sendable @escaping () -> Void) {
    self.onDeinit = onDeinit
  }
  
  deinit {
    onDeinit()
  }
}
