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
import VergeStore
#endif

extension Comparer where Input : DatabaseType {

  /// Returns true if Database has no changes.
  ///
  /// - Complexity: O(1)
  public static func databaseNoUpdates() -> Self {
    return .init { pre, new in
      (pre._backingStorage.entityUpdatedMarker, pre._backingStorage.indexUpdatedMarker) == (new._backingStorage.entityUpdatedMarker, new._backingStorage.indexUpdatedMarker)
    }
  }
  
  public static func indexNoUpdates() -> Self {
    return .init { pre, new in
      pre._backingStorage.indexUpdatedMarker == new._backingStorage.indexUpdatedMarker
    }
  }

  /// Returns true if the table of the entity in database has no changes.
  ///
  /// - Complexity: O(1)
  public static func tableNoUpdates<E: EntityType>(_ entityType: E.Type) -> Self {
    Comparer.init(selector: {
      $0._backingStorage.entityBackingStorage.table(E.self).updatedMarker      
    })
  }

  /// Returns true if the entity has no changes.
  ///
  /// - Complexity: O(1)
  public static func entityNoUpdates<E: EntityType & Equatable>(_ entityID: E.EntityID) -> Self {
    return .init(selector: { $0.entities.table(E.self).find(by: entityID) })
  }

  /// Returns true if the updates result does not contain the entity.
  public static func changesNoContains<E: EntityType>(_ entityID: E.EntityID) -> Self {
    return .init { _, new in
      guard let result = new._backingStorage.lastUpdatesResult else {
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
