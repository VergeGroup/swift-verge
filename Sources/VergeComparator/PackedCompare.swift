
@_spi(Internal)
public func areEqual<each Element: Equatable>(_ lhs: (repeat each Element), _ rhs: (repeat each Element)) -> Bool {

  // https://github.com/apple/swift-evolution/blob/main/proposals/0408-pack-iteration.md

  func isEqual<T: Equatable>(_ left: T, _ right: T) throws {
    if left == right {
      return
    }

    throw NotEqual()
  }

  do {
    repeat try isEqual(each lhs, each rhs)
  } catch {
    return false
  }

  return true
}

