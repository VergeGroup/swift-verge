
struct QueryPipeline<
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

  func yieldContinuously(_ input: Input, transaction: Transaction) -> Verge.ContinuousResult<Output> {

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
