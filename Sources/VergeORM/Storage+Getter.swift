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

#if canImport(Combine)

@available(iOS 13, macOS 10.15, *)
extension EntityType {
  
  #if COCOAPODS
  public typealias Getter = Verge.Getter<Self>
  public typealias GetterSource<Source> = Verge.GetterSource<Source, Self>
  #else
  public typealias Getter = VergeStore.Getter<Self>
  public typealias GetterSource<Source> = VergeStore.GetterSource<Source, Self>
  #endif
  
}
#endif

public protocol DatabaseEmbedding {
  
  associatedtype Database: DatabaseType
  
  static var getterToDatabase: (Self) -> Database { get }
  
}

extension Comparer where Input : DatabaseType {
  
  public static func databaseUpdated() -> Self {
    return .init { pre, new in
      (pre._backingStorage.entityUpdatedMarker, pre._backingStorage.indexUpdatedMarker) == (new._backingStorage.entityUpdatedMarker, new._backingStorage.indexUpdatedMarker)
    }
  }
  
  public static func tableUpdated<E: EntityType>(_ entityType: E.Type) -> Self {
    Comparer.init(selector: { $0._backingStorage.entityBackingStorage.table(E.self).updatedMarker })
  }
  
  public static func entityUpdated<E: EntityType & Equatable>(_ entityID: E.EntityID) -> Self {
    return .init(selector: { $0.entities.table(E.self).find(by: entityID) })
  }
  
  public static func changesContains<E: EntityType>(_ entityID: E.EntityID) -> Self {
    return .init { _, new in
      guard let result = new._backingStorage.lastUpdatesResult else {
        return false
      }
      guard !result.wasUpdated(entityID) else {
        return false
      }
      guard !result.wasDeleted(entityID) else {
        return false
      }
      return true
    }
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

extension GetterComponents where Input : DatabaseEmbedding {
    
  /// Factory of the getter for querying entity from database
  ///
  /// This method already contains pre-filter to keep performant.
  /// update closure would run only when database changed.
  ///
  /// - Parameters:
  ///   - update:
  ///   - filter:
  /// - Returns:
  public static func makeEntityGetter<Output>(
    update: @escaping (Input.Database) -> Output,
    filter: Comparer<Input.Database>?
  ) -> GetterComponents<Input, Input.Database, Output, Output> {
    
    let path = Input.getterToDatabase
    
    let filter = Comparer<Input.Database>.init(or: [
      .databaseUpdated(),
      filter,
      ].compactMap { $0 })
    
    return GetterComponents<Input, Input.Database, Output, Output>(
      onPreFilterWillReceive: { _ in },
      preFilter: .init(
        keySelector: { path($0) },
        comparer: filter
      ),
      onTransformWillReceive: { _ in },
      transform: { (value) -> Output in
        let t = VergeSignpostTransaction("ORM.Getter.update")
        defer {
          t.end()
        }
        return update(Input.getterToDatabase(value))
    },
      postFilter: .noFilter,
      onPostFilterWillEmit: { _ in }
    )
      
  }
  
  /// Factory of the getter for querying entity from database
  ///
  /// This method already contains pre-filter to keep performant.
  /// update closure would run only when database changed.
  ///
  public static func makeEntityGetter<E: EntityType>(
    from entityID: E.EntityID,
    filter: Comparer<Input.Database>?
  ) -> GetterComponents<Input, Input.Database, E?, E?> {
    
    return makeEntityGetter(
      update: { db in
        db.entities.table(E.self).find(by: entityID)
    },
      filter: .init(or: [
        .tableUpdated(E.self),
        .changesContains(entityID),
        filter
        ].compactMap { $0 }
      )
    )
        
  }
  
  /// Factory of the getter for querying entity from database
  ///
  /// This method already contains pre-filter to keep performant.
  /// update closure would run only when database changed.
  ///
  public static func makeNonNullEntityGetter<E: EntityType>(
    from entity: E,
    filter: Comparer<Input.Database>?
  ) -> GetterComponents<Input, Input.Database, E, E> {
    
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
      filter: Comparer.init(or: [
        .tableUpdated(E.self),
        .changesContains(entityID),
        filter
        ].compactMap { $0 }
      )
    )
    return newGetter
    
  }
  
}

#if canImport(Combine)

fileprivate var _valueContainerAssociated: Void?

@available(iOS 13, macOS 10.15, *)
extension Store where State : DatabaseEmbedding {
    
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
  ///   - filter: Check to necessory of needs to update to reduce number of updating.
  public func makeEntityGetter<Output>(
    update: @escaping (State.Database) -> Output,
    filter: Comparer<State.Database>?
  ) -> GetterSource<State, Output> {
      
    return makeGetter(from: .makeEntityGetter(update: update, filter: filter))
  }
  
  public func makeEntityGetter<E: EntityType>(
    from entityID: E.EntityID,
    filter: Comparer<State.Database>?
  ) -> GetterSource<State, E?> {
    
    return makeGetter(from: .makeEntityGetter(from: entityID, filter: filter))
  }
  
  public func makeNonNullEntityGetter<E: EntityType>(
    from entity: E,
    filter: Comparer<State.Database>?
  ) -> GetterSource<State, E> {
    
    return makeGetter(from: .makeNonNullEntityGetter(from: entity, filter: filter))
  }
  
  // MARK: -
  
  /// A entity getter that entity id based.
  /// - Parameters:
  ///   - tableSelector:
  ///   - entityID:
  public func entityGetter<E: EntityType>(from entityID: E.EntityID) -> GetterSource<State, E?> {
    
    let _cache = cache
    
    guard let getterBuilder = _cache.getter(entityID: entityID) as? GetterSource<State, E?> else {
      let newGetter = makeEntityGetter(from: entityID, filter: nil)
      _cache.setGetter(newGetter, entityID: entityID)
      return newGetter
    }
    
    return getterBuilder
    
  }
  
  public func entityGetter<E: EntityType & Equatable>(
    from entityID: E.EntityID
  ) -> GetterSource<State, E?> {
    
    let _cache = cache
    
    guard let getterBuilder = _cache.getter(entityID: entityID) as? GetterSource<State, E?> else {
      let newGetter = makeEntityGetter(from: entityID, filter: Comparer.entityUpdated(entityID))
      _cache.setGetter(newGetter, entityID: entityID)
      return newGetter
    }
    
    return getterBuilder
    
  }
  
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType>(from entity: E) -> GetterSource<State, E> {
    
    let _cache = cache
    
    guard let getterBuilder = _cache.getter(entityID: entity.entityID) as? GetterSource<State, E> else {
      let entityID = entity.entityID
      let newGetter = makeNonNullEntityGetter(from: entity, filter: nil)
      _cache.setGetter(newGetter, entityID: entityID)
      return newGetter
    }
    
    return getterBuilder
    
  }
  
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    from entity: E
  ) -> GetterSource<State, E> {
    
    let _cache = cache
    
    guard let getterBuilder = _cache.getter(entityID: entity.entityID) as? GetterSource<State, E> else {
      let entityID = entity.entityID
      let newGetter = makeNonNullEntityGetter(from: entity, filter: Comparer.entityUpdated(entityID))
      _cache.setGetter(newGetter, entityID: entityID)
      return newGetter
    }
    
    return getterBuilder
    
  }
  
  // MARK: -
  
  /// A selector that if get nil then return latest non-null value
  @inline(__always)
  public func nonNullEntityGetters<S: Sequence, E: EntityType>(
    from entities: S
  ) -> [GetterSource<State, E>] where S.Element == E {
    entities.map {
      nonNullEntityGetter(from: $0)
    }
  }
  
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    from entityID: E.EntityID
  ) -> GetterSource<State, E>? {
    
    let db = State.getterToDatabase(state)
    guard let entity = db.entities.table(E.self).find(by: entityID) else { return nil }
    return nonNullEntityGetter(from: entity)
  }
  
  @inline(__always)
  public func nonNullEntityGetters<S: Sequence, E: EntityType>(
    from entityIDs: S
  ) -> [E.EntityID : GetterSource<State, E>] where S.Element == E.EntityID {
    
    let db = State.getterToDatabase(state)
    
    return db.entities.table(E.self).find(in: entityIDs)
      .reduce(into: [E.EntityID : GetterSource<Value, E>](), { (container, entity) in
        container[entity.entityID] = nonNullEntityGetter(from: entity)
      })
  }
  
  /// A selector that if get nil then return latest non-null value
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType>(
    from insertionResult: EntityTable<State.Database.Schema, E>.InsertionResult
  ) -> GetterSource<State, E> {
    
    return nonNullEntityGetter(from: insertionResult.entity)
    
  }
  
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    from insertionResult: EntityTable<State.Database.Schema, E>.InsertionResult
  ) -> GetterSource<State, E> {
    
    return nonNullEntityGetter(from: insertionResult.entity)
  }
  
  public func nonNullEntityGetters<E: EntityType, S: Sequence>(
    from insertionResults: S
  ) -> [GetterSource<State, E>] where S.Element == EntityTable<State.Database.Schema, E>.InsertionResult {
    insertionResults.map {
      nonNullEntityGetter(from: $0)
    }
  }
  
  public func nonNullEntityGetters<E: EntityType & Equatable, S: Sequence>(
    from insertionResults: S
  ) -> [GetterSource<State, E>] where S.Element == EntityTable<State.Database.Schema, E>.InsertionResult {
    insertionResults.map {
      nonNullEntityGetter(from: $0)
    }
  }
  
}

#endif
