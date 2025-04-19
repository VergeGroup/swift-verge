import Normalization
import Verge

struct SingleEntityPipeline<
  _StorageSelector: StorageSelector,
  _TableSelector: TableSelector
>: PipelineType
where _StorageSelector.Storage == _TableSelector.Storage, _StorageSelector.Source : Sendable {
  
  struct Storage {
    var tableVersion: UInt64
    var entity: Entity?
  }
  
  typealias Entity = _TableSelector.Table.Entity
  typealias Input = StateWrapper<_StorageSelector.Source>
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
  
  func makeStorage() -> Storage {
    return .init(tableVersion: 0)
  }
  
  func yield(_ input: consuming Input, storage: inout Storage) -> Output {
    
    let table = selector.table(source: input.state)
    storage.tableVersion = table.updatedMarker.value
    
    let result = table.find(by: entityID)
    storage.entity = result
    
    return .init(id: entityID, entity: consume result)
    
  }
  
  func yieldContinuously(_ input: Input, storage: inout Storage) -> Verge.ContinuousResult<Output> {
    
    let table = selector.table(source: input.state)
    
    guard storage.tableVersion != table.updatedMarker.value else {
      return .noUpdates
    }
    
    storage.tableVersion = table.updatedMarker.value
    
    let result = table.find(by: entityID)
    
    guard storage.entity != result else {
      return .noUpdates
    }
    
    storage.entity = result
    
    return .new(.init(id: entityID, entity: consume result))
    
  }
  
}

struct NonNullSingleEntityPipeline<
  _StorageSelector: StorageSelector,
  _TableSelector: TableSelector
>: PipelineType
where _StorageSelector.Storage == _TableSelector.Storage, _StorageSelector.Source : Sendable {
  
  struct Storage {
    var tableVersion: UInt64
    var entity: Entity?
  }
  
  typealias Entity = _TableSelector.Table.Entity
  typealias Input = StateWrapper<_StorageSelector.Source>
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
  
  func makeStorage() -> Storage {
    return .init(tableVersion: 0)
  }
  
  func yield(_ input: consuming Input, storage: inout Storage) -> Output {
    
    let table = selector.table(source: input.state)
    storage.tableVersion = table.updatedMarker.value
    
    let result = table
      .find(by: entityID)
    
    storage.entity = result
    
    if let result {
      return .init(entity: result, isFallBack: false)
    } else {
      return .init(entity: latestValue, isFallBack: true)
    }
    
  }
  
  func yieldContinuously(_ input: Input, storage: inout Storage) -> Verge.ContinuousResult<Output> {
    
    let table = selector.table(source: input.state)
    
    guard storage.tableVersion != table.updatedMarker.value else {
      return .noUpdates
    }
    
    storage.tableVersion = table.updatedMarker.value
    
    let result = table
      .find(by: entityID)
    
    guard storage.entity != result else {
      return .noUpdates
    }
    
    storage.entity = result

    if let result {
      return .new(.init(entity: result, isFallBack: false))
    } else {
      return .new(.init(entity: latestValue, isFallBack: true))
    }
    
  }
  
}

struct QueryPipeline<
  _StorageSelector: StorageSelector,
  Output
>: PipelineType, Sendable where _StorageSelector.Source : Sendable {
  
  struct Storage {
    var storageVersion: UInt64
  }
  
  typealias Input = StateWrapper<_StorageSelector.Source>
  typealias EntityStorage = _StorageSelector.Storage
    
  private let storageSelector: _StorageSelector
  private let query: @Sendable (EntityStorage) -> Output
  
  init(
    storageSelector: consuming _StorageSelector,
    query: @escaping @Sendable (EntityStorage) -> Output
  ) {
    self.storageSelector = storageSelector
    self.query = query
  }
  
  func makeStorage() -> Storage {
    .init(storageVersion: 0)
  }
  
  func yield(_ input: consuming Input, storage: inout Storage) -> Output {
    
    let entityStorage = storageSelector.select(source: input.state)
    
    storage.storageVersion = entityStorage.version
      
    let output = query(entityStorage)
    
    return output
    
  }
  
  func yieldContinuously(_ input: Input, storage: inout Storage) -> Verge.ContinuousResult<Output> {
    
    let entityStorage = storageSelector.select(source: input.state)
    
    guard entityStorage.version != storage.storageVersion else {
      return .noUpdates
    }
    
    storage.storageVersion = entityStorage.version
    
    let output = query(entityStorage)
    
    return .new(output)
    
  }
  
}
