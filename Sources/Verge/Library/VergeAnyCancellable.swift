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
public final class VergeAnyCancellable: Hashable, CancellableType, @unchecked Sendable {

  private let lock = VergeConcurrency.UnfairLock()

  private var wasCancelled = false

  public static func == (lhs: VergeAnyCancellable, rhs: VergeAnyCancellable) -> Bool {
    lhs === rhs
  }

  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }

  private var actions: ContiguousArray<() -> Void>? = .init()

  public init(onDeinit: @escaping () -> Void) {
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

  public func associate(_ object: AnyObject) -> VergeAnyCancellable {

    lock.lock()
    defer {
      lock.unlock()
    }

    assert(!wasCancelled)

    actions?.append {
      withExtendedLifetime(object) {}
    }

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
public protocol CancellableType {

  func cancel()
}

extension CancellableType {

  public func asAutoCancellable() -> VergeAnyCancellable {
    .init(self)
  }
}

extension CancellableType {

  /// Stores this cancellable instance in the specified collection.
  ///
  /// According to Combine.framework API Design.
  public func store<C>(in collection: inout C) where C : RangeReplaceableCollection, C.Element == VergeAnyCancellable {
    collection.append(.init(self))
  }

  /// Stores this cancellable instance in the specified set.
  ///
  /// According to Combine.framework API Design.
  public func store(in set: inout Set<VergeAnyCancellable>) {
    set.insert(.init(self))
  }

}

#if canImport(Combine)

import Combine

extension CancellableType {

  /// Interop with Combine
  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  public func store(in set: inout Set<AnyCancellable>) {
    set.insert(AnyCancellable.init {
      self.cancel()
    })
  }

}

#endif

