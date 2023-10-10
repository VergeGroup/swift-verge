
public protocol StoreMapType<Mapped>: Sendable {

  associatedtype Mapped: Equatable

  func sinkState(
    dropsFirst: Bool,
    queue: MainActorTargetQueue,
    receive: @escaping @MainActor (Changes<Mapped>) -> Void
  ) -> StoreSubscription

  func sinkState(
    dropsFirst: Bool,
    queue: some TargetQueueType,
    receive: @escaping (Changes<Mapped>) -> Void
  ) -> StoreSubscription
}

extension StoreMapType {

  public func sinkState(
    queue: some TargetQueueType,
    receive: @escaping (Changes<Mapped>) -> Void
  ) -> StoreSubscription {
    sinkState(dropsFirst: false, queue: queue, receive: receive)
  }

  func sinkState(
    receive: @escaping @MainActor (Changes<Mapped>) -> Void
  ) -> StoreSubscription {
    sinkState(dropsFirst: false, queue: .mainIsolated(), receive: receive)
  }

  func sinkState(
    queue: MainActorTargetQueue,
    receive: @escaping @MainActor (Changes<Mapped>) -> Void
  ) -> StoreSubscription {
    sinkState(dropsFirst: false, queue: queue, receive: receive)
  }

}

/**
 Against Derived, StoreMap won't retain the value from the store.
 sink function works with store directly.
 state property retrieves the value from state of the store by mapping.
 */
public struct StoreMap<Store: StoreType, Mapped: Equatable>: Sendable {

  public typealias State = Store.State

  public let store: Store

  private let _map: @Sendable (borrowing Store.State) -> Mapped

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

          mapped.ifChanged().do { _ in
            receive(mapped)
          }

        }
      )

    return subscription
  }

  /**
   Assigns a Store's state to a property of a store.

   - Returns: a cancellable. See detail of handling cancellable from ``StoreSubscription``'s docs
   */
  public func assign(
    queue: some TargetQueueType = .passthrough,
    to binder: @escaping (Changes<Mapped>) -> Void
  ) -> StoreSubscription {
    sinkState(queue: queue, receive: binder)
  }

  /**
   Assigns a Store's state to a property of a store.

   - Returns: a cancellable. See detail of handling cancellable from ``StoreSubscription``'s docs
   */
  public func assign(
    queue: MainActorTargetQueue,
    to binder: @escaping (Changes<Mapped>) -> Void
  ) -> StoreSubscription {
    sinkState(queue: queue, receive: binder)
  }

  /**
   Creates a derived state object from a given pipeline.

   This function can be used to create a Derived object that contains only a selected part of the state. The selected part is determined by a pipeline that is passed in as an argument.

   - Parameters:
   - pipeline: The pipeline object that selects a part of the state to be passed to other components.
   - queue: The target queue for dispatching events.
   */
  public func derived<Pipeline: PipelineType>(
    _ pipeline: Pipeline,
    queue: MainActorTargetQueue
  ) -> Derived<Pipeline.Output> where Pipeline.Input == Changes<Mapped> {
    derived(pipeline, queue: Queues.MainActor(queue))
  }

  /**
   Creates a derived state object from a given pipeline.

   This function can be used to create a Derived object that contains only a selected part of the state. The selected part is determined by a pipeline that is passed in as an argument.

   - Parameters:
   - pipeline: The pipeline object that selects a part of the state to be passed to other components.
   - queue: The target queue for dispatching events.
   */
  public func derived<Pipeline: PipelineType>(
    _ pipeline: Pipeline,
    queue: some TargetQueueType = .passthrough
  ) -> Derived<Pipeline.Output> where Pipeline.Input == Changes<Mapped> {

    let derived = Derived<Pipeline.Output>(
      get: pipeline,
      set: { _ in /* no operation as read only */},
      initialUpstreamState: state,
      subscribeUpstreamState: { callback in
        sinkState(
          dropsFirst: true,
          queue: queue,
          receive: callback
        )
      },
      retainsUpstream: nil
    )

    store.asStore().onDeinit { [weak derived] in
      derived?.invalidate()
    }

    return derived
  }

}

extension StoreType {

  public func map<Mapped>(_ map: @escaping @Sendable (borrowing State) -> Mapped) -> StoreMap<Self, Mapped> {
    .init(store: self, map: map)
  }

}
