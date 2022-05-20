
import Foundation
import Dispatch

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

public actor AsyncStorage<Value> {

  private let snapshotStorage: SnapshotStorage<Value>
  public var value: Value

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

  public func read() -> Value {
    Log.debug(.storage, "Read", Thread.current)
    return value
  }

  public func update(_ mutate: @Sendable (inout Value) -> Void) {
    Log.debug(.storage, "Update", Thread.current)
    mutate(&value)
    snapshotStorage.setValue(value)
  }
}
