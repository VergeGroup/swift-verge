
extension _BackingStorage {
  
  func map<U>(_ transform: (borrowing Value) throws -> U) rethrows -> _BackingStorage<U> {
    return .init(
      try transform(value)
    )
  }
  
}

