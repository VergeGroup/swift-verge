import Combine
@_implementationOnly import Atomics

/// A typealias to `Set<AnyCancellable>`.
public typealias VergeAnyCancellables = Set<AnyCancellable>

final class Reference: Equatable, Hashable {

  static func == (lhs: Reference, rhs: Reference) -> Bool {
    lhs === rhs
  }

  func hash(into hasher: inout Hasher) {
    ObjectIdentifier(value).hash(into: &hasher)
  }

  let value: AnyObject

  init(value: AnyObject) {
    self.value = value
  }

}

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
  private var retainObjects: Set<Reference> = .init()

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

    retainObjects.insert(.init(value: object))

    return self
  }

  public func dissociate(_ object: AnyObject) {

    lock.lock()

    let target = retainObjects.remove(.init(value: object))

    lock.unlock()

    guard let target else {
      return
    }

    withExtendedLifetime(target, {})

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

    guard !wasCancelled else {
      lock.unlock()
      return
    }

    wasCancelled = true

    let _retainObjects = self.retainObjects
    retainObjects.removeAll()

    let _actions = self.actions
    self.actions = nil

    lock.unlock()

    withExtendedLifetime(_retainObjects, {})

    _actions?.forEach {
      $0()
    }

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
