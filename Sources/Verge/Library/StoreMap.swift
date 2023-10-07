
/**
 Against Derived, StoreMap won't retain the value from the store.
 sink function works with store directly.
 state property retrieves the value from state of the store by mapping.
 */
public final class StoreMap<Store: StoreType, Mapped: Equatable> {

  public typealias State = Store.State
  public let store: Store
  private let _map: (Store.State) -> Mapped

  public var state: Changes<Mapped> {
    store.state.map(_map)
  }

  public init(store: Store, map: @escaping @Sendable (borrowing Store.State) -> Mapped) {
    self.store = store
    self._map = map
  }

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
          receive(state.map(_map))
        }
      )

    _ = subscription.associate(object: self)

    return subscription
  }

}

extension StoreType {

  public func map<Mapped>(_ map: @escaping @Sendable (State) -> Mapped) -> StoreMap<Self, Mapped> {
    .init(store: self, map: map)
  }

}
