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

#if !COCOAPODS
import VergeCore
#endif

protocol EntityModifierType: AnyObject {
  
  var entityName: EntityTableIdentifier { get }
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
  private var insertsOrUpdates: EntityTable<Schema, Entity>
    
  /// A set of entity ids that entity will be deleted after batchUpdates finished.
  /// The current entities will be deleted with this identifiers.
  public var deletes: Set<Entity.EntityID> = .init()
  
  init(current: EntityTable<Schema, Entity>) {
    self.current = current
    self.insertsOrUpdates = .init()
  }
  
  // MARK: - Querying
  
  /// All entities from context and current
  ///
  /// - TODO: Expensive
  public func all() -> AnyCollection<Entity> {
    AnyCollection(
      insertsOrUpdates
        .rawTable
        .entities
        .merging(current.rawTable.entities, uniquingKeysWith: { e, _ in e })
        .values
        .lazy
        .map { $0.base as! Entity }
    )
  }
    
  /// Find entity from updates and current.
  ///
  /// Firstly, find from updates and then find from current.
  /// - Parameter id:
  public func find(by id: Entity.EntityID) -> Entity? {
    insertsOrUpdates.find(by: id) ?? current.find(by: id)
  }
  
  /// Find entities from updates and current.
  ///
  /// Firstly, find from updates and then find from current.
  /// - Parameter id:
  public func find<S: Sequence>(in ids: S) -> [Entity] where S.Element == Entity.EntityID {
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
    deletes.insert(entity.entityID)
  }
    
  /// Set deletes entity with identifier
  /// - Parameter entityID:
  public func delete(_ entityID: Entity.EntityID) {
    deletes.insert(entityID)
  }
  
  /// Set deletes entities with passed entities.
  /// - Parameter entities:
  public func delete<S: Sequence>(_ entities: S) where S.Element == Entity {
    deletes.formUnion(entities.lazy.map { $0.entityID })
  }
    
  /// Set deletes entities with passed sequence of entity's identifier.
  /// - Parameter entityIDs:
  public func delete<S: Sequence>(_ entityIDs: S) where S.Element == Entity.EntityID {
    deletes.formUnion(entityIDs)
  }
    
  /// Set deletes all entities
  public func deleteAll() {
    deletes.formUnion(current.allIDs())
  }
  
  /// Update existing entity. it throws if does not exsist.
  @discardableResult
  @inline(__always)
  public func updateExists(id: Entity.EntityID, update: (inout Entity) throws -> Void) throws -> Entity {
    
    if insertsOrUpdates.find(by: id) != nil {
      return try insertsOrUpdates.updateExists(id: id, update: update)
    }
    
    if var target = current.find(by: id) {
      try update(&target)
      insertsOrUpdates.insert(target)
      return target
    }
    
    throw BatchUpdatesError.storedEntityNotFound
    
  }
    
  /// Updates existing entity from insertsOrUpdates or current.
  /// It's never been called update closure if the entity was not found.
  ///
  /// - Parameters:
  ///   - id:
  ///   - update:
  @discardableResult
  public func updateIfExists(id: Entity.EntityID, update: (inout Entity) throws -> Void) rethrows -> Entity? {
    try? updateExists(id: id, update: update)
  }
  
}

public struct DatabaseEntityUpdatesResult<Schema: EntitySchemaType>: Equatable {
  
  let updated: [EntityTableIdentifier : Set<AnyHashable>]
  let deleted: [EntityTableIdentifier : Set<AnyHashable>]
  
  public func wasUpdated<E: EntityType>(_ id: E.EntityID) -> Bool {
    guard let set = updated[E.entityName] else { return false }
    return set.contains(id)
  }
  
  public func wasDeleted<E: EntityType>(_ id: E.EntityID) -> Bool {
    guard let set = deleted[E.entityName] else { return false }
    return set.contains(id)
  }
  
  public func containsEntityUpdated<E: EntityType>(_ entityType: E.Type) -> Bool {
    updated.keys.contains(E.entityName)
  }
  
  public func containsEntityDeleted<E: EntityType>(_ entityType: E.Type) -> Bool {
    deleted.keys.contains(E.entityName)
  }
  
}

@dynamicMemberLookup
public class DatabaseEntityBatchUpdatesContext<Schema: EntitySchemaType> {
  
  private let current: EntityTablesStorage<Schema>
  var editing: [EntityTableIdentifier : EntityModifierType] = [:]
    
  init(current: EntityTablesStorage<Schema>) {
    self.current = current
  }
  
  public func abort() throws -> Never {
    throw BatchUpdatesError.aborted
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
    table(U.self)
  }
  
  func makeResult() -> DatabaseEntityUpdatesResult<Schema> {
    
    var updated: [EntityTableIdentifier : Set<AnyHashable>] = [:]
    var deleted: [EntityTableIdentifier : Set<AnyHashable>] = [:]
    
    for (entityName, rawEntityData) in editing {
                  
      deleted[entityName] = rawEntityData._deletes
      updated[entityName] = Set(rawEntityData._insertsOrUpdates.rawTable.entities.keys)
            
    }
    
    return .init(updated: updated, deleted: deleted)
    
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
    
    let t = VergeSignpostTransaction("DatabaseType.commit")
    defer {
      t.end()
    }
    
    middlewareAfter: do {
      middlewares.forEach {
        $0.performAfterUpdates(context: context)
      }
    }
    
    apply: do {
      _backingStorage.entityBackingStorage.apply(edits: context.editing)
      context.indexes.apply(edits: context.editing)
      _backingStorage.indexesStorage = context.indexes
    }
    
    _backingStorage.markUpdated()
    _backingStorage.lastUpdatesResult = context.makeResult()
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
