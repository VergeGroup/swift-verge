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
  var entityBackingStorage: EntityBackingStorage { get set }
  var orderTableBackingStorage: OrderTableBackingStorage { get set }
}

extension DatabaseType {
  
  public typealias EntityBackingStorage = VergeORM.BackingEntityStorage<Schema, Read>
  public typealias OrderTableBackingStorage = VergeORM.BackingOrderTableStorage<OrderTables, Read>
  
  public typealias WritableBackingStorage = VergeORM.BackingEntityStorage<Schema, Write>
  public typealias WritableOrderTableBackingStorage = VergeORM.BackingOrderTableStorage<OrderTables, Write>
}

@dynamicMemberLookup
public struct EntityPropertyAdapter<DB: DatabaseType> {
  
  let get: () -> DB
  
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<DB.Schema, MappingKey<U>>) -> Table<U, Read> {
    get {
      get().entityBackingStorage[dynamicMember: keyPath]
    }
  }
}

@dynamicMemberLookup
public struct OrderTablePropertyAdapter<DB: DatabaseType> {
  
  let get: () -> DB
  
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<DB.OrderTables, OrderTablePropertyKey<U>>) -> OrderTable<U, Read> {
    get {
      get().orderTableBackingStorage[dynamicMember: keyPath]
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
  
  public var insertsOrUpdates: Database.WritableBackingStorage = .init()
  public var deletes: BackingRemovingEntityStorage<Database.Schema> = .init()
  
  public var orderTables: Database.WritableOrderTableBackingStorage
  
  init(current: Database) {
    self.current = current
    self.orderTables = current.orderTableBackingStorage.makeWriable()
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
      var target = self.entityBackingStorage.makeWriable()
      target.merge(otherStorage: context.insertsOrUpdates)
      target.subtract(otherStorage: context.deletes)
      
      updateOrderTable: do {
        
        self.orderTableBackingStorage = context.orderTables.makeReadonly()
        
        context.deletes.entityTableStorage.forEach { key, value in
          
          if let table = context.orderTables.orderTableStorage[key] {
            var modified = table
            
            modified.removeAll { value.contains($0) }
            
            self.orderTableBackingStorage.orderTableStorage[key] = modified
          }
          
        }
        
      }
                  
      self.entityBackingStorage = target.makeReadonly()
    } catch {
      throw error
    }
  }
}
