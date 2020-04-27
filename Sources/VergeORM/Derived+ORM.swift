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
  
  fileprivate init(_ wrapped: Entity?) {
    self.wrapped = wrapped
  }

  public subscript<Property>(dynamicMember keyPath: KeyPath<Entity, Property>) -> Property? {
    wrapped?[keyPath: keyPath]
  }
  
}

@dynamicMemberLookup
public struct NonNullEntityWrapper<Entity: EntityType> {
  
  public private(set) var wrapped: Entity
  
  public let isUsingFallback: Bool
  
  fileprivate init(_ wrapped: Entity, isUsingFallback: Bool) {
    self.wrapped = wrapped
    self.isUsingFallback = isUsingFallback
  }
  
  public subscript<Property>(dynamicMember keyPath: KeyPath<Entity, Property>) -> Property {
    wrapped[keyPath: keyPath]
  }
  
}

extension MemoizeMap where Input : ChangesType, Input.Value : DatabaseEmbedding {
  
  @inline(__always)
  fileprivate static func makeEntityQuery<Entity: EntityType>(entityID: Entity.EntityID) -> MemoizeMap<Input, EntityWrapper<Entity>> {
    
    let path = Input.Value.getterToDatabase
      
    return .init(
      makeInitial: { changes in
        .init(
          path(changes.current).entities.table(Entity.self).find(by: entityID)
        )
    },
      update: { changes in
        
        let hasChanges = changes.asChanges().hasChanges(
          compose: { (composing) -> Input.Value.Database in
            let db = type(of: composing.root).getterToDatabase(composing.root)
            return db
        }, comparer: { old, new in
          Comparer<Input.Value.Database>.init(or: [
            .databaseNoUpdates(),
            .tableNoUpdates(Entity.self),
            .changesNoContains(entityID)
          ])
            .equals(old, new)
        })
        
        guard !hasChanges else {
          return .noChanages
        }
        
        let entity = path(changes.current).entities.table(Entity.self).find(by: entityID)
        return .updated(.init(entity))
    })
  }
  
}

extension StoreType where State : DatabaseEmbedding {
    
  @inline(__always)
  public func derived<Entity: EntityType>(
    from entityID: Entity.EntityID,
    entityWasUpdated: @escaping (Entity?, Entity?) -> Bool
  ) -> Entity.Derived {
        
    let d = derived(
      .makeEntityQuery(entityID: entityID),
      dropsOutput: { changes in
        changes.noChanges(\.root, {
          entityWasUpdated($0.wrapped, $1.wrapped)
        })
    })
        
    return d
  }
  
  @inline(__always)
  public func derived<Entity: EntityType & Equatable>(
    from entityID: Entity.EntityID
  ) -> Entity.Derived {
    
    derived(from: entityID, entityWasUpdated: ==)
  }
  
}

extension StoreType where State : DatabaseEmbedding {
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType>(
    from entityID: Entity.EntityID,
    entityWasUpdated: @escaping (Entity?, Entity?) -> Bool
  ) throws -> Entity.NonNullDerived {
    
    let path = State.getterToDatabase
    
    guard let initalValue = path(state).entities.table(Entity.self).find(by: entityID) else {
      throw VergeORMError.notFoundEntityFromDatabase
    }
   
    return derivedNonNull(from: initalValue, entityWasUpdated: entityWasUpdated)
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable>(
    from entityID: Entity.EntityID
  ) throws -> Entity.NonNullDerived {
    try derivedNonNull(from: entityID, entityWasUpdated: ==)
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType>(
    from entity: Entity,
    entityWasUpdated: @escaping (Entity?, Entity?) -> Bool
  ) -> Entity.NonNullDerived {
    
    let lastValue = VergeConcurrency.Atomic<Entity>.init(entity)
    
    #if DEBUG
    let checker = VergeConcurrency.SynchronizationTracker()
    #endif
    
    return derived(from: entity.entityID, entityWasUpdated: entityWasUpdated)
      .chain(.init(map: {
        #if DEBUG
        checker.register(); defer { checker.unregister() }
        #endif
        if let wrapped = $0.current.wrapped {
          lastValue.swap(wrapped)
          return .init(wrapped, isUsingFallback: false)
        }
        return .init(lastValue.value, isUsingFallback: true)
      }))
    
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable>(
    from entity: Entity
  ) -> Entity.NonNullDerived {
    derivedNonNull(from: entity, entityWasUpdated: ==)
  }
  
  public typealias NonNullDerivedRecord<Entity: EntityType> = [Entity.EntityID : Entity.NonNullDerived]
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType, S: Sequence>(
    from entities: S,
    entityWasUpdated: @escaping (S.Element?, S.Element?) -> Bool
  ) -> NonNullDerivedRecord<Entity> where S.Element == Entity {
    entities.reduce(into: NonNullDerivedRecord<Entity>()) { (r, e) in
      r[e.entityID] = derivedNonNull(from: e, entityWasUpdated: entityWasUpdated)
    }
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable, S: Sequence>(
    from entities: S
  ) -> NonNullDerivedRecord<Entity> where S.Element == Entity {
    derivedNonNull(from: entities, entityWasUpdated: ==)
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType>(
    from entities: Set<Entity>,
    entityWasUpdated: @escaping (Entity?, Entity?) -> Bool
  ) -> NonNullDerivedRecord<Entity> {
    entities.reduce(into: NonNullDerivedRecord<Entity>()) { (r, e) in
      r[e.entityID] = derivedNonNull(from: e, entityWasUpdated: entityWasUpdated)
    }
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable>(
    from entities: Set<Entity>
  ) -> NonNullDerivedRecord<Entity> {
    derivedNonNull(from: entities, entityWasUpdated: ==)
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType>(
    from insertionResult: EntityTable<State.Database.Schema, Entity>.InsertionResult,
    entityWasUpdated: @escaping (Entity?, Entity?) -> Bool
  ) -> Entity.NonNullDerived {
    derivedNonNull(from: insertionResult.entity, entityWasUpdated: entityWasUpdated)
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable>(
    from insertionResult: EntityTable<State.Database.Schema, Entity>.InsertionResult
  ) -> Entity.NonNullDerived {
    derivedNonNull(from: insertionResult, entityWasUpdated: ==)
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType, S: Sequence>(
    from insertionResults: S,
    entityWasUpdated: @escaping (Entity?, Entity?) -> Bool
  ) -> NonNullDerivedRecord<Entity> where S.Element == EntityTable<State.Database.Schema, Entity>.InsertionResult {
    
    insertionResults.reduce(into: NonNullDerivedRecord<Entity>()) { (r, e) in
      r[e.entityID] = derivedNonNull(from: e.entity, entityWasUpdated: entityWasUpdated)
    }
  }
  
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable, S: Sequence>(
    from insertionResults: S
  ) -> NonNullDerivedRecord<Entity> where S.Element == EntityTable<State.Database.Schema, Entity>.InsertionResult {
    
    derivedNonNull(from: insertionResults, entityWasUpdated: ==)
  }
     
}
