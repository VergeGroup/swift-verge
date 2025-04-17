import Normalization
import Verge

struct SingleEntityPipeline<
  _StorageSelector: StorageSelector,
  _TableSelector: TableSelector
>: PipelineType
where _StorageSelector.Storage == _TableSelector.Storage {
  
  typealias Entity = _TableSelector.Table.Entity
  typealias Input = Changes<_StorageSelector.Source>
  typealias EntityStorage = _StorageSelector.Storage
  typealias Output = EntityWrapper<Entity>
  
  private let selector: AbsoluteTableSelector<_StorageSelector, _TableSelector>
  private let entityID: Entity.TypedID
  
  init(
    targetIdentifier: Entity.TypedID,
    selector: consuming AbsoluteTableSelector<_StorageSelector, _TableSelector>
  ) {
    self.entityID = targetIdentifier
    self.selector = selector
  }
  
  func yield(_ input: consuming Input, storage: Void) -> Output {
    
    let result = selector.table(source: input.primitive)
      .find(by: entityID)
    
    return .init(id: entityID, entity: consume result)
    
  }
  
  func yieldContinuously(_ input: Input, storage: Void) -> Verge.ContinuousResult<Output> {
    
    guard let previous = input.previous else {
      return .new(yield(input, storage: storage))
    }
    
    if NormalizedStorageComparators<EntityStorage>.StorageComparator()(selector.storage(source: input.primitive), selector.storage(source: previous.primitive)) {
      return .noUpdates
    }
    
    if NormalizedStorageComparators<EntityStorage>.TableComparator<_TableSelector.Table>()(selector.table(source: input.primitive), selector.table(source: previous.primitive)) {
      return .noUpdates
    }
    
    return .new(yield(input, storage: storage))
    
  }
  
}

struct NonNullSingleEntityPipeline<
  _StorageSelector: StorageSelector,
  _TableSelector: TableSelector
>: PipelineType
where _StorageSelector.Storage == _TableSelector.Storage {
  
  typealias Entity = _TableSelector.Table.Entity
  typealias Input = Changes<_StorageSelector.Source>
  typealias EntityStorage = _StorageSelector.Storage
  typealias Output = NonNullEntityWrapper<Entity>
  
  private let selector: AbsoluteTableSelector<_StorageSelector, _TableSelector>
  private let entityID: Entity.TypedID
  
  private let latestValue: Entity
  
  init(
    initialEntity: Entity,
    selector: consuming AbsoluteTableSelector<_StorageSelector, _TableSelector>
  ) {
    
    self.entityID = initialEntity.typedID
    self.latestValue = initialEntity
    self.selector = selector
    
  }
  
  func yield(_ input: consuming Input, storage: Void) -> Output {
    
    let result = selector.table(source: input.primitive)
      .find(by: entityID)
    
    if let result {
      return .init(entity: result, isFallBack: false)
    } else {
      return .init(entity: latestValue, isFallBack: true)
    }
    
  }
  
  func yieldContinuously(_ input: Input, storage: Void) -> Verge.ContinuousResult<Output> {
    
    guard let previous = input.previous else {
      return .new(yield(input, storage: storage))
    }
    
    if NormalizedStorageComparators<EntityStorage>.StorageComparator()(selector.storage(source: input.primitive), selector.storage(source: previous.primitive)) {
      return .noUpdates
    }
    
    if NormalizedStorageComparators<EntityStorage>.TableComparator<_TableSelector.Table>()(selector.table(source: input.primitive), selector.table(source: previous.primitive)) {
      return .noUpdates
    }
    
    return .new(yield(input, storage: storage))
    
  }
  
}

struct QueryPipeline<
  _StorageSelector: StorageSelector,
  Output
>: PipelineType, Sendable {
  
  typealias Input = Changes<_StorageSelector.Source>
  typealias EntityStorage = _StorageSelector.Storage
  typealias Storage = Void
  
  private let storageSelector: _StorageSelector
  private let query: @Sendable (EntityStorage) -> Output
  
  init(
    storageSelector: consuming _StorageSelector,
    query: @escaping @Sendable (EntityStorage) -> Output
  ) {
    self.storageSelector = storageSelector
    self.query = query
  }
  
  func makeStorage() -> Void {
    ()
  }
  
  func yield(_ input: consuming Input, storage: Storage) -> Output {
    
    let storage = storageSelector.select(source: input.primitive)
    let output = query(storage)
    
    return output
    
  }
  
  func yieldContinuously(_ input: Input, storage: Storage) -> Verge.ContinuousResult<Output> {
    
    guard let previous = input.previous else {
      return .new(yield(input, storage: storage))
    }
    
    // check if the storage has been updated
    if NormalizedStorageComparators<EntityStorage>.StorageComparator()(storageSelector.select(source: input.primitive), storageSelector.select(source: previous.primitive)) {
      return .noUpdates
    }
    
    return .new(yield(input, storage: storage))
    
  }
  
}
