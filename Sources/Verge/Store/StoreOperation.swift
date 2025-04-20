import class Foundation.NSRecursiveLock

public enum StoreOperation: Sendable {
  case nonAtomic
  case atomic(NSRecursiveLock)

  func lock() {
    switch self {
    case .nonAtomic:
      break
    case .atomic(let lock):
      lock.lock()
    }
  }

  func unlock() {
    switch self {
    case .nonAtomic:
      break
    case .atomic(let lock):
      lock.unlock()
    }
  }

  public static var atomic: Self {
    return .atomic(.init())
  }
}

