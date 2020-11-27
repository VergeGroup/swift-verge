import os

public var _verge_signpost_enabled = false

@available(iOS 12, macOS 10.14, tvOS 12, watchOS 5, *)
@usableFromInline
enum SignpostConstants {
  @usableFromInline
  static let performanceLog = { () -> OSLog in
    if #available(iOSApplicationExtension 13.0, *) {
      return OSLog(subsystem: "lib.verge", category: "performance")
    } else {
      return OSLog(subsystem: "lib.verge", category: "performance")
    }
  }()
  @usableFromInline
  static let pointOfInterestLog = OSLog(subsystem: "lib.verge", category: .pointsOfInterest)
}

@inlinable
public func vergeSignpostEvent(_ event: StaticString) {
  #if DEBUG
  if #available(iOS 12, macOS 10.14, tvOS 12, watchOS 5, *), _verge_signpost_enabled {
    let id = OSSignpostID(log: SignpostConstants.pointOfInterestLog)
    os_signpost(.event, log: SignpostConstants.pointOfInterestLog, name: event, signpostID: id)
  }
  #endif
}

@inlinable
public func vergeSignpostEvent(_ event: StaticString, label: @autoclosure () -> String) {
  #if DEBUG
  if #available(iOS 12, macOS 10.14, tvOS 12, watchOS 5, *), _verge_signpost_enabled {
    let id = OSSignpostID(log: SignpostConstants.pointOfInterestLog)
    os_signpost(.event, log: SignpostConstants.pointOfInterestLog, name: event, signpostID: id, "%@", label())
  }
  #endif
}


public struct VergeSignpostTransaction {
  
  #if DEBUG
  @usableFromInline
  let _end: () -> Void
  public let rawID: os_signpost_id_t
  #endif
  
  @inlinable
  @inline(__always)
  public init(_ name: StaticString) {
    #if DEBUG
    if #available(iOS 12, macOS 10.14, tvOS 12, watchOS 5, *), _verge_signpost_enabled {
      let id = OSSignpostID(log: SignpostConstants.performanceLog)
      self.rawID = id.rawValue
      os_signpost(.begin, log: SignpostConstants.performanceLog, name: name, signpostID: id)
      _end = {
        os_signpost(.end, log: SignpostConstants.performanceLog, name: name, signpostID: id)
      }
    } else {
      rawID = 0
      _end = {}
    }
    #else
    #endif
  }
  
  @inlinable
  @inline(__always)
  public init(_ name: StaticString, label: @autoclosure () -> String) {
    #if DEBUG
    if #available(iOS 12, macOS 10.14, tvOS 12, watchOS 5, *), _verge_signpost_enabled {
      let id = OSSignpostID(log: SignpostConstants.performanceLog)
      self.rawID = id.rawValue
      let _label = label()
      os_signpost(.begin, log: SignpostConstants.performanceLog, name: name, signpostID: id, "Begin: %@", _label)
      _end = {
        os_signpost(.end, log: SignpostConstants.performanceLog, name: name, signpostID: id, "End: %@", _label)
      }
    } else {
      rawID = 0
      _end = {}
    }
    #else
    #endif
  }
  
  @inlinable
  @inline(__always)
  public func event(name: StaticString, label: @autoclosure () -> String) {
    #if DEBUG
    if #available(iOS 12, macOS 10.14, tvOS 12, watchOS 5, *), _verge_signpost_enabled {
      let id = OSSignpostID(rawID)
      os_signpost(.event, log: SignpostConstants.pointOfInterestLog, name: name, signpostID: id, "%@", label())
    }
    #endif
  }
  
  @inlinable
  @inline(__always)
  public func event(name: StaticString) {
    #if DEBUG
    if #available(iOS 12, macOS 10.14, tvOS 12, watchOS 5, *), _verge_signpost_enabled {
      let id = OSSignpostID(rawID)
      os_signpost(.event, log: SignpostConstants.pointOfInterestLog, name: name, signpostID: id)
    }
    #endif
  }
  
  @inlinable
  @inline(__always)
  public func end() {
    #if DEBUG
    _end()
    #endif
  }
}
