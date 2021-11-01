
import Dispatch

private final class UnsafeStorage<Value> {

  let queue = DispatchQueue(label: "UnsafeStorage")

  var value: Value {
    queue.sync {
      _value
    }
  }

  private var _value: Value

  init(
    _ value: Value
  ) {
    self._value = value
  }

  func setValue(_ value: Value) {
    queue.async { [self] in
      _value = value
    }
  }

}

public actor AsyncStorage<Value> {

  private let st: UnsafeStorage<Value>
  public var value: Value

  public nonisolated var snapshot: Value {
    st.value
  }

  public init(
    _ value: Value
  ) {
    self.value = value
    st = .init(value)
  }

  public func read() async -> Value {
    print("Read", Thread.current)
    return value
  }

  public func update(_ mutate: @Sendable (inout Value) -> Void) async {
    print("Update", Thread.current)
    mutate(&value)
    st.setValue(value)
  }
}
