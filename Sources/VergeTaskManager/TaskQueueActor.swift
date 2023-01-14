
import Foundation

public actor TaskQueueActor {
    
  @Published private var items: ContiguousArray<() async -> Void> = .init()
  
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
      
      let item = self.items.first!
      
      await item()
      
      if self.items.isEmpty == false {
        self.items.removeFirst()
      }
            
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
  
  public func addTask(
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async -> Void
  ) {
        
    self._addTask(priority: priority, operation: operation)
  }
  
  public func addTask(
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async throws -> Void
  ) {
    
    self._addTask(priority: priority, operation: operation)
  }
  
  public func waitUntilAllItemProcessed() async {
           
    let stream = AsyncStream<ContiguousArray<() async -> Void>> { continuation in
      
      let cancellable = $items.sink { value in
        continuation.yield(value)
      }
      
      continuation.onTermination = { _ in
        cancellable.cancel()
      }
      
    }
                
    for await items in stream {
      if items.isEmpty {
        return
      }
    }
        
  }
  
}
