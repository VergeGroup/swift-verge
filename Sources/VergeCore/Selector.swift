//
// Copyright (c) 2019 muukii
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

open class SelectorBase<Destination> {
  
  let willUpdateEmitter: EventEmitter<Void>
  let didUpdateEmitter: EventEmitter<Destination>
  
  init(willUpdateEmitter: EventEmitter<Void>, didUpdateEmitter: EventEmitter<Destination>) {
    self.willUpdateEmitter = willUpdateEmitter
    self.didUpdateEmitter = didUpdateEmitter
  }
  
  /// Register observer with closure.
  /// Storage tells got a newValue.
  /// - Returns: Token to stop subscribing. (Optional) You may need to retain somewhere. But subscription will be disposed when Storage was destructed.
  @discardableResult
  public func addWillUpdate(subscriber: @escaping () -> Void) -> EventEmitterSubscribeToken {
    willUpdateEmitter.add(subscriber)
  }
  
  /// Register observer with closure.
  /// Storage tells got a newValue.
  /// - Returns: Token to stop subscribing. (Optional) You may need to retain somewhere. But subscription will be disposed when Storage was destructed.
  @discardableResult
  public func addDidUpdate(subscriber: @escaping (Destination) -> Void) -> EventEmitterSubscribeToken {
    didUpdateEmitter.add(subscriber)
  }
}

public final class AnySelector<Destination>: SelectorBase<Destination> {
  
  private let valueGetter: () -> Destination
  
  public init<Source>(_ source: MemoizeSelector<Source, Destination>) {
    
    self.valueGetter = {
      source.value
    }
    
    super.init(
      willUpdateEmitter: source.willUpdateEmitter,
      didUpdateEmitter: source.didUpdateEmitter
    )
  }
  
  public var value: Destination {
    valueGetter()
  }
  
}

open class MemoizeSelector<Source, Destination>: SelectorBase<Destination> {
  
  let source: Source
  let selector: (Source) -> Destination
  private var computedValue: Destination
  private let checker: (Source) -> Bool
    
  public init<Key>(
    initialSource: Source,
    selector: @escaping (Source) -> Destination,
    equality: EqualityComputer<Source, Key>
  ) {
    self.source = initialSource
    self.selector = selector
    self.checker = equality.input
    
    self.computedValue = selector(initialSource)
    
    super.init(willUpdateEmitter: .init(), didUpdateEmitter: .init())
  }
  
  public var value: Destination {
    computedValue
  }
  
  public func _accept(sourceValue: Source) {
    guard !checker(sourceValue) else { return }
    willUpdateEmitter.accept(())
    let newValue = selector(sourceValue)
    computedValue = newValue
    didUpdateEmitter.accept(newValue)
  }
    
  public func asAny() -> AnySelector<Destination> {
    .init(self)
  }
  
}

#if canImport(Combine)

import Combine

fileprivate var _willChangeAssociated: Void?
fileprivate var _didChangeAssociated: Void?

@available(iOS 13.0, macOS 10.15, *)
extension SelectorBase: ObservableObject {
  
  public var objectWillChange: ObservableObjectPublisher {
    if let associated = objc_getAssociatedObject(self, &_willChangeAssociated) as? ObservableObjectPublisher {
      return associated
    } else {
      let associated = ObservableObjectPublisher()
      objc_setAssociatedObject(self, &_willChangeAssociated, associated, .OBJC_ASSOCIATION_RETAIN)
      
      addWillUpdate {
        if Thread.isMainThread {
          associated.send()
        } else {
          DispatchQueue.main.async {
            associated.send()
          }
        }
      }
      
      return associated
    }
  }
  
  public var didChangePublisher: AnyPublisher<Destination, Never> {
    
    if let associated = objc_getAssociatedObject(self, &_didChangeAssociated) as? PassthroughSubject<Destination, Never> {
      return associated.eraseToAnyPublisher()
    } else {
      let associated = PassthroughSubject<Destination, Never>()
      objc_setAssociatedObject(self, &_didChangeAssociated, associated, .OBJC_ASSOCIATION_RETAIN)
      
      addDidUpdate { s in
        if Thread.isMainThread {
          associated.send(s)
        } else {
          DispatchQueue.main.async {
            associated.send(s)
          }
        }
      }
      
      return associated.eraseToAnyPublisher()
    }
  }
  
}

#endif

public final class EqualityComputer<Value, Key> {
  
  public static func alwaysDifferent() -> EqualityComputer<Value, Value> {
    EqualityComputer<Value, Value>.init(selector: { $0 }) { (v, b) -> Bool in
      return false
    }
  }
  
  private let selector: (Value) -> Key
  private let equals: (Key, Key) -> Bool
  
  private var previousValue: Key?
  
  public init(
    selector: @escaping (Value) -> Key,
    equals: @escaping (Key, Key) -> Bool
  ) {
    
    self.selector = selector
    self.equals = equals
    
  }
     
  func input(value: Value) -> Bool {
    
    let key = selector(value)
    
    if let previousValue = previousValue {
      return equals(previousValue, key)
    } else {
      previousValue = key
      return false
    }
    
  }
}

extension EqualityComputer where Key : Equatable {
  public convenience init(selector: @escaping (Value) -> Key) {
    self.init(selector: selector, equals: ==)
  }
}

extension EqualityComputer where Value == Key {
  
  public convenience init(equals: @escaping (Key, Key) -> Bool) {
    self.init(selector: { $0 }, equals: equals)
  }
}

extension EqualityComputer where Key : Equatable, Value == Key {
    
  public convenience init() {
    self.init(equals: ==)
  }
}

extension Storage {
  
  public func selector<Key, Destination>(
    selector: @escaping (Value) -> Destination,
    equality: EqualityComputer<Value, Key>
  ) -> MemoizeSelector<Value, Destination> {
    
    let getter = MemoizeSelector(
      initialSource: value,
      selector: selector,
      equality: equality
    )
    
    addDidUpdate { (newValue) in
      getter._accept(sourceValue: newValue)
    }
    
    return getter
    
  }
}
