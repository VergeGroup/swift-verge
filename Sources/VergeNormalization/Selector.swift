public protocol TableSelector<Entity> {
  associatedtype Entity: EntityType
  associatedtype Storage: NormalizedStorageType
  func select(storage: Storage) -> Table<Entity>
}

public protocol StorageSelector {
  associatedtype Source
  associatedtype Storage: NormalizedStorageType

  func select(source: Source) -> Storage
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

  public let storage: _StorageSelector
  public let table: _TableSelector

  public init(
    storage: consuming _StorageSelector,
    table: consuming _TableSelector
  ) {
    self.storage = storage
    self.table = table
  }

  public func select(source: _StorageSelector.Source) -> Table<_TableSelector.Entity> {
    table.select(storage: storage.select(source: source))
  }

}
