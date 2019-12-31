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

public protocol DatabaseEmbedding {
  
  associatedtype Database: DatabaseType
  
  static var getterToDatabase: (Self) -> Database { get }
  
}

extension ValueContainerType where Value : DatabaseEmbedding {
    
  /// Make getter to select value with update closure
  ///
  /// - Parameters:
  ///   - update: Updating output value each Input value updated.
  ///   - additionalEqualityComputer: Check to necessory of needs to update to reduce number of updating.
  public func entityGetter<Output>(
    update: @escaping (Value.Database) -> Output,
    additionalEqualityComputer: EqualityComputer<Value.Database>?
  ) -> Getter<Value, Output> {
    
    let path = Value.getterToDatabase
    
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
        update(Value.getterToDatabase(value))
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
    
  /// A entity getter that entity id based.
  /// - Parameters:
  ///   - tableSelector:
  ///   - entityID:
  public func entityGetter<E: EntityType>(entityID: E.ID) -> Getter<Value, E?> {
    
    return entityGetter(
      update: { db in
        db.entities.table(E.self).find(by: entityID)
    },
      additionalEqualityComputer: nil
    )
    
  }
  
  public func entityGetter<E: EntityType & Equatable>(
    entityID: E.ID
  ) -> Getter<Value, E?> {
    
    return entityGetter(
      update: { db in
        db.entities.table(E.self).find(by: entityID)
    },
      additionalEqualityComputer: .init(
        selector: { db in db.entities.table(E.self).find(by: entityID) },
        equals: { $0 == $1 }
      )
    )
    
  }
  
  public func nonNullEntityGetter<E: EntityType>(entity: E) -> Getter<Value, E> {
    
    var fetched: E = entity
    let entityID = entity.id
    
    return entityGetter(
      update: { db in
        let table = db.entities.table(E.self)
        if let e = table.find(by: entityID) {
          fetched = e
        }
        return fetched
    },
      additionalEqualityComputer: nil
    )
    
  }
  
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    entity: E
  ) -> Getter<Value, E> {
    
    var fetched: E = entity
    let entityID = entity.id
    
    return entityGetter(
      update: { db in
        let table = db.entities.table(E.self)
        if let e = table.find(by: entityID) {
          fetched = e
        }
        return fetched
    },
      additionalEqualityComputer: .init(
        selector: { db in db.entities.table(E.self).find(by: entityID) },
        equals: { $0 == $1 }
      )
    )
    
  }
  
  /// A selector that if get nil then return latest non-null value
  public func nonNullEntityGetter<E: EntityType>(
    from insertionResult: EntityTable<Value.Database.Schema, E>.InsertionResult
  ) -> Getter<Value, E> {
            
    return nonNullEntityGetter(entity: insertionResult.entity)
            
  }
  
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    from insertionResult: EntityTable<Value.Database.Schema, E>.InsertionResult
  ) -> Getter<Value, E> {
      
    return nonNullEntityGetter(entity: insertionResult.entity)
    
  }
}

