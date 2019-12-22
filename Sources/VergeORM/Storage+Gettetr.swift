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

extension ValueContainerType {
  
  public func entityGetter<Schema: EntitySchemaType, E: EntityType>(
    entityTableSelector: @escaping (Value) -> EntityTable<Schema, E>,
    entityID: E.ID
  ) -> Getter<Value, E?> {
    
    getter(selector: { (value) -> E? in
      let table = entityTableSelector(value)
      return table.find(by: entityID)
    }, equality: .alwaysDifferent()
    )
           
  }
  
  public func entityGetter<Schema: EntitySchemaType, E: EntityType & Equatable>(
    entityTableSelector: @escaping (Value) -> EntityTable<Schema, E>,
    entityID: E.ID
  ) -> Getter<Value, E?> {
    
    getter(selector: { (value) -> E? in
      let table = entityTableSelector(value)
      return table.find(by: entityID)
    }, equality: .init(selector: entityTableSelector, equals: { $0 == $1 })
    )
    
  }
    
  /// A selector that if get nil then return latest non-null value
  /// - Parameters:
  ///   - entityTableSelector:
  ///   - entity:
  public func nonNullEntityGetter<Schema: EntitySchemaType, E: EntityType>(
    entityTableSelector: @escaping (Value) -> EntityTable<Schema, E>,
    entity: E
  ) -> Getter<Value, E> {
    
    var fetched: E = entity
    
    return getter(selector: { (value) -> E in
      let table = entityTableSelector(value)
      if let e = table.find(by: entity.id) {
        fetched = e
      }
      return fetched
    }, equality: .alwaysDifferent()
    )
    
  }
  
  /// A selector that if get nil then return latest non-null value
  /// - Parameters:
  ///   - entityTableSelector:
  ///   - entity:
  public func nonNullEntityGetter<Schema: EntitySchemaType, E: EntityType & Equatable>(
    entityTableSelector: @escaping (Value) -> EntityTable<Schema, E>,
    entity: E
  ) -> Getter<Value, E> {
    
    var fetched: E = entity
    
    return getter(selector: { (value) -> E in
      let table = entityTableSelector(value)
      if let e = table.find(by: entity.id) {
        fetched = e
      }
      return fetched
    }, equality: .init(selector: entityTableSelector, equals: { $0 == $1 })
    )
    
  }
  
   
}

public protocol HasDatabaseStateType {
  
  associatedtype Database: DatabaseType
  
  static var keyPathToDatabase: (Self) -> Database { get }
  
}

extension ValueContainerType where Value : HasDatabaseStateType {
  
  public func nonNullEntityGetter<E: EntityType>(
    from insertionResult: EntityTable<Value.Database.Schema, E>.InsertionResult
  ) -> Getter<Value, E> {
    
    var fetched: E = insertionResult.entity
    let id = fetched.id
    
    let _s = insertionResult.makeSelector(Value.keyPathToDatabase)
    return getter(selector: { (value) -> E in
      let table = _s(value)
      if let e = table.find(by: id) {
        fetched = e
      }
      return fetched
    }, equality: .alwaysDifferent()
    )
  }
  
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    from insertionResult: EntityTable<Value.Database.Schema, E>.InsertionResult
  ) -> Getter<Value, E> {
    
    var fetched: E = insertionResult.entity
    let id = fetched.id
    
    let _s = insertionResult.makeSelector(Value.keyPathToDatabase)
    return getter(selector: { (value) -> E in
      let table = _s(value)
      if let e = table.find(by: id) {
        fetched = e
      }
      return fetched
    }, equality: .init(selector: _s, equals: { $0 == $1 })
    )
    
  }
}
