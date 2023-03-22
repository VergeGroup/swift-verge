import Combine
@_implementationOnly import Atomics

/// A typealias to `Set<AnyCancellable>`.
public typealias VergeAnyCancellables = Set<AnyCancellable>

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

  public convenience init<C>(_ cancellable: C) where C : Cancellable {
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

  public func insert(_ cancellable: Cancellable) {

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
@available(*, deprecated, renamed: "Cancellable", message: "Integrated with Combine")
public typealias CancellableType = Cancellable

/**
 A subscription that is compatible with Combine’s Cancellable.
 You can manage asynchronous tasks either call the ``cancel()`` to halt the subscription, or allow it to terminate upon instance deallocation, and by implementing the ``storeWhileSourceActive()`` technique, the subscription’s active status is maintained until the source store is released.
 */
public final class StoreSubscription: Hashable, Cancellable {

  public static func == (lhs: StoreSubscription, rhs: StoreSubscription) -> Bool {
    lhs === rhs
  }

  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }

  private let wasCancelled = ManagedAtomic(false)

  private let source: EventEmitterCancellable
  private weak var storeCancellable: VergeAnyCancellable?
  private var associatedStore: (any StoreType)?

  init(
    _ eventEmitterCancellable: EventEmitterCancellable,
    storeCancellable: VergeAnyCancellable
  ) {
    self.source = eventEmitterCancellable
    self.storeCancellable = storeCancellable
  }

  public func cancel() {

    guard wasCancelled.compareExchange(expected: false, desired: true, ordering: .relaxed).exchanged else { return }

    source.cancel()
    associatedStore = nil
  }

  func associate(store: some StoreType) -> StoreSubscription {
    ensureAlive()
    associatedStore = store
    return self
  }

  /**
   Make this subscription alive while the source is active.
   the source means a root data store which is Store.

   In case of Derived, the source will be Derived's upstream.
   If the upstream invalidated, this subscription will stop.
   */
  @discardableResult
  public func storeWhileSourceActive() -> StoreSubscription {
    ensureAlive()
    assert(storeCancellable != nil)
    storeCancellable?.associate(self)
    return self
  }

  @inline(__always)
  private func ensureAlive() {
    assert(wasCancelled.load(ordering: .relaxed) == false)
  }

  /**
   Converts to Combine.AnyCancellable to make it auto cancellable.
   */
  public func asAny() -> AnyCancellable {
    return .init { [self] in
      self.cancel()
    }
  }

  deinit {
    cancel()
  }
}

