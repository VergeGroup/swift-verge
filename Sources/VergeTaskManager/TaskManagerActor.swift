import Foundation

public protocol TaskKeyType {

}

/**
 
 ```swift
 enum MyRequestTask: TaskKeyType {}
 let key = TaskKey(MyRequestTask.self)
 ```
 
 */
public struct TaskKey: Hashable, Sendable, ExpressibleByStringLiteral {
  
  public typealias StringLiteralType = String

  private enum Node: Hashable, @unchecked Sendable {
    case int(Int)
    case int64(Int64)
    case string(String)
    case boolean(Bool)
    case type(ObjectIdentifier)
    case anyHashable(AnyHashable)
  }

  private var nodes: Set<Node>

  public init<Key: TaskKeyType>(_ key: Key.Type) {
    self.nodes = .init(arrayLiteral: .type(.init(Key.self)))
  }

  public init(_ hashableItem: some Hashable & Sendable) {
    self.nodes = .init(arrayLiteral: .anyHashable(hashableItem))
  }

  public init(_ value: Int64) {
    self.nodes = .init(arrayLiteral: .int64(value))
  }

  public init(_ value: Bool) {
    self.nodes = .init(arrayLiteral: .boolean(value))
  }

  public init(_ value: Int) {
    self.nodes = .init(arrayLiteral: .int(value))
  }

  public init(_ customString: String) {
    self.nodes = .init(arrayLiteral: .string(customString))
  }

  public init(stringLiteral customString: String) {
    self.nodes = .init(arrayLiteral: .string(customString))
  }

  /**
   Make new distinct key with others.
   Note that ignores the given key if it's already included in the current.
   */
  public func combined(_ other: TaskKey) -> Self {
    var new = self
    new.nodes.formUnion(other.nodes)
    return new
  }

  /// Make with a new unique identifier
  public static func distinct() -> Self {
    .init(UUID().uuidString)
  }

}

/**
 An actor that manages tasks by specified keys.
 It enqueues a given task into a separated queue by key.
 Consumers can specify how to handle the current task as dropping it or waiting for it. 
 */
public actor TaskManagerActor {

  public struct Configuration {

    public init() {

    }
  }
 
  public enum Mode: Sendable {
    /**
     Cancels the current running task then start a new task.
     */
    case dropCurrent
    /**
     Waits the current task finished then start a new task.
     */
    case waitInCurrent
  }

  // MARK: Lifecycle

  public init(configuration: Configuration = .init()) {
    self.configuration = configuration
  }

  deinit {
  }

  // MARK: Public

  public let configuration: Configuration

  /**
   Returns a Boolean value that indicates whether the task for given key is currently running.
   */
  public func isRunning(for key: TaskKey) -> Bool {
    return queues[key] != nil
  }
  
  /// Registers an asynchronous operation
  ///
  /// Task's Error may be ``CancellationError``
  /// - Parameters:
  ///   - label: String value for debugging
  ///   - key: ``TaskKey`` value takes associated operations. It creates queues for each key.
  ///   - mode: Mode tells the queue how controls the given new operation. to run immediately with drop all current operation or wait all them.
  ///   - priority:
  ///   - action:
  /// - Returns: An Task to track the operation's completion.
  @discardableResult
  public func task<Return>(
    label: String = "",
    key: TaskKey,
    mode: Mode,
    priority: TaskPriority = .userInitiated,
    @_inheritActorContext _ operation: @Sendable @escaping () async throws -> Return
  ) -> Task<Return, Error> {

    let extendedContinuation: AutoReleaseContinuationBox<Return> = .init(nil)

    let referenceTask = Task { [weak extendedContinuation] in
      return try await withUnsafeThrowingContinuation{ (continuation: UnsafeContinuation<Return, Error>) in
        extendedContinuation?.continuation = continuation
      }
    }

    let newNode = TaskNode(label: label) { [weak self] box in

      await withTaskCancellationHandler {
        do {
          let result = try await operation()

          guard Task.isCancelled == false else {
            extendedContinuation.resume(throwing: CancellationError())
            return
          }

          extendedContinuation.resume(returning: result)

        } catch {

          guard Task.isCancelled == false else {
            extendedContinuation.resume(throwing: CancellationError())
            return
          }

          extendedContinuation.resume(throwing: error)

        }
      } onCancel: {
        referenceTask.cancel()
      }

      // connecting to the next if presents

      guard let self = self, let node = box.value else { return }

      await self.loopback(key: key, completedNode: node)

    }

    switch mode {
    case .dropCurrent:

      self.queues[key]?.forEach {
        $0.invalidate()
      }

      self.queues[key] = newNode
      newNode.activate()

    case .waitInCurrent:

      if let head = self.queues[key] {
        head.endpoint().addNext(newNode)
      } else {
        self.queues[key] = newNode
        newNode.activate()
      }

    }

    return referenceTask
    
  }

  public func taskDetached<Return>(
    label: String = "",
    key: TaskKey,
    mode: Mode,
    priority: TaskPriority = .userInitiated,
    _ action: @Sendable @escaping () async throws -> Return
  ) -> Task<Return, Error> {
    task(label: label, key: key, mode: mode, priority: priority, action)
  }

  public func batch(_ closure: (isolated TaskManagerActor) -> Void) {
    closure(self)
  }

  public func batch(_ closure: (isolated TaskManagerActor) async -> Void) async {
    await closure(self)
  }

  /**
   Cancells all tasks managed in this manager.
   */
  public func cancelAll() async {

    for head in queues.values {
      for node in sequence(first: head, next: \.next) {
        node.invalidate()
      }
    }

    queues.removeAll()
  }

  private func loopback(key: TaskKey, completedNode: TaskNode) {

    if let node = queues[key] {

      if let next = node.next {
        next.activate()
        queues[key] = next
      } else {
        if node === completedNode {
          queues.removeValue(forKey: key)
        }
      }
    } else {
      assertionFailure()
    }

    Log.debug(.taskManager, queues)

  }

  // MARK: Private
  
  private var queues: [TaskKey : TaskNode] = [:]
  
}
