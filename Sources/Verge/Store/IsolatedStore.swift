
@MainActor
public final class MainActorStore<State: StateType, Activity>: DerivedMaking, Sendable, MainActorStoreDriverType, ObservableObject {

  public typealias State = State

  public nonisolated var objectWillChange: ObservableObjectPublisher {
    backingStore.objectWillChange
  }

  public nonisolated var store: MainActorStore<State, Activity> { self }

  public typealias Scope = State

  public nonisolated var state: Changes<State> {
    backingStore.state
  }

  @_spi(Internal)
  public let backingStore: Store<State, Activity>

  public nonisolated init(initialState: State) {
    self.backingStore = .init(initialState: initialState, storeOperation: .atomic(.init()), logger: nil, sanitizer: nil)
  }

  public func commit<Result>(
    mutation: (inout InoutRef<State>) throws -> Result
  ) rethrows -> Result {

    try backingStore._receive(mutation: { state, _ in try mutation(&state) })

  }

  public func commit<Result>(
    mutation: (inout InoutRef<State>, inout Transaction) throws -> Result
  ) rethrows -> Result {
    try backingStore._receive(mutation: mutation)
  }

  /// Send activity
  /// - Parameter activity:
  public func send(
    _ activity: Activity,
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line
  ) {
    let trace = ActivityTrace(
      name: "",
      file: file.description,
      function: function.description,
      line: line
    )

    backingStore._send(activity: activity, trace: trace)
  }

  /**
   Subscribe the state that scoped

   First object always returns true from ifChanged / hasChanges / noChanges unless dropsFirst is true.

   - Parameters:
   - dropsFirst: Drops the latest value on started. if true, receive closure will call from next state updated.
   - queue: Specify a queue to receive changes object.
   - Returns: A subscriber that performs the provided closure upon receiving values.
   */
  @_disfavoredOverload
  public nonisolated func sinkState(
    dropsFirst: Bool = false,
    queue: some TargetQueueType,
    receive: @escaping (Changes<State>) -> Void
  ) -> StoreSubscription {
    return backingStore
      .sinkState(dropsFirst: dropsFirst, queue: queue, receive: receive)
  }

  /**
   Subscribe the state that scoped

   First object always returns true from ifChanged / hasChanges / noChanges unless dropsFirst is true.

   - Parameters:
   - dropsFirst: Drops the latest value on started. if true, receive closure will call from next state updated.
   - queue: Specify a queue to receive changes object.
   - Returns: A subscriber that performs the provided closure upon receiving values.
   */
  public nonisolated func sinkState(
    dropsFirst: Bool = false,
    queue: MainActorTargetQueue = .mainIsolated(),
    receive: @escaping @MainActor (Changes<State>) -> Void
  ) -> StoreSubscription {
    return backingStore
      .sinkState(dropsFirst: dropsFirst, queue: queue, receive: receive)
  }

  public nonisolated func derived<Pipeline: PipelineType>(
    _ pipeline: Pipeline,
    queue: some TargetQueueType = .passthrough
  ) -> Derived<Pipeline.Output> where Pipeline.Input == Changes<State> {

    let derived = Derived<Pipeline.Output>(
      get: pipeline,
      set: { _ in /* no operation as read only */},
      initialUpstreamState: backingStore.state,
      subscribeUpstreamState: { callback in
        backingStore.asStore()._primitive_sinkState(
          dropsFirst: true,
          queue: queue,
          receive: callback
        )
      },
      retainsUpstream: nil
    )

    backingStore.asStore().onDeinit { [weak derived] in
      derived?.invalidate()
    }

    return derived
  }

  /**
   Adds an asynchronous task to perform.

   Use this function to perform an asynchronous task with a lifetime that matches that of this store.
   If this store is deallocated ealier than the given task finished, that asynchronous task will be cancelled.

   Carefully use this function - If the task retains this store, it will continue to live until the task is finished.

   - Parameters:
   - key:
   - mode:
   - priority:
   - action
   - Returns: A Task for tracking given async operation's completion.
   */
  @discardableResult
  public func task<Return>(
    key: ConcurrencyTaskManager.TaskKey = .distinct(),
    mode: ConcurrencyTaskManager.TaskManagerActor.Mode = .dropCurrent,
    priority: TaskPriority = .userInitiated,
    @_inheritActorContext _ action: @Sendable @escaping () async throws -> Return
  ) -> Task<Return, Error> {
    backingStore.task(key: key, mode: mode, priority: priority, action)
  }

  public func add(middleware: some StoreMiddlewareType<State>) {
    backingStore.add(middleware: middleware)
  }
}

public final class AsyncStore<State: StateType, Activity>: DerivedMaking, Sendable, AsyncStoreDriverType, ObservableObject {

  public typealias State = State

  public var objectWillChange: ObservableObjectPublisher {
    backingStore.objectWillChange
  }

  public var store: AsyncStore<State, Activity> { self }

  public typealias Scope = State

  public var state: Changes<State> {
    backingStore.state
  }

  public var latestState: Changes<State> {
    get async {
      await writer.perform { _ in
        backingStore.state
      }
    }
  }

  @_spi(Internal)
  public let backingStore: Store<State, Activity>

  private let writer: AsyncStoreOperator = .init()

  public init(initialState: State) {
    self.backingStore = .init(initialState: initialState, storeOperation: .atomic(.init()), logger: nil, sanitizer: nil)
  }

  public func commit<Result>(
    mutation: @Sendable (inout InoutRef<State>) throws -> Result
  ) async rethrows -> Result {
    try await writer.perform { _ in
      try backingStore._receive(mutation: { state, _ in try mutation(&state) })
    }
  }

  public func commit<Result>(
    mutation: @Sendable (inout InoutRef<State>, inout Transaction) throws -> Result
  ) async rethrows -> Result {
    try await writer.perform { _ in
      try backingStore._receive(mutation: mutation)
    }
  }

  /**
   Adds an asynchronous task to perform.

   Use this function to perform an asynchronous task with a lifetime that matches that of this store.
   If this store is deallocated ealier than the given task finished, that asynchronous task will be cancelled.

   Carefully use this function - If the task retains this store, it will continue to live until the task is finished.

   - Parameters:
   - key:
   - mode:
   - priority:
   - action
   - Returns: A Task for tracking given async operation's completion.
   */
  @discardableResult
  public func task<Return>(
    key: ConcurrencyTaskManager.TaskKey = .distinct(),
    mode: ConcurrencyTaskManager.TaskManagerActor.Mode = .dropCurrent,
    priority: TaskPriority = .userInitiated,
    @_inheritActorContext _ action: @Sendable @escaping () async throws -> Return
  ) -> Task<Return, Error> {
    backingStore.task(key: key, mode: mode, priority: priority, action)
  }

  public func add(middleware: some StoreMiddlewareType<State>) {
    backingStore.add(middleware: middleware)
  }

  /// Send activity
  /// - Parameter activity:
  public func send(
    _ activity: Activity,
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line
  ) {
    let trace = ActivityTrace(
      name: "",
      file: file.description,
      function: function.description,
      line: line
    )

    backingStore._send(activity: activity, trace: trace)
  }

  /**
   Subscribe the state that scoped

   First object always returns true from ifChanged / hasChanges / noChanges unless dropsFirst is true.

   - Parameters:
   - dropsFirst: Drops the latest value on started. if true, receive closure will call from next state updated.
   - queue: Specify a queue to receive changes object.
   - Returns: A subscriber that performs the provided closure upon receiving values.
   */
  @_disfavoredOverload
  public func sinkState(
    dropsFirst: Bool = false,
    queue: some TargetQueueType,
    receive: @escaping (Changes<State>) -> Void
  ) -> StoreSubscription {
    return backingStore
      .sinkState(dropsFirst: dropsFirst, queue: queue, receive: receive)
  }

  /**
   Subscribe the state that scoped

   First object always returns true from ifChanged / hasChanges / noChanges unless dropsFirst is true.

   - Parameters:
   - dropsFirst: Drops the latest value on started. if true, receive closure will call from next state updated.
   - queue: Specify a queue to receive changes object.
   - Returns: A subscriber that performs the provided closure upon receiving values.
   */
  public func sinkState(
    dropsFirst: Bool = false,
    queue: MainActorTargetQueue = .mainIsolated(),
    receive: @escaping @MainActor (Changes<State>) -> Void
  ) -> StoreSubscription {
    return backingStore
      .sinkState(dropsFirst: dropsFirst, queue: queue, receive: receive)
  }

  public func derived<Pipeline: PipelineType>(
    _ pipeline: Pipeline,
    queue: some TargetQueueType = .passthrough
  ) -> Derived<Pipeline.Output> where Pipeline.Input == Changes<State> {

    let derived = Derived<Pipeline.Output>(
      get: pipeline,
      set: { _ in /* no operation as read only */},
      initialUpstreamState: backingStore.state,
      subscribeUpstreamState: { callback in
        backingStore.asStore()._primitive_sinkState(
          dropsFirst: true,
          queue: queue,
          receive: callback
        )
      },
      retainsUpstream: nil
    )

    backingStore.asStore().onDeinit { [weak derived] in
      derived?.invalidate()
    }

    return derived
  }

}


private actor AsyncStoreOperator {

  init() {

  }

  func perform<R>(_ operation: (isolated AsyncStoreOperator) throws -> R) rethrows -> R {
    try operation(self)
  }

}

// MARK: -

@MainActor
public protocol MainActorStoreDriverType {

  associatedtype State: StateType
  associatedtype Activity

  associatedtype Scope: Equatable = State

  nonisolated var store: MainActorStore<State, Activity> { get }
  nonisolated var scope: WritableKeyPath<State, Scope> { get }

  func commit<Result>(
    mutation: (inout InoutRef<Scope>) throws -> Result
  ) rethrows -> Result

  func commit<Result>(
    mutation: (inout InoutRef<Scope>, inout Transaction) throws -> Result
  ) rethrows -> Result

  func derived<Pipeline: PipelineType>(
    _ pipeline: Pipeline,
    queue: some TargetQueueType
  ) -> Derived<Pipeline.Output> where Pipeline.Input == Changes<State>

}

extension MainActorStoreDriverType {
  /// A state that cut out from root-state with the scope key path.
  public var state: Changes<Scope> {
    store.state.map { $0[keyPath: scope] }
  }

  public var rootState: Changes<State> {
    return store.state
  }

  /// Send activity
  /// - Parameter activity:
  public func send(
    _ activity: Activity,
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line
  ) {
    store.send(activity, file, function, line)
  }

  /// Run Mutation that created inline
  ///
  /// Throwable
  public func commit<Result>(
    mutation: (inout InoutRef<Scope>) throws -> Result
  ) rethrows -> Result {

    return try store.commit { ref in
      try ref.map(keyPath: scope, perform: mutation)
    }

  }

  public func commit<Result>(
    mutation: (inout InoutRef<Scope>, inout Transaction) throws -> Result
  ) rethrows -> Result {

    return try store.commit { ref, transaction in
      try ref.map(keyPath: scope, perform: {
        try mutation(&$0, &transaction)
      })
    }

  }

  /**
   Subscribe the state that scoped

   First object always returns true from ifChanged / hasChanges / noChanges unless dropsFirst is true.

   - Parameters:
   - dropsFirst: Drops the latest value on started. if true, receive closure will call from next state updated.
   - queue: Specify a queue to receive changes object.
   - Returns: A subscriber that performs the provided closure upon receiving values.
   */
  @_disfavoredOverload
  public nonisolated func sinkState(
    dropsFirst: Bool = false,
    queue: some TargetQueueType,
    receive: @escaping (Changes<Scope>) -> Void
  ) -> StoreSubscription {
    return store.sinkState(dropsFirst: dropsFirst, queue: queue, receive: { state in
      receive(state.map({ $0[keyPath: scope] }))
    })
  }

  /**
   Subscribe the state that scoped

   First object always returns true from ifChanged / hasChanges / noChanges unless dropsFirst is true.

   - Parameters:
   - dropsFirst: Drops the latest value on started. if true, receive closure will call from next state updated.
   - queue: Specify a queue to receive changes object.
   - Returns: A subscriber that performs the provided closure upon receiving values.
   */
  public nonisolated func sinkState(
    dropsFirst: Bool = false,
    queue: MainActorTargetQueue = .mainIsolated(),
    receive: @escaping @MainActor (Changes<Scope>) -> Void
  ) -> StoreSubscription {
    return store.sinkState(dropsFirst: dropsFirst, queue: queue, receive: { state in
      receive(state.map({ $0[keyPath: scope] }))
    })
  }

  public nonisolated func derived<Pipeline: PipelineType>(
    _ pipeline: Pipeline,
    queue: some TargetQueueType = .passthrough
  ) -> Derived<Pipeline.Output> where Pipeline.Input == Changes<State> {
    return store.derived(pipeline, queue: queue)
  }
}

extension MainActorStoreDriverType where Scope == State {

  public nonisolated var scope: WritableKeyPath<State, State> {
    \State.self
  }

  /// Run Mutation that created inline
  ///
  /// Throwable
  public func commit<Result>(
    mutation: (inout InoutRef<Scope>) throws -> Result
  ) rethrows -> Result {

    return try store.commit(mutation: mutation)

  }

}

// MARK: -

public protocol AsyncStoreDriverType {

  associatedtype State: StateType
  associatedtype Activity

  associatedtype Scope: Equatable = State

  var store: AsyncStore<State, Activity> { get }
  var scope: WritableKeyPath<State, Scope> { get }

  func commit<Result>(
    mutation: @Sendable (inout InoutRef<Scope>) throws -> Result
  ) async rethrows -> Result

  func commit<Result>(
    mutation: @Sendable (inout InoutRef<Scope>, inout Transaction) throws -> Result
  ) async rethrows -> Result
}

extension AsyncStoreDriverType {
  /// A state that cut out from root-state with the scope key path.
  public nonisolated var state: Changes<Scope> {
    store.state.map { $0[keyPath: scope] }
  }

  public nonisolated var rootState: Changes<State> {
    return store.state
  }

  /// Send activity
  /// - Parameter activity:
  public func send(
    _ activity: Activity,
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line
  ) {
    store.send(activity, file, function, line)
  }

  /// Run Mutation that created inline
  ///
  /// Throwable
  public func commit<Result>(
    mutation: @Sendable (inout InoutRef<Scope>) throws -> Result
  ) async rethrows -> Result {

    return try await store.commit { ref in
      try ref.map(keyPath: scope, perform: mutation)
    }

  }

  /// Run Mutation that created inline
  ///
  /// Throwable
  public func commit<Result>(
    mutation: @Sendable (inout InoutRef<Scope>, inout Transaction) throws -> Result
  ) async rethrows -> Result {

    return try await store.commit { ref, transaction in
      try ref.map(keyPath: scope, perform: {
        try mutation(&$0, &transaction)
      })
    }

  }

  /**
   Subscribe the state that scoped

   First object always returns true from ifChanged / hasChanges / noChanges unless dropsFirst is true.

   - Parameters:
   - dropsFirst: Drops the latest value on started. if true, receive closure will call from next state updated.
   - queue: Specify a queue to receive changes object.
   - Returns: A subscriber that performs the provided closure upon receiving values.
   */
  @_disfavoredOverload
  public nonisolated func sinkState(
    dropsFirst: Bool = false,
    queue: some TargetQueueType,
    receive: @escaping (Changes<Scope>) -> Void
  ) -> StoreSubscription {
    return store.sinkState(dropsFirst: dropsFirst, queue: queue, receive: { state in
      receive(state.map({ $0[keyPath: scope] }))
    })
  }

  /**
   Subscribe the state that scoped

   First object always returns true from ifChanged / hasChanges / noChanges unless dropsFirst is true.

   - Parameters:
   - dropsFirst: Drops the latest value on started. if true, receive closure will call from next state updated.
   - queue: Specify a queue to receive changes object.
   - Returns: A subscriber that performs the provided closure upon receiving values.
   */
  public nonisolated func sinkState(
    dropsFirst: Bool = false,
    queue: MainActorTargetQueue = .mainIsolated(),
    receive: @escaping @MainActor (Changes<Scope>) -> Void
  ) -> StoreSubscription {
    return store.sinkState(dropsFirst: dropsFirst, queue: queue, receive: { state in
      receive(state.map({ $0[keyPath: scope] }))
    })
  }
}

extension AsyncStoreDriverType where Scope == State {

  public var scope: WritableKeyPath<State, State> {
    \State.self
  }

  /// Run Mutation that created inline
  ///
  /// Throwable
  public func commit<Result>(
    mutation: @Sendable (inout InoutRef<Scope>) throws -> Result
  ) async rethrows -> Result {

    return try await store.commit(mutation: mutation)

  }

  /// Run Mutation that created inline
  ///
  /// Throwable
  public func commit<Result>(
    mutation: @Sendable (inout InoutRef<Scope>, inout Transaction) throws -> Result
  ) async rethrows -> Result {

    return try await store.commit(mutation: mutation)

  }
}

