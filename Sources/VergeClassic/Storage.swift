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
@_spi(EventEmitter) import Verge

open class ReadonlyStorage<Value>: @unchecked Sendable, CustomReflectable {

  public enum Event: EventEmitterEventType {
    case willUpdate
    case didUpdate(Value)
    case willDeinit

    public func onComsume() {
      
    }
  }

  private let eventEmitter = EventEmitter<Event>()

  /// Returns a current value with thread-safety.
  ///
  /// It causes locking and unlocking with a bit cost.
  /// It may cause blocking if any other is doing mutation or reading.
  public final var wrappedValue: Value {
    return value
  }

  /// Returns a current value with thread-safety.
  ///
  /// It causes locking and unlocking with a bit cost.
  /// It may cause blocking if any other is doing mutation or reading.
  public final var value: Value {
    _lock.lock()
    defer {
      _lock.unlock()
    }
    return nonatomicValue
  }
  
  fileprivate var nonatomicValue: Value
  
  private let _lock: NSRecursiveLock
  
  fileprivate let upstreams: [AnyObject]

  public init(
    _ value: Value,
    upstreams: [AnyObject] = []
  ) {

    self._lock = .init()
    self.nonatomicValue = value
    self.upstreams = upstreams

    if _verge_signpost_enabled {
      eventEmitter.addEventHandler { event in
        switch event {
        case .willUpdate:
          vergeSignpostEvent("Storage.willUpdate")
        case .didUpdate(_):
          break
        case .willDeinit:
          break
        }
      }
    }

  }
  
  deinit {
    eventEmitter.accept(.willDeinit)
  }
  
  public func lock() {
    _lock.lock()
  }
  
  public func unlock() {
    _lock.unlock()
  }

  @discardableResult
  public final func sinkEvent(subscriber: @escaping (Event) -> Void) -> EventEmitterCancellable {
    eventEmitter.addEventHandler { event in
      subscriber(event)
    }
  }
    
  @inline(__always)
  fileprivate func notifyWillUpdate(value: Value) {
    eventEmitter.accept(.willUpdate)
  }
  
  @inline(__always)
  fileprivate func notifyDidUpdate(value: Value) {
    eventEmitter.accept(.didUpdate(value))
  }
  
  public var customMirror: Mirror {
    Mirror(
      self,
      children: ["value": value],
      displayStyle: .struct
    )
  }
  
}

open class Storage<Value>: ReadonlyStorage<Value> {
  
  public enum UpdateResult {
    case updated
    case nothingUpdates
  }

  @inline(__always)
  public final func _update(_ update: (inout Value) throws -> UpdateResult) rethrows {

    let signpost = VergeSignpostTransaction("Storage.update")
    defer {
      signpost.end()
    }

    lock()
    do {

      let previousValue = nonatomicValue

      let result = try update(&nonatomicValue)

      switch result {
      case .nothingUpdates:
        unlock()
      case .updated:
        let afterValue = nonatomicValue
        
        /**
         Unlocks lock before emitting event to avoid dead-locking.
         But it causes cracking the order of event.
         SeeAlso: testOrderOfEvents
         */
        unlock()
      
        // it's not actual `will` 👨🏻❓
        notifyWillUpdate(value: previousValue)
        notifyDidUpdate(value: afterValue)
            
      }

    } catch {
      unlock()
      throw error
    }
  }
  
  @discardableResult
  @inline(__always)
  public final func update<Result>(_ update: (inout Value) throws -> Result) rethrows -> Result {
    let signpost = VergeSignpostTransaction("Storage.update")
    defer {
      signpost.end()
    }
    do {
      let notifyValue: Value
      lock()
      notifyValue = nonatomicValue
      unlock()
      notifyWillUpdate(value: notifyValue)
    }
    
    lock()
    do {
      let r = try update(&nonatomicValue)
      let notifyValue = nonatomicValue
      unlock()
      // TODO: cause cracking the order of event
      notifyDidUpdate(value: notifyValue)
      return r
    } catch {
      unlock()
      throw error
    }
  }
    
}

public final class StateStorage<Value>: Storage<Value> {

}

extension ReadonlyStorage {
  
  /// Transform value with filtering.
  /// - Attention: Retains upstream storage
  public func map<U>(
    filter: @escaping (Value) -> Bool = { _ in false },
    transform: @escaping (Value) -> U
  ) -> ReadonlyStorage<U> {
    
    let initialValue = transform(value)
    let newStorage = Storage<U>.init(
      initialValue,
      upstreams: [self]
    )

    var token: EventEmitterCancellable?
    token = sinkEvent { [weak newStorage] (event) in
      switch event {
      case .willUpdate:
        break
      case .didUpdate(let newValue):
        guard !filter(newValue) else {
          return
        }
        newStorage?.update {
          $0 = transform(newValue)
        }
      case .willDeinit:
        token?.cancel()
      }
    }

    return newStorage
  }
}

#if canImport(Combine)

import Combine

// MARK: - Integrate with Combine

fileprivate var _willChangeAssociated: Void?
fileprivate var _didChangeAssociated: Void?

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension ReadonlyStorage: ObservableObject {
  
  public var objectWillChange: ObservableObjectPublisher {
    assert(Thread.isMainThread)
    if let associated = objc_getAssociatedObject(self, &_willChangeAssociated) as? ObservableObjectPublisher {
      return associated
    } else {
      let associated = ObservableObjectPublisher()
      objc_setAssociatedObject(self, &_willChangeAssociated, associated, .OBJC_ASSOCIATION_RETAIN)

      sinkEvent { (event) in
        switch event {
        case .willUpdate:
          if Thread.isMainThread {
            associated.send()
          } else {
            DispatchQueue.main.async {
              associated.send()
            }
          }
        case .didUpdate:
         break
        case .willDeinit:
          break
        }
      }
      
      return associated
    }
  }
  
  public var objectDidChange: AnyPublisher<Value, Never> {
    valuePublisher.dropFirst().eraseToAnyPublisher()
  }
  
  public var valuePublisher: AnyPublisher<Value, Never> {

    objc_sync_enter(self)
    defer {
      objc_sync_exit(self)
    }
    
    if let associated = objc_getAssociatedObject(self, &_didChangeAssociated) as? CurrentValueSubject<Value, Never> {
      return associated.eraseToAnyPublisher()
    } else {
      let associated = CurrentValueSubject<Value, Never>(value)
      objc_setAssociatedObject(self, &_didChangeAssociated, associated, .OBJC_ASSOCIATION_RETAIN)

      sinkEvent { (event) in
        switch event {
        case .willUpdate:
          break
        case .didUpdate(let newValue):
          associated.send(newValue)
        case .willDeinit:
          break
        }
      }
      
      return associated.eraseToAnyPublisher()
    }
  }
    
}

#endif
