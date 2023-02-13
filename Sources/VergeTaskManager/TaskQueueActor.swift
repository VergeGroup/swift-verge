import Foundation

private final class TaskNode {

  private struct State {

    var isFinished: Bool = false
    var isInvalidated: Bool = false

  }

  private var anyTask: _Verge_TaskType?

  let taskFactory: (TaskNode) async -> Void

  private(set) var next: TaskNode?

  @Published private var state: State = .init()

  init(
    taskFactory: @escaping @Sendable (TaskNode) async -> Void
  ) {
    self.taskFactory = taskFactory
  }

  /// Starts the deferred task
  func activate() {
    guard state.isInvalidated == false else { return }
    guard anyTask == nil else { return }

    self.anyTask = Task {
      await taskFactory(self)
      state.isFinished = true
    }
  }

  func invalidate() {
    state.isInvalidated = true
    anyTask?.cancel()
  }

  func addNext(_ node: TaskNode) {
    guard self.next == nil else {
      assertionFailure("next is already set.")
      return
    }
    self.next = node
  }

  func endpoint() -> TaskNode {
    sequence(first: self, next: \.next).map { $0 }.last ?? self
  }

  func wait() async {

    let stream = AsyncStream<State> { continuation in
      
      let cancellable = $state.sink { state in
        continuation.yield(state)
      }

      continuation.onTermination = { _ in
        cancellable.cancel()
      }

    }
    
    for await state in stream {
      if state.isInvalidated == true || state.isFinished == true {
        break
      }
    }

  }

}

public actor TaskQueueActor {

  @Published private var head: TaskNode?

  private var isTaskProcessing = false

  public let label: String

  public init(label: String = "") {
    self.label = label
  }

  deinit {

  }

  public func cancelAllTasks() {
    if let head {
      sequence(first: head, next: \.next).forEach {
        $0.invalidate()
      }
    }
  }

  @discardableResult
  public func addTask<Return>(
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async -> Return
  ) -> Task<Return, Never> {

    let ref = addTask(priority: priority) { () async throws -> Return in
      await operation()
    }

    let mapped = Task {
      do {
        return try await ref.value
      } catch {
        fatalError("Never happen")
      }
    }

    return mapped
  }

  @discardableResult
  public func addTask<Return>(
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async throws -> Return
  ) -> Task<Return, Error> {

    let extendedContinuation: UnsafeBox<CheckedContinuation<Return, Error>?> = .init(nil)

    let referenceTask = Task {
      return try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<Return, Error>) in
        extendedContinuation.value = continuation
      }
    }

    let newNode = TaskNode { [weak self] node in

      await withTaskCancellationHandler {
        do {
          let result = try await operation()
          guard Task.isCancelled == false else { return }
          extendedContinuation.value!.resume(returning: result)
        } catch {
          guard Task.isCancelled == false else { return }
          extendedContinuation.value!.resume(throwing: error)
        }
      } onCancel: {
        referenceTask.cancel()
      }
      
      // connecting to the next if presents

      await self?.batch {
        if let next = node.next {
          $0.head = next
          next.activate()
        } else {
          $0.head = nil
        }
      }

    }

    if let head {
      head.endpoint().addNext(newNode)
    } else {
      self.head = newNode
      newNode.activate()
    }

    return referenceTask
  }

  /**
   Waits until the current enqueued items are all processed
   */
  public func waitUntilAllItemProcessedInCurrent() async {
    await head?.endpoint().wait()
  }
  
  /**
   Waits until the all enqueued are processed.
   Including added items while processing.
   */
  public func waitUntilAllItemProcessed() async {
    
    let stream = AsyncStream<TaskNode?> { continuation in
      
      let cancellable = $head.sink { state in
        continuation.yield(state)
      }
      
      continuation.onTermination = { _ in
        cancellable.cancel()
      }
      
    }
    
    for await node in stream {
      if let node {
        await node.wait()
      } else {
        return
      }
    }
    
  }

  /**
   Performs given closure in a critical session
   */
  @discardableResult
  public func batch<Return>(_ perform: (isolated TaskQueueActor) -> Return) -> Return {
    return perform(self)
  }

}

private final class UnsafeBox<T>: @unchecked Sendable {

  var value: T

  init(_ value: T) {
    self.value = value
  }
}
