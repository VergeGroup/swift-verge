
public class StoreSubscriptionBase: Hashable, Cancellable {

  public static func == (lhs: StoreSubscriptionBase, rhs: StoreSubscriptionBase) -> Bool {
    lhs === rhs
  }
  
  private struct State {
    var wasCancelled: Bool = false
    weak var storeCancellable: VergeAnyCancellable?
    var associatedStore: (any StoreType)?
  }
  
  private let state: VergeConcurrency.ManagedCriticalState<State>
  
  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }    
  
  private let source: EventEmitterCancellable
  
  init(
    _ eventEmitterCancellable: EventEmitterCancellable,
    storeCancellable: VergeAnyCancellable
  ) {
    self.source = eventEmitterCancellable
    self.state = .init(State(storeCancellable: storeCancellable))
  }
  
  public func cancel() {
    
    let continues = state.withCriticalRegion { state -> Bool in
      guard state.wasCancelled == false else {
        return false
      }
      state.wasCancelled = true  
      // if it's associated as storeWhileSourceActive.
      state.storeCancellable?.dissociate(self)
      state.associatedStore = nil
      return true
    }
    
    guard continues else {
      return
    }
    
    source.cancel()
  }
  
  /**
   Make this subscription alive while the source is active.
   the source means a root data store which is Store.
   
   In case of Derived, the source will be Derived's upstream.
   If the upstream invalidated, this subscription will stop.
   */
  @discardableResult
  public func storeWhileSourceActive() -> Self {
    state.withCriticalRegion { state in   
      assert(state.wasCancelled == false)
      assert(state.storeCancellable != nil)
      state.storeCancellable?.associate(self)
    }
    return self
  }
       
  func associate(store: any StoreType) -> Self {
    state.withCriticalRegion { state in
      assert(state.wasCancelled == false)
      assert(state.storeCancellable != nil)
      state.associatedStore = store
    }
    return self
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
