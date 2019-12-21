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

public enum BatchUpdateError: Error {
  case aborted
}

protocol EntityModifierType: AnyObject {
  
  var entityName: EntityName { get }
  var _insertsOrUpdates: EntityTableType { get }
  var _deletes: Set<AnyHashable> { get }
}

public final class EntityModifier<E: EntityType>: EntityModifierType {
  
  var _current: EntityTableType {
    current
  }
  
  var _insertsOrUpdates: EntityTableType {
    insertsOrUpdates
  }
  
  var _deletes: Set<AnyHashable> {
    deletes
  }
    
  let entityName = E.entityName
  
  public let current: EntityTable<E>
  public var insertsOrUpdates: EntityTable<E> = .init()
  public var deletes: Set<E.ID> = .init()
  
  init(current: EntityTable<E>) {
    self.current = current
  }
}

@dynamicMemberLookup
public class DatabaseEntityBatchUpdatesContext<Schema: EntitySchemaType> {
  
  private let current: EntityTablesStorage<Schema>
  var editing: [EntityName : EntityModifierType] = [:]
    
  init(current: EntityTablesStorage<Schema>) {
    self.current = current
  }
  
  public func abort() throws -> Never {
    throw BatchUpdateError.aborted
  }
  
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<Schema, EntityTableKey<U>>) -> EntityModifier<U> {
    get {
      guard let rawTable = editing[U.entityName] else {
        let modifier = EntityModifier(current: current[dynamicMember: keyPath])
        editing[U.entityName] = modifier
        return modifier
      }
      return rawTable as! EntityModifier<U>
    }
  }
  
}

public final class DatabaseBatchUpdatesContext<Database: DatabaseType>: DatabaseEntityBatchUpdatesContext<Database.Schema> {
  
  public var indexes: IndexesStorage<Database.Schema, Database.Indexes>
  
  init(current: Database) {
    self.indexes = current._backingStorage.indexesStorage
    super.init(current: current._backingStorage.entityBackingStorage)
  }
  
}

extension DatabaseType {
    
  /// Performs operations to update entities and indexes
  /// If can be run on background thread with locking.
  ///
  /// - Parameter update:
  public mutating func performBatchUpdates<Result>(_ update: (DatabaseBatchUpdatesContext<Self>) throws -> Result) rethrows -> Result {
            
    let context = DatabaseBatchUpdatesContext<Self>(current: self)
    do {
      let result = try update(context)
      
      middlewares.forEach {
        $0.performAfterUpdates(context: context)
      }
      
      do {
        var target = self._backingStorage.entityBackingStorage
        context.editing.forEach { _, value in
          
          target.apply(modifier: value)
          context.indexes.apply(removing: value._deletes, entityName: value.entityName)
        }
        self._backingStorage.entityBackingStorage = target
        self._backingStorage.indexesStorage = context.indexes
      }
                             
      return result
    } catch {
      throw error
    }
  }
}
