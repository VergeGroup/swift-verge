import VergeTypedIdentifier

/// a storage of the entity
public protocol TableType<Entity>: Equatable {

  associatedtype Entity: EntityType

  typealias InsertionResult = VergeNormalization.InsertionResult<Entity>

  var updatedMarker: NonAtomicCounter { get }

  var count: Int { get }
  var isEmpty: Bool { get }

  borrowing func find(by id: consuming Entity.EntityID) -> Entity?

  borrowing func find(in ids: consuming some Sequence<Entity.EntityID>) -> [Entity]

  mutating func updateExists(
    id: consuming Entity.EntityID,
    update: (inout Entity) throws -> Void
  ) throws -> Entity

  mutating func updateIfExists(
    id: consuming Entity.EntityID,
    update: (inout Entity) throws -> Void
  ) rethrows -> Entity?

  @discardableResult
  mutating func insert(_ entity: consuming Entity) -> InsertionResult

  @discardableResult
  mutating func insert(_ addingEntities: consuming some Sequence<Entity>) -> [InsertionResult]

  mutating func remove(_ id: Entity.EntityID)

  mutating func removeAll()
}

/// An object indicates result of insertion
/// It can be used to create a getter object.
public struct InsertionResult<Entity: EntityType> {
  public var entityID: Entity.EntityID {
    entity.entityID
  }
  public let entity: Entity

  init(entity: consuming Entity) {
    self.entity = entity
  }
}
