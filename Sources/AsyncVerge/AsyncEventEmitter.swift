
import Verge

public final class AsyncEventEmitterCancellable: Hashable, CancellableType {

  public static func == (lhs: AsyncEventEmitterCancellable, rhs: AsyncEventEmitterCancellable) -> Bool {
    lhs === rhs
  }

  private weak var owner: AsyncEventEmitterType?

  fileprivate init(owner: AsyncEventEmitterType) {
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

  private var subscribers: ContiguousArray<(AsyncEventEmitterCancellable, (Event) -> Void)> = []

  private var deinitHandlers: VergeConcurrency.UnfairLockAtomic<[() -> Void]> = .init([])

  public init() {

  }

  public func accept(_ event: Event) async {
    subscribers.forEach {
      $0.1(event)
    }
  }

  @discardableResult
  public func add(_ eventReceiver: @escaping (Event) -> Void) -> AsyncEventEmitterCancellable {
    let token = AsyncEventEmitterCancellable(owner: self)
    subscribers.append((token, eventReceiver))
    return token
  }

  func remove(_ token: AsyncEventEmitterCancellable) {
    guard let index = subscribers.firstIndex(where: { $0.0 == token }) else { return }
    subscribers.remove(at: index)
  }

  deinit {
    deinitHandlers.value.forEach {
      $0()
    }
  }
}
