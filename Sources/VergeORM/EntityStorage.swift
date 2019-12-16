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

public struct EntityTableKey<S: EntityType> {
  
  public var typeName: String {
    String(reflecting: S.self)
  }
  
  public init() {
    
  }
}

public struct EntityTable<Entity: EntityType, Trait: AccessControlType> {
  
  public var count: Int {
    entities.count
  }
  
  internal var entities: [AnyHashable : Any] = [:]
  
  init() {
    
  }
  
  init(buffer: [AnyHashable : Any]) {
    self.entities = buffer
  }
  
  public func all() -> [Entity] {
    entities.map { $0.value as! Entity }
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
    
}

extension EntityTable: Equatable where Entity : Equatable {
  public static func == (lhs: EntityTable<Entity, Trait>, rhs: EntityTable<Entity, Trait>) -> Bool {
    (lhs.entities as! [AnyHashable : Entity]) == (rhs.entities as! [AnyHashable : Entity])
  }
}

extension EntityTable where Trait == Write {
  
  @discardableResult
  public mutating func insert(_ entity: Entity) -> Entity.ID {
    entities[entity.id] = entity
    return entity.id
  }
    
  @discardableResult
  public mutating func insert<S: Sequence>(_ addingEntities: S) -> [Entity.ID] where S.Element == Entity {
    var ids: [Entity.ID] = []
    addingEntities.forEach { entity in
      entities[entity.id] = entity
      ids.append(entity.id)
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

public protocol EntitySchemaType {
  init()
}

@dynamicMemberLookup
public struct EntityStorage<Schema: EntitySchemaType, Trait: AccessControlType> {
  
  typealias RawTable = [AnyHashable : Any]
  private(set) var entityTableStorage: [String : RawTable]
  
  private let schema = Schema()
  
  public init() {
    self.entityTableStorage = [:]
  }
  
  private init(entityTableStorage: [String : RawTable]) {
    self.entityTableStorage = entityTableStorage
  }
     
}

extension EntityStorage where Trait == Read {
  
  func makeWriable() -> EntityStorage<Schema, Write> {
    .init(entityTableStorage: entityTableStorage)
  }
  
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<Schema, EntityTableKey<U>>) -> EntityTable<U, Trait> {
    get {
      let key = schema[keyPath: keyPath]
      guard let rawTable = entityTableStorage[key.typeName] else {
        return EntityTable<U, Trait>(buffer: [:])
      }
      return EntityTable<U, Trait>(buffer: rawTable)
    }
  }
}

extension EntityStorage where Trait == Write {
  
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<Schema, EntityTableKey<U>>) -> EntityTable<U, Trait> {
    get {
      let key = schema[keyPath: keyPath]
      guard let rawTable = entityTableStorage[key.typeName] else {
        return EntityTable<U, Trait>(buffer: [:])
      }
      return EntityTable<U, Trait>(buffer: rawTable)
    }
    set {
      let key = schema[keyPath: keyPath]
      entityTableStorage[key.typeName] = newValue.entities
    }
  }
  
  func makeReadonly() -> EntityStorage<Schema, Read> {
    .init(entityTableStorage: entityTableStorage)
  }
  
  mutating func merge<T>(otherStorage: EntityStorage<Schema, T>) {
    otherStorage.entityTableStorage.forEach { key, value in
      if let table = entityTableStorage[key] {
        var modified = table
        
        value.forEach { key, value in
          modified[key] = value
        }
        
        entityTableStorage[key] = modified
      } else {
        entityTableStorage[key] = value
      }
    }
  }
  
  mutating func subtract(otherStorage: BackingRemovingEntityStorage<Schema>) {
    otherStorage.entityTableStorage.forEach { key, value in
      if let table = entityTableStorage[key] {
        var modified = table
        
        value.forEach { key in
          modified.removeValue(forKey: key)
        }
        
        entityTableStorage[key] = modified
      }
    }
  }
}

@dynamicMemberLookup
public struct BackingRemovingEntityStorage<Schema: EntitySchemaType> {
  
  typealias RawTable = Set<AnyHashable>
  private(set) var entityTableStorage: [String : RawTable]
  
  private let schema = Schema()
  
  public init() {
    self.entityTableStorage = [:]
  }
  
  private init(entityTableStorage: [String : RawTable]) {
    self.entityTableStorage = entityTableStorage
  }
  
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<Schema, EntityTableKey<U>>) -> Set<U.ID> {
    get {
      let key = schema[keyPath: keyPath]
      guard let rawTable = entityTableStorage[key.typeName] else {
        return Set<U.ID>([])
      }
      return rawTable as! Set<U.ID>
    }
    set {
      let key = schema[keyPath: keyPath]
      entityTableStorage[key.typeName] = newValue
    }
  }
  
}

