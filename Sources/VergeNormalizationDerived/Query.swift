
extension NormalizedStoragePath {

  /**
   ```
   store.normalizedStorage(.keyPath(\.db)).derived {
     MyComposed(
       book: $0.book.find(...)
       author: $0.author.find(...)
     )
   }
   ```
   */
  public func derived<Composed: Equatable>(query: @escaping @Sendable (Self.Storage) -> Composed) -> Derived<Composed> {
    return store.derived(Pipeline(storageSelector: storageSelector, query: query), queue: .passthrough)
  }
}

private struct Pipeline<
  _StorageSelector: StorageSelector,
  Output
>: PipelineType, Sendable {

  typealias Input = Changes<_StorageSelector.Source>
  typealias Storage = _StorageSelector.Storage

  private let storageSelector: _StorageSelector
  private let query: @Sendable (Storage) -> Output

  init(
    storageSelector: consuming _StorageSelector,
    query: @escaping @Sendable (Storage) -> Output
  ) {
    self.storageSelector = storageSelector
    self.query = query
  }

  func yield(_ input: consuming Input) -> Output {

    let storage = storageSelector.select(source: input.primitive)
    let output = query(storage)

    return output

  }

  func yieldContinuously(_ input: Input) -> Verge.ContinuousResult<Output> {

    guard let previous = input.previous else {
      return .new(yield(input))
    }

    // check if the storage has been updated
    if NormalizedStorageComparisons<Storage>.StorageComparison()(storageSelector.select(source: input.primitive), storageSelector.select(source: previous.primitive)) {
      return .noUpdates
    }

    return .new(yield(input))

  }

}
