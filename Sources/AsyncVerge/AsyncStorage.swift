import Dispatch

private final class SnapshotAsyncStorage<Value> {

  let queue = DispatchQueue(label: "UnsafeStorage")

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

  public enum Event {
    case willUpdate
    case didUpdate(Value)
    case willDeinit
  }

  public enum UpdateResult {
    case updated
    case nothingUpdates
  }

  public var value: Value
  private let eventEmitter = AsyncEventEmitter<Event>()
  private let snapshotStorage: SnapshotAsyncStorage<Value>

  private var notificationFilter: (Value) -> Bool = { _ in true }

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

  public func update(_ mutate: (inout Value) -> UpdateResult) async {
    Log.debug(.storage, "Update", Thread.current)

    let previousValue = value

    let result = mutate(&value)

    snapshotStorage.setValue(value)

    switch result {
    case .nothingUpdates:
      break
    case .updated:
      let afterValue = value

      if notificationFilter(previousValue) {
        await notifyWillUpdate(value: previousValue)
      }

      if notificationFilter(afterValue) {
        await notifyDidUpdate(value: afterValue)
      }

    }

  }

  @discardableResult
  public final func sinkEvent(
    subscriber: @escaping (Event) -> Void
  ) async -> AsyncEventEmitterCancellable {
    await eventEmitter.add { event in
      subscriber(event)
    }
  }

  @inline(__always)
  fileprivate func notifyWillUpdate(value: Value) async {
    await eventEmitter.accept(.willUpdate)
  }

  @inline(__always)
  fileprivate func notifyDidUpdate(value: Value) async {
    await eventEmitter.accept(.didUpdate(value))
  }

  /// Filter to supress update notifications
  /// - Parameter filter: Return true, notification will emit.
  public func setNotificationFilter(_ filter: @escaping (Value) -> Bool) {
    notificationFilter = filter
  }

  public var customMirror: Mirror {
    Mirror(
      self,
      children: ["value": value],
      displayStyle: .struct
    )
  }

  deinit {
    Task {
      await eventEmitter.accept(.willDeinit)
    }
  }
}

#if canImport(Combine)

import Combine

// MARK: - Integrate with Combine

private var _willChangeAssociated: Void?
private var _didChangeAssociated: Void?

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension AsyncStorage: ObservableObject {

  nonisolated public var objectWillChange: ObservableObjectPublisher {
    assert(Thread.isMainThread)
    if let associated = objc_getAssociatedObject(self, &_willChangeAssociated)
      as? ObservableObjectPublisher
    {
      return associated
    } else {
      let associated = ObservableObjectPublisher()
      objc_setAssociatedObject(self, &_willChangeAssociated, associated, .OBJC_ASSOCIATION_RETAIN)

      Task {
        await sinkEvent { (event) in
          switch event {
          case .willUpdate:
            if Thread.isMainThread {
              associated.send()
            } else {
              DispatchQueue.main.async {
                associated.send()
              }
            }
          case .didUpdate:
            break
          case .willDeinit:
            break
          }
        }
      }

      return associated
    }
  }

  public var objectDidChange: AnyPublisher<Value, Never> {
    valuePublisher.dropFirst().eraseToAnyPublisher()
  }

  public var valuePublisher: AnyPublisher<Value, Never> {

    objc_sync_enter(self)
    defer {
      objc_sync_exit(self)
    }

    if let associated = objc_getAssociatedObject(self, &_didChangeAssociated)
      as? CurrentValueSubject<Value, Never>
    {
      return associated.eraseToAnyPublisher()
    } else {
      let associated = CurrentValueSubject<Value, Never>(value)
      objc_setAssociatedObject(self, &_didChangeAssociated, associated, .OBJC_ASSOCIATION_RETAIN)

      Task {
        await sinkEvent { (event) in
          switch event {
          case .willUpdate:
            break
          case .didUpdate(let newValue):
            associated.send(newValue)
          case .willDeinit:
            break
          }
        }
      }

      return associated.eraseToAnyPublisher()
    }
  }

}

#endif
