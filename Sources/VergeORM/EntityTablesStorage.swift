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
import VergeStore
#endif

protocol EntityTableType {
  typealias RawTable = EntityRawTable
  var rawTable: RawTable { get }
  var entityName: EntityTableIdentifier { get }
}

struct EntityRawTable: Equatable {
  
  static func == (lhs: EntityRawTable, rhs: EntityRawTable) -> Bool {
    guard lhs.updatedMarker == rhs.updatedMarker else { return false }
    guard lhs.entities == rhs.entities else { return false }
    return true
  }
  
  typealias RawTable = [AnyHashable : AnyEntity]
  
  private(set) var updatedMarker = NonAtomicVersionCounter()

  private(set) var entities: RawTable = [:]
  
  mutating func updateEntity<Result>(_ update: (inout RawTable) throws -> Result) rethrows -> Result {    
    let r = try update(&entities)
    updatedMarker.markAsUpdated()
    return r
  }
    
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
  
  let entityName: EntityTableIdentifier = Entity.entityName
  
  public var updatedMarker: NonAtomicVersionCounter {
    _read { yield rawTable.updatedMarker }
  }
    
  /// The number of entities in table
  public var count: Int {
    _read { yield rawTable.entities.count }
  }
  
  internal var rawTable: RawTable = .init()
    
  init() {
  }
  
  init(rawTable: RawTable) {
    self.rawTable = rawTable
  }
    
  /// Returns all entity ids that stored.
  ///
  /// - TODO: It's expensive
  public func allIDs() -> Set<Entity.EntityID> {
    .init(rawTable.entities.keys.map { $0 as! Entity.EntityID })
  }
  
  /// Returns all entity that stored.
  ///
  /// - TODO: It's expensive
  public func allEntities() -> AnyCollection<Entity> {
    .init(rawTable.entities.values.lazy.map { $0.base as! Entity })
  }
  
  public func find(by id: Entity.EntityID) -> Entity? {
    let t = VergeSignpostTransaction("EntityTable.findBy", label: "EntityType:\(Entity.entityName.name)")
    defer {
      t.end()
    }
    return rawTable.entities[id]?.base as? Entity
  }
    
  /// Find entities by set of ids.
  /// The order of array would not be sorted, it depends on dictionary's buffer.
  ///
  /// if ids contains same id, result also contains same element.
  /// - Parameter ids: sequence of Entity.ID
  public func find<S: Sequence>(in ids: S) -> [Entity] where S.Element == Entity.EntityID {
    let t = VergeSignpostTransaction("EntityTable.findIn", label: "EntityType:\(Entity.entityName.name)")
    defer {
      t.end()
    }
    return ids.reduce(into: [Entity]()) { (buf, id) in
      guard let entity = rawTable.entities[id] else { return }
      buf.append(entity.base as! Entity)
    }
  }
  
  @discardableResult
  @inline(__always)
  public mutating func updateExists(id: Entity.EntityID, update: (inout Entity) throws -> Void) throws -> Entity {
    
    guard rawTable.entities.keys.contains(id) else {
      throw BatchUpdatesError.storedEntityNotFound
    }
    
    let e = try rawTable.updateEntity { (entities) -> Entity in
      return try withUnsafeMutablePointer(to: &entities[id]!) { (pointer) -> Entity in
        var entity = pointer.pointee.base as! Entity
        try update(&entity)
        pointer.pointee.base = entity as Any
        return entity
      }
    }
    
    return e
  }
   
  @discardableResult
  mutating func updateIfExists(id: Entity.EntityID, update: (inout Entity) throws -> Void) rethrows -> Entity? {
    try? updateExists(id: id, update: update)
  }
  
  @discardableResult
  mutating func insert(_ entity: Entity) -> InsertionResult {
    let t = VergeSignpostTransaction("ORM.EntityTable.insertOne", label: "EntityType:\(Entity.entityName.name)")
    defer {
      t.end()
    }
    rawTable.updateEntity { (entities) in
      entities[entity.entityID] = .init(entity)
    }
    return .init(entity: entity)
  }
  
  @discardableResult
  mutating func insert<S: Sequence>(_ addingEntities: S) -> [InsertionResult] where S.Element == Entity {
    let t = VergeSignpostTransaction("ORM.EntityTable.insertSequence", label: "EntityType:\(Entity.entityName.name)")
    defer {
      t.end()
    }
    
    let results = addingEntities.map { entity -> InsertionResult in
      rawTable.updateEntity { (entities) in
        entities[entity.entityID] = .init(entity)
      }
      return .init(entity: entity)
    }
      
    return results
  }
  
  mutating func remove(_ id: Entity.EntityID) {
    rawTable.updateEntity { (entities) -> Void in
      entities.removeValue(forKey: id)
    }
  }
  
  mutating func removeAll() {
    rawTable.updateEntity { (entities) in
      entities.removeAll(keepingCapacity: false)
    }
  }
}

extension EntityTable: Equatable {
  public static func == (lhs: EntityTable<Schema, Entity>, rhs: EntityTable<Schema, Entity>) -> Bool {
    (lhs.updatedMarker) == (rhs.updatedMarker)
  }
}

extension EntityTable where Entity : Equatable {
  public static func == (lhs: EntityTable<Schema, Entity>, rhs: EntityTable<Schema, Entity>) -> Bool {
    (lhs.rawTable) == (rhs.rawTable)
  }
}

@dynamicMemberLookup
public struct EntityTablesStorage<Schema: EntitySchemaType> {
  
  private(set) var entityTableStorage: [EntityTableIdentifier : EntityTableType.RawTable]
      
  public init() {
    self.entityTableStorage = [:]
  }
  
  private init(entityTableStorage: [EntityTableIdentifier : EntityTableType.RawTable]) {
    self.entityTableStorage = entityTableStorage
  }
  
  @inline(__always)
  public func table<E: EntityType>(_ entityType: E.Type) -> EntityTable<Schema, E> {
    guard let rawTable = entityTableStorage[E.entityName] else {
      return EntityTable<Schema, E>(rawTable: .init())
    }
    return EntityTable<Schema, E>(rawTable: rawTable)
  }
    
  public subscript <E: EntityType>(dynamicMember keyPath: KeyPath<Schema, EntityTableKey<E>>) -> EntityTable<Schema, E> {
    table(E.self)
  }
  
  @inline(__always)
  mutating func apply(edits: [EntityTableIdentifier : EntityModifierType]) {    
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
    let rawTable = anyEntityTable.rawTable
    let entityName = anyEntityTable.entityName
    
    guard !rawTable.entities.isEmpty else { return }
    
    if entityTableStorage.keys.contains(entityName) {
      
      withUnsafeMutablePointer(to: &entityTableStorage[entityName]!) { (pointer) -> Void in
        pointer.pointee.updateEntity { (entities) -> Void in
          rawTable.entities.forEach { key, value in
            entities[key] = value
          }
        }
      }
      
    } else {
      entityTableStorage[entityName] = rawTable
    }
    
  }
  
  @inline(__always)
  private mutating func _subtract(ids: Set<AnyHashable>, entityName: EntityTableIdentifier) {
   
    guard entityTableStorage.keys.contains(entityName) else {
      return
    }
    
    guard !ids.isEmpty else {
      return
    }
    
    withUnsafeMutablePointer(to: &entityTableStorage[entityName]!) { (pointer) -> Void in
      pointer.pointee.updateEntity { (entities) -> Void in
        ids.forEach { key in
          entities.removeValue(forKey: key)
        }
      }
    }
  }
}
