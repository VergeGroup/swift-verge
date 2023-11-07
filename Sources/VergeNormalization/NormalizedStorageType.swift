
public protocol NormalizedStorageType: Equatable, Sendable {

  /**
   Performs any additional operations for updating.
   */
  func finalizeTransaction(transaction: inout ModifyingTransaction<Self>)

  static func compare(lhs: Self, rhs: Self) -> Bool
}

extension NormalizedStorageType {
  public func finalizeTransaction(transaction: inout ModifyingTransaction<Self>) {

  }

  public func table<Selector: TableSelector>(
    _ selector: consuming Selector
  ) -> Selector.Table where Selector.Storage == Self {
    selector.select(storage: self)
  }
}

extension NormalizedStorageType {

  public func beginBatchUpdates() -> ModifyingTransaction<Self> {
    let context = ModifyingTransaction<Self>(target: self)
    return context
  }

  public mutating func commitBatchUpdates(transaction: consuming ModifyingTransaction<Self>) {

    // middlewareAfter
    do {
      finalizeTransaction(transaction: &transaction)
    }

    // apply
    do {
      self = transaction.modifying
    }

  }

  /// Performs operations to update entities and indexes
  /// If can be run on background thread with locking.
  ///
  /// - Parameter update:
  @discardableResult
  public mutating func performBatchUpdates<Result>(_ update: (inout ModifyingTransaction<Self>) throws -> Result) rethrows -> Result {
    do {
      var transaction = beginBatchUpdates()
      let result = try update(&transaction)
      commitBatchUpdates(transaction: transaction)
      return result
    } catch {
      throw error
    }
  }
}

public enum ModifyingTransactionError: Error {
  case aborted
  case storedEntityNotFound
}

/**
 The context of the current modifying storage update.
 */
public struct ModifyingTransaction<NormalizedStorage: NormalizedStorageType>: ~Copyable {

  /// a storage before updated
  public let current: NormalizedStorage

  /// a modifiable storage that will be applied.
  public var modifying: NormalizedStorage

  init(target: NormalizedStorage) {
    self.current = target
    self.modifying = target
  }

  /// raises an error
  public func abort() throws -> Never {
    throw ModifyingTransactionError.aborted
  }
}

