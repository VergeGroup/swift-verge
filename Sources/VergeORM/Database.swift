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

#if !COCOAPODS
import VergeStore
#endif

public struct EntityTableKey<S: EntityType> {

  private let sourceInfo: String

  public init(file: StaticString = #file, line: UInt = #line, column: UInt = #column) {
    self.sourceInfo = "\(file)|\(line)|\(column)"
  }

}

public struct IndexKey<Index: IndexType> {

  private let sourceInfo: String

  public init(file: StaticString = #file, line: UInt = #line, column: UInt = #column) {
    self.sourceInfo = "\(file)|\(line)|\(column)"
  }
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

/**

 A protocol indicates it is a root object as a Database
 As a Database, it provides the tables of the entity, the index storage.

 Here is boilerplate
 ```swift
 public struct Database: DatabaseType {

  public struct Schema: EntitySchemaType {

    public init() {}
  }

  public struct Indexes: IndexesType {

    public init() {}
  }

  public var _backingStorage: BackingStorage = .init()

}
 ```
 */
public protocol DatabaseType: Equatable, DatabaseEmbedding where Database == Self {
    
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

public struct DatabaseStorage<Schema: EntitySchemaType, Indexes: IndexesType>: Equatable {

  public static func == (lhs: DatabaseStorage<Schema, Indexes>, rhs: DatabaseStorage<Schema, Indexes>) -> Bool {
    guard lhs.entityUpdatedMarker == rhs.entityUpdatedMarker else { return false }
    guard lhs.indexUpdatedMarker == rhs.indexUpdatedMarker else { return false }
    return true
  }

  private(set) public var entityUpdatedMarker = NonAtomicVersionCounter()
  private(set) public var indexUpdatedMarker = NonAtomicVersionCounter()
  internal(set) public var lastUpdatesResult: DatabaseEntityUpdatesResult<Schema>?
  
  var entityBackingStorage: EntityTablesStorage<Schema> = .init()
  
  var indexesStorage: IndexesStorage<Schema, Indexes> = .init()
  
  mutating func markUpdated() {
    entityUpdatedMarker.markAsUpdated()
    indexUpdatedMarker.markAsUpdated()
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
