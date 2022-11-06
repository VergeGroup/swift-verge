import Foundation
import Atomics

public actor TaskManager {
  
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
    
  }
  
  // MARK: Public
    
  public func task(
    id: TaskID,
    mode: Mode,
    priority: TaskPriority = .userInitiated,
    _ action: @Sendable @escaping () async -> Void
  ) {
    
    let internalID = TaskID.distinct()
    
    let task = Task(priority: priority) {
      
      await withTaskCancellationHandler {
        await action()
      } onCancel: {
        
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
    for (_, task) in tasks {
      task.cancel()
    }
  }
  
  // MARK: Private
  
  private var tasks: ContiguousArray<(InternalTaskID, any _Verge_TaskType)> = .init()
  
  private func unmanageTask(internalID: TaskID) {
    tasks.removeAll { $0.0.internalID == internalID }
  }
  
}

public protocol _Verge_TaskType {
  func cancel()
}

extension _Concurrency.Task: _Verge_TaskType {}
