import TypedComparator

public enum NormalizedStorageComparators<Storage: NormalizedStorageType> {

  /// True indicates database is not changed
  public struct StorageComparator: TypedComparator {
    public typealias Input = Storage

    public init() {}

    public func callAsFunction(_ lhs: Input, _ rhs: Input) -> Bool {
      Storage.compare(lhs: lhs, rhs: rhs)
    }
  }

  /// Returns true if the table of the entity in database has no changes.
  public struct TableComparator<Table: TableType>: TypedComparator {

    public typealias Input = Table

    public init() {}

    public func callAsFunction(_ lhs: Input, _ rhs: Input) -> Bool {
      guard lhs.updatedMarker == rhs.updatedMarker else {
        return lhs == rhs
      }
      return true
    }

  }

  /// Returns true if the updates result does not contain the entity.
//  public struct UpdateComparison<Entity: EntityType>: Comparison {
//
//    public typealias Input = Storage
//
//    public let entityID: Entity.TypedID
//
//    public init(entityID: Entity.TypedID) {
//      self.entityID = entityID
//    }
//
//    public func callAsFunction(_ lhs: Storage, _ rhs: Storage) -> Bool {
//
//      fatalError()
//
////      guard let result = rhs._backingStorage.lastUpdatesResult else {
////        return false
////      }
////      guard !result.wasUpdated(entityID) else {
////        return false
////      }
////      guard !result.wasDeleted(entityID) else {
////        return false
////      }
////      return true
//
//    }
//  }

}

