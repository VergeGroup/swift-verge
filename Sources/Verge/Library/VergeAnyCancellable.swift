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
