
import Foundation

/// A protocol to register logger and get the event VergeStore emits.
public protocol StoreLogger {
  
  func willCommit(store: AnyObject, state: Any, mutation: MutationMetadata, context: Any?)
  func didCommit(store: AnyObject, state: Any, mutation: MutationMetadata, context: Any?, time: CFTimeInterval)
  func didDispatch(store: AnyObject, state: Any, action: ActionMetadata, context: Any?)
  
  func didCreateDispatcher(store: AnyObject, dispatcher: Any)
  func didDestroyDispatcher(store: AnyObject, dispatcher: Any)
}
