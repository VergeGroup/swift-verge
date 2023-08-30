extension DispatcherType {

  public func derivedEntity<
    _StorageSelector: StorageSelector,
    _TableSelector: TableSelector
  >(
    selector: consuming AbsoluteTableSelector<_StorageSelector, _TableSelector>
  ) -> Derived<EntityWrapper<_TableSelector.Entity>>
  where
    _StorageSelector.Storage == _TableSelector.Storage,
    _StorageSelector.Source == Changes<Self.State>
  {

    derived(SingleEntityPipeline(selector: selector), queue: .passthrough)

  }

}

private struct SingleEntityPipeline<
  _StorageSelector: StorageSelector,
  _TableSelector: TableSelector
>: PipelineType
where _StorageSelector.Storage == _TableSelector.Storage, _StorageSelector.Source: ChangesType {

  typealias Entity = _TableSelector.Entity
  typealias Input = _StorageSelector.Source
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

    let result = selector.select(source: input)
      .find(by: entityID)

    return .init(id: entityID, entity: consume result)

  }

  func yieldContinuously(_ input: Input) -> Verge.ContinuousResult<EntityWrapper<Entity>> {
    fatalError()
  }

}
