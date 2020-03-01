import os

@available(iOS 12, macOS 10.14, *)
@usableFromInline
enum SignpostConstants {
  @usableFromInline
  static let performanceLog = OSLog(subsystem: "me.muukii.Verge", category: "performance")
  @usableFromInline
  static let activityLog = OSLog(subsystem: "me.muukii.Verge", category: "activity")
}

@inlinable
public func vergeSignpostEvent(_ event: StaticString) {
  if #available(iOS 12, macOS 10.14, *) {
    os_signpost(.event, log: SignpostConstants.activityLog, name: event)
  }
}

public struct VergeSignpostTransaction {
  
  @usableFromInline
  let _end: () -> Void
  
  public init(_ name: StaticString) {
    if #available(iOS 12, macOS 10.14, *) {
      let id = OSSignpostID(log: SignpostConstants.performanceLog)
      os_signpost(.begin, log: SignpostConstants.performanceLog, name: name, signpostID: id)
      _end = {
        os_signpost(.end, log: SignpostConstants.performanceLog, name: name, signpostID: id)
      }
    } else {
      _end = {}
    }
  }
  
  public init(_ name: StaticString, label: String) {
    if #available(iOS 12, macOS 10.14, *) {
      let id = OSSignpostID(log: SignpostConstants.performanceLog)
      os_signpost(.begin, log: SignpostConstants.performanceLog, name: name, signpostID: id, "Begin: %@", label)
      _end = {
        os_signpost(.end, log: SignpostConstants.performanceLog, name: name, signpostID: id, "End: %@", label)
      }
    } else {
      _end = {}
    }
  }
    
  @inlinable
  public func end() {
    _end()
  }
}
