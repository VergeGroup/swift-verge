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
    
  public var entities: [Entity.ID : Entity] = [:]
  
  public init() {
    
  }
  
  public func all() -> [Entity] {
    entities.map { $0.value }
  }
  
  public func find(by id: Entity.ID) -> Entity? {
    entities[id]
  }
  
  public func find<S: Sequence>(in ids: S) -> [Entity] where S.Element == Entity.ID {
    ids.reduce(into: [Entity]()) { (buf, id) in
      guard let entity = entities[id] else { return }
      buf.append(entity)
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
    
}

public protocol DatabaseType {
  
  /// Create a empty database to perform batch update
  static func makeEmtpy() -> Self
  
  mutating func merge(database: Self)
}

public enum ORMError: Error {
  case aborted
}

public final class DatabaseBatchUpdateContext<Database: DatabaseType> {
  
  public let current: Database
  
  public var insertOrUpdates: Database = .makeEmtpy()
  public var deletes: Database = .makeEmtpy()

  init(current: Database) {
    self.current = current
  }
  
  public func abort() throws -> Never {
    throw ORMError.aborted
  }
}

extension DatabaseType {
  
  public mutating func mergeTable<Entity>(keyPath: WritableKeyPath<Self, Table<Entity>>, otherDatabase: Self) {
    self[keyPath: keyPath].merge(otherTable: otherDatabase[keyPath: keyPath])
  }
  
  public mutating func performBatchUpdate(_ update: (DatabaseBatchUpdateContext<Self>) throws -> Void) rethrows {
    let context = DatabaseBatchUpdateContext<Self>(current: self)
    do {
      try update(context)
      self.merge(database: context.insertOrUpdates)
    } catch {
      // TODO:
      throw error
    }
  }
}
