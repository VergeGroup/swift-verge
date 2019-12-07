//
//  VergeNormalizer.swift
//  VergeStore
//
//  Created by muukii on 2019/12/07.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public protocol VergeTypedIdentifiable: Equatable, Identifiable {
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
  // TODO: Add some methods for updating entity.
}

public struct Table<Entity: VergeTypedIdentifiable> {
  
  public var count: Int {
    entities.count
  }
    
  public var entities: [Entity.ID : Entity] = [:]
  
  public init() {
    
  }
  
  public func get(by id: Entity.ID) -> Entity? {
    entities[id]
  }
    
  public mutating func update(_ entity: Entity) {
    entities[entity.id] = entity
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
  public private(set) var updates: Database = .makeEmtpy()
  
  init(current: Database) {
    self.current = current
  }
  
  public func update(_ update: (inout Database) -> Void) {
    update(&updates)
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
      self.merge(database: context.updates)
    } catch {
      // TODO:
      throw error
    }
  }
}
