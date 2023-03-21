
import Verge

public final class AsyncEventEmitterCancellable: Hashable, CancellableType {

  public static func == (lhs: AsyncEventEmitterCancellable, rhs: AsyncEventEmitterCancellable) -> Bool {
    lhs === rhs
  }

  private weak var owner: (any AsyncEventEmitterType)?

  fileprivate init(owner: any AsyncEventEmitterType) {
    self.owner = owner
  }

  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }

  public func cancel() {
    Task {
      await owner?.remove(self)
    }
  }
}

protocol AsyncEventEmitterType: Actor {
  func remove(_ token: AsyncEventEmitterCancellable)
}

public actor AsyncEventEmitter<Event>: AsyncEventEmitterType {

  private var subscribers: [(AsyncEventEmitterCancellable, (Event) -> Void)] = []

  private var deinitHandlers: [() -> Void] = []
  
#if DEBUG
  private let reentrancyDetector = AsyncReentrancyDetector()
#endif
  
  public init() {

  }

  public func accept(_ event: Event) {
    
#if DEBUG
    
    /*
     Make sure it eliminates accepting another event while emitting the current event.
     */
    
    reentrancyDetector.enter()
    defer {
      reentrancyDetector.leave()
    }
#endif
    
    for subscriber in subscribers {
      subscriber.1(event)
    }
    
  }

  @discardableResult
  public func addEventHandler(_ eventReceiver: @escaping (Event) -> Void) -> AsyncEventEmitterCancellable {
    let token = AsyncEventEmitterCancellable(owner: self)
    subscribers.append((token, eventReceiver))
    return token
  }
  
  public func addDeinitHandler(_ eventReceiver: @escaping () -> Void) {
    deinitHandlers.append(eventReceiver)
  }

  func remove(_ token: AsyncEventEmitterCancellable) {
    guard let index = subscribers.firstIndex(where: { $0.0 == token }) else { return }
    subscribers.remove(at: index)
  }

  deinit {
    for handler in deinitHandlers {
      handler()
    }
  }
}
