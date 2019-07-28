import Foundation
import Combine

/// Use with @ObjectBinding in View
@propertyWrapper public final class VergeSwiftUIStorage<T> {
  
  public typealias WillChangePublisher = PassthroughSubject<T, Never>
  
  public let willChange: WillChangePublisher = .init()
  
  fileprivate let lock: NSRecursiveLock = .init()
  
  public var projectedValue: VergeSwiftUIStorage<T> {
    self
  }
    
  @VergeSwiftUIAtomic fileprivate(set) public var wrappedValue: T
  
  public init(initialValue value: T) {
    self.wrappedValue = value
  }
  
  func makeWritableContext() -> WritableContext<T> {
    .init(target: self)
  }
  
  @inline(__always)
  fileprivate func notifyUpdate() {
    willChange.send(wrappedValue)
  }
  
}

struct WritableContext<T> {
  
  private let target: VergeSwiftUIStorage<T>
  
  init(target: VergeSwiftUIStorage<T>) {
    self.target = target
  }
  
  public func commit(_ mutation: (inout T) throws -> Void) rethrows {
    target.lock.lock()
    var v = target.wrappedValue
    do {
      try mutation(&v)
    } catch {
      target.lock.unlock()
    }
    target.wrappedValue = v
    target.lock.unlock()
    target.notifyUpdate()
  }
}
