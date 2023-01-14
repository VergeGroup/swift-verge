import Foundation

public protocol TaskKeyType {
  
}

public struct TaskKey: Hashable {
  
  private struct TypedKey: Hashable {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.metatype == rhs.metatype
    }
    
    func hash(into hasher: inout Hasher) {
      hasher.combine(ObjectIdentifier(metatype))
    }
    
    let metatype: Any.Type
    
    init<T>(base: T.Type) {
      self.metatype = base
    }
    
  }
  
  private enum Node: Hashable {
    case customString(String)
    case type(TypedKey)
  }
  
  private let node: Node
  
  public init<Key: TaskKeyType>(_ key: Key.Type) {
    self.node = .type(.init(base: Key.self))
  }
  
  public init(_ customString: String) {
    self.node = .customString(customString)
  }
  
  public static func distinct() -> Self {
    .init(UUID().uuidString)
  }
  
}

public final class TaskManager: @unchecked Sendable, CustomReflectable {
  
  public struct Configuration {
    
    public init() {
      
    }
  }
  
  private struct TaskID: Hashable {
    var raw: String
    
    init(_ id: String) {
      self.raw = id
    }
    
    static func distinct() -> Self {
      .init(UUID().uuidString)
    }
  }

  private struct DistinctID: Hashable {
    let key: TaskKey
    let internalID: TaskID
  }
  
  public enum Mode {
    case dropCurrent
    //    case waitCurrent
  }

  // MARK: Lifecycle

  public init(configuration: Configuration = .init()) {
    self.configuration = configuration
  }

  deinit {
    cancelAll()
  }

  // MARK: Public
  
  public let configuration: Configuration
  
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
  
  public func isRunning(key: TaskKey) -> Bool {
    return tasks.first(where: { $0.0.key == key }) != nil
  }

  public func task(
    key: TaskKey,
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

    let task = Task.detached(priority: priority) { [weakSelf] in

      await withTaskCancellationHandler {
        await action()
        weakSelf?.unmanageTask(internalID: internalID)
      } onCancel: {
        weakSelf?.unmanageTask(internalID: internalID)
      }

    }

    let anyTask = task as _Verge_TaskType

    if let item = tasks.first(where: { $0.0.key == key }) {
      switch mode {
      case .dropCurrent:
        unmanageTask(internalID: item.0.internalID)
        item.1.cancel()
      }
    }

    tasks.append((.init(key: key, internalID: internalID), anyTask))

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

  private var tasks: ContiguousArray<(DistinctID, any _Verge_TaskType)> = .init()

  private func unmanageTask(internalID: TaskID) {
    tasks.removeAll { $0.0.internalID == internalID }
  }

}
