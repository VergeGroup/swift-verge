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
  
  public init() {}
}

public struct IndexKey<Index: IndexType> {
  
  public init() {}
}

public protocol IndexesType {
  init()
}

public protocol EntitySchemaType {
  init()
}

public protocol MiddlewareType {
  associatedtype Database: DatabaseType
  
  func performAfterUpdates(context: DatabaseBatchUpdatesContext<Database>)
}

public struct AnyMiddleware<Database: DatabaseType>: MiddlewareType {
  
  private let _performAfterUpdates: (DatabaseBatchUpdatesContext<Database>) -> ()
  
  public init<Base: MiddlewareType>(_ base: Base) where Base.Database == Database {
    self._performAfterUpdates = base.performAfterUpdates
  }
  
  public init(performAfterUpdates: @escaping (DatabaseBatchUpdatesContext<Database>) -> ()) {
    self._performAfterUpdates = performAfterUpdates
  }
  
  public func performAfterUpdates(context: DatabaseBatchUpdatesContext<Database>) {
    _performAfterUpdates(context)
  }
}

/// A protocol indicates it is a root object as a Database
/// As a Database, it provides the tables of the entity, the index storage.
public protocol DatabaseType: DatabaseEmbedding where Database == Self {
    
  associatedtype Schema: EntitySchemaType
  associatedtype Indexes: IndexesType
  typealias BackingStorage = DatabaseStorage<Schema, Indexes>
  var _backingStorage: BackingStorage { get set }
  
  var middlewares: [AnyMiddleware<Self>] { get }
}

// MARK: - DatabaseEmbedding
extension DatabaseType {
  public static var getterToDatabase: (Self) -> Self { { $0 } }
}

extension DatabaseType {
  
  public var middlewares: [AnyMiddleware<Self>] { [] }
}

public struct DatabaseStorage<Schema: EntitySchemaType, Indexes: IndexesType> {
  
  private(set) public var entityUpdatedAt: Date = .init()
  private(set) public var indexUpdatedAt: Date = .init()
  internal(set) public var lastUpdatesResult: DatabaseEntityUpdatesResult<Schema>?
  
  var entityBackingStorage: EntityTablesStorage<Schema> = .init()
  
  var indexesStorage: IndexesStorage<Schema, Indexes> = .init()
  
  mutating func markUpdated() {
    entityUpdatedAt = .init()
    indexUpdatedAt = .init()
  }
  
  public init() {
    
  }
}

@dynamicMemberLookup
public struct EntityPropertyAdapter<DB: DatabaseType> {
  
  let get: () -> DB
  
  public func table<E: EntityType>(_ entityType: E.Type) -> EntityTable<DB.Schema, E> {
    get()._backingStorage.entityBackingStorage.table(entityType)
  }
  
  public subscript <E: EntityType>(dynamicMember keyPath: KeyPath<DB.Schema, EntityTableKey<E>>) -> EntityTable<DB.Schema, E> {
    `get`()._backingStorage.entityBackingStorage.table(E.self)
  }
}

@dynamicMemberLookup
public struct IndexesPropertyAdapter<DB: DatabaseType> {
  
  let get: () -> DB
  
  public subscript <Index: IndexType>(dynamicMember keyPath: KeyPath<DB.Indexes, IndexKey<Index>>) -> Index where DB.Schema == Index.Schema {
    `get`()._backingStorage.indexesStorage[dynamicMember: keyPath]    
  }
}

extension DatabaseType {
  
  public var entities: EntityPropertyAdapter<Self> {
    .init {
      self
    }
  }
  
  public var indexes: IndexesPropertyAdapter<Self> {
    .init {
      self
    }
  }
  
}
