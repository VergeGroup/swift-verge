
import Foundation

/// A protocol to register logger and get the event VergeStore emits.
public protocol StoreLogger {
  
  func didCommit(log: CommitLog, sender: AnyObject)
  func didSendActivity(log: ActivityLog, sender: AnyObject)

  func didCreateDispatcher(log: DidCreateDispatcherLog, sender: AnyObject)
  func didDestroyDispatcher(log: DidDestroyDispatcherLog, sender: AnyObject)
}
