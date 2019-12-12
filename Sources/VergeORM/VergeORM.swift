//
//  VergeNormalizer.swift
//  VergeStore
//
//  Created by muukii on 2019/12/07.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public protocol AccessControlType {}

public enum Read: AccessControlType {
  
}

public enum Write: AccessControlType {
  
}

public protocol DatabaseType {
  
  associatedtype Schema: EntitySchemaType
  associatedtype OrderTables: OrderTablesType
  typealias Storage = DatabaseStorage<Schema, OrderTables>
  var storage: Storage { get set }
}

public struct DatabaseStorage<Schema: EntitySchemaType, OrderTables: OrderTablesType> {
  
  public typealias EntityBackingStorage = VergeORM.BackingEntityStorage<Schema, Read>
  public typealias OrderTableBackingStorage = VergeORM.BackingOrderTableStorage<OrderTables, Read>
  
  public typealias WritableBackingStorage = VergeORM.BackingEntityStorage<Schema, Write>
  public typealias WritableOrderTableBackingStorage = VergeORM.BackingOrderTableStorage<OrderTables, Write>
 
  var entityBackingStorage: EntityBackingStorage = .init()
  var orderTableBackingStorage: OrderTableBackingStorage = .init()
  
  public init() {
    
  }
}

@dynamicMemberLookup
public struct EntityPropertyAdapter<DB: DatabaseType> {
  
  let get: () -> DB
  
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<DB.Schema, MappingKey<U>>) -> Table<U, Read> {
    get {
      get().storage.entityBackingStorage[dynamicMember: keyPath]
    }
  }
}

@dynamicMemberLookup
public struct OrderTablePropertyAdapter<DB: DatabaseType> {
  
  let get: () -> DB
  
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<DB.OrderTables, OrderTablePropertyKey<U>>) -> OrderTable<U, Read> {
    get {
      get().storage.orderTableBackingStorage[dynamicMember: keyPath]
    }
  }
}

extension DatabaseType {
    
  public var entities: EntityPropertyAdapter<Self> {
    .init {
      self
    }
  }
  
  public var orderTables: OrderTablePropertyAdapter<Self> {
    .init {
      self
    }
  }
  
}

public enum ORMError: Error {
  case aborted
}

public final class DatabaseBatchUpdateContext<Database: DatabaseType> {
  
  public let current: Database
  
  public var insertsOrUpdates: Database.Storage.WritableBackingStorage = .init()
  public var deletes: BackingRemovingEntityStorage<Database.Schema> = .init()
  
  public var orderTables: Database.Storage.WritableOrderTableBackingStorage
  
  init(current: Database) {
    self.current = current
    self.orderTables = current.storage.orderTableBackingStorage.makeWriable()
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
      var target = self.storage.entityBackingStorage.makeWriable()
      target.merge(otherStorage: context.insertsOrUpdates)
      target.subtract(otherStorage: context.deletes)
      
      updateOrderTable: do {
        
        self.storage.orderTableBackingStorage = context.orderTables.makeReadonly()
        
        context.deletes.entityTableStorage.forEach { key, value in
          
          if let table = context.orderTables.orderTableStorage[key] {
            var modified = table
            
            modified.removeAll { value.contains($0) }
            
            self.storage.orderTableBackingStorage.orderTableStorage[key] = modified
          }
          
        }
        
      }
                  
      self.storage.entityBackingStorage = target.makeReadonly()
    } catch {
      throw error
    }
  }
}
