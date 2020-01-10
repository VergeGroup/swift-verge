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

#if canImport(Combine)

@available(iOS 13, macOS 10.15, *)
extension EntityType {
  
  #if COCOAPODS
  public typealias Getter = Verge.Getter<Self>
  public typealias GetterSource<Source> = Verge.GetterSource<Source, Self>
  #else
  public typealias Getter = VergeCore.Getter<Self>
  public typealias GetterSource<Source> = VergeCore.GetterSource<Source, Self>
  #endif
  
}
#endif

public protocol DatabaseEmbedding {
  
  associatedtype Database: DatabaseType
  
  static var getterToDatabase: (Self) -> Database { get }
  
}

extension EqualityComputer where Input : DatabaseType {
  
  public static func tableEqual<E: EntityType>(_ entityType: E.Type) -> EqualityComputer<Input> {
    let checkTableUpdated = EqualityComputer<Input>.init(
      selector: { input -> Date in
        return input._backingStorage.entityBackingStorage.table(E.self).updatedAt
    },
      equals: { (old, new) -> Bool in
        old == new
    })
    return checkTableUpdated
  }
  
  public static func entityEqual<E: EntityType & Equatable>(_ entityID: E.EntityID) -> EqualityComputer<Input> {
    return .init(
      selector: { db in db.entities.table(E.self).find(by: entityID) },
      equals: { $0 == $1 }
    )
  }
  
}

fileprivate final class _GetterCache {
  
  private let cache = NSCache<NSString, AnyObject>()
  
  @inline(__always)
  private func key<E: EntityType>(entityID: E.EntityID) -> NSString {
    "\(ObjectIdentifier(E.self))_\(entityID)" as NSString
  }
  
  func getter<E: EntityType>(entityID: E.EntityID) -> AnyObject? {
    cache.object(forKey: key(entityID: entityID))
  }
  
  func setGetter<E: EntityType>(_ getter: AnyObject, entityID: E.EntityID) {
    cache.setObject(getter, forKey: key(entityID: entityID))
  }
  
}

#if canImport(Combine)

fileprivate var _valueContainerAssociated: Void?

@available(iOS 13, macOS 10.15, *)
extension ValueContainerType where Value : DatabaseEmbedding {
  
  private var cache: _GetterCache {
    
    if let associated = objc_getAssociatedObject(self, &_valueContainerAssociated) as? _GetterCache {
      
      return associated
      
    } else {
      
      let associated = _GetterCache()
      objc_setAssociatedObject(self, &_valueContainerAssociated, associated, .OBJC_ASSOCIATION_RETAIN)
      return associated
    }
  }
  
  /// Make getter to select value with update closure
  ///
  /// - Parameters:
  ///   - update: Updating output value each Input value updated.
  ///   - additionalEqualityComputer: Check to necessory of needs to update to reduce number of updating.
  public func makeEntityGetter<Output>(
    update: @escaping (Value.Database) -> Output,
    additionalEqualityComputer: EqualityComputer<Value.Database>?
  ) -> GetterSource<Value, Output> {
    
    let path = Value.getterToDatabase
    
    let checkDatabaseUpdated = EqualityComputer<Value.Database>.init(
      selector: { input -> (Date, Date) in
        let v = input
        return (v._backingStorage.entityUpdatedAt, v._backingStorage.indexUpdatedAt)
    },
      equals: { (old, new) -> Bool in
        old == new
    })
    
    let computer = EqualityComputer.init(or: [
      checkDatabaseUpdated,
      additionalEqualityComputer
      ].compactMap { $0 })
    
    let _getter = getter(
      filter: EqualityComputer.init(selector: { path($0) }, equals: { (old, new) -> Bool in
        computer.isEqual(value: new)
      }),
      map: { (value) -> Output in
        let t = SignpostTransaction("ORM.Getter.update")
        defer {
          t.end()
        }
        return update(Value.getterToDatabase(value))
    })
    
    return _getter
  }
  
  public func makeEntityGetter<E: EntityType>(
    from entityID: E.EntityID,
    additionalEqualityComputer: EqualityComputer<Value.Database>?
  ) -> GetterSource<Value, E?> {
    
    let newGetter = makeEntityGetter(
      update: { db in
        db.entities.table(E.self).find(by: entityID)
    },
      additionalEqualityComputer: .init(or: [
        .tableEqual(E.self),
        additionalEqualityComputer
        ].compactMap { $0 }
      )
    )
    return newGetter
    
  }
  
  public func makeNonNullEntityGetter<E: EntityType>(
    from entity: E,
    additionalEqualityComputer: EqualityComputer<Value.Database>?
  ) -> GetterSource<Value, E> {
    
    var box = entity
    let entityID = entity.entityID
    
    let newGetter = makeEntityGetter(
      update: { db -> E in
        let table = db.entities.table(E.self)
        if let e = table.find(by: entityID) {
          box = e
        }
        return box
    },
      additionalEqualityComputer: .init(or: [
        .tableEqual(E.self),
        additionalEqualityComputer
        ].compactMap { $0 }
      )
    )
    return newGetter
    
  }
  
  // MARK: -
  
  /// A entity getter that entity id based.
  /// - Parameters:
  ///   - tableSelector:
  ///   - entityID:
  public func entityGetter<E: EntityType>(from entityID: E.EntityID) -> GetterSource<Value, E?> {
    
    let _cache = cache
    
    guard let getter = _cache.getter(entityID: entityID) as? GetterSource<Value, E?> else {
      let newGetter = makeEntityGetter(from: entityID, additionalEqualityComputer: nil)
      _cache.setGetter(newGetter, entityID: entityID)
      return newGetter
    }
    
    return getter
    
  }
  
  public func entityGetter<E: EntityType & Equatable>(
    from entityID: E.EntityID
  ) -> GetterSource<Value, E?> {
    
    let _cache = cache
    
    guard let getter = _cache.getter(entityID: entityID) as? GetterSource<Value, E?> else {
      let newGetter = makeEntityGetter(from: entityID, additionalEqualityComputer: .entityEqual(entityID))
      _cache.setGetter(newGetter, entityID: entityID)
      return newGetter
    }
    
    return getter
    
  }
  
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType>(from entity: E) -> GetterSource<Value, E> {
    
    let _cache = cache
    
    guard let getter = _cache.getter(entityID: entity.entityID) as? GetterSource<Value, E> else {
      let entityID = entity.entityID
      let newGetter = makeNonNullEntityGetter(from: entity, additionalEqualityComputer: nil)
      _cache.setGetter(newGetter, entityID: entityID)
      return newGetter
    }
    
    return getter
    
  }
  
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    from entity: E
  ) -> GetterSource<Value, E> {
    
    let _cache = cache
    
    guard let getter = _cache.getter(entityID: entity.entityID) as? GetterSource<Value, E> else {
      let entityID = entity.entityID
      let newGetter = makeNonNullEntityGetter(from: entity, additionalEqualityComputer: .entityEqual(entityID))
      _cache.setGetter(newGetter, entityID: entityID)
      return newGetter
    }
    
    return getter
    
  }
  
  // MARK: -
  
  /// A selector that if get nil then return latest non-null value
  @inline(__always)
  public func nonNullEntityGetters<S: Sequence, E: EntityType>(
    from entities: S
  ) -> [GetterSource<Value, E>] where S.Element == E {
    entities.map {
      nonNullEntityGetter(from: $0)
    }
  }
  
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    from entityID: E.EntityID
  ) -> GetterSource<Value, E>? {
    
    let db = Value.getterToDatabase(wrappedValue)
    guard let entity = db.entities.table(E.self).find(by: entityID) else { return nil }
    return nonNullEntityGetter(from: entity)
  }
  
  @inline(__always)
  public func nonNullEntityGetters<S: Sequence, E: EntityType>(
    from entityIDs: S
  ) -> [E.EntityID : GetterSource<Value, E>] where S.Element == E.EntityID {
    
    let db = Value.getterToDatabase(wrappedValue)
    
    return db.entities.table(E.self).find(in: entityIDs)
      .reduce(into: [E.EntityID : GetterSource<Value, E>](), { (container, entity) in
        container[entity.entityID] = nonNullEntityGetter(from: entity)
      })
  }
  
  /// A selector that if get nil then return latest non-null value
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType>(
    from insertionResult: EntityTable<Value.Database.Schema, E>.InsertionResult
  ) -> GetterSource<Value, E> {
    
    return nonNullEntityGetter(from: insertionResult.entity)
    
  }
  
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    from insertionResult: EntityTable<Value.Database.Schema, E>.InsertionResult
  ) -> GetterSource<Value, E> {
    
    return nonNullEntityGetter(from: insertionResult.entity)
  }
  
  public func nonNullEntityGetters<E: EntityType, S: Sequence>(
    from insertionResults: S
  ) -> [GetterSource<Value, E>] where S.Element == EntityTable<Value.Database.Schema, E>.InsertionResult {
    insertionResults.map {
      nonNullEntityGetter(from: $0)
    }
  }
  
  public func nonNullEntityGetters<E: EntityType & Equatable, S: Sequence>(
    from insertionResults: S
  ) -> [GetterSource<Value, E>] where S.Element == EntityTable<Value.Database.Schema, E>.InsertionResult {
    insertionResults.map {
      nonNullEntityGetter(from: $0)
    }
  }
  
}

#endif
