
final class UnsafeSendableClass<T>: @unchecked Sendable {
  var value: T
  
  init(value: T) {
    self.value = value
  }
}

struct UnsafeSendableStruct<T: ~Copyable>: ~Copyable, @unchecked Sendable {
  var value: T
  
  init(_ value: consuming T) {
    self.value = value
  }
  
  consuming func send() -> sending T {
    return value
  }
}

func withUnsafeSending<T: ~Copyable>(_ value: consuming T) -> sending T {
  UnsafeSendableStruct(value).send()
}
