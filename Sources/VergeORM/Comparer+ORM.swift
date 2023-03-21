//
// Copyright (c) 2019 muukii
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#if !COCOAPODS
import Verge
#endif

public enum DatabaseComparisons<Database: DatabaseType> {

  /// True indicates index storage is not changed
  public struct DatabaseIndexComparison: Comparison {

    public typealias Input = Database

    public func callAsFunction(_ lhs: Database, _ rhs: Database) -> Bool {
      lhs._backingStorage.indexUpdatedMarker == rhs._backingStorage.indexUpdatedMarker
    }

  }

  /// True indicates database is not changed
  public struct DatabaseComparison: Comparison {
    public typealias Input = Database

    public func callAsFunction(_ lhs: Database, _ rhs: Database) -> Bool {
      (lhs._backingStorage.entityUpdatedMarker, lhs._backingStorage.indexUpdatedMarker) == (rhs._backingStorage.entityUpdatedMarker, rhs._backingStorage.indexUpdatedMarker)
    }
  }

  /// Returns true if the table of the entity in database has no changes.
  ///
  /// - Complexity: O(1)
  public struct TableComparison<Entity: EntityType>: Comparison {

    public typealias Input = Database

    public func callAsFunction(_ lhs: Database, _ rhs: Database) -> Bool {
      lhs._backingStorage.entityBackingStorage.table(Entity.self).updatedMarker == rhs._backingStorage.entityBackingStorage.table(Entity.self).updatedMarker
    }

  }

  /// Returns true if the updates result does not contain the entity.
  public struct UpdateComparison<Entity: EntityType>: Comparison {

    public typealias Input = Database


    public let entityID: Entity.EntityID

    public init(entityID: Entity.EntityID) {
      self.entityID = entityID
    }

    public func callAsFunction(_ lhs: Database, _ rhs: Database) -> Bool {

      guard let result = rhs._backingStorage.lastUpdatesResult else {
        return false
      }
      guard !result.wasUpdated(entityID) else {
        return false
      }
      guard !result.wasDeleted(entityID) else {
        return false
      }
      return true

    }
  }

}

