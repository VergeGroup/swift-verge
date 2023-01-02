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

extension NonNullEntityWrapper: Equatable where Entity: Equatable {}

extension NonNullEntityWrapper: Hashable where Entity: Hashable {}


private final class DerivedCacheKey: NSObject {
  
  let entityType: ObjectIdentifier
  let entityID: AnyEntityIdentifier
  let keyPathToDatabase: AnyKeyPath
  
  init(entityType: ObjectIdentifier, entityID: AnyEntityIdentifier, keyPathToDatabase: AnyKeyPath) {
    self.entityType = entityType
    self.entityID = entityID
    self.keyPathToDatabase = keyPathToDatabase
  }
  
  override func isEqual(_ object: Any?) -> Bool {
    
    guard let other = object as? DerivedCacheKey else {
      return false
    }
    
    guard entityType == other.entityType else { return false }
    guard entityID == other.entityID else { return false }
    guard keyPathToDatabase == other.keyPathToDatabase else { return false }
    
    return true
  }
  
}

fileprivate final class _DerivedObjectCache {
    
  private let _cache = NSCache<DerivedCacheKey, AnyObject>()
  
  @inline(__always)
  private func key<E: EntityType>(entityID: E.EntityID, keyPathToDatabase: AnyKeyPath) -> DerivedCacheKey {
    return .init(entityType: ObjectIdentifier(E.self), entityID: entityID.any, keyPathToDatabase: keyPathToDatabase)
  }
  
  func get<E: EntityType>(entityID: E.EntityID, keyPathToDatabase: AnyKeyPath) -> E.Derived? {
    _cache.object(forKey: key(entityID: entityID, keyPathToDatabase: keyPathToDatabase)) as? E.Derived
  }
  
  func set<E: EntityType>(_ getter: E.Derived, entityID: E.EntityID, keyPathToDatabase: AnyKeyPath) {
    _cache.setObject(getter, forKey: key(entityID: entityID, keyPathToDatabase: keyPathToDatabase))
  }
  
}

fileprivate final class _NonNullDerivedObjectCache {
  
  private let _cache = NSCache<DerivedCacheKey, AnyObject>()
  
  @inline(__always)
  private func key<E: EntityType>(entityID: E.EntityID, keyPathToDatabase: AnyKeyPath) -> DerivedCacheKey {
    return .init(entityType: ObjectIdentifier(E.self), entityID: entityID.any, keyPathToDatabase: keyPathToDatabase)
  }
  
  func get<E: EntityType>(entityID: E.EntityID, keyPathToDatabase: AnyKeyPath) -> E.NonNullDerived? {
    _cache.object(forKey: key(entityID: entityID, keyPathToDatabase: keyPathToDatabase)) as? E.NonNullDerived
  }
  
  func set<E: EntityType>(_ getter: E.NonNullDerived, entityID: E.EntityID, keyPathToDatabase: AnyKeyPath) {
    _cache.setObject(getter, forKey: key(entityID: entityID, keyPathToDatabase: keyPathToDatabase))
  }
  
}

public typealias NonNullDerivedResult<Entity: EntityType> = DerivedResult<Entity, Entity.NonNullDerived>

// MARK: - Primitive operators

fileprivate var _derivedContainerAssociated: Void?
fileprivate var _nonnull_derivedContainerAssociated: Void?

extension StoreType {
        
  private var _nonatomic_derivedObjectCache: _DerivedObjectCache {
    
    if let associated = objc_getAssociatedObject(self, &_derivedContainerAssociated) as? _DerivedObjectCache {
      
      return associated
      
    } else {
      
      let associated = _DerivedObjectCache()
      objc_setAssociatedObject(self, &_derivedContainerAssociated, associated, .OBJC_ASSOCIATION_RETAIN)
      return associated
    }
  }
  
  private var _nonatomic_nonnull_derivedObjectCache: _NonNullDerivedObjectCache {
    
    if let associated = objc_getAssociatedObject(self, &_nonnull_derivedContainerAssociated) as? _NonNullDerivedObjectCache {
      
      return associated
      
    } else {
      
      let associated = _NonNullDerivedObjectCache()
      objc_setAssociatedObject(self, &_nonnull_derivedContainerAssociated, associated, .OBJC_ASSOCIATION_RETAIN)
      return associated
    }
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

/**
 Do not retain, use as just method-chain
 */
@MainActor
public struct DatabaseContext<Store: StoreType, Database: DatabaseType> {
  
  let keyPath: KeyPath<Store.State, Database>
  unowned let store: Store
  
  init(keyPath: KeyPath<Store.State, Database>, store: Store) {
    self.keyPath = keyPath
    self.store = store
  }
    
}

@MainActor
@dynamicMemberLookup
public struct DatabaseDynamicMembers<Store: StoreType> {
  
  unowned let store: Store
  
  init(store: Store) {
    self.store = store
  }

  public subscript<Database: DatabaseType>(dynamicMember keyPath: KeyPath<Store.State, Database>) -> DatabaseContext<Store, Database> {
    .init(keyPath: keyPath, store: store)
  }
  
}

extension StoreType {
  
  /**
   A cushion for databases. the return object has properties to databases.
   
   ```
   yourStore.databases.yourDatabase.derived(...)
   ```
   */
  public var databases: DatabaseDynamicMembers<Self> {
    .init(store: self)
  }
  
  /**
   Returns a ``Verge/Derived`` object that projects fetched Entity object by the entity identifier.
   
   The Derived object is constructed from multiple Derived.
   Underlying-Derived: Fetch the entity from id
   DropsOutput-Derived: Drops the duplicated object
   
   Underlying-Derived would be cached by the id.
   */
  @inline(__always)
  public func derivedEntity<Entity: EntityType, Database: DatabaseType>(
    entityID: Entity.EntityID,
    from keyPathToDatabase: KeyPath<State, Database>,
    queue: TargetQueueType = .passthrough
  ) -> Entity.Derived {
    
    objc_sync_enter(self); defer { objc_sync_exit(self) }
    
    let underlyingDerived: Derived<EntityWrapper<Entity>>
    
    if let cached = _nonatomic_derivedObjectCache.get(entityID: entityID, keyPathToDatabase: keyPathToDatabase) {
      underlyingDerived = cached
    } else {
      /// creates a new underlying derived object
      underlyingDerived = derived(
        _DatabaseSingleEntityPipeline(
          keyPathToDatabase: keyPathToDatabase,
          entityID: entityID
        ),
        queue: queue
      )
      .chain(.map(\.root))
      
      _nonatomic_derivedObjectCache.set(underlyingDerived, entityID: entityID, keyPathToDatabase: keyPathToDatabase)
    }
    
    return underlyingDerived
  }
  
  /**
   Returns a ``Verge/Derived`` object that projects fetched Entity object by the entity identifier.
   
   The Derived object is constructed from multiple Derived.
   Underlying-Derived: Fetch the entity from id
   DropsOutput-Derived: Drops the duplicated object
   
   Underlying-Derived would be cached by the id.
   */
  @inline(__always)
  public func derivedEntityPersistent<Entity: EntityType, Database: DatabaseType>(
    entity: Entity,
    from keyPathToDatabase: KeyPath<State, Database>,
    queue: TargetQueueType = .passthrough
  ) -> Entity.NonNullDerived {
    
    objc_sync_enter(self); defer { objc_sync_exit(self) }
    
    let underlyingDerived: Derived<NonNullEntityWrapper<Entity>>
    
    if let cached = _nonatomic_nonnull_derivedObjectCache.get(entityID: entity.entityID, keyPathToDatabase: keyPathToDatabase) {
      underlyingDerived = cached
    } else {
      /// creates a new underlying derived object
      underlyingDerived = derived(
        _DatabaseCachedSingleEntityPipeline(
          keyPathToDatabase: keyPathToDatabase,
          entity: entity
        ),
        queue: queue
      )
      .chain(.map(\.root))
      
      _nonatomic_nonnull_derivedObjectCache.set(underlyingDerived, entityID: entity.entityID, keyPathToDatabase: keyPathToDatabase)
    }
    
    return underlyingDerived
  }
}

extension DatabaseContext {
     
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
    queue: TargetQueueType = .passthrough
  ) -> Entity.Derived {
    store.derivedEntity(entityID: entityID, from: keyPath)
  }
  
  // MARK: - Convenience operators
  
  @inline(__always)
  fileprivate func _primary_derivedNonNull<Entity: EntityType>(
    from entity: Entity,
    queue: TargetQueueType = .passthrough
  ) -> Entity.NonNullDerived {
    store.derivedEntityPersistent(entity: entity, from: keyPath)
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
    queue: TargetQueueType = .passthrough
  ) -> Entity.NonNullDerived {

    _primary_derivedNonNull(from: entity, queue: queue)
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
    queue: TargetQueueType = .passthrough
  ) throws -> Entity.NonNullDerived {
          
    guard let initalValue = store.primitiveState[keyPath: keyPath].entities.table(Entity.self).find(by: entityID) else {
      throw VergeORMError.notFoundEntityFromDatabase
    }
   
    return _primary_derivedNonNull(from: initalValue, queue: queue)
  }

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  public func derivedNonNull<Entity: EntityType>(
    from entity: Entity,
    queue: TargetQueueType = .passthrough
  ) -> Entity.NonNullDerived {
    _primary_derivedNonNull(from: entity, queue: queue)
  }
  

  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  public func derivedNonNull<Entity: EntityType, S: Sequence>(
    from entityIDs: S,
    queue: TargetQueueType = .passthrough
  ) -> NonNullDerivedResult<Entity> where S.Element == Entity.EntityID {
    entityIDs.reduce(into: NonNullDerivedResult<Entity>()) { (r, e) in
      do {
        r.append(derived: try derivedNonNull(from: e, queue: queue), id: e)
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
  public func derivedNonNull<Entity: EntityType>(
    from entityIDs: Set<Entity.EntityID>,
    queue: TargetQueueType = .passthrough
  ) -> NonNullDerivedResult<Entity> {
    // TODO: Stop using AnySequence
    derivedNonNull(from: AnySequence.init(entityIDs.makeIterator), queue: queue)
  }
 
  /// Returns a derived object that provides a concrete entity according to the updating source state
  /// It uses the last value if the entity has been removed source.
  /// You can get a flag that indicates whether the entity is live or removed which from `NonNullEntityWrapper<T>`
  ///
  /// If you call this method in many time, it's not so big issue.
  /// Because, the backing derived-object to construct itself would be cached.
  /// A pointer of the result derived object will be different from each other, but the backing source will be shared.
  ///
  public func derivedNonNull<Entity: EntityType, S: Sequence>(
    from entities: S,
    queue: TargetQueueType = .passthrough
  ) -> NonNullDerivedResult<Entity> where S.Element == Entity {
    entities.reduce(into: NonNullDerivedResult<Entity>()) { (r, e) in
      r.append(derived: _primary_derivedNonNull(from: e, queue: queue), id: e.entityID)
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
  public func derivedNonNull<Entity: EntityType>(
    from entities: Set<Entity>,
    queue: TargetQueueType = .passthrough
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
  public func derivedNonNull<Entity: EntityType>(
    from insertionResult: EntityTable<Database.Schema, Entity>.InsertionResult,
    queue: TargetQueueType = .passthrough
  ) -> Entity.NonNullDerived {
    _primary_derivedNonNull(from: insertionResult.entity, queue: queue)
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
    queue: TargetQueueType = .passthrough
  ) -> NonNullDerivedResult<Entity> where S.Element == EntityTable<Database.Schema, Entity>.InsertionResult {
    derivedNonNull(from: insertionResults.map { $0.entity }, queue: queue)
  }

  /// Experimental
  /// TODO: More performant
  public func _derivedQueriedEntities<Entity: EntityType>(
    ids: @escaping (IndexesPropertyAdapter<Database>) -> AnyCollection<Entity.EntityID>,
    queue: TargetQueueType = .passthrough
  ) -> Derived<[Entity.Derived]> {
    
    return store.derived(
      _DatabaseMultipleEntityPipeline(
        keyPathToDatabase: keyPath,
        index: ids,
        makeDerived: {
          self.derived(from: $0)
        }
      )
    )
       
  }

}

struct _DatabaseMultipleEntityPipeline<Source: Equatable, Database: DatabaseType, Entity: EntityType>: PipelineType {
  
  typealias Input = Changes<Source>
  
  typealias Output = [Entity.Derived]
  
  let keyPathToDatabase: KeyPath<Source, Database>
  
  // TODO: write inline
  private let noChangesComparer: Comparer<Database>
  private let index: (IndexesPropertyAdapter<Database>) -> AnyCollection<Entity.EntityID>
  private let storage: CachedMapStorage<Entity.EntityID, Entity.Derived> = .init(keySelector: \.raw)
  private let makeDerived: (Entity.EntityID) -> Entity.Derived
  
  init(
    keyPathToDatabase: KeyPath<Source, Database>,
    index: @escaping (IndexesPropertyAdapter<Database>) -> AnyCollection<Entity.EntityID>,
    makeDerived: @escaping (Entity.EntityID) -> Entity.Derived
  ) {
    
    self.keyPathToDatabase = keyPathToDatabase
    self.index = index
    self.makeDerived = makeDerived
    
    self.noChangesComparer = Comparer<Database>(or: [
      
      /** Step 1 */
      Comparer<Database>.indexNoUpdates(),
      
      /** Step 2 */
      Comparer<Database>.tableNoUpdates(Entity.self),
      
      /** And more we need */
    ])
  }
  
  func yield(_ input: Changes<Source>) -> [Entity.Derived] {
    
    let db = input.primitive[keyPath: keyPathToDatabase]
    let ids = index(db.indexes)
    
    // TODO: O(n)
    let result = ids.cachedMap(using: storage, makeNew: makeDerived)
    
    return result
    
  }
  
  func yieldContinuously(_ input: Changes<Source>) -> ContinuousResult<[Entity.Derived]> {
    
    let changes = input
    
    guard changes.hasChanges({ $0.primitive[keyPath: keyPathToDatabase] }, noChangesComparer) else {
      return .noUpdates
    }
    
    let _derivedArray = changes.takeIfChanged({ state -> [Entity.Derived] in
      
      let ids = index(state.primitive[keyPath: keyPathToDatabase].indexes)
      
      // TODO: O(n)
      let result = ids.cachedMap(using: storage, makeNew: makeDerived)
      
      return result
      
    }, .init(==))
    
    guard let derivedArray = _derivedArray else {
      return .noUpdates
    }
    
    return .new(derivedArray)

    
  }
}

struct _DatabaseSingleEntityPipeline<Source: Equatable, Database: DatabaseType, Entity: EntityType>: PipelineType {
  
  typealias Input = Changes<Source>
  
  typealias Output = EntityWrapper<Entity>
  
  let keyPathToDatabase: KeyPath<Source, Database>
  let entityID: Entity.EntityID
  
  // TODO: write inline
  private let noChangesComparer: Comparer<Database>
  
  init(
    keyPathToDatabase: KeyPath<Source, Database>,
    entityID: Entity.EntityID
  ) {
    
    self.keyPathToDatabase = keyPathToDatabase
    self.entityID = entityID
    self.noChangesComparer = Comparer<Database>(or: [
      
      /** Step 1 */
      Comparer<Database>.databaseNoUpdates(),
      
      /** Step 2 */
      Comparer<Database>.tableNoUpdates(Entity.self),
      
      /** Step 3 */
      Comparer<Database>.changesNoContains(entityID),
      
    ])
  }
  
  func yield(_ input: Input) -> Output {
    
    EntityWrapper<Entity>(
      id: entityID,
      entity: input.primitive[keyPath: keyPathToDatabase].entities.table(Entity.self).find(by: entityID) /** Queries an entity */
    )
    
  }
  
  func yieldContinuously(_ input: Input) -> ContinuousResult<Output> {
    
    func makeNew() -> ContinuousResult<Output> {
      let wrapper =  EntityWrapper<Entity>(
        id: entityID,
        entity: input.primitive[keyPath: keyPathToDatabase].entities.table(Entity.self).find(by: entityID) /** Queries an entity */
      )
      return .new(wrapper)
    }
    
    guard let previous = input.previous else {
      return makeNew()
    }
    
    let previousDB = previous.primitive[keyPath: keyPathToDatabase]
    let newDB = input.primitive[keyPath: keyPathToDatabase]
    
    guard noChangesComparer.equals(previousDB, newDB) else {
      return makeNew()
    }
        
    return .noUpdates
  }
  
}

struct _DatabaseCachedSingleEntityPipeline<Source: Equatable, Database: DatabaseType, Entity: EntityType>: PipelineType {
  
  typealias Input = Changes<Source>
  
  typealias Output = NonNullEntityWrapper<Entity>
  
  let keyPathToDatabase: KeyPath<Source, Database>
  let entityID: Entity.EntityID
  
  // TODO: write inline
  private let noChangesComparer: Comparer<Database>
  
  private let latestValue: VergeConcurrency.RecursiveLockAtomic<Entity>
  
  init(
    keyPathToDatabase: KeyPath<Source, Database>,
    entity: Entity
  ) {
    
    self.keyPathToDatabase = keyPathToDatabase
    self.entityID = entity.entityID
    self.latestValue = .init(entity)
    
    self.noChangesComparer = Comparer<Database>(or: [
      
      /** Step 1 */
      Comparer<Database>.databaseNoUpdates(),
      
      /** Step 2 */
      Comparer<Database>.tableNoUpdates(Entity.self),
      
      /** Step 3 */
      Comparer<Database>.changesNoContains(entityID),
      
    ])
  }
  
  func yield(_ input: Input) -> Output {
    
    let entity = input.primitive[keyPath: keyPathToDatabase].entities.table(Entity.self).find(by: entityID) /** Queries an entity */
    
    if let entity {
      latestValue.swap(entity)
      return NonNullEntityWrapper.init(
        entity: entity,
        isFallBack: false
      )
    } else {
      return NonNullEntityWrapper.init(
        entity: latestValue.value,
        isFallBack: true
      )
    }
    
  }
  
  func yieldContinuously(_ input: Input) -> ContinuousResult<Output> {
           
    guard let previous = input.previous else {
      return .new(yield(input))
    }
    
    let previousDB = previous.primitive[keyPath: keyPathToDatabase]
    let newDB = input.primitive[keyPath: keyPathToDatabase]
    
    guard noChangesComparer.equals(previousDB, newDB) else {
      return .new(yield(input))
    }
    
    return .noUpdates
  }
  
}
