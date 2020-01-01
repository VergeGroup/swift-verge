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

/// For performBatchUpdates
public final class EntityModifier<Schema: EntitySchemaType, Entity: EntityType>: EntityModifierType {
  
  public typealias InsertionResult = EntityTable<Schema, Entity>.InsertionResult
  
  var _current: EntityTableType {
    current
  }
  
  var _insertsOrUpdates: EntityTableType {
    insertsOrUpdates
  }
  
  var _deletes: Set<AnyHashable> {
    deletes
  }
    
  let entityName = Entity.entityName
    
  /// An EntityTable contains entities that stored currently.
  public let current: EntityTable<Schema, Entity>
    
  /// An EntityTable contains entities that will be stored after batchUpdates finished.
  /// The objects this table contains would be applied, that's why it's mutable property.
  public var insertsOrUpdates: EntityTable<Schema, Entity>
    
  /// A set of entity ids that entity will be deleted after batchUpdates finished.
  /// The current entities will be deleted with this identifiers.
  public var deletes: Set<Entity.ID> = .init()
  
  init(current: EntityTable<Schema, Entity>) {
    self.current = current
    self.insertsOrUpdates = .init()
  }
  
  // MARK: - Querying
    
  /// Find entity from updates and current.
  ///
  /// Firstly, find from updates and then find from current.
  /// - Parameter id:
  public func find(by id: Entity.ID) -> Entity? {
    insertsOrUpdates.find(by: id) ?? current.find(by: id)
  }
  
  /// Find entities from updates and current.
  ///
  /// Firstly, find from updates and then find from current.
  /// - Parameter id:
  public func find<S: Sequence>(in ids: S) -> [Entity] where S.Element == Entity.ID {
    insertsOrUpdates.find(in: ids) + current.find(in: ids)
  }
  
  // MARK: - Mutating
  
  /// Set inserts entity
  @discardableResult
  public func insert(_ entity: Entity) -> InsertionResult {
    insertsOrUpdates.insert(entity)
  }
  
  /// Set inserts entities
  @discardableResult
  public func insert<S: Sequence>(_ addingEntities: S) -> [InsertionResult] where S.Element == Entity {
    insertsOrUpdates.insert(addingEntities)
  }
    
  /// Set deletes entity with entity object
  /// - Parameter entity:
  public func delete(_ entity: Entity) {
    deletes.insert(entity.id)
  }
    
  /// Set deletes entity with identifier
  /// - Parameter entityID:
  public func delete(_ entityID: Entity.ID) {
    deletes.insert(entityID)
  }
  
  /// Set deletes entities with passed entities.
  /// - Parameter entities:
  public func delete<S: Sequence>(_ entities: S) where S.Element == Entity {
    deletes.formUnion(entities.lazy.map { $0.id })
  }
    
  /// Set deletes entities with passed sequence of entity's identifier.
  /// - Parameter entityIDs:
  public func delete<S: Sequence>(_ entityIDs: S) where S.Element == Entity.ID {
    deletes.formUnion(entityIDs)
  }
    
  /// Set deletes all entities
  public func deleteAll() {
    deletes.formUnion(current.allIDs())
  }
    
  /// Updates existing entity from insertsOrUpdates or current.
  /// It's never been called update closure if the entity was not found.
  ///
  /// - Parameters:
  ///   - id:
  ///   - update:
  public func updateIfExists(id: Entity.ID, update: (inout Entity) throws -> Void) rethrows {
    
    if insertsOrUpdates.find(by: id) != nil {
      try insertsOrUpdates.updateIfExists(id: id, update: update)
      return
    }
    
    if var target = current.find(by: id) {
      try update(&target)
      insertsOrUpdates.insert(target)
      return
    }
        
  }
  
}

extension EntityModifier where Entity : Hashable {
  
  public func find<S: Sequence>(in ids: S) -> Set<Entity> where S.Element == Entity.ID {
    insertsOrUpdates.find(in: ids).union(current.find(in: ids))
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
  
  public func table<E: EntityType>(_ entityType: E.Type) -> EntityModifier<Schema, E> {
    guard let rawTable = editing[E.entityName] else {
      let modifier = EntityModifier<Schema, E>(current: current.table(E.self))
      editing[E.entityName] = modifier
      return modifier
    }
    return rawTable as! EntityModifier<Schema, E>
  }
  
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<Schema, EntityTableKey<U>>) -> EntityModifier<Schema, U> {
    get {
      guard let rawTable = editing[U.entityName] else {
        let modifier = EntityModifier<Schema, U>(current: current[dynamicMember: keyPath])
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
  
  public func beginBatchUpdates() -> DatabaseBatchUpdatesContext<Self> {
    let context = DatabaseBatchUpdatesContext<Self>(current: self)
    return context
  }
  
  public mutating func commitBatchUpdates(context: DatabaseBatchUpdatesContext<Self>) {
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
  }
    
  /// Performs operations to update entities and indexes
  /// If can be run on background thread with locking.
  ///
  /// - Parameter update:
  public mutating func performBatchUpdates<Result>(_ update: (DatabaseBatchUpdatesContext<Self>) throws -> Result) rethrows -> Result {               
    do {
      let context = beginBatchUpdates()
      let result = try update(context)
      commitBatchUpdates(context: context)
      return result
    } catch {
      throw error
    }
  }
}
