
import Foundation

public actor TaskQueue {
    
  private var items: ContiguousArray<() async -> Void> = .init()
  
  private var isTaskProcessing = false
  
  public let label: String
  
  public init(label: String = "") {
    self.label = label
  }
  
  private func drain() {
    
    guard isTaskProcessing == false else {
      return
    }
    
    isTaskProcessing = true
    
    Task {
            
      guard self.items.isEmpty == false else {
        isTaskProcessing = false
        return
      }
      
      let item = self.items.removeFirst()
      
      await item()
            
      isTaskProcessing = false
      self.drain()
    }
  }
    
  private func _addTask(
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async -> Void
  ) {
        
    items.append {
      await operation()
    }
    
    if isTaskProcessing == false {
      drain()
    }
  }
  
  private func _addTask(
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async throws -> Void
  ) {
    
    items.append {
      do {
        try await operation()
      } catch {
        
      }
    }
    
    if isTaskProcessing == false {
      drain()
    }
  }
  
  public func cancelAllTasks() {
    items.removeAll()
  }
  
  public nonisolated func addTask(
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async -> Void
  ) {
        
    Task {
      await self._addTask(priority: priority, operation: operation)
    }
  }
  
  public nonisolated func addTask(
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async throws -> Void
  ) {
    
    Task {
      await self._addTask(priority: priority, operation: operation)
    }
  }
  
}
