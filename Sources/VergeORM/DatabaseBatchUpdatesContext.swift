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

public final class EntityModifier<Schema: EntitySchemaType, E: EntityType>: EntityModifierType {
  
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
  
  private let keyPath: KeyPath<Schema, EntityTableKey<E>>
  
  /// An EntityTable contains entities that stored currently.
  public let current: EntityTable<Schema, E>
  /// An EntityTable contains entities that will be stored after batchUpdates finished.
  public var insertsOrUpdates: EntityTable<Schema, E>
  /// A set of entity ids that entity will be deleted after batchUpdates finished.
  public var deletes: Set<E.ID> = .init()
  
  init(current: EntityTable<Schema, E>, keyPath: KeyPath<Schema, EntityTableKey<E>>) {
    self.current = current
    self.keyPath = keyPath
    self.insertsOrUpdates = .init(keyPath: keyPath)
  }
    
  /// Updates existing entity from insertsOrUpdates or current.
  ///
  /// - Parameters:
  ///   - id:
  ///   - update:
  public func updateIfExists(id: E.ID, update: (inout E) -> Void) {
    
    if var target = current.find(by: id) {
      update(&target)
      insertsOrUpdates.insert(target)
      return
    }
    
    insertsOrUpdates.updateIfExists(id: id, update: update)
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
  
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<Schema, EntityTableKey<U>>) -> EntityModifier<Schema, U> {
    get {
      guard let rawTable = editing[U.entityName] else {
        let modifier = EntityModifier<Schema, U>(current: current[dynamicMember: keyPath], keyPath: keyPath)
        editing[U.entityName] = modifier
        return modifier
      }
      return rawTable as! EntityModifier<Schema, U>
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
      
      middlewareAfter: do {
        middlewares.forEach {
          $0.performAfterUpdates(context: context)
        }
      }
      
      apply: do {        
        self._backingStorage.entityBackingStorage.apply(edits: context.editing)
        context.indexes.apply(edits: context.editing)
        self._backingStorage.indexesStorage = context.indexes
      }
                             
      return result
    } catch {
      throw error
    }
  }
}
