import VergeNormalization

/// A value that wraps an entity and results of fetching.
public struct EntityWrapper<Entity: EntityType>: Sendable {

  public private(set) var wrapped: Entity?
  public let id: Entity.EntityID

  public init(id: Entity.EntityID, entity: Entity?) {
    self.id = id
    self.wrapped = entity
  }

}

extension EntityWrapper: Equatable where Entity: Equatable {

}

extension EntityWrapper: Hashable where Entity: Hashable {

}

