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

open class GetterBase<Output>: Hashable {
  
  public static func == (lhs: GetterBase<Output>, rhs: GetterBase<Output>) -> Bool {
    lhs === rhs
  }
    
  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }
    
  public var value: Output {
    _read { yield storage.value }
  }
  
  let storage: Storage<Output>
  
  init(storage: Storage<Output>) {
    self.storage = storage
  }
  
  /// Register observer with closure.
  /// Storage tells got a newValue.
  /// - Returns: Token to stop subscribing. (Optional) You may need to retain somewhere. But subscription will be disposed when Storage was destructed.
  @discardableResult
  public final func addWillUpdate(subscriber: @escaping () -> Void) -> EventEmitterSubscribeToken {
    storage.addWillUpdate(subscriber: subscriber)
  }
  
  /// Register observer with closure.
  /// Storage tells got a newValue.
  /// - Returns: Token to stop subscribing. (Optional) You may need to retain somewhere. But subscription will be disposed when Storage was destructed.
  @discardableResult
  public final func addDidUpdate(subscriber: @escaping (Output) -> Void) -> EventEmitterSubscribeToken {
    storage.addDidUpdate(subscriber: subscriber)
  }
}

public protocol AnyGetterType: AnyObject {
  associatedtype Output
  var value: Output { get }
  
  @discardableResult
  func addWillUpdate(subscriber: @escaping () -> Void) -> EventEmitterSubscribeToken
  
  /// Register observer with closure.
  /// Storage tells got a newValue.
  /// - Returns: Token to stop subscribing. (Optional) You may need to retain somewhere. But subscription will be disposed when Storage was destructed.
  @discardableResult
  func addDidUpdate(subscriber: @escaping (Output) -> Void) -> EventEmitterSubscribeToken
}

public final class AnyGetter<Output>: GetterBase<Output>, AnyGetterType {
  
  private let valueGetter: () -> Output
  
  public init<Input>(_ source: Getter<Input, Output>) {
    
    self.valueGetter = {
      // retains source
      source.value
    }
    
    super.init(storage: source.storage)
  }
      
  public override var value: Output {
    valueGetter()
  }
  
}

public protocol GetterType: AnyGetterType {
  associatedtype Input
  associatedtype Output
  var value: Output { get }
}

open class Getter<Input, Output>: GetterBase<Output>, GetterType {
  
  private var didUpdates: [(Output) -> Void] = []
  
  var onDeinit: () -> Void = {}
      
  private let map: (Input) -> Output
  private let filter: (Input) -> Bool
  private let ratainUpstream: () -> Void
  
  public init(
    input: Input,
    filter: EqualityComputer<Input>,
    map: @escaping (Input) -> Output
  ) {
    
    _ = filter.isEqual(value: input)
    
    self.map = map
    self.filter = filter.isEqual
    self.ratainUpstream = {}
    
    super.init(storage: .init(map(input)))
  }
  
  public init<UpstreamInput>(
    upstream: Getter<UpstreamInput, Input>,
    filter: EqualityComputer<Input>,
    map: @escaping (Input) -> Output
  ) {
            
    self.map = map
    self.filter = filter.isEqual
    
    _ = filter.isEqual(value: upstream.value)
    
    self.ratainUpstream = {
      withExtendedLifetime(upstream) {}
    }
    
    super.init(storage: .init(map(upstream.value)))
    
    upstream.addDidUpdate { [weak self] value in
      self?._receive(newValue: value)
    }
  }
  
  deinit {
    onDeinit()
  }
  
  final func _receive(newValue: Input) {
    
    guard !filter(newValue) else { return }
    let nextValue = map(newValue)
    storage.replace(nextValue)
  }
    
  public final func asAny() -> AnyGetter<Output> {
    .init(self)
  }
  
}

#if canImport(Combine)

import Combine

fileprivate var _willChangeAssociated: Void?
fileprivate var _didChangeAssociated: Void?

@available(iOS 13.0, macOS 10.15, *)
extension GetterBase: ObservableObject {
  
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
  
  public var didChangePublisher: AnyPublisher<Output, Never> {
    
    if let associated = objc_getAssociatedObject(self, &_didChangeAssociated) as? PassthroughSubject<Output, Never> {
      return associated.eraseToAnyPublisher()
    } else {
      let associated = PassthroughSubject<Output, Never>()
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

public final class EqualityComputer<Input> {
  
  public static func alwaysDifferent() -> EqualityComputer<Input> {
    EqualityComputer<Input>.init(selector: { _ in () }) { (_, _) -> Bool in
      return false
    }
  }
  
  public static func alwaysEquals() -> EqualityComputer<Input> {
    EqualityComputer<Input>.init(selector: { _ in () }) { (_, _) -> Bool in
      return true
    }
  }
    
  private let _isEqual: (Input) -> Bool
  
  public init(_ sources: [EqualityComputer<Input>]) {
    self._isEqual = { input in
      for source in sources {
        guard source.isEqual(value: input) else {
          return false
        }
      }
      return true
    }
  }
  
  public init<Key>(
    selector: @escaping (Input) -> Key,
    equals: @escaping (Key, Key) -> Bool
  ) {
    
    var previousValue: Key?
    
    self._isEqual = { input in

      let key = selector(input)
      defer {
        previousValue = key
      }
      if let previousValue = previousValue {
        return equals(previousValue, key)
      } else {
        return false
      }
      
    }
              
  }
     
  public func isEqual(value: Input) -> Bool {
    _isEqual(value)
  }

}

extension EqualityComputer where Input : Equatable {
  
  public convenience init() {
    self.init(selector: { $0 }, equals: ==)
  }
}
