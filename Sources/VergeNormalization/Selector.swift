
public protocol TableSelector: Hashable {
  associatedtype Storage: NormalizedStorageType
  associatedtype Table: TableType
  func select(storage: consuming Storage) -> Table
}

public struct KeyPathTableSelector<
  Storage: NormalizedStorageType,
  Table: TableType
>: TableSelector, Equatable {

  public let keyPath: KeyPath<Storage, Table>

  public init(keyPath: KeyPath<Storage, Table>) {
    self.keyPath = keyPath
  }

  public func select(storage: consuming Storage) -> Table {
    storage[keyPath: keyPath]
  }

}

extension TableSelector {

  public static func keyPath<
    Storage: NormalizedStorageType,
    Table: TableType
  >(
    _ keyPath: KeyPath<Storage, Table>
  ) -> Self where Self == KeyPathTableSelector<Storage, Table> {
    return .init(keyPath: keyPath)
  }
}

public protocol StorageSelector: Hashable {
  associatedtype Source: Equatable
  associatedtype Storage: NormalizedStorageType

  func select(source: consuming Source) -> Storage
}

public struct KeyPathStorageSelector<
  Source: Equatable,
  Storage: NormalizedStorageType
>: StorageSelector, Equatable {

  public let keyPath: KeyPath<Source, Storage>

  public init(keyPath: KeyPath<Source, Storage>) {
    self.keyPath = keyPath
  }

  public func select(source: consuming Source) -> Storage {
    source[keyPath: keyPath]
  }

}

extension StorageSelector {

  public static func keyPath<
    Source: Equatable,
    Storage: NormalizedStorageType
  >
  (
    _ keyPath: KeyPath<Source, Storage>
  ) -> Self where Self == KeyPathStorageSelector<Source, Storage> {
    return .init(keyPath: keyPath)
  }

  public consuming func appending<_TableSelector: TableSelector>(
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
>: Hashable where _StorageSelector.Storage == _TableSelector.Storage {

  public typealias Storage = _StorageSelector.Storage
  public typealias Entity = _TableSelector.Table.Entity

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

  public func table(source: consuming _StorageSelector.Source) -> _TableSelector.Table {
    tableSelector.select(storage: storageSelector.select(source: source))
  }

}
