/// A container that manages raw value to describe mark as updated.
public struct NonAtomicCounter: Hashable, Sendable {

  private(set) public var value: UInt64 = 0

  public init() {}

  public consuming func increment() {
    value &+= 1
  }

}
