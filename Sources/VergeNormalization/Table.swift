import struct HashTreeCollections.TreeDictionary

public struct Table<Entity: EntityType>: Equatable {

  public typealias Entity = Entity

  private var storage: TreeDictionary<Entity.EntityID, Entity>
  private(set) var updatedMarker = NonAtomicCounter()

  /// The number of entities in table
  public var count: Int {
    _read { yield storage.count }
  }

  /// A Boolean value that indicates whether the dictionary is empty.
  public var isEmpty: Bool {
    _read { yield storage.isEmpty }
  }

  public init(entities: TreeDictionary<Entity.EntityID, Entity> = .init()) {
    self.storage = entities
  }

  /// Returns all entity ids that stored.
  public borrowing func allIDs() -> TreeDictionary<Entity.EntityID, Entity>.Keys {
    return storage.keys
  }

  /// Returns all entity that stored.
  public borrowing func allEntities() -> some Collection {
    return storage
  }

  /**
   Finds an entity by the identifier of the entity.
   - Returns: An entity that found by identifier. Nil if the table does not have that entity.
   */
  public borrowing func find(by id: consuming Entity.EntityID) -> Entity? {
    return storage[id]
  }

  /// Finds entities by set of ids.
  /// The order of array would not be sorted, it depends on dictionary's buffer.
  ///
  /// if ids contains same id, result also contains same element.
  /// - Parameter ids: sequence of Entity.ID
  public borrowing func find<S: Sequence>(in ids: consuming S) -> [Entity] where S.Element == Entity.EntityID {

    return ids.reduce(into: [Entity]()) { (buf, id) in
      guard let entity = storage[id] else { return }
      buf.append(entity)
    }
  }

  /**
   Updates the entity that already exsisting in the table.

   - Attention: Please don't change `EntityType.entityID` value. if we changed, the crash happens (precondition)
   */
  @discardableResult
  @inline(__always)
  public mutating func updateExists(
    id: consuming Entity.EntityID,
    update: (inout Entity) throws -> Void
  ) throws -> Entity {

    guard var current = storage[id] else {
      throw ModifyingTransactionError.storedEntityNotFound
    }

    try update(&current)
    precondition(current.entityID == id)
    storage[id] = current

    updatedMarker.increment()

    return current
  }

  /**
   Updates the entity that already exsisting in the table.

   - Attention: Please don't change `EntityType.entityID` value. if we changed, the crash happens (precondition)
   */
  @discardableResult
  public mutating func updateIfExists(
    id: consuming Entity.EntityID,
    update: (inout Entity) throws -> Void
  ) rethrows -> Entity? {
    try? updateExists(id: id, update: update)
  }

  /**
   Inserts an entity
   */
  @discardableResult
  public mutating func insert(_ entity: consuming Entity) -> InsertionResult {

    let copied = copy entity

    storage[entity.entityID] = copied

    updatedMarker.increment()

    return .init(entity: copied)
  }

  /**
   Inserts a collection of the entity.
   */
  @discardableResult
  public mutating func insert<S: Sequence>(_ addingEntities: consuming S) -> [InsertionResult] where S.Element == Entity {

    let results = addingEntities.map { entity -> InsertionResult in
      storage[entity.entityID] = entity
      return .init(entity: entity)
    }

    updatedMarker.increment()

    return results
  }

  /**
   Removes the entity by the identifier.
   */
  public consuming func remove(_ id: Entity.EntityID) {
    storage.removeValue(forKey: id)
    updatedMarker.increment()
  }

  /**
   Removes the all of the entities in the table.
   */
  public consuming func removeAll() {
    storage.removeAll(where: { _ in true })
    updatedMarker.increment()
  }
}

extension Table {
  /// An object indicates result of insertion
  /// It can be used to create a getter object.
  public struct InsertionResult {
    public var entityID: Entity.EntityID {
      entity.entityID
    }
    public let entity: Entity

    init(entity: consuming Entity) {
      self.entity = entity
    }
  }
}
