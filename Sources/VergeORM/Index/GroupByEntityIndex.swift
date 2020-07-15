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

import Foundation

@available(*, deprecated, renamed: "GroupByEntityIndex")
public typealias GroupByIndex<
  Schema: EntitySchemaType,
  GroupEntity: EntityType,
  GroupedEntity: EntityType
  > = GroupByEntityIndex<
  Schema,
  GroupEntity,
  GroupedEntity
>

/// A Indexing store
///
/// {
///   Grouping-ID : [
///     - Grouped-ID
///     - Grouped-ID
///     - Grouped-ID
///   ],
///   Grouping-ID : [
///     - Grouped-ID
///     - Grouped-ID
///     - Grouped-ID
///   ]
/// }
///
public struct GroupByEntityIndex<
  Schema: EntitySchemaType,
  GroupEntity: EntityType,
  GroupedEntity: EntityType
>: IndexType, Equatable {
  
  private var backing: [GroupEntity.EntityID : OrderedIDIndex<Schema, GroupedEntity>] = [:]
  
  public init() {
    
  }
  
  // MARK: - Querying
  
  public func groupCount() -> Int {
    backing.keys.count
  }
  
  public func groups() -> Set<GroupEntity.EntityID> {
    Set(backing.keys)
  }

  /// Returns stored identifier related with the grouping identifier
  ///
  /// - Complexity: O(n)
  /// - Parameter groupEntityID:
  /// - Returns:
  public func orderedID(in groupEntityID: GroupEntity.EntityID) -> OrderedIDIndex<Schema, GroupedEntity> {
    backing[groupEntityID, default: .init()]
  }
  
  // MARK: - Mutating
    
  /// Internal method
  /// - Parameters:
  ///   - removing: a set of entity id that will be removed from store
  ///   - entityName: the entity name of removing
  public mutating func _apply(removing: Set<AnyHashable>, entityName: EntityTableIdentifier) {
    
    if GroupEntity.entityName == entityName {
      removing.forEach {
        backing.removeValue(forKey: $0 as! GroupEntity.EntityID)
      }
    }
    
    if GroupedEntity.entityName == entityName {
      backing.keys.forEach { key in
        backing[key]?._apply(removing: removing, entityName: entityName)
        
        cleanup: do {
          
          if backing[key]?.isEmpty == true {
            backing.removeValue(forKey: key)
          }
          
        }
      }
    }
    
  }
      
  public mutating func update(in groupEntityID: GroupEntity.EntityID, update: (inout OrderedIDIndex<Schema, GroupedEntity>) -> Void) {
    update(&backing[groupEntityID, default: .init()])
  }
      
  public mutating func removeGroup(_ groupEntityID: GroupEntity.EntityID) {
    backing.removeValue(forKey: groupEntityID)
  }
      
}
