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
import VergeCore
#endif

extension EntityType {
  
  #if COCOAPODS
  public typealias AnyGetter = Verge.AnyGetter<Self>
  public typealias Getter<Source> = Verge.Getter<Source, Self>
  #else
  public typealias AnyGetter = VergeCore.AnyGetter<Self>
  public typealias Getter<Source> = VergeCore.Getter<Source, Self>
  #endif
  
}

public protocol HasDatabaseStateType {
  
  associatedtype Database: DatabaseType
  
  static var keyPathToDatabase: (Self) -> Database { get }
  
}

extension ValueContainerType where Value : HasDatabaseStateType {
  
  public func entityGetter<Output>(
    update: @escaping (Value.Database) -> Output,
    additionalEqualityComputer: EqualityComputer<Value.Database>?
  ) -> Getter<Value, Output> {
    
    let path = Value.keyPathToDatabase
    
    let baseComputer = EqualityComputer<Value.Database>.init(
      selector: { input -> (Date, Date) in
        let v = input
        return (v._backingStorage.entityUpdatedAt, v._backingStorage.indexUpdatedAt)
    },
      equals: { (old, new) -> Bool in
        old == new
    })
    
    let _getter = getter(
      selector: { (value) -> Output in
        update(Value.keyPathToDatabase(value))
    },
      equality: EqualityComputer.init(selector: { path($0) }, equals: { (old, new) -> Bool in
        guard !baseComputer.isEqual(value: new) else {
          return true
        }
        return additionalEqualityComputer?.isEqual(value: new) ?? false
      })
    )
        
    return _getter
  }
  
  public func entityGetter<E: EntityType>(
    tableSelector: @escaping (Value.Database) -> EntityTable<Value.Database.Schema, E>,
    entityID: E.ID
  ) -> Getter<Value, E?> {
    
    return entityGetter(
      update: { db in
        tableSelector(db).find(by: entityID)
    },
      additionalEqualityComputer: nil
    )
    
  }
  
  public func entityGetter<E: EntityType & Equatable>(
    tableSelector: @escaping (Value.Database) -> EntityTable<Value.Database.Schema, E>,
    entityID: E.ID
  ) -> Getter<Value, E?> {
    
    return entityGetter(
      update: { db in
        tableSelector(db).find(by: entityID)
    },
      additionalEqualityComputer: .init(
        selector: { tableSelector($0).find(by: entityID) },
        equals: { $0 == $1 }
      )
    )
    
  }
  
  public func nonNullEntityGetter<E: EntityType>(
    tableSelector: @escaping (Value.Database) -> EntityTable<Value.Database.Schema, E>,
    entity: E
  ) -> Getter<Value, E> {
    
    var fetched: E = entity
    let entityID = entity.id
    
    return entityGetter(
      update: { db in
        let table = tableSelector(db)
        if let e = table.find(by: entityID) {
          fetched = e
        }
        return fetched
    },
      additionalEqualityComputer: nil
    )
    
  }
  
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    tableSelector: @escaping (Value.Database) -> EntityTable<Value.Database.Schema, E>,
    entity: E
  ) -> Getter<Value, E> {
    
    var fetched: E = entity
    let entityID = entity.id
    
    return entityGetter(
      update: { db in
        let table = tableSelector(db)
        if let e = table.find(by: entityID) {
          fetched = e
        }
        return fetched
    },
      additionalEqualityComputer: .init(
        selector: { tableSelector($0).find(by: entityID) },
        equals: { $0 == $1 }
      )
    )
    
  }
  
  /// A selector that if get nil then return latest non-null value
  public func nonNullEntityGetter<E: EntityType>(
    from insertionResult: EntityTable<Value.Database.Schema, E>.InsertionResult
  ) -> Getter<Value, E> {
            
    let selector = insertionResult.makeSelector(Value.Database.self)
    return nonNullEntityGetter(tableSelector: selector, entity: insertionResult.entity)
            
  }
  
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    from insertionResult: EntityTable<Value.Database.Schema, E>.InsertionResult
  ) -> Getter<Value, E> {
      
    let selector = insertionResult.makeSelector(Value.Database.self)
    return nonNullEntityGetter(tableSelector: selector, entity: insertionResult.entity)
    
  }
}

