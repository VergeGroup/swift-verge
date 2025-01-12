import Normalization

/// A value that wraps an entity and results of fetching.
public struct EntityWrapper<Entity: EntityType>: Sendable {

  public private(set) var wrapped: Entity?
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

