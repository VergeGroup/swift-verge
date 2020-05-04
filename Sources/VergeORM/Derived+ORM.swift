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

public enum VergeORMError: Swift.Error {
  case notFoundEntityFromDatabase
}

extension EntityType {
  
  #if COCOAPODS
  public typealias Derived = Verge.Derived<EntityWrapper<Self>>
  public typealias NonNullDerived = Verge.Derived<NonNullEntityWrapper<Self>>
  #else
  public typealias Derived = VergeStore.Derived<EntityWrapper<Self>>
  public typealias NonNullDerived = VergeStore.Derived<NonNullEntityWrapper<Self>>
  #endif
  
}

@dynamicMemberLookup
public struct EntityWrapper<Entity: EntityType> {
  
  public private(set) var wrapped: Entity?
  
  public init(_ wrapped: Entity?) {
    self.wrapped = wrapped
  }

  public subscript<Property>(dynamicMember keyPath: KeyPath<Entity, Property>) -> Property? {
    wrapped?[keyPath: keyPath]
  }
  
}

extension EntityWrapper: Equatable where Entity: Equatable {
  
}

@dynamicMemberLookup
public struct NonNullEntityWrapper<Entity: EntityType> {
  
  public private(set) var wrapped: Entity
  
  public let isUsingFallback: Bool
  
  public init(_ wrapped: Entity, isUsingFallback: Bool) {
    self.wrapped = wrapped
    self.isUsingFallback = isUsingFallback
  }
  
  public subscript<Property>(dynamicMember keyPath: KeyPath<Entity, Property>) -> Property {
    wrapped[keyPath: keyPath]
  }
  
}

extension NonNullEntityWrapper: Equatable where Entity: Equatable {
  
}

extension MemoizeMap where Input : ChangesType, Input.Value : DatabaseEmbedding {
  
  @inline(__always)
  fileprivate static func makeEntityQuery<Entity: EntityType>(entityID: Entity.EntityID) -> MemoizeMap<Input, EntityWrapper<Entity>> {
    
    let path = Input.Value.getterToDatabase
    
    let comparer = Comparer<Input.Value.Database>(or: [
      Comparer<Input.Value.Database>.databaseNoUpdates(),
      Comparer<Input.Value.Database>.tableNoUpdates(Entity.self),
      Comparer<Input.Value.Database>.changesNoContains(entityID),
    ])
      
    return .init(
      makeInitial: { changes in
        .init(
          path(changes.current).entities.table(Entity.self).find(by: entityID)
        )
    },
      update: { changes in
                
        let hasChanges = changes.asChanges().hasChanges(
          compose: { (composing) -> Input.Value.Database in
            let db = path(composing.root)
            return db
        }, comparer: comparer.curried()
        )
        
        guard hasChanges else {
          return .noChanages
        }
        
        let entity = path(changes.current).entities.table(Entity.self).find(by: entityID)
        return .updated(.init(entity))
    })
  }
  
}

fileprivate final class _GetterCache {
  
  private let cache = NSCache<NSString, AnyObject>()
  
  @inline(__always)
  private func key<E: EntityType>(entityID: E.EntityID) -> NSString {
    "\(ObjectIdentifier(E.self))_\(entityID)" as NSString
  }
  
  func get<E: EntityType>(entityID: E.EntityID) -> E.Derived? {
    cache.object(forKey: key(entityID: entityID)) as? E.Derived
  }
  
  func set<E: EntityType>(_ getter: E.Derived, entityID: E.EntityID) {
    cache.setObject(getter, forKey: key(entityID: entityID))
  }
  
}

// MARK: - Primitive operators

fileprivate var _valueContainerAssociated: Void?

extension StoreType where State : DatabaseEmbedding {
  
  private var cache: _GetterCache {
        
    objc_sync_enter(self); defer { objc_sync_exit(self) }
    
    if let associated = objc_getAssociatedObject(self, &_valueContainerAssociated) as? _GetterCache {
      
      return associated
      
    } else {
      
      let associated = _GetterCache()
      objc_setAssociatedObject(self, &_valueContainerAssociated, associated, .OBJC_ASSOCIATION_RETAIN)
      return associated
    }
  }
  
  /**
   Returns Derived object that projects fetched Entity object by the entity identifier.
   
   The Derived object is constructed from multiple Derived.
   Underlying-Derived: Fetch the entity from id
   DropsOutput-Derived: Drops the duplicated object
   
   Underlying-Derived would be cached by the id.
   If the cached object found, it will be used to construct Derived with DropsOutput-Derived.
   
   - Parameters:
     - entityID: an identifier of the entity
     - dropsOutput: Used for Derived. the condition to drop duplicated object.
   */
  @inline(__always)
  public func derived<Entity: EntityType>(
    from entityID: Entity.EntityID,
    dropsOutput: @escaping (Entity?, Entity?) -> Bool = { _, _ in false }
  ) -> Entity.Derived {
    
    objc_sync_enter(self); defer { objc_sync_exit(self) }
    
    let underlyingDerived: Derived<EntityWrapper<Entity>>
    
    if let cached = cache.get(entityID: entityID) {
      underlyingDerived = cached
    } else {
      underlyingDerived = derived(
        .makeEntityQuery(entityID: entityID)
      )
      cache.set(underlyingDerived, entityID: entityID)
    }
        
    let d = underlyingDerived.chain(
      .init(map: { $0.root }),
      dropsOutput: { changes in
        changes.noChanges(\.root, {
          dropsOutput($0.wrapped, $1.wrapped)
        })
    })
        
    return d
  }
  
}

// MARK: - Convenience operators

extension StoreType where State : DatabaseEmbedding {
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType>(
    from entity: Entity,
    dropsOutput: @escaping (Entity?, Entity?) -> Bool = { _, _ in false }
  ) -> Entity.NonNullDerived {
    
    let lastValue = VergeConcurrency.Atomic<Entity>.init(entity)
    
    #if DEBUG
    let checker = VergeConcurrency.SynchronizationTracker()
    #endif
    
    return derived(from: entity.entityID, dropsOutput: dropsOutput)
      .chain(.init(map: {
        #if DEBUG
        checker.register(); defer { checker.unregister() }
        #endif
        if let wrapped = $0.root.wrapped {
          lastValue.swap(wrapped)
          return .init(wrapped, isUsingFallback: false)
        }
        return .init(lastValue.value, isUsingFallback: true)
      }))
    
  }
  
}

extension StoreType where State : DatabaseEmbedding {
  
  @inline(__always)
  public func derived<Entity: EntityType & Equatable>(
    from entityID: Entity.EntityID
  ) -> Entity.Derived {
    
    derived(from: entityID, dropsOutput: ==)
  }
    
  @inline(__always)
  public func derivedNonNull<Entity: EntityType>(
    from entityID: Entity.EntityID,
    dropsOutput: @escaping (Entity?, Entity?) -> Bool = { _, _ in false }
  ) throws -> Entity.NonNullDerived {
    
    let path = State.getterToDatabase
    
    guard let initalValue = path(state).entities.table(Entity.self).find(by: entityID) else {
      throw VergeORMError.notFoundEntityFromDatabase
    }
   
    return derivedNonNull(from: initalValue, dropsOutput: dropsOutput)
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable>(
    from entityID: Entity.EntityID
  ) throws -> Entity.NonNullDerived {
    try derivedNonNull(from: entityID, dropsOutput: ==)
  }
  
 
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable>(
    from entity: Entity
  ) -> Entity.NonNullDerived {
    derivedNonNull(from: entity, dropsOutput: ==)
  }
  
  public typealias NonNullDerivedRecord<Entity: EntityType> = [Entity.EntityID : Entity.NonNullDerived]
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType, S: Sequence>(
    from entities: S,
    dropsOutput: @escaping (S.Element?, S.Element?) -> Bool = { _, _ in false }
  ) -> NonNullDerivedRecord<Entity> where S.Element == Entity {
    entities.reduce(into: NonNullDerivedRecord<Entity>()) { (r, e) in
      r[e.entityID] = derivedNonNull(from: e, dropsOutput: dropsOutput)
    }
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable, S: Sequence>(
    from entities: S
  ) -> NonNullDerivedRecord<Entity> where S.Element == Entity {
    derivedNonNull(from: entities, dropsOutput: ==)
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType>(
    from entities: Set<Entity>,
    dropsOutput: @escaping (Entity?, Entity?) -> Bool = { _, _ in false }
  ) -> NonNullDerivedRecord<Entity> {
    entities.reduce(into: NonNullDerivedRecord<Entity>()) { (r, e) in
      r[e.entityID] = derivedNonNull(from: e, dropsOutput: dropsOutput)
    }
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable>(
    from entities: Set<Entity>
  ) -> NonNullDerivedRecord<Entity> {
    derivedNonNull(from: entities, dropsOutput: ==)
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType>(
    from insertionResult: EntityTable<State.Database.Schema, Entity>.InsertionResult,
    dropsOutput: @escaping (Entity?, Entity?) -> Bool = { _, _ in false }
  ) -> Entity.NonNullDerived {
    derivedNonNull(from: insertionResult.entity, dropsOutput: dropsOutput)
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable>(
    from insertionResult: EntityTable<State.Database.Schema, Entity>.InsertionResult
  ) -> Entity.NonNullDerived {
    derivedNonNull(from: insertionResult, dropsOutput: ==)
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType, S: Sequence>(
    from insertionResults: S,
    dropsOutput: @escaping (Entity?, Entity?) -> Bool = { _, _ in false }
  ) -> NonNullDerivedRecord<Entity> where S.Element == EntityTable<State.Database.Schema, Entity>.InsertionResult {
    
    insertionResults.reduce(into: NonNullDerivedRecord<Entity>()) { (r, e) in
      r[e.entityID] = derivedNonNull(from: e.entity, dropsOutput: dropsOutput)
    }
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable, S: Sequence>(
    from insertionResults: S
  ) -> NonNullDerivedRecord<Entity> where S.Element == EntityTable<State.Database.Schema, Entity>.InsertionResult {
    
    derivedNonNull(from: insertionResults, dropsOutput: ==)
  }
     
}

extension StoreType where State : DatabaseEmbedding {
  
  @inline(__always)
  public func derivedNonNull<E0: EntityType & Equatable, E1: EntityType & Equatable>(
    from e0ID: E0.EntityID,
    _ e1ID: E1.EntityID
  ) throws -> Derived<(NonNullEntityWrapper<E0>, NonNullEntityWrapper<E1>)> {
    
    Derived.combined(
      try derivedNonNull(from: e0ID),
      try derivedNonNull(from: e1ID)
    )
  }
  
  @inline(__always)
  public func derivedNonNull<E0: EntityType & Equatable, E1: EntityType & Equatable, E2: EntityType & Equatable>(
    from e0ID: E0.EntityID,
    _ e1ID: E1.EntityID,
    _ e2ID: E2.EntityID
  ) throws -> Derived<(NonNullEntityWrapper<E0>, NonNullEntityWrapper<E1>, NonNullEntityWrapper<E2>)> {
    
    Derived.combined(
      try derivedNonNull(from: e0ID),
      try derivedNonNull(from: e1ID),
      try derivedNonNull(from: e2ID)
    )
  }
}
