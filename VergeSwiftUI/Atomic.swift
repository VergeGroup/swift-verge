import Foundation

@propertyWrapper
public final class VergeSwiftUIAtomic<T> {
  
  private let lock: NSLock = .init()
  
  public var wrappedValue: T {
    get {
      lock.lock(); defer { lock.unlock() }
      return _value
    }
    set {
      lock.lock(); defer { lock.unlock() }
      _value = newValue
    }
  }
  
  private var _value: T
  
  public init(initialValue value: T) {
    self._value = value
  }
}
