import Foundation

extension DispatcherType {

  public func derivedEntity<
    _StorageSelector: StorageSelector,
    _TableSelector: TableSelector
  >(
    selector: consuming AbsoluteTableSelector<_StorageSelector, _TableSelector>,
    entityID: consuming _TableSelector.Entity.EntityID
  ) -> Derived<EntityWrapper<_TableSelector.Entity>>
  where
    _StorageSelector.Storage == _TableSelector.Storage,
    _StorageSelector.Source == Self.State
  {

    // TODO: caching

    return derived(
      SingleEntityPipeline(
        targetIdentifier: entityID,
        selector: selector
      ),
      queue: .passthrough
    )

  }

  public func derivedEntityNonNull<
    _StorageSelector: StorageSelector,
    _TableSelector: TableSelector
  >(
    selector: consuming AbsoluteTableSelector<_StorageSelector, _TableSelector>,
    entity: consuming _TableSelector.Entity
  ) -> Derived<NonNullEntityWrapper<_TableSelector.Entity>>
  where
  _StorageSelector.Storage == _TableSelector.Storage,
  _StorageSelector.Source == Self.State
  {

    // TODO: caching

    return derived(
      NonNullSingleEntityPipeline(
        initialEntity: entity,
        selector: selector
      ),
      queue: .passthrough
    )

  }
}

private struct SingleEntityPipeline<
  _StorageSelector: StorageSelector,
  _TableSelector: TableSelector
>: PipelineType
where _StorageSelector.Storage == _TableSelector.Storage {

  typealias Entity = _TableSelector.Entity
  typealias Input = Changes<_StorageSelector.Source>
  typealias Storage = _StorageSelector.Storage
  typealias Output = EntityWrapper<Entity>

  private let selector: AbsoluteTableSelector<_StorageSelector, _TableSelector>
  private let entityID: _TableSelector.Entity.EntityID

  init(
    targetIdentifier: _TableSelector.Entity.EntityID,
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

    if NormalizedStorageComparisons<Storage>.TableComparison<Entity>()(selector.table(source: input.primitive), selector.table(source: previous.primitive)) {
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

  typealias Entity = _TableSelector.Entity
  typealias Input = Changes<_StorageSelector.Source>
  typealias Storage = _StorageSelector.Storage
  typealias Output = NonNullEntityWrapper<Entity>

  private let selector: AbsoluteTableSelector<_StorageSelector, _TableSelector>
  private let entityID: _TableSelector.Entity.EntityID

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

    if NormalizedStorageComparisons<Storage>.TableComparison<Entity>()(selector.table(source: input.primitive), selector.table(source: previous.primitive)) {
      return .noUpdates
    }

    return .new(yield(input))

  }

}
