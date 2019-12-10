//
//  VergeNormalizer.swift
//  VergeStore
//
//  Created by muukii on 2019/12/07.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public protocol VergeTypedIdentifiable: Identifiable {
  associatedtype RawValue: Hashable
  var rawID: RawValue { get }
}

extension VergeTypedIdentifiable {
  
  public var id: VergeTypedIdentifier<Self> {
    .init(raw: rawID)
  }
}

public struct VergeTypedIdentifier<T: VergeTypedIdentifiable> : Hashable {
  
  public let raw: T.RawValue
  
  public init(raw: T.RawValue) {
    self.raw = raw
  }
}

public struct MappingKey<S: EntityType> {
  
  public var typeName: String {
    String(reflecting: type(of: self))
  }
  
  public init() {
    
  }
}

public protocol EntityType: VergeTypedIdentifiable {
  typealias Table = VergeORM.Table<Self>
  // TODO: Add some methods for updating entity.
}

extension EntityType {
  public static func makeTable() -> Table {
    .init()
  }
}

public struct Table<Entity: EntityType> {
  
  public var count: Int {
    entities.count
  }
    
  internal var entities: [AnyHashable : Any] = [:]
  
  public init() {
    
  }
  
  init(buffer: [AnyHashable : Any]) {
    self.entities = buffer
  }
  
  public func all() -> [Entity] {
    entities.map { $0.value as! Entity }
  }
  
  public func find(by id: Entity.ID) -> Entity? {
    unsafeBitCast(entities[id], to: Entity?.self)
  }
  
  public func find<S: Sequence>(in ids: S) -> [Entity] where S.Element == Entity.ID {
    ids.reduce(into: [Entity]()) { (buf, id) in
      guard let entity = entities[id] else { return }
      buf.append(entity as! Entity)
    }
  }
    
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
  
  public mutating func merge(otherTable: Table<Entity>) {
    entities.merge(otherTable.entities, uniquingKeysWith: { _, new in new })
  }
  
  public mutating func subtract(otherTable: Table<Entity>) {
    otherTable.entities.forEach { key, _ in
      entities.removeValue(forKey: key)
    }
  }
    
}

public protocol MappingTableType {
  init()
}

@dynamicMemberLookup
public struct BackingStorage<MappingTable: MappingTableType> {
  
  private typealias RawTable = [AnyHashable : Any]
  private var storage: [String : RawTable] = [:]
  
  let keyTable = MappingTable()
  
  public init() {}
  
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<MappingTable, MappingKey<U>>) -> Table<U> {
    mutating get {
      let key = keyTable[keyPath: keyPath]
      guard let rawTable = storage[key.typeName] else {
        storage[key.typeName] = [:]
        return storage[key.typeName].map { Table<U>(buffer: $0) }!
      }
      return Table<U>(buffer: rawTable)
    }
    set {
      let key = keyTable[keyPath: keyPath]
      storage[key.typeName] = newValue.entities
    }
  }
  
  mutating func merge(otherStorage: BackingStorage<MappingTable>) {
    otherStorage.storage.forEach { key, value in
      if var table = storage[key] {
        var merged = table
        
        value.forEach { key, value in
          merged[key] = value
        }
        
        table = merged
        storage[key] = table
      } else {
        storage[key] = value
      }
    }
  }
  
  mutating func subtract(otherStorage: BackingStorage<MappingTable>) {
    // TODO:
//    otherStorage.storage.forEach { key, value in
//      if var table = storage[key] {
//        var merged = table
//
//        value.forEach { key, value in
//          merged[key] = value
//        }
//
//        table = merged
//        storage[key] = table
//      } else {
//        storage[key] = value
//      }
//    }
  }
    
}

@dynamicMemberLookup
public protocol DatabaseType {
  
  associatedtype MappingTable: MappingTableType
  typealias BackingStorage = VergeORM.BackingStorage<MappingTable>
  var backingStorage: BackingStorage { get set }
}

extension DatabaseType {
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<MappingTable, MappingKey<U>>) -> Table<U> {
    mutating get {
      backingStorage[dynamicMember: keyPath]
    }
    set {
      backingStorage[dynamicMember: keyPath] = newValue
    }
  }
}

public enum ORMError: Error {
  case aborted
}

public final class DatabaseBatchUpdateContext<Database: DatabaseType> {
  
  public let current: Database
  
  public var insertsOrUpdates: Database.BackingStorage = .init()
  public var deletes: Database.BackingStorage = .init()

  init(current: Database) {
    self.current = current
  }
  
  public func abort() throws -> Never {
    throw ORMError.aborted
  }
}

extension DatabaseType {
  
  public mutating func performBatchUpdate(_ update: (DatabaseBatchUpdateContext<Self>) throws -> Void) rethrows {
    let context = DatabaseBatchUpdateContext<Self>(current: self)
    do {
      try update(context)
      self.backingStorage.merge(otherStorage: context.insertsOrUpdates)
      self.backingStorage.subtract(otherStorage: context.deletes)
    } catch {
      // TODO:
      throw error
    }
  }
}
