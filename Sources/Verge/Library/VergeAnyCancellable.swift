import Combine
import Atomics

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
public final class VergeAnyCancellable: Hashable, Cancellable, Sendable {

  private struct State {
    var wasCancelled: Bool = false
    var actions: ContiguousArray<() -> Void>? = .init()
    var retainObjects: [AnyObject] = []
  }
  
  private let state: VergeConcurrency.ManagedCriticalState<State> = .init(State())

  public static func == (lhs: VergeAnyCancellable, rhs: VergeAnyCancellable) -> Bool {
    lhs === rhs
  }

  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }

  public init() {
  }

  public convenience init(onDeinit: @escaping () -> Void) {
    self.init()
    state.withCriticalRegion { $0.actions = [onDeinit] }
  }

  public convenience init<C>(_ cancellable: C) where C : Cancellable {
    self.init {
      cancellable.cancel()
    }
  }

  @discardableResult
  public func associate(_ object: AnyObject) -> VergeAnyCancellable {
    state.withCriticalRegion { state in
      assert(!state.wasCancelled)
      state.retainObjects.append(object)
    }
    return self
  }

  public func dissociate(_ object: AnyObject) {
    let targets = state.withCriticalRegion { state -> [AnyObject] in
      var targets: [AnyObject] = .init()
      targets.reserveCapacity(state.retainObjects.count)
      state.retainObjects.removeAll {
        let remove = $0 === object
        if remove {
          targets.append($0)
        }
        return remove          
      }
      return targets
    }
    
    guard targets.isEmpty == false else {
      return
    }

    withExtendedLifetime(targets, {})
  }

  public func insert(_ cancellable: Cancellable) {
    state.withCriticalRegion { state in
      assert(!state.wasCancelled)
      state.actions?.append {
        cancellable.cancel()
      }
    }
  }

  public func insert(onDeinit: @escaping () -> Void) {
    state.withCriticalRegion { state in
      assert(!state.wasCancelled)
      state.actions?.append(onDeinit)
    }
  }

  deinit {
    cancel()
  }

  public func cancel() {
    let result = state.withCriticalRegion { state -> (
      retainObjects: [AnyObject],
      actions: ContiguousArray<() -> Void>?
    )? in
      guard !state.wasCancelled else {
        return nil
      }
      
      state.wasCancelled = true
      
      let retainObjects = state.retainObjects
      state.retainObjects.removeAll()
      
      let actions = state.actions
      state.actions = nil
      
      return (retainObjects, actions)
    }
    
    guard let result else {
      return
    }
    
    withExtendedLifetime(result.retainObjects, {})
    
    result.actions?.forEach {
      $0()
    }
  }
}

