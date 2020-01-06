import os

@available(iOS 12, macOS 10.14, *)
fileprivate enum Static {
  static let log = OSLog(subsystem: "me.muukii.Verge", category: "performance")
}

public struct SignpostTransaction {
  
  @usableFromInline
  let _end: () -> Void
  
  public init(_ name: StaticString) {
    if #available(iOS 12, macOS 10.14, *) {
      let id = OSSignpostID(log: Static.log)
      os_signpost(.begin, log: Static.log, name: name, signpostID: id)
      _end = {
        os_signpost(.end, log: Static.log, name: name, signpostID: id)
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
