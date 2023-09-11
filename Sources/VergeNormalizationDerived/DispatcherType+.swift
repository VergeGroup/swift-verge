import Foundation

@_spi(NormalizedStorage) import Verge

extension StoreType {

  public func normalizedStorage<Selector: StorageSelector>(_ selector: Selector) -> NormalizedStoragePath<Self, Selector> {
    .init(store: self, storageSelector: selector)
  }

}

public struct NormalizedStoragePath<
  Store: DispatcherType,
  _StorageSelector: StorageSelector
>: ~Copyable where Store.State == _StorageSelector.Source {

  public typealias Storage = _StorageSelector.Storage
  unowned let store: Store
  let storageSelector: _StorageSelector

  public init(
    store: Store,
    storageSelector: _StorageSelector
  ) {
    self.store = store
    self.storageSelector = storageSelector
  }

  public func table<Selector: TableSelector>(
    _ selector: Selector
  ) -> NormalizedStorageTablePath<Store, _StorageSelector, Selector> where Selector.Storage == _StorageSelector.Storage {
    return .init(
      store: store,
      storageSelector: storageSelector,
      tableSelector: selector
    )
  }
}

public struct NormalizedStorageTablePath<
  Store: DispatcherType,
  _StorageSelector: StorageSelector,
  _TableSelector: TableSelector
>: ~Copyable where _StorageSelector.Storage == _TableSelector.Storage, Store.State == _StorageSelector.Source {

  unowned let store: Store
  let storageSelector: _StorageSelector
  let tableSelector: _TableSelector

  public func derivedEntity(
    entityID: consuming _TableSelector.Table.Entity.EntityID
  ) -> Derived<EntityWrapper<_TableSelector.Table.Entity>> {

    return store.derivedEntity(
      selector: .init(storage: storageSelector, table: tableSelector),
      entityID: entityID
    )

  }

  public func derivedEntityNonNull(
    tableSelector: consuming _TableSelector,
    entity: consuming _TableSelector.Table.Entity
  ) -> Derived<NonNullEntityWrapper<_TableSelector.Table.Entity>> {

    return store.derivedEntityNonNull(
      selector: .init(storage: storageSelector, table: tableSelector),
      entity: entity
    )

  }

}

extension DispatcherType {

  public func derivedEntity<
    _StorageSelector: StorageSelector,
    _TableSelector: TableSelector
  >(
    selector: AbsoluteTableSelector<_StorageSelector, _TableSelector>,
    entityID: consuming _TableSelector.Table.Entity.EntityID
  ) -> Derived<EntityWrapper<_TableSelector.Table.Entity>>
  where
    _StorageSelector.Storage == _TableSelector.Storage,
    _StorageSelector.Source == Self.State
  {

    return store.asStore().$_derivedCache.modify { cache in

      typealias _Derived = Derived<SingleEntityPipeline<_StorageSelector, _TableSelector>.Output>

      let key = KeyObject(content: AnyHashable(copy selector))

      if let cached = cache.object(forKey: key) {
        return cached as! _Derived
      } else {

        let new = derived(
          SingleEntityPipeline(
            targetIdentifier: entityID,
            selector: selector
          ),
          queue: .passthrough
        )

        cache.setObject(new, forKey: key)

        return new as _Derived
      }

    }

  }

  public func derivedEntityNonNull<
    _StorageSelector: StorageSelector,
    _TableSelector: TableSelector
  >(
    selector: AbsoluteTableSelector<_StorageSelector, _TableSelector>,
    entity: consuming _TableSelector.Table.Entity
  ) -> Derived<NonNullEntityWrapper<_TableSelector.Table.Entity>>
  where
  _StorageSelector.Storage == _TableSelector.Storage,
  _StorageSelector.Source == Self.State
  {

    return store.asStore().$_nonnull_derivedCache.modify { cache in

      typealias _Derived = Derived<NonNullSingleEntityPipeline<_StorageSelector, _TableSelector>.Output>

      let key = KeyObject(content: AnyHashable(copy selector))

      if let cached = cache.object(forKey: key) {
        return cached as! _Derived
      } else {

        let new = derived(
          NonNullSingleEntityPipeline(
            initialEntity: entity,
            selector: selector
          ),
          queue: .passthrough
        )

        cache.setObject(new, forKey: key)

        return new as _Derived
      }

    }

  }
}

private struct SingleEntityPipeline<
  _StorageSelector: StorageSelector,
  _TableSelector: TableSelector
>: PipelineType
where _StorageSelector.Storage == _TableSelector.Storage {

  typealias Entity = _TableSelector.Table.Entity
  typealias Input = Changes<_StorageSelector.Source>
  typealias Storage = _StorageSelector.Storage
  typealias Output = EntityWrapper<Entity>

  private let selector: AbsoluteTableSelector<_StorageSelector, _TableSelector>
  private let entityID: Entity.EntityID

  init(
    targetIdentifier: Entity.EntityID,
    selector: consuming AbsoluteTableSelector<_StorageSelector, _TableSelector>
  ) {
    self.entityID = targetIdentifier
    self.selector = selector
  }

  func yield(_ input: consuming Input) -> Output {

    let result = selector.table(source: input.primitive)
      .find(by: entityID)

    return .init(id: entityID, entity: consume result)

  }

  func yieldContinuously(_ input: Input) -> Verge.ContinuousResult<Output> {

    guard let previous = input.previous else {
      return .new(yield(input))
    }

    if NormalizedStorageComparisons<Storage>.StorageComparison()(selector.storage(source: input.primitive), selector.storage(source: previous.primitive)) {
      return .noUpdates
    }

    if NormalizedStorageComparisons<Storage>.TableComparison<_TableSelector.Table>()(selector.table(source: input.primitive), selector.table(source: previous.primitive)) {
      return .noUpdates
    }

    return .new(yield(input))

  }

}

private struct NonNullSingleEntityPipeline<
  _StorageSelector: StorageSelector,
  _TableSelector: TableSelector
>: PipelineType
where _StorageSelector.Storage == _TableSelector.Storage {

  typealias Entity = _TableSelector.Table.Entity
  typealias Input = Changes<_StorageSelector.Source>
  typealias Storage = _StorageSelector.Storage
  typealias Output = NonNullEntityWrapper<Entity>

  private let selector: AbsoluteTableSelector<_StorageSelector, _TableSelector>
  private let entityID: Entity.EntityID

  private let latestValue: Entity
  private let lock: NSLock = .init()

  init(
    initialEntity: Entity,
    selector: consuming AbsoluteTableSelector<_StorageSelector, _TableSelector>
  ) {

    self.entityID = initialEntity.entityID
    self.latestValue = initialEntity
    self.selector = selector

  }

  func yield(_ input: consuming Input) -> Output {

    let result = selector.table(source: input.primitive)
      .find(by: entityID)

    if let result {
      return .init(entity: result, isFallBack: false)
    } else {
      return .init(entity: latestValue, isFallBack: true)
    }

  }

  func yieldContinuously(_ input: Input) -> Verge.ContinuousResult<Output> {

    guard let previous = input.previous else {
      return .new(yield(input))
    }

    if NormalizedStorageComparisons<Storage>.StorageComparison()(selector.storage(source: input.primitive), selector.storage(source: previous.primitive)) {
      return .noUpdates
    }

    if NormalizedStorageComparisons<Storage>.TableComparison<_TableSelector.Table>()(selector.table(source: input.primitive), selector.table(source: previous.primitive)) {
      return .noUpdates
    }

    return .new(yield(input))

  }

}
