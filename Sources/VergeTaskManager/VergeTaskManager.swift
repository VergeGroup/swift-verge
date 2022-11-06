import Foundation

public final class TaskManager: @unchecked Sendable, CustomReflectable {

  public struct TaskID: Hashable {
    public var raw: String

    public init(_ id: String) {
      self.raw = id
    }

    public static func distinct() -> Self {
      .init(UUID().uuidString)
    }
  }

  private struct InternalTaskID: Hashable {
    let publicID: TaskID
    let internalID: TaskID
  }

  public enum Mode {
    case dropCurrent
    //    case waitCurrent
  }

  // MARK: Lifecycle

  public init() {

  }

  deinit {
    cancelAll()
  }

  // MARK: Public
  
  /// Number of counts in current managing tasks
  public var count: Int {
    tasks.count
  }

  public var customMirror: Mirror {
    Mirror.init(
      self,
      children: [
        ("taskCount", tasks.count.description),
        ("tasks", tasks.description)
      ],
      displayStyle: .struct,
      ancestorRepresentation: .generated
    )
  }

  public func task(
    id: TaskID,
    mode: Mode,
    priority: TaskPriority = .userInitiated,
    _ action: @Sendable @escaping () async -> Void
  ) {

    lock.lock()
    defer {
      lock.unlock()
    }

    let internalID = TaskID.distinct()

    weak var weakSelf = self

    let task = Task(priority: priority) { [weakSelf] in

      await withTaskCancellationHandler {
        await action()
        weakSelf?.unmanageTask(internalID: internalID)
      } onCancel: {
        weakSelf?.unmanageTask(internalID: internalID)
      }

    }

    let anyTask = task as _Verge_TaskType

    if let item = tasks.first(where: { $0.0.publicID == id }) {
      unmanageTask(internalID: item.0.internalID)
      item.1.cancel()
    }

    tasks.append((.init(publicID: id, internalID: internalID), anyTask))

  }

  public func cancelAll() {

    lock.lock()
    defer {
      lock.unlock()
    }

    for (_, task) in tasks {
      task.cancel()
    }

    tasks.removeAll()
  }

  // MARK: Private

  private let lock = NSRecursiveLock()

  private var tasks: ContiguousArray<(InternalTaskID, any _Verge_TaskType)> = .init()

  private func unmanageTask(internalID: TaskID) {
    tasks.removeAll { $0.0.internalID == internalID }
  }

}

public protocol _Verge_TaskType {
  func cancel()
}

extension _Concurrency.Task: _Verge_TaskType {}
