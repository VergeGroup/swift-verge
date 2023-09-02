public protocol TableSelector<Entity> {
  associatedtype Entity: EntityType
  associatedtype Storage: NormalizedStorageType
  func select(storage: consuming Storage) -> Tables.Hash<Entity>
}

public protocol StorageSelector {
  associatedtype Source: Equatable
  associatedtype Storage: NormalizedStorageType

  func select(source: consuming Source) -> Storage
}

extension StorageSelector {

  public func append<_TableSelector: TableSelector>(
    _ tableSelector: consuming _TableSelector
  )
    -> AbsoluteTableSelector<Self, _TableSelector>
  {
    AbsoluteTableSelector(storage: self, table: tableSelector)
  }

}

public struct AbsoluteTableSelector<
  _StorageSelector: StorageSelector,
  _TableSelector: TableSelector
> where _StorageSelector.Storage == _TableSelector.Storage {

  public let storageSelector: _StorageSelector
  public let tableSelector: _TableSelector

  public init(
    storage: consuming _StorageSelector,
    table: consuming _TableSelector
  ) {
    self.storageSelector = storage
    self.tableSelector = table
  }

  public func storage(source: consuming _StorageSelector.Source) -> _StorageSelector.Storage {
    storageSelector.select(source: source)
  }

  public func table(source: consuming _StorageSelector.Source) -> Tables.Hash<_TableSelector.Entity> {
    tableSelector.select(storage: storageSelector.select(source: source))
  }

}
