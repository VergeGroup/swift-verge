import TypedIdentifier

/// a storage of the entity
public protocol TableType<Entity>: Equatable, Sendable {

  associatedtype Entity: EntityType

  typealias InsertionResult = VergeNormalization.InsertionResult<Entity>

  var updatedMarker: NonAtomicCounter { get }

  var count: Int { get }
  var isEmpty: Bool { get }

  borrowing func find(by id: consuming Entity.TypedID) -> Entity?

  borrowing func find(in ids: consuming some Sequence<Entity.TypedID>) -> [Entity]

  mutating func updateExists(
    id: consuming Entity.TypedID,
    update: (inout Entity) throws -> Void
  ) throws -> Entity

  mutating func updateIfExists(
    id: consuming Entity.TypedID,
    update: (inout Entity) throws -> Void
  ) rethrows -> Entity?

  @discardableResult
  mutating func insert(_ entity: consuming Entity) -> InsertionResult

  @discardableResult
  mutating func insert(_ addingEntities: consuming some Sequence<Entity>) -> [InsertionResult]

  mutating func remove(_ id: Entity.TypedID)

  mutating func removeAll()
}

/// An object indicates result of insertion
/// It can be used to create a getter object.
public struct InsertionResult<Entity: EntityType> {
  
  public var typedID: Entity.TypedID {
    entity.typedID
  }
  
  public let entity: Entity

  init(entity: consuming Entity) {
    self.entity = entity
  }
}
