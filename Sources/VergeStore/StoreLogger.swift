
import Foundation

enum Static {
  
  static let dateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter.init()
    formatter.formatOptions = [.withFullDate, .withFullTime]
    return formatter
  }()
  
}

/// A protocol to register logger and get the event VergeStore emits.
public protocol StoreLogger {
  
  func willCommit(store: AnyObject, state: Any, mutation: MutationMetadata)
  func didCommit(store: AnyObject, state: Any, mutation: MutationMetadata, time: CFTimeInterval)
  func didDispatch(store: AnyObject, state: Any, action: ActionMetadata)
  
  func didCreateDispatcher(store: AnyObject, dispatcher: Any)
  func didDestroyDispatcher(store: AnyObject, dispatcher: Any)
}
