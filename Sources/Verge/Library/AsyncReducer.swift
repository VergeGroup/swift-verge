import Foundation
import VergeTaskManager

open class AsyncReducer<Result: Equatable, Partial>: StoreComponentType {

  public let store: Store<Result, Never>

  public init(initialResult: Result) {

    self.store = .init(initialState: initialResult)

  }

  open func reduce(result: inout InoutRef<Result>, partial: Partial) {

  }

  public func task(
    key: VergeTaskManager.TaskKey = .distinct(),
    mode: VergeTaskManager.TaskManagerActor.Mode = .dropCurrent,
    priority: TaskPriority = .userInitiated,
    _ operation: @Sendable @escaping () async -> Partial
  ) async -> Task<(), Error> {

    await store.taskManager.task(key: key, mode: mode, priority: priority) { [weak self] in

      let partial = await operation()

      guard Task.isCancelled else {
        return
      }

      self?.store.commit { state in
        self?.reduce(result: &state, partial: partial)
      }
    }

  }

}
