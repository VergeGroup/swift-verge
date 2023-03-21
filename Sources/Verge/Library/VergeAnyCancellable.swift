import Combine

/// A typealias to `Set<VergeAnyCancellable>`.
public typealias VergeAnyCancellables = Set<VergeAnyCancellable>

/// A type-erasing cancellable object that executes a provided closure when canceled.
/// An AnyCancellable instance automatically calls cancel() when deinitialized.
/// To cancel depending owner, can be written following
///
/// ```
/// class ViewController {
///
///   var subscriptions = VergeAnyCancellables()
///
///   func something() {
///
///   let derived = store.derived(...)
///
///   derived
///     .subscribeStateChanges { ... }
///     .store(in: &subscriptions)
///   }
///
/// }
/// ```
public final class VergeAnyCancellable: Hashable, Cancellable, @unchecked Sendable {

  private let lock = VergeConcurrency.UnfairLock()

  private var wasCancelled = false

  public static func == (lhs: VergeAnyCancellable, rhs: VergeAnyCancellable) -> Bool {
    lhs === rhs
  }

  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }

  private var actions: ContiguousArray<() -> Void>? = .init()
  private var retainObjects: ContiguousArray<AnyObject> = .init()

  public init() {
  }

  public convenience init(onDeinit: @escaping () -> Void) {
    self.init()
    self.actions = [onDeinit]
  }

  public convenience init<C>(_ cancellable: C) where C : CancellableType {
    self.init {
      cancellable.cancel()
    }
  }

  public convenience init(_ cancellable: CancellableType) {
    self.init {
      cancellable.cancel()
    }
  }

  @discardableResult
  public func associate(_ object: AnyObject) -> VergeAnyCancellable {

    lock.lock()
    defer {
      lock.unlock()
    }

    assert(!wasCancelled)

    retainObjects.append(object)

    return self
  }

  public func insert(_ cancellable: CancellableType) {

    lock.lock()
    defer {
      lock.unlock()
    }

    assert(!wasCancelled)

    actions?.append {
      cancellable.cancel()
    }
  }

  public func insert(onDeinit: @escaping () -> Void) {

    lock.lock()
    defer {
      lock.unlock()
    }

    assert(!wasCancelled)
    actions?.append(onDeinit)
  }

  deinit {
    cancel()
  }

  public func cancel() {

    lock.lock()
    defer {
      lock.unlock()
    }

    guard !wasCancelled else { return }
    wasCancelled = true

    retainObjects.removeAll()
    
    actions?.forEach {
      $0()
    }

    actions = nil

  }

}

/// An object to cancel subscription
///
/// To cancel depending owner, can be written following
///
/// ```
/// class ViewController {
///
///   var subscriptions = VergeAnyCancellables()
///
///   func something() {
///
///   let derived = store.derived(...)
///
///   derived
///     .subscribeStateChanges { ... }
///     .store(in: &subscriptions)
///   }
///
/// }
/// ```
///
public typealias CancellableType = Cancellable

public final class StoreSubscription: CancellableType {

  private let source: EventEmitterCancellable
  private weak var storeCancellable: VergeAnyCancellable?
  private var associatedStore: (any StoreType)?

  init(_ eventEmitterCancellable: EventEmitterCancellable) {
    self.source = eventEmitterCancellable
  }

  public func cancel() {
    source.cancel()
  }

  func associate(store: some StoreType) -> StoreSubscription {
    associatedStore = store
    return self
  }

  @discardableResult
  public func withSource() -> StoreSubscription {
    storeCancellable?.associate(self)
    return self
  }

  deinit {
    self.cancel()
  }
}

