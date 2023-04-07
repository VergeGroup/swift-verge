import Foundation

final class TaskNode: CustomStringConvertible {

  struct WeakBox<T: AnyObject> {
    weak var value: T?
  }

  private struct State {

    var isFinished: Bool = false
    var isInvalidated: Bool = false

  }

  private var anyTask: _Verge_TaskType?

  let taskFactory: (WeakBox<TaskNode>) async -> Void

  private(set) var next: TaskNode?
  let label: String

  @Published private var state: State = .init()

  init(
    label: String = "",
    @_inheritActorContext taskFactory: @escaping @Sendable (WeakBox<TaskNode>) async -> Void
  ) {
    self.label = label
    self.taskFactory = taskFactory
  }

  /// Starts the deferred task
  func activate() {
    guard state.isInvalidated == false else { return }
    guard anyTask == nil else { return }

    Log.debug(.taskNode, "activate: \(label) <\(Unmanaged.passUnretained(self).toOpaque())>")

    self.anyTask = Task { [weak self] in
      await self?.taskFactory(.init(value: self))
      self?.state.isFinished = true
    }
  }

  func invalidate() {
    Log.debug(.taskNode, "invalidated \(label) <\(Unmanaged.passUnretained(self).toOpaque())>")
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
    sequence(first: self, next: \.next).compactMap { $0 }.last!
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
  
  deinit {
    Log.debug(.taskNode, "Deinit: \(label) <\(Unmanaged.passUnretained(self).toOpaque())>")
  }

  var description: String {
    let chain = sequence(first: self, next: \.next).compactMap { $0 }.map {"<\(Unmanaged.passUnretained($0).toOpaque())>:\($0.label)" }.joined(separator: " -> ")
    return "\(chain)"
  }

  func forEach(_ closure: (TaskNode) -> Void) {
    sequence(first: self, next: \.next).forEach(closure)
  }
}

public actor TaskQueueActor {

  public var hasTask: Bool {
    head != nil
  }

  @Published private var head: TaskNode?

  private var isTaskProcessing = false

  public let label: String

  public init(label: String = "") {
    Log.debug(.taskQueue, "Init Queue: \(label)")
    self.label = label
  }

  deinit {

  }

  public func cancelAllTasks() {
    Log.debug(.taskQueue, "Cancell all task")
    if let head {
      sequence(first: head, next: \.next).forEach {
        $0.invalidate()
      }
    }
    self.head = nil
  }

  @discardableResult
  public func addTask<Return>(
    label: String = "",
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async throws -> Return
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

      await self?.batch {
        guard let node = box.value else { return }
        if let next = node.next {
          $0.head = next
          next.activate()
        } else {
          if $0.head === node {
            $0.head = nil
          }
        }
      }
      
    }

    if let head {
      head.endpoint().addNext(newNode)
      Log.debug(.taskQueue, "Add \(label) currentHead: \(head as Any)")
    } else {
      Log.debug(.taskQueue, "Add \(label) as head")
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
        break
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

final class AutoReleaseContinuationBox<T>: @unchecked Sendable {

  var continuation: UnsafeContinuation<T, Error>?
  private var wasConsumed: Bool = false

  init(_ value: UnsafeContinuation<T, Error>?) {
    self.continuation = value
  }
  
  deinit {
    resume(throwing: CancellationError())
  }
  
  func resume(throwing error: Error) {
    guard wasConsumed == false else {
      return
    }
    wasConsumed = true
    continuation?.resume(throwing: error)
  }
  
  func resume(returning value: T) {
    guard wasConsumed == false else {
      return
    }
    wasConsumed = true
    continuation?.resume(returning: value)
  }
    
}
