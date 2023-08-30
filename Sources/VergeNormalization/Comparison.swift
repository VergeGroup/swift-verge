import VergeComparator

public enum NormalizedStorageComparisons<Storage: NormalizedStorageType> {

  /// True indicates database is not changed
  public struct StorageComparison: Comparison {
    public typealias Input = Storage

    public func callAsFunction(_ lhs: Storage, _ rhs: Storage) -> Bool {

      lhs == rhs

//      (lhs._backingStorage.entityUpdatedMarker, lhs._backingStorage.indexUpdatedMarker) == (rhs._backingStorage.entityUpdatedMarker, rhs._backingStorage.indexUpdatedMarker)
    }
  }

  /// Returns true if the table of the entity in database has no changes.
  ///
  /// - Complexity: O(1)
  public struct TableComparison<Entity: EntityType>: Comparison {

    public typealias Input = Storage

    public func callAsFunction(_ lhs: Storage, _ rhs: Storage) -> Bool {
//      lhs._backingStorage.entityBackingStorage.table(Entity.self).updatedMarker == rhs._backingStorage.entityBackingStorage.table(Entity.self).updatedMarker
      fatalError()
    }

  }

  /// Returns true if the updates result does not contain the entity.
  public struct UpdateComparison<Entity: EntityType>: Comparison {

    public typealias Input = Storage


    public let entityID: Entity.EntityID

    public init(entityID: Entity.EntityID) {
      self.entityID = entityID
    }

    public func callAsFunction(_ lhs: Storage, _ rhs: Storage) -> Bool {

      fatalError()

//      guard let result = rhs._backingStorage.lastUpdatesResult else {
//        return false
//      }
//      guard !result.wasUpdated(entityID) else {
//        return false
//      }
//      guard !result.wasDeleted(entityID) else {
//        return false
//      }
//      return true

    }
  }

}

