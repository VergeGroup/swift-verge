import Foundation

protocol _Verge_TaskType {
  func cancel()
}

extension _Concurrency.Task: _Verge_TaskType {}
