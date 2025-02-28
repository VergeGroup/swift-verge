import Normalization
import StateStruct

public protocol NonNullEntityWrapperType: TrackingObject {
  associatedtype Entity: EntityType  
  
  var id: Entity.TypedID { get }
}

/// A value that wraps an entity and results of fetching.
@dynamicMemberLookup
@Tracking
public struct NonNullEntityWrapper<Entity: EntityType>: Sendable, NonNullEntityWrapperType {

  /// An entity value
  public let wrapped: Entity

  /// An identifier
  public let id: Entity.TypedID

  @available(*, deprecated, renamed: "isFallBack")
  public var isUsingFallback: Bool {
    isFallBack
  }

  /// A boolean value that indicates whether the wrapped entity is last value and has been removed from source store.
  public let isFallBack: Bool

  public init(entity: Entity, isFallBack: Bool) {
    self.id = entity.entityID
    self.wrapped = entity
    self.isFallBack = isFallBack
  }

  public subscript<Property>(dynamicMember keyPath: KeyPath<Entity, Property>) -> Property {
    wrapped[keyPath: keyPath]
  }

}

extension NonNullEntityWrapper: Equatable where Entity: Equatable {}

extension NonNullEntityWrapper: Hashable where Entity: Hashable {}

