
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
  
  consuming func with<Return: ~Copyable>(_ mutation: (inout sending T) throws -> sending Return) rethrows -> sending Return {
    try mutation(&value)
  }
}

func withUnsafeSending<T: ~Copyable>(_ value: consuming T) -> sending T {
  UnsafeSendableStruct(value).send()
}
