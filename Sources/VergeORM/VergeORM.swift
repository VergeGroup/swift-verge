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

public protocol AccessControlType {}

public enum Read: AccessControlType {
  
}

public enum Write: AccessControlType {
  
}

public protocol DatabaseType {
  
  associatedtype Schema: EntitySchemaType
  associatedtype OrderTables: OrderTablesType
  typealias BackingStorage = DatabaseStorage<Schema, OrderTables>
  var _backingStorage: BackingStorage { get set }
}

public struct DatabaseStorage<Schema: EntitySchemaType, OrderTables: OrderTablesType> {
  
  public typealias EntityBackingStorage = EntityStorage<Schema, Read>
  public typealias OrderTableBackingStorage = OrderTableStorage<OrderTables, Read>
  
  public typealias WritableBackingStorage = EntityStorage<Schema, Write>
  public typealias WritableOrderTableBackingStorage = OrderTableStorage<OrderTables, Write>
 
  var entityBackingStorage: EntityBackingStorage = .init()
  var orderTableBackingStorage: OrderTableBackingStorage = .init()
  
  public init() {
    
  }
}

@dynamicMemberLookup
public struct EntityPropertyAdapter<DB: DatabaseType> {
  
  let get: () -> DB
  
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<DB.Schema, EntityTableKey<U>>) -> EntityTable<U, Read> {
    get {
      get()._backingStorage.entityBackingStorage[dynamicMember: keyPath]
    }
  }
}

@dynamicMemberLookup
public struct OrderTablePropertyAdapter<DB: DatabaseType> {
  
  let get: () -> DB
  
  public subscript <U: EntityType>(dynamicMember keyPath: KeyPath<DB.OrderTables, OrderTableKey<U>>) -> OrderTable<U, Read> {
    get {
      get()._backingStorage.orderTableBackingStorage[dynamicMember: keyPath]
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
  
  public var insertsOrUpdates: Database.BackingStorage.WritableBackingStorage = .init()
  public var deletes: BackingRemovingEntityStorage<Database.Schema> = .init()
  
  public var orderTables: Database.BackingStorage.WritableOrderTableBackingStorage
  
  init(current: Database) {
    self.current = current
    self.orderTables = current._backingStorage.orderTableBackingStorage.makeWriable()
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
      var target = self._backingStorage.entityBackingStorage.makeWriable()
      target.merge(otherStorage: context.insertsOrUpdates)
      target.subtract(otherStorage: context.deletes)
      
      updateOrderTable: do {
        
        self._backingStorage.orderTableBackingStorage = context.orderTables.makeReadonly()
        
        context.deletes.entityTableStorage.forEach { key, value in
          
          if let table = context.orderTables.orderTableStorage[key] {
            var modified = table
            
            modified.removeAll { value.contains($0) }
            
            self._backingStorage.orderTableBackingStorage.orderTableStorage[key] = modified
          }
          
        }
        
      }
                  
      self._backingStorage.entityBackingStorage = target.makeReadonly()
    } catch {
      throw error
    }
  }
}
