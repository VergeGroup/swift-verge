import struct HashTreeCollections.TreeDictionary

extension Tables {

  /**
   A table that stores entities with hash table.
   */
  public struct Hash<Entity: EntityType>: TableType, Sendable {

    public typealias Entity = Entity

    private var storage: TreeDictionary<Entity.EntityID, Entity>
    public private(set) var updatedMarker = NonAtomicCounter()

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
    public borrowing func allEntities() -> some Collection<Entity> {
      return storage.values
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
    public borrowing func find(in ids: consuming some Sequence<Entity.EntityID>) -> [Entity] {

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
    public mutating func insert(_ entity: Entity) -> Self.InsertionResult {

      storage[entity.entityID] = entity

      updatedMarker.increment()

      return .init(entity: entity)
    }

    /**
     Inserts a collection of the entity.
     */
    @discardableResult
    public mutating func insert(_ addingEntities: consuming some Sequence<Entity>) -> [Self.InsertionResult] {

      let results = addingEntities.map { entity -> Self.InsertionResult in
        storage[entity.entityID] = entity
        return .init(entity: entity)
      }

      updatedMarker.increment()

      return results
    }

    /**
     Removes the entity by the identifier.
     */
    public mutating func remove(_ id: Entity.EntityID) {
      storage.removeValue(forKey: id)
      updatedMarker.increment()
    }

    /**
     Removes the all of the entities in the table.
     */
    public mutating func removeAll() {
      storage.removeAll(where: { _ in true })
      updatedMarker.increment()
    }
  }
}
