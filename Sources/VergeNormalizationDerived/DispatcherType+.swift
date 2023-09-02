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

  public func derivedEntity2<
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

  func yield(_ input: consuming Input) -> EntityWrapper<Entity> {

    let result = selector.table(source: input.primitive)
      .find(by: entityID)

    return .init(id: entityID, entity: consume result)

  }

  func yieldContinuously(_ input: Input) -> Verge.ContinuousResult<EntityWrapper<Entity>> {

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
