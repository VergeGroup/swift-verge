import Combine
@_implementationOnly import Atomics

/**
 A subscription that is compatible with Combine’s Cancellable.
 You can manage asynchronous tasks either call the ``cancel()`` to halt the subscription, or allow it to terminate upon instance deallocation, and by implementing the ``storeWhileSourceActive()`` technique, the subscription’s active status is maintained until the source store is released.
 */
public final class StoreSubscription: Hashable, Cancellable, @unchecked Sendable {

  public static func == (lhs: StoreSubscription, rhs: StoreSubscription) -> Bool {
    lhs === rhs
  }

  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }

  private let wasCancelled = ManagedAtomic(false)

  private let source: EventEmitterCancellable

  // TODO: can't be sendable
  private weak var storeCancellable: VergeAnyCancellable?
  private var associatedStore: (any StoreType)?
  private var associatedReferences: [AnyObject] = []

  init(
    _ eventEmitterCancellable: EventEmitterCancellable,
    storeCancellable: VergeAnyCancellable
  ) {
    self.source = eventEmitterCancellable
    self.storeCancellable = storeCancellable
  }

  public func cancel() {

    guard wasCancelled.compareExchange(expected: false, desired: true, ordering: .relaxed).exchanged else { return }

    storeCancellable?.dissociate(self)
    source.cancel()
    associatedStore = nil
  }

  func associate(store: some StoreType) -> StoreSubscription {
    ensureAlive()
    associatedStore = store
    return self
  }

  func associate(object: AnyObject) -> StoreSubscription {
    ensureAlive()
    associatedReferences.append(object)
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

public final class StoreStateSubscription: Hashable, Cancellable, @unchecked Sendable {

  enum Action {
    case suspend
    case resume
  }

  public static func == (lhs: StoreStateSubscription, rhs: StoreStateSubscription) -> Bool {
    lhs === rhs
  }

  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }

  private let wasCancelled = ManagedAtomic(false)

  private let isSuspending: ManagedAtomic<Bool> = .init(false)

  private var entranceForSuspension: ManagedAtomic<Int8> = .init(0)

  private var source: AtomicReferenceStorage<EventEmitterCancellable>

  // TODO: can't be sendable
  private weak var storeCancellable: VergeAnyCancellable?
  private var associatedStore: (any StoreType)?
  private var associatedReferences: [AnyObject] = []

  private var onAction: ((StoreStateSubscription, Action) -> Void)?

  init(
    _ eventEmitterCancellable: EventEmitterCancellable,
    storeCancellable: VergeAnyCancellable,
    onAction: @escaping (StoreStateSubscription, Action) -> Void
  ) {
    self.source = .init(eventEmitterCancellable)
    self.storeCancellable = storeCancellable
    self.onAction = onAction
  }

  public func cancel() {

    guard wasCancelled.compareExchange(expected: false, desired: true, ordering: .sequentiallyConsistent).exchanged else {
      return
    }

    AtomicReferenceStorage.atomicLoad(at: &source, ordering: .relaxed).cancel()
    storeCancellable?.dissociate(self)
    associatedStore = nil
    onAction = nil
  }

  func cancelSubscription() {

    guard wasCancelled.load(ordering: .sequentiallyConsistent) == false else {
      return
    }

    AtomicReferenceStorage.atomicLoad(at: &source, ordering: .relaxed).cancel()

  }

  func replace(cancellable: consuming EventEmitterCancellable) {

    guard wasCancelled.load(ordering: .sequentiallyConsistent) == false else {
      return
    }

    AtomicReferenceStorage.atomicStore(cancellable, at: &source, ordering: .relaxed)
  }

  public func suspend() {

    guard wasCancelled.load(ordering: .sequentiallyConsistent) == false else {
      return
    }

    guard entranceForSuspension.loadThenWrappingIncrement(ordering: .sequentiallyConsistent) == 0 else {
      assertionFailure("currently operating")
      return
    }

    defer {
      entranceForSuspension.wrappingDecrement(ordering: .sequentiallyConsistent)
    }

    guard isSuspending.compareExchange(expected: false, desired: true, ordering: .sequentiallyConsistent).exchanged else {      
      return
    }

    onAction?(self, .suspend)

  }

  public func resume() {

    guard wasCancelled.load(ordering: .sequentiallyConsistent) == false else {
      return
    }

    guard entranceForSuspension.loadThenWrappingIncrement(ordering: .sequentiallyConsistent) == 0 else {
      assertionFailure("currently operating")
      return
    }

    defer {
      entranceForSuspension.wrappingDecrement(ordering: .sequentiallyConsistent)
    }

    guard isSuspending.compareExchange(expected: true, desired: false, ordering: .sequentiallyConsistent).exchanged else {
      return
    }

    onAction?(self, .resume)
  }

  func associate(store: some StoreType) -> StoreStateSubscription {
    ensureAlive()
    associatedStore = store
    return self
  }

  func associate(object: AnyObject) -> StoreStateSubscription {
    ensureAlive()
    associatedReferences.append(object)
    return self
  }

  /**
   Make this subscription alive while the source is active.
   the source means a root data store which is Store.

   In case of Derived, the source will be Derived's upstream.
   If the upstream invalidated, this subscription will stop.
   */
  @discardableResult
  public func storeWhileSourceActive() -> StoreStateSubscription {
    ensureAlive()
    assert(storeCancellable != nil)
    storeCancellable?.associate(self)
    return self
  }

  @inline(__always)
  private func ensureAlive() {
    assert(wasCancelled.load(ordering: .sequentiallyConsistent) == false)
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
