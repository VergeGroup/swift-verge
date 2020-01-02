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

protocol EntityTableType {
  typealias RawTable = [AnyHashable : AnyEntity]
  var entities: RawTable { get }
  var entityName: EntityName { get }
}

/// A wrapper of raw table
public struct EntityTable<Schema: EntitySchemaType, Entity: EntityType>: EntityTableType {
    
  /// An object indicates result of insertion
  /// It can be used to create a getter object.
  public struct InsertionResult {
    public var entityID: Entity.EntityID {
      entity.entityID
    }
    public let entity: Entity        
  }
  
  let entityName: EntityName = Entity.entityName
    
  /// The number of entities in table
  public var count: Int {
    _read { yield entities.count }
  }
  
  internal var entities: RawTable = [:]
    
  init() {
  }
  
  init(buffer: RawTable) {
    self.entities = buffer
  }
    
  /// Returns all entity ids that stored.
  ///
  /// - TODO: It's expensive
  public func allIDs() -> Set<Entity.EntityID> {
    .init(entities.keys.map { $0 as! Entity.EntityID })
  }
  
  /// Returns all entity that stored.
  ///
  /// - TODO: It's expensive
  public func allEntities() -> AnyCollection<Entity> {
    .init(entities.values.lazy.map { $0.base as! Entity })
  }
  
  public func find(by id: Entity.EntityID) -> Entity? {
    entities[id]?.base as? Entity
  }
    
  /// Find entities by set of ids.
  /// The order of array would not be sorted, it depends on dictionary's buffer.
  ///
  /// - Parameter ids: sequence of Entity.ID
  public func find<S: Sequence>(in ids: S) -> [Entity] where S.Element == Entity.EntityID {
    ids.reduce(into: [Entity]()) { (buf, id) in
      guard let entity = entities[id] else { return }
      buf.append(entity.base as! Entity)
    }
  }
  
  @discardableResult
  @inline(__always)
  public mutating func updateExists(id: Entity.EntityID, update: (inout Entity) throws -> Void) throws -> Entity {
    
    guard entities.keys.contains(id) else {
      throw BatchUpdatesError.storedEntityNotFound
    }
    
    return try withUnsafeMutablePointer(to: &entities[id]!) { (pointer) -> Entity in
      var entity = pointer.pointee.base as! Entity
      try update(&entity)
      pointer.pointee.base = entity as Any
      return entity
    }
  }
   
  @discardableResult
  public mutating func updateIfExists(id: Entity.EntityID, update: (inout Entity) throws -> Void) rethrows -> Entity? {
    try? updateExists(id: id, update: update)
  }
  
  @discardableResult
  public mutating func insert(_ entity: Entity) -> InsertionResult {
    entities[entity.entityID] = .init(entity)
    return .init(entity: entity)
  }
  
  @discardableResult
  public mutating func insert<S: Sequence>(_ addingEntities: S) -> [InsertionResult] where S.Element == Entity {
    let results = addingEntities.map {
      insert($0)
    }
    return results
  }
  
  public mutating func remove(_ id: Entity.EntityID) {
    entities.removeValue(forKey: id)
  }
  
  public mutating func removeAll() {
    entities.removeAll(keepingCapacity: false)
  }
}

extension EntityTable where Entity : Hashable {
  
  public func find<S: Sequence>(in ids: S) -> Set<Entity> where S.Element == Entity.EntityID {
    ids.reduce(into: Set<Entity>()) { (buf, id) in
      guard let entity = entities[id] else { return }
      buf.insert(entity as! Entity)
    }
  }
}

extension EntityTable: Equatable where Entity : Equatable {
  public static func == (lhs: EntityTable<Schema, Entity>, rhs: EntityTable<Schema, Entity>) -> Bool {
    (lhs.entities) == (rhs.entities)
  }
}

@dynamicMemberLookup
public struct EntityTablesStorage<Schema: EntitySchemaType> {
  
  private(set) var entityTableStorage: [EntityName : EntityTableType.RawTable]
      
  public init() {
    self.entityTableStorage = [:]
  }
  
  private init(entityTableStorage: [EntityName : EntityTableType.RawTable]) {
    self.entityTableStorage = entityTableStorage
  }
  
  @inline(__always)
  public func table<E: EntityType>(_ entityType: E.Type) -> EntityTable<Schema, E> {
    guard let rawTable = entityTableStorage[E.entityName] else {
      return EntityTable<Schema, E>(buffer: [:])
    }
    return EntityTable<Schema, E>(buffer: rawTable)
  }
    
  public subscript <E: EntityType>(dynamicMember keyPath: KeyPath<Schema, EntityTableKey<E>>) -> EntityTable<Schema, E> {
    table(E.self)
  }
  
  @inline(__always)
  mutating func apply(edits: [EntityName : EntityModifierType]) {    
    edits.forEach { _, value in
      apply(modifier: value)
    }
  }
  
  @inline(__always)
  private mutating func apply(modifier: EntityModifierType) {
    _merge(anyEntityTable: modifier._insertsOrUpdates)
    _subtract(ids: modifier._deletes, entityName: modifier.entityName)
  }
  
  @inline(__always)
  private mutating func _merge(anyEntityTable: EntityTableType) {
    let entityRawTable = anyEntityTable.entities
    let entityName = anyEntityTable.entityName
    if var modified = entityTableStorage[entityName] {
      
      entityRawTable.forEach { key, value in
        modified[key] = value
      }
      
      entityTableStorage[entityName] = modified
    } else {
      entityTableStorage[entityName] = entityRawTable
    }
  }

  @inline(__always)
  private mutating func _subtract(ids: Set<AnyHashable>, entityName: EntityName) {
    guard var modified = entityTableStorage[entityName] else {
      return
    }
    
    ids.forEach { key in
      modified.removeValue(forKey: key)
    }
    
    entityTableStorage[entityName] = modified
  }
}
