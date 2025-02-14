
public final class ReadonlyBox<Value> {

  public let value: Value

  public init(value: consuming Value) {
    self.value = value
  }

  func map<U>(_ transform: (borrowing Value) throws -> U) rethrows -> ReadonlyBox<U> {
    return .init(
      value: try transform(value)
    )
  }

  @discardableResult
  @inline(__always)
  func _read<Return>(perform: (borrowing Value) -> Return) -> Return {
    perform(value)
  }
}
