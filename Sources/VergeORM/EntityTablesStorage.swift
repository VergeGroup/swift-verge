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

public struct EntityTable<Entity: EntityType>: EntityTableType {
  
  var entityName: EntityName {
    Entity.entityName
  }
  
  public var count: Int {
    entities.count
  }
  
  internal var entities: [AnyHashable : Any] = [:]
  
  init() {
    
  }
  
  init(buffer: [AnyHashable : Any]) {
    self.entities = buffer
  }
  
  public func all() -> AnyCollection<Entity> {
    .init(entities.lazy.map { $0.value as! Entity })
  }
  
  public func find(by id: Entity.ID) -> Entity? {
    entities[id] as? Entity
  }
  
  public func find<S: Sequence>(in ids: S) -> [Entity] where S.Element == Entity.ID {
    ids.reduce(into: [Entity]()) { (buf, id) in
      guard let entity = entities[id] else { return }
      buf.append(entity as! Entity)
    }
  }
  
  public mutating func updateIfExists(by id: Entity.ID, update: (inout Entity) -> Void) {
    guard entities.keys.contains(id) else { return }
    withUnsafeMutablePointer(to: &entities[id]!) { (pointer) -> Void in
      var entity = pointer.pointee as! Entity
      update(&entity)
      pointer.pointee = entity
    }
  }
    
  @discardableResult
  public mutating func insert(_ entity: Entity) -> Entity.ID {
    entities[entity.id] = entity
    return entity.id
  }
  
  @discardableResult
  public mutating func insert<S: Sequence>(_ addingEntities: S) -> [Entity.ID] where S.Element == Entity {
    let ids = addingEntities.map {
      insert($0)
    }
    return ids
  }
  
  public mutating func remove(_ id: Entity.ID) {
    entities.removeValue(forKey: id)
  }
  
  public mutating func removeAll() {
    entities.removeAll(keepingCapacity: false)
  }
}

extension EntityTable: Equatable where Entity : Equatable {
  public static func == (lhs: EntityTable<Entity>, rhs: EntityTable<Entity>) -> Bool {
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
    
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<Schema, EntityTableKey<U>>) -> EntityTable<U> {
    get {
      guard let rawTable = entityTableStorage[U.entityName] else {
        return EntityTable<U>(buffer: [:])
      }
      return EntityTable<U>(buffer: rawTable)
    }
    set {
      entityTableStorage[U.entityName] = newValue.entities
    }
  }
  
  mutating func apply(modifier: EntityModifierType) {
    _merge(anyEntityTable: modifier._insertsOrUpdates)
    _subtract(ids: modifier._deletes, entityName: modifier.entityName)
  }
  
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
