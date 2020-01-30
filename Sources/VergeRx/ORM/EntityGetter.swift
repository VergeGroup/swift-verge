//
//  EntityGetter.swift
//  VergeRx
//
//  Created by muukii on 2020/01/10.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import RxSwift

#if !COCOAPODS
import VergeORM
import VergeCore
#endif

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

fileprivate var _valueContainerAssociated: Void?

extension Reactive where Base : RxValueContainerType, Base.Value : DatabaseEmbedding {
  
  private var cache: _GetterCache {
    
    if let associated = objc_getAssociatedObject(base, &_valueContainerAssociated) as? _GetterCache {
      
      return associated
      
    } else {
      
      let associated = _GetterCache()
      objc_setAssociatedObject(base, &_valueContainerAssociated, associated, .OBJC_ASSOCIATION_RETAIN)
      return associated
    }
  }
  
  /// Make getter to select value with update closure
  ///
  /// - Parameters:
  ///   - update: Updating output value each Input value updated.
  ///   - andFilter: Check to necessory of needs to update to reduce number of updating.
  public func makeEntityGetter<Output>(
    update: @escaping (Base.Value.Database) -> Output,
    andFilter: AnyComparer<Base.Value.Database>?
  ) -> RxGetterSource<Base.Value, Output> {
    
    return makeGetter(from: .makeEntityGetter(update: update, andFilter: andFilter))
    
  }
  
  public func makeEntityGetter<E: EntityType>(
    from entityID: E.EntityID,
    andFilter: AnyComparer<Base.Value.Database>?
  ) -> RxGetterSource<Base.Value, E?> {
    
    return makeGetter(from: .makeEntityGetter(from: entityID, andFilter: andFilter))
  }
  
  public func makeNonNullEntityGetter<E: EntityType>(
    from entity: E,
    andFilter: AnyComparer<Base.Value.Database>?
  ) -> RxGetterSource<Base.Value, E> {
    
    return makeGetter(from: .makeNonNullEntityGetter(from: entity, andFilter: andFilter))
  }
  
  // MARK: -
  
  /// A entity getter that entity id based.
  /// - Parameters:
  ///   - tableSelector:
  ///   - entityID:
  public func entityGetter<E: EntityType>(from entityID: E.EntityID) -> RxGetterSource<Base.Value, E?> {
    
    let _cache = cache
    
    guard let getter = _cache.getter(entityID: entityID) as? RxGetterSource<Base.Value, E?> else {
      let newGetter = makeEntityGetter(from: entityID, andFilter: nil)
      _cache.setGetter(newGetter, entityID: entityID)
      return newGetter
    }
    
    return getter
    
  }
  
  public func entityGetter<E: EntityType & Equatable>(
    from entityID: E.EntityID
  ) -> RxGetterSource<Base.Value, E?> {
    
    let _cache = cache
    
    guard let getter = _cache.getter(entityID: entityID) as? RxGetterSource<Base.Value, E?> else {
      let newGetter = makeEntityGetter(from: entityID, andFilter: AnyComparer.entityUpdated(entityID))
      _cache.setGetter(newGetter, entityID: entityID)
      return newGetter
    }
    
    return getter
    
  }
  
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType>(from entity: E) -> RxGetterSource<Base.Value, E> {
    
    let _cache = cache
    
    guard let getter = _cache.getter(entityID: entity.entityID) as? RxGetterSource<Base.Value, E> else {
      let entityID = entity.entityID
      let newGetter = makeNonNullEntityGetter(from: entity, andFilter: nil)
      _cache.setGetter(newGetter, entityID: entityID)
      return newGetter
    }
    
    return getter
    
  }
  
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    from entity: E
  ) -> RxGetterSource<Base.Value, E> {
    
    let _cache = cache
    
    guard let getter = _cache.getter(entityID: entity.entityID) as? RxGetterSource<Base.Value, E> else {
      let entityID = entity.entityID
      let newGetter = makeNonNullEntityGetter(from: entity, andFilter: AnyComparer.entityUpdated(entityID))
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
  ) -> [RxGetterSource<Base.Value, E>] where S.Element == E {
    entities.map {
      nonNullEntityGetter(from: $0)
    }
  }
  
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    from entityID: E.EntityID
  ) -> RxGetterSource<Base.Value, E>? {
    
    let db = Base.Value.getterToDatabase(base.wrappedValue)
    guard let entity = db.entities.table(E.self).find(by: entityID) else { return nil }
    return nonNullEntityGetter(from: entity)
  }
  
  @inline(__always)
  public func nonNullEntityGetters<S: Sequence, E: EntityType>(
    from entityIDs: S
  ) -> [E.EntityID : RxGetterSource<Base.Value, E>] where S.Element == E.EntityID {
    
    let db = Base.Value.getterToDatabase(base.wrappedValue)
    
    return db.entities.table(E.self).find(in: entityIDs)
      .reduce(into: [E.EntityID : RxGetterSource<Base.Value, E>](), { (container, entity) in
        container[entity.entityID] = nonNullEntityGetter(from: entity)
      })
  }
  
  /// A selector that if get nil then return latest non-null value
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType>(
    from insertionResult: EntityTable<Base.Value.Database.Schema, E>.InsertionResult
  ) -> RxGetterSource<Base.Value, E> {
    
    return nonNullEntityGetter(from: insertionResult.entity)
    
  }
  
  @inline(__always)
  public func nonNullEntityGetter<E: EntityType & Equatable>(
    from insertionResult: EntityTable<Base.Value.Database.Schema, E>.InsertionResult
  ) -> RxGetterSource<Base.Value, E> {
    
    return nonNullEntityGetter(from: insertionResult.entity)
  }
  
  public func nonNullEntityGetters<E: EntityType, S: Sequence>(
    from insertionResults: S
  ) -> [RxGetterSource<Base.Value, E>] where S.Element == EntityTable<Base.Value.Database.Schema, E>.InsertionResult {
    insertionResults.map {
      nonNullEntityGetter(from: $0)
    }
  }
  
  public func nonNullEntityGetters<E: EntityType & Equatable, S: Sequence>(
    from insertionResults: S
  ) -> [RxGetterSource<Base.Value, E>] where S.Element == EntityTable<Base.Value.Database.Schema, E>.InsertionResult {
    insertionResults.map {
      nonNullEntityGetter(from: $0)
    }
  }
  
}
