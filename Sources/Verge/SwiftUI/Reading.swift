import StateStruct
import SwiftUI

@propertyWrapper
public struct Reading<State: TrackingObject>: @preconcurrency DynamicProperty {
  
  private enum Mode {
    case instantiated(any ReadingStoreType<State>)
    case constant(State)
  }
  
  private let stateObject: StateObject<Wrapper>    
  private let mode: Mode?

  @MainActor
  @preconcurrency
  public var wrappedValue: State { 
    
    if let mode {
      switch mode {
      case .instantiated(let store):
        return store.trackingState(for: id)!
      case .constant(let value):
        return value
      }
    } else {
      stateObject.wrappedValue.object!.trackingState(for: id)!
    }
    
    fatalError()
  } 

  @MainActor
  @preconcurrency
  public var projectedValue: Reading<State> {
    self
  }

  /// A trigger to update owning view
  @SwiftUI.State private var version: Int64 = 0

  /// Recreated each time the view identity updates.
  @Namespace private var id
  
  private var token: _Token?

  public nonisolated init<Driver: StoreDriverType>(wrappedValue: @escaping () -> Driver)
  where State == Driver.TargetStore.State,
    Driver.Scope == Driver.TargetStore.State  ,
  Driver.TargetStore: ReadingStoreType
  
  {
    self.stateObject = .init(wrappedValue: .init(object: wrappedValue().store))
    self.mode = nil
  }

  public nonisolated init<Store: ReadingStoreType>(wrappedValue: @escaping () -> Store) where Store.State == State {
    self.stateObject = .init(wrappedValue: .init(object: wrappedValue()))
    self.mode = nil
  }
  
  public nonisolated init<Driver: StoreDriverType>(wrappedValue: Driver)
  where
  State == Driver.TargetStore.State,
  Driver.Scope == Driver.TargetStore.State  ,
  Driver.TargetStore: ReadingStoreType
  {
    self.stateObject = .init(wrappedValue: .init(object: nil))
    self.mode = .instantiated(wrappedValue.store)
  }
  
  public nonisolated init<Store: ReadingStoreType>(wrappedValue: Store) where Store.State == State {

    self.stateObject = .init(wrappedValue: .init(object: nil))
    self.mode = .instantiated(wrappedValue)        
  }
  
  public nonisolated init(constant: State) {
    self.stateObject = .init(wrappedValue: .init(object: nil))
    self.mode = .constant(constant)    
  }

  @MainActor
  @preconcurrency
  public mutating func update() {
    // trigger to subscribe
    _ = $version.wrappedValue
    
    let id = self.id
    
    if let mode {
      switch mode {
      case .instantiated(let store):
        return store.startTracking(
          for: id,
          onChange: { [v = $version] in
            v.wrappedValue += 1
          })
      case .constant(let value):
        break
      }
    } else {
      stateObject.wrappedValue.object!.startTracking(
        for: id,
        onChange: { [v = $version] in
          v.wrappedValue += 1
        })
    }
 
  }
  
  /// A wrapper for the `Store` that serves as a bridge to `ObservableObject`.
  private final class Wrapper: ObservableObject {
    
    let object: (any ReadingStoreType<State>)?
    
    init(object: (any ReadingStoreType<State>)?) {
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
