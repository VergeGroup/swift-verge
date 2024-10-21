
@_spi(Internal)
public func areEqual<each Element: Equatable>(_ lhs: (repeat each Element), _ rhs: (repeat each Element)) -> Bool {
  
  for (left, right) in repeat (each lhs, each rhs) {
    guard left == right else { return false }
  }
  return true
  
}

