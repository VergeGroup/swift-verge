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
  public let id: Entity.EntityID
  
  public init(id: Entity.EntityID, entity: Entity?) {
    self.id = id
    self.wrapped = entity
  }

  public subscript<Property>(dynamicMember keyPath: KeyPath<Entity, Property>) -> Property? {
    wrapped?[keyPath: keyPath]
  }
  
}

extension EntityWrapper: Equatable where Entity: Equatable {
  
}

extension EntityWrapper: Hashable where Entity: Hashable {
  
}

@dynamicMemberLookup
public struct NonNullEntityWrapper<Entity: EntityType> {
  
  public private(set) var wrapped: Entity
  public let id: Entity.EntityID
  
  public let isUsingFallback: Bool
  
  public init(entity: Entity, isUsingFallback: Bool) {
    self.id = entity.entityID
    self.wrapped = entity
    self.isUsingFallback = isUsingFallback
  }
  
  public subscript<Property>(dynamicMember keyPath: KeyPath<Entity, Property>) -> Property {
    wrapped[keyPath: keyPath]
  }
  
}

extension NonNullEntityWrapper: Equatable where Entity: Equatable {
  
}

extension NonNullEntityWrapper: Hashable where Entity: Hashable {
  
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
          id: entityID,
          entity: path(changes.primitive).entities.table(Entity.self).find(by: entityID)
        )
    },
      update: { changes in
                
        let hasChanges = changes.asChanges().hasChanges(
          { (composing) -> Input.Value.Database in
            let db = path(composing.root)
            return db
        }, comparer.curried()
        )
        
        guard hasChanges else {
          return .noChanages
        }
        
        let entity = path(changes.primitive).entities.table(Entity.self).find(by: entityID)
        return .updated(.init(id: entityID, entity: entity))
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
    
    let lastValue = VergeConcurrency.RecursiveLockAtomic<Entity>.init(entity)
    
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
          return .init(entity: wrapped, isUsingFallback: false)
        }
        return .init(entity: lastValue.value, isUsingFallback: true)
      }))
    
  }
  
}

/// A result instance that contains created Derived object
/// While creating non-null derived from entity id, some entity may be not founded.
/// Created derived object are stored in hashed storage to the consumer can check if the entity was not found by the id.
public struct DerivedResult<Entity: EntityType, Derived: AnyObject> {
  
  /// A dictionary of Derived that stored by id
  /// It's faster than filtering values array to use this dictionary to find missing id or created id.
  public private(set) var storage: [Entity.EntityID : Derived] = [:]
  
  /// An array of Derived that orderd by specified the order of id.
  public private(set) var values: [Derived]
  
  public init() {
    self.storage = [:]
    self.values = []
  }
  
  public mutating func append(derived: Derived, id: Entity.EntityID) {
    storage[id] = derived
    values.append(derived)
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
    
    guard let initalValue = path(primitiveState).entities.table(Entity.self).find(by: entityID) else {
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
  
  public typealias NonNullDerivedResult<Entity: EntityType> = DerivedResult<Entity, Entity.NonNullDerived>
    
  @inline(__always)
  public func derivedNonNull<Entity: EntityType, S: Sequence>(
    from entityIDs: S,
    dropsOutput: @escaping (Entity?, Entity?) -> Bool = { _, _ in false }
  ) -> NonNullDerivedResult<Entity> where S.Element == Entity.EntityID {
    entityIDs.reduce(into: NonNullDerivedResult<Entity>()) { (r, e) in
      do {
        r.append(derived: try derivedNonNull(from: e, dropsOutput: dropsOutput), id: e)
      } catch {
        //
      }
    }
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable, S: Sequence>(
    from entityIDs: S
  ) -> NonNullDerivedResult<Entity> where S.Element == Entity.EntityID {
    derivedNonNull(from: entityIDs, dropsOutput: ==)
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType>(
    from entityIDs: Set<Entity.EntityID>,
    dropsOutput: @escaping (Entity?, Entity?) -> Bool = { _, _ in false }
  ) -> NonNullDerivedResult<Entity> {
    derivedNonNull(from: AnySequence.init(entityIDs.makeIterator), dropsOutput: dropsOutput)
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable>(
    from entityIDs: Set<Entity.EntityID>
  ) -> NonNullDerivedResult<Entity> {
    derivedNonNull(from: entityIDs, dropsOutput: ==)
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType, S: Sequence>(
    from entities: S,
    dropsOutput: @escaping (S.Element?, S.Element?) -> Bool = { _, _ in false }
  ) -> NonNullDerivedResult<Entity> where S.Element == Entity {
    entities.reduce(into: NonNullDerivedResult<Entity>()) { (r, e) in
      r.append(derived: derivedNonNull(from: e, dropsOutput: dropsOutput), id: e.entityID)
    }
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable, S: Sequence>(
    from entities: S
  ) -> NonNullDerivedResult<Entity> where S.Element == Entity {
    derivedNonNull(from: entities, dropsOutput: ==)
  }
    
  @inline(__always)
  public func derivedNonNull<Entity: EntityType>(
    from entities: Set<Entity>,
    dropsOutput: @escaping (Entity?, Entity?) -> Bool = { _, _ in false }
  ) -> NonNullDerivedResult<Entity> {
    derivedNonNull(from: AnySequence.init(entities.makeIterator))
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable>(
    from entities: Set<Entity>
  ) -> NonNullDerivedResult<Entity> {
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
  ) -> NonNullDerivedResult<Entity> where S.Element == EntityTable<State.Database.Schema, Entity>.InsertionResult {
    derivedNonNull(from: insertionResults.map { $0.entity })
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable, S: Sequence>(
    from insertionResults: S
  ) -> NonNullDerivedResult<Entity> where S.Element == EntityTable<State.Database.Schema, Entity>.InsertionResult {
    
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
