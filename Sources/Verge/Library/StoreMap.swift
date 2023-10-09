
/**
 Against Derived, StoreMap won't retain the value from the store.
 sink function works with store directly.
 state property retrieves the value from state of the store by mapping.
 */
public final class StoreMap<Store: StoreType, Mapped: Equatable>: Sendable {

  public typealias State = Store.State

  public let store: Store

  private let _map: @Sendable (Store.State) -> Mapped

  public var state: Changes<Mapped> {
    store.state.map(_map)
  }

  public init(store: Store, map: @escaping @Sendable (borrowing Store.State) -> Mapped) {
    self.store = store
    self._map = map
  }

}

// MARK: Implementations
extension StoreMap {

  /**
   Start subscribing state updates in receive closure.
   It skips publishing values if the mapped value is not changed.
   */
  @_disfavoredOverload
  public func sinkState(
    dropsFirst: Bool = false,
    queue: MainActorTargetQueue = .mainIsolated(),
    receive: @escaping @MainActor (Changes<Mapped>) -> Void
  ) -> StoreSubscription {

    let subscription = store.asStore()
      .sinkState(
        dropsFirst: dropsFirst,
        queue: queue,
        receive: { [_map] state in

          let mapped = state
            .map(_map)

          mapped.ifChanged().do { _ in
            receive(mapped)
          }

        }
      )

    _ = subscription.associate(object: self)

    return subscription
  }

  /**
   Start subscribing state updates in receive closure.
   It skips publishing values if the mapped value is not changed.
   */
  public func sinkState(
    dropsFirst: Bool = false,
    queue: some TargetQueueType,
    receive: @escaping (Changes<Mapped>) -> Void
  ) -> StoreSubscription {

    let subscription = store.asStore()
      .sinkState(
        dropsFirst: dropsFirst,
        queue: queue,
        receive: { [_map] state in

          let mapped = state
            .map(_map)

          mapped.ifChanged().do {
            receive(mapped)
          }

        }
      )

    _ = subscription.associate(object: self)

    return subscription
  }

  /**
   Assigns a Store's state to a property of a store.

   - Returns: a cancellable. See detail of handling cancellable from ``StoreSubscription``'s docs
   */
  public func assign(
    queue: some TargetQueueType = .passthrough,
    to binder: @escaping (Changes<State>) -> Void
  ) -> StoreSubscription {
    store.asStore().sinkState(queue: queue, receive: binder)
  }

  /**
   Assigns a Store's state to a property of a store.

   - Returns: a cancellable. See detail of handling cancellable from ``StoreSubscription``'s docs
   */
  public func assign(
    queue: MainActorTargetQueue,
    to binder: @escaping (Changes<State>) -> Void
  ) -> StoreSubscription {
    store.asStore().sinkState(queue: queue, receive: binder)
  }

}

extension StoreType {

  public func map<Mapped>(_ map: @escaping @Sendable (borrowing State) -> Mapped) -> StoreMap<Self, Mapped> {
    .init(store: self, map: map)
  }

}
