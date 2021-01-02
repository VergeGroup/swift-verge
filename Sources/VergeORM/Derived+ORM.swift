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
import Verge
#endif

public enum VergeORMError: Swift.Error {
  case notFoundEntityFromDatabase
}

extension EntityType {
  
  #if COCOAPODS
  public typealias Derived = Verge.Derived<EntityWrapper<Self>>
  public typealias NonNullDerived = Verge.Derived<NonNullEntityWrapper<Self>>
  #else
  public typealias Derived = Verge.Derived<EntityWrapper<Self>>
  public typealias NonNullDerived = Verge.Derived<NonNullEntityWrapper<Self>>
  #endif
  
}

/// A value that wraps an entity and results of fetching.
public struct EntityWrapper<Entity: EntityType> {
  
  public private(set) var wrapped: Entity?
  public let id: Entity.EntityID
  
  public init(id: Entity.EntityID, entity: Entity?) {
    self.id = id
    self.wrapped = entity
  }
  
}

extension EntityWrapper: Equatable where Entity: Equatable {
  
}

extension EntityWrapper: Hashable where Entity: Hashable {
  
}

/// A value that wraps an entity and results of fetching.
@dynamicMemberLookup
public struct NonNullEntityWrapper<Entity: EntityType> {

  /// An entity value
  public private(set) var wrapped: Entity

  /// An identifier
  public let id: Entity.EntityID

  @available(*, deprecated, renamed: "isFallBack")
  public var isUsingFallback: Bool {
    isFallBack
  }

  /// A boolean value that indicates whether the wrapped entity is last value and has been removed from source store.
  public let isFallBack: Bool

  public init(entity: Entity, isFallBack: Bool) {
    self.id = entity.entityID
    self.wrapped = entity
    self.isFallBack = isFallBack
  }
  
  public subscript<Property>(dynamicMember keyPath: KeyPath<Entity, Property>) -> Property {
    wrapped[keyPath: keyPath]
  }
  
}

extension NonNullEntityWrapper: Equatable where Entity: Equatable {
  
}

extension NonNullEntityWrapper: Hashable where Entity: Hashable {
  
}

extension Pipeline where Input : ChangesType, Input.Value : DatabaseEmbedding {

  /// Returns a MemoizeMap value that optimized for looking entity up from the database.
  @inline(__always)
  fileprivate static func _makeEntityQuery<Entity: EntityType>(entityID: Entity.EntityID) -> Pipeline<Input, EntityWrapper<Entity>> {
    
    let path = Input.Value.getterToDatabase
    
    let noChangesComparer = Comparer<Input.Value.Database>(or: [

      /** Step 1 */
      Comparer<Input.Value.Database>.databaseNoUpdates(),

      /** Step 2 */
      Comparer<Input.Value.Database>.tableNoUpdates(Entity.self),

      /** Step 3 */
      Comparer<Input.Value.Database>.changesNoContains(entityID),
    ])
      
    return Pipeline<Input, EntityWrapper<Entity>>(
      makeInitial: { state in
        EntityWrapper<Entity>(
          id: entityID,
          entity: path(state.primitive).entities.table(Entity.self).find(by: entityID) /** Queries an entity */
        )
    },
      update: { state in
                
        let hasChanges = state.asChanges().hasChanges(
          { (composing) -> Input.Value.Database in
            let db = path(composing.root)
            return db
        }, noChangesComparer
        )
        
        guard hasChanges else {
          return .noUpdates
        }

        /** Queries an entity */
        let entity = path(state.primitive).entities.table(Entity.self).find(by: entityID)
        return .new(EntityWrapper<Entity>(id: entityID, entity: entity))
    })
  }
  
}

fileprivate final class _DerivedObjectCache {
  
  private let _cache = NSCache<NSString, AnyObject>()
  
  @inline(__always)
  private func key<E: EntityType>(entityID: E.EntityID) -> NSString {
    "\(ObjectIdentifier(E.self))_\(entityID)" as NSString
  }
  
  func get<E: EntityType>(entityID: E.EntityID) -> E.Derived? {
    _cache.object(forKey: key(entityID: entityID)) as? E.Derived
  }
  
  func set<E: EntityType>(_ getter: E.Derived, entityID: E.EntityID) {
    _cache.setObject(getter, forKey: key(entityID: entityID))
  }
  
}

// MARK: - Primitive operators

fileprivate var _valueContainerAssociated: Void?

extension StoreType where State : DatabaseEmbedding {
  
  private var _nonatomic_derivedObjectCache: _DerivedObjectCache {

    if let associated = objc_getAssociatedObject(self, &_valueContainerAssociated) as? _DerivedObjectCache {
      
      return associated
      
    } else {
      
      let associated = _DerivedObjectCache()
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
    dropsOutput: @escaping (Entity?, Entity?) -> Bool = { _, _ in false },
    queue: TargetQueue = .passthrough
  ) -> Entity.Derived {
    
    objc_sync_enter(self); defer { objc_sync_exit(self) }
    
    let underlyingDerived: Derived<EntityWrapper<Entity>>
    
    if let cached = _nonatomic_derivedObjectCache.get(entityID: entityID) {
      underlyingDerived = cached
    } else {
      /// creates a new underlying derived object
      underlyingDerived = derived(
        ._makeEntityQuery(entityID: entityID),
        queue: queue
      )
      _nonatomic_derivedObjectCache.set(underlyingDerived, entityID: entityID)
    }
        
    let d = underlyingDerived.chain(
      .init(map: { $0.root }),
      dropsOutput: { changes in
        changes.noChanges(\.root, .init {
          dropsOutput($0.wrapped, $1.wrapped)
        })
      },
      queue: queue
    )

    return d
  }
  
}

// MARK: - Convenience operators

extension StoreType where State : DatabaseEmbedding {
  
  @inline(__always)
  fileprivate func _primary_derivedNonNull<Entity: EntityType>(
    from entity: Entity,
    dropsOutput: @escaping (Entity?, Entity?) -> Bool = { _, _ in false },
    queue: TargetQueue = .passthrough
  ) -> Entity.NonNullDerived {
    
    let fallingBackValue = VergeConcurrency.RecursiveLockAtomic<Entity>.init(entity)
    
    #if DEBUG
    let checker = VergeConcurrency.SynchronizationTracker()
    #endif
    
    return derived(from: entity.entityID, dropsOutput: dropsOutput, queue: queue)
      .chain(
        .init(map: {
          #if DEBUG
          checker.register(); defer { checker.unregister() }
          #endif
          if let wrapped = $0.root.wrapped {
            fallingBackValue.swap(wrapped)
            return .init(entity: wrapped, isFallBack: false)
          }
          return .init(entity: fallingBackValue.value, isFallBack: true)
        }),
        queue: queue
      )
    
  }

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  /// - Parameters:
  ///   - entity:
  ///   - dropsOutput:
  /// - Returns: A derived object
  @inline(__always)
  public func derivedNonNull<Entity: EntityType>(
    from entity: Entity,
    dropsOutput: @escaping (Entity?, Entity?) -> Bool = { _, _ in false },
    queue: TargetQueue = .passthrough
  ) -> Entity.NonNullDerived {

    _primary_derivedNonNull(from: entity, dropsOutput: dropsOutput, queue: queue)
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
  public func derived<Entity: EntityType & Equatable>(
    from entityID: Entity.EntityID,
    queue: TargetQueue = .passthrough
  ) -> Entity.Derived {
    
    derived(from: entityID, dropsOutput: ==, queue: queue)
  }

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  @inline(__always)
  public func derivedNonNull<Entity: EntityType>(
    from entityID: Entity.EntityID,
    dropsOutput: @escaping (Entity?, Entity?) -> Bool = { _, _ in false },
    queue: TargetQueue = .passthrough
  ) throws -> Entity.NonNullDerived {
    
    let path = State.getterToDatabase
    
    guard let initalValue = path(primitiveState).entities.table(Entity.self).find(by: entityID) else {
      throw VergeORMError.notFoundEntityFromDatabase
    }
   
    return _primary_derivedNonNull(from: initalValue, dropsOutput: dropsOutput, queue: queue)
  }

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable>(
    from entityID: Entity.EntityID,
    queue: TargetQueue = .passthrough
  ) throws -> Entity.NonNullDerived {
    try derivedNonNull(from: entityID, dropsOutput: ==, queue: queue)
  }

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable>(
    from entity: Entity,
    queue: TargetQueue = .passthrough
  ) -> Entity.NonNullDerived {
    _primary_derivedNonNull(from: entity, dropsOutput: ==, queue: queue)
  }
  
  public typealias NonNullDerivedResult<Entity: EntityType> = DerivedResult<Entity, Entity.NonNullDerived>

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  @inline(__always)
  public func derivedNonNull<Entity: EntityType, S: Sequence>(
    from entityIDs: S,
    dropsOutput: @escaping (Entity?, Entity?) -> Bool = { _, _ in false },
    queue: TargetQueue = .passthrough
  ) -> NonNullDerivedResult<Entity> where S.Element == Entity.EntityID {
    entityIDs.reduce(into: NonNullDerivedResult<Entity>()) { (r, e) in
      do {
        r.append(derived: try derivedNonNull(from: e, dropsOutput: dropsOutput, queue: queue), id: e)
      } catch {
        //
      }
    }
  }

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable, S: Sequence>(
    from entityIDs: S,
    queue: TargetQueue = .passthrough
  ) -> NonNullDerivedResult<Entity> where S.Element == Entity.EntityID {
    derivedNonNull(from: entityIDs, dropsOutput: ==, queue: queue)
  }

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  @inline(__always)
  public func derivedNonNull<Entity: EntityType>(
    from entityIDs: Set<Entity.EntityID>,
    dropsOutput: @escaping (Entity?, Entity?) -> Bool = { _, _ in false },
    queue: TargetQueue = .passthrough
  ) -> NonNullDerivedResult<Entity> {
    derivedNonNull(from: AnySequence.init(entityIDs.makeIterator), dropsOutput: dropsOutput, queue: queue)
  }

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable>(
    from entityIDs: Set<Entity.EntityID>,
    queue: TargetQueue = .passthrough
  ) -> NonNullDerivedResult<Entity> {
    derivedNonNull(from: entityIDs, dropsOutput: ==, queue: queue)
  }

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  @inline(__always)
  public func derivedNonNull<Entity: EntityType, S: Sequence>(
    from entities: S,
    dropsOutput: @escaping (S.Element?, S.Element?) -> Bool = { _, _ in false },
    queue: TargetQueue = .passthrough
  ) -> NonNullDerivedResult<Entity> where S.Element == Entity {
    entities.reduce(into: NonNullDerivedResult<Entity>()) { (r, e) in
      r.append(derived: _primary_derivedNonNull(from: e, dropsOutput: dropsOutput, queue: queue), id: e.entityID)
    }
  }

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable, S: Sequence>(
    from entities: S,
    queue: TargetQueue = .passthrough
  ) -> NonNullDerivedResult<Entity> where S.Element == Entity {
    derivedNonNull(from: entities, dropsOutput: ==, queue: queue)
  }

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  @inline(__always)
  public func derivedNonNull<Entity: EntityType>(
    from entities: Set<Entity>,
    dropsOutput: @escaping (Entity?, Entity?) -> Bool = { _, _ in false },
    queue: TargetQueue = .passthrough
  ) -> NonNullDerivedResult<Entity> {
    derivedNonNull(from: AnySequence.init(entities.makeIterator), queue: queue)
  }

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable>(
    from entities: Set<Entity>,
    queue: TargetQueue = .passthrough
  ) -> NonNullDerivedResult<Entity> {
    derivedNonNull(from: entities, dropsOutput: ==, queue: queue)
  }

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  @inline(__always)
  public func derivedNonNull<Entity: EntityType>(
    from insertionResult: EntityTable<State.Database.Schema, Entity>.InsertionResult,
    dropsOutput: @escaping (Entity?, Entity?) -> Bool = { _, _ in false },
    queue: TargetQueue = .passthrough
  ) -> Entity.NonNullDerived {
    _primary_derivedNonNull(from: insertionResult.entity, dropsOutput: dropsOutput, queue: queue)
  }

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable>(
    from insertionResult: EntityTable<State.Database.Schema, Entity>.InsertionResult,
    queue: TargetQueue = .passthrough
  ) -> Entity.NonNullDerived {
    derivedNonNull(from: insertionResult, dropsOutput: ==, queue: queue)
  }

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  @inline(__always)
  public func derivedNonNull<Entity: EntityType, S: Sequence>(
    from insertionResults: S,
    dropsOutput: @escaping (Entity?, Entity?) -> Bool = { _, _ in false },
    queue: TargetQueue = .passthrough
  ) -> NonNullDerivedResult<Entity> where S.Element == EntityTable<State.Database.Schema, Entity>.InsertionResult {
    derivedNonNull(from: insertionResults.map { $0.entity }, queue: queue)
  }

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  @inline(__always)
  public func derivedNonNull<Entity: EntityType & Equatable, S: Sequence>(
    from insertionResults: S,
    queue: TargetQueue = .passthrough
  ) -> NonNullDerivedResult<Entity> where S.Element == EntityTable<State.Database.Schema, Entity>.InsertionResult {
    
    derivedNonNull(from: insertionResults, dropsOutput: ==, queue: queue)
  }
     
}

// MARK: - Collection

extension StoreType where State : DatabaseEmbedding {

  /// Experimental
  /// TODO: More performant
  public func _derivedQueriedEntities<Entity: EntityType>(
    update: @escaping (IndexesPropertyAdapter<State.Database>) -> AnyCollection<Entity.EntityID>,
    queue: TargetQueue = .passthrough
  ) -> Derived<[Entity.Derived]> {
    
    let path = State.getterToDatabase
    let storage: CachedMapStorage<Entity.EntityID, Derived<EntityWrapper<Entity>>> = .init(keySelector: \.raw)
    
    let noChangesComparer = Comparer<State.Database>(or: [

      /** Step 1 */
      Comparer<State.Database>.indexNoUpdates(),

      /** Step 2 */
      Comparer<State.Database>.tableNoUpdates(Entity.self),

      /** And more we need */
    ])

    let pipeline = Pipeline<Changes<State>, [Entity.Derived]>(
      makeInitial: { (state: Changes<State>) in
        
        let db = path(state.primitive)
        let ids = update(db.indexes)

        // TODO: O(n)
        let result = ids.cachedMap(using: storage) {
          self.derived(from: $0)
        }
        
        return result
      },
      update: { state in

        let changes = state.asChanges()

        guard changes.hasChanges({ path($0.primitive) }, noChangesComparer) else {
          return .noUpdates
        }

        let _derivedArray = changes.takeIfChanged({ state -> [Entity.Derived] in

          let ids = update(path(state.primitive).indexes)

          // TODO: O(n)
          let result = ids.cachedMap(using: storage) {
            self.derived(from: $0)
          }

          return result

        }, .init(==))

        guard let derivedArray = _derivedArray else {
          return .noUpdates
        }

        return .new(derivedArray)

      }
    )
    
    let d = derived(pipeline)
    d.associate(storage)
    return d
  }

}
