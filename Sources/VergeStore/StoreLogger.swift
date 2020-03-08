
import Foundation

/// A protocol to register logger and get the event VergeStore emits.
public protocol StoreLogger {
  
  func didCommit(log: CommitLog)
  func didDispatch(log: DispatchLog)
  
  func didCreateDispatcher(log: DidCreateDispatcherLog)
  func didDestroyDispatcher(log: DidDestroyDispatcherLog)
}
