
extension NormalizedStoragePath {

  /**
   Make a new Derived of a composed object from the storage.
   This is an effective way to resolving relationship entities into a single object. it's like SQLite's view.

   ```
   store.normalizedStorage(.keyPath(\.db)).derived {
     MyComposed(
       book: $0.book.find(...)
       author: $0.author.find(...)
     )
   }
   ```

   This Derived makes a new composed object if the storage has updated.
   There is not filters for entity tables so that Derived possibly makes a new object if not related entity has updated.
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
