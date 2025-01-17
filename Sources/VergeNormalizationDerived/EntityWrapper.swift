import Normalization

public protocol EntityWrapperType {
  associatedtype Entity: EntityType
  
  var id: Entity.TypedID { get }
}

/// A value that wraps an entity and results of fetching.
public struct EntityWrapper<Entity: EntityType>: Sendable, EntityWrapperType {

  public let wrapped: Entity?
  
  public let id: Entity.TypedID

  public init(id: Entity.TypedID, entity: Entity?) {
    self.id = id
    self.wrapped = entity
  }

}

extension EntityWrapper: Equatable where Entity: Equatable {

}

extension EntityWrapper: Hashable where Entity: Hashable {

}

