
import Foundation
import Dispatch
import Verge

private final class SnapshotStorage<Value>: @unchecked Sendable {

  private let queue = DispatchQueue(label: "UnsafeStorage")

  var value: Value {
    queue.sync {
      _value
    }
  }

  private var _value: Value

  init(
    _ value: Value
  ) {
    self._value = value
  }

  func setValue(_ value: Value) {
    queue.async { [self] in
      _value = value
    }
  }

}

//public final class AsyncStorageSubscription: Hashable {
//
//  public static func == (lhs: Self, rhs: Self) -> Bool {
//    lhs === rhs
//  }
//
//  public func hash(into hasher: inout Hasher) {
//    ObjectIdentifier(self).hash(into: &hasher)
//  }
//
//}

public actor AsyncStorage<Value> {
  
  public enum Event {
    case willUpdate
    case didUpdate(Value)
    case willDeinit
  }
  
  private let snapshotStorage: SnapshotStorage<Value>
  
  public private(set) var value: Value

  /// for performance, set emtpy closure
  private var subscriber: (Event) -> Void = { _ in }
  private var hasSetSubscriber = false

  /// Returns a snapshot of the value in the point of time to mutation completed.
  /// the value may be older than the current processing.
  public nonisolated var snapshot: Value {
    snapshotStorage.value
  }

  public init(
    _ value: Value
  ) {
    self.value = value
    snapshotStorage = .init(value)
  }
  
  deinit {
    emit(.willDeinit)
  }

  public func update(_ mutate: @Sendable (inout Value) -> Void) {
    
    emit(.willUpdate)
        
    Log.debug(.storage, "Update", Thread.current)
    mutate(&value)
    snapshotStorage.setValue(value)
    
    emit(.didUpdate(value))
    
  }
  
  /**
   Allows set only once.
   */
  func setEventHandlerOnce(subscriber: @escaping (Event) -> Void) {
    assert(self.hasSetSubscriber == false)
    self.subscriber = subscriber
  }
  
  @inline(__always)
  private func emit(_ event: Event) {
    subscriber(event)
  }
}
