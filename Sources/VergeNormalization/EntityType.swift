@_exported import TypedIdentifier

public protocol EntityType: TypedIdentifiable, Equatable, Sendable {
}

extension EntityType {
  public var entityID: TypedID { 
    return typedID
  }
}
