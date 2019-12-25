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
  typealias RawTable = [AnyHashable : Any]
  var entities: RawTable { get }
  var entityName: EntityName { get }
}

public struct EntityTable<Schema: EntitySchemaType, Entity: EntityType>: EntityTableType {
    
  /// An object indicates result of insertion
  /// It can be used to create a getter object.
  public struct InsertionResult {
    public var entityID: Entity.ID {
      entity.id
    }
    public let entity: Entity
    internal let keyPath: KeyPath<Schema, EntityTableKey<Entity>>
        
    func makeSelector<DB: DatabaseType>(_ type: DB.Type) -> (DB) -> EntityTable<Schema, Entity> where DB.Schema == Schema {
      return { db in
        let a = db.entities[dynamicMember: self.keyPath]
        return a
      }
    }
  }
  
  var entityName: EntityName {
    Entity.entityName
  }
    
  /// The number of entities in table
  public var count: Int {
    entities.count
  }
  
  internal var entities: [AnyHashable : Any] = [:]
  
  internal let keyPath: KeyPath<Schema, EntityTableKey<Entity>>
  
  init(keyPath: KeyPath<Schema, EntityTableKey<Entity>>) {
    self.keyPath = keyPath
  }
  
  init(buffer: [AnyHashable : Any], keyPath: KeyPath<Schema, EntityTableKey<Entity>>) {
    self.entities = buffer
    self.keyPath = keyPath
  }
    
  /// Returns all entity ids that stored.
  ///
  /// - TODO: It's expensive
  public func allIDs() -> Set<Entity.ID> {
    .init(entities.keys.map { $0 as! Entity.ID })
  }
  
  /// Returns all entity that stored.
  ///
  /// - TODO: It's expensive
  public func allEntities() -> AnyCollection<Entity> {
    .init(entities.values.lazy.map { $0 as! Entity })
  }
  
  public func find(by id: Entity.ID) -> Entity? {
    entities[id] as? Entity
  }
    
  /// Find entities by set of ids.
  /// The order of array would not be sorted, it depends on dictionary's buffer.
  ///
  /// - Parameter ids: sequence of Entity.ID
  public func find<S: Sequence>(in ids: S) -> [Entity] where S.Element == Entity.ID {
    ids.reduce(into: [Entity]()) { (buf, id) in
      guard let entity = entities[id] else { return }
      buf.append(entity as! Entity)
    }
  }
   
  public mutating func updateIfExists(id: Entity.ID, update: (inout Entity) -> Void) {
    guard entities.keys.contains(id) else { return }
    withUnsafeMutablePointer(to: &entities[id]!) { (pointer) -> Void in
      var entity = pointer.pointee as! Entity
      update(&entity)
      pointer.pointee = entity
    }
  }
  
  @discardableResult
  public mutating func insert(_ entity: Entity) -> InsertionResult {
    entities[entity.id] = entity
    return .init(entity: entity, keyPath: keyPath)
  }
  
  @discardableResult
  public mutating func insert<S: Sequence>(_ addingEntities: S) -> [InsertionResult] where S.Element == Entity {
    let results = addingEntities.map {
      insert($0)
    }
    return results
  }
  
  public mutating func remove(_ id: Entity.ID) {
    entities.removeValue(forKey: id)
  }
  
  public mutating func removeAll() {
    entities.removeAll(keepingCapacity: false)
  }
}

extension EntityTable where Entity : Hashable {
  
  public func find<S: Sequence>(in ids: S) -> Set<Entity> where S.Element == Entity.ID {
    ids.reduce(into: Set<Entity>()) { (buf, id) in
      guard let entity = entities[id] else { return }
      buf.insert(entity as! Entity)
    }
  }
}

extension EntityTable: Equatable where Entity : Equatable {
  public static func == (lhs: EntityTable<Schema, Entity>, rhs: EntityTable<Schema, Entity>) -> Bool {
    (lhs.entities as! [AnyHashable : Entity]) == (rhs.entities as! [AnyHashable : Entity])
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
    
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<Schema, EntityTableKey<U>>) -> EntityTable<Schema, U> {
    get {
      guard let rawTable = entityTableStorage[U.entityName] else {
        return EntityTable<Schema, U>(buffer: [:], keyPath: keyPath)
      }
      return EntityTable<Schema, U>(buffer: rawTable, keyPath: keyPath)
    }
    set {
      entityTableStorage[U.entityName] = newValue.entities
    }
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
    let value = anyEntityTable.entities
    let entityName = anyEntityTable.entityName
    if let table = entityTableStorage[entityName] {
      var modified = table
      
      value.forEach { key, value in
        modified[key] = value
      }
      
      entityTableStorage[entityName] = modified
    } else {
      entityTableStorage[entityName] = value
    }
  }

  @inline(__always)
  private mutating func _subtract(ids: Set<AnyHashable>, entityName: EntityName) {
    guard let table = entityTableStorage[entityName] else {
      return
    }
    var modified = table
    
    ids.forEach { key in
      modified.removeValue(forKey: key)
    }
    
    entityTableStorage[entityName] = modified
  }
}
