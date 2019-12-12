//
//  BackingEntityStorage.swift
//  VergeORM
//
//  Created by muukii on 2019/12/13.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public struct MappingKey<S: EntityType> {
  
  public var typeName: String {
    String(reflecting: S.self)
  }
  
  public init() {
    
  }
}

public struct Table<Entity: EntityType, Trait: AccessControlType> {
  
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
  
  public mutating func remove(_ id: Entity.ID) {
    entities.removeValue(forKey: id)
  }
  
  public mutating func removeAll() {
    entities.removeAll(keepingCapacity: false)
  }
  
  
}

extension Table where Trait == Write {
  
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
}

public protocol EntitySchemaType {
  init()
}

@dynamicMemberLookup
public struct BackingEntityStorage<Schema: EntitySchemaType, Trait: AccessControlType> {
  
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

extension BackingEntityStorage where Trait == Read {
  
  func makeWriable() -> BackingEntityStorage<Schema, Write> {
    .init(entityTableStorage: entityTableStorage)
  }
  
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<Schema, MappingKey<U>>) -> Table<U, Trait> {
    get {
      let key = schema[keyPath: keyPath]
      guard let rawTable = entityTableStorage[key.typeName] else {
        return Table<U, Trait>(buffer: [:])
      }
      return Table<U, Trait>(buffer: rawTable)
    }
  }
}

extension BackingEntityStorage where Trait == Write {
  
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<Schema, MappingKey<U>>) -> Table<U, Trait> {
    get {
      let key = schema[keyPath: keyPath]
      guard let rawTable = entityTableStorage[key.typeName] else {
        return Table<U, Trait>(buffer: [:])
      }
      return Table<U, Trait>(buffer: rawTable)
    }
    set {
      let key = schema[keyPath: keyPath]
      entityTableStorage[key.typeName] = newValue.entities
    }
  }
  
  func makeReadonly() -> BackingEntityStorage<Schema, Read> {
    .init(entityTableStorage: entityTableStorage)
  }
  
  mutating func merge<T>(otherStorage: BackingEntityStorage<Schema, T>) {
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
  
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<Schema, MappingKey<U>>) -> Set<U.ID> {
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

