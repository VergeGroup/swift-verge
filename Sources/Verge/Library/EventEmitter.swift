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
import os

public final class EventEmitterCancellable: Hashable, CancellableType {
  
  public static func == (lhs: EventEmitterCancellable, rhs: EventEmitterCancellable) -> Bool {
    lhs === rhs
  }
  
  private weak var owner: EventEmitterType?
  
  fileprivate init(owner: EventEmitterType) {
    self.owner = owner
  }
  
  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }
  
  public func cancel() {
    owner?.remove(self)
  }
}

protocol EventEmitterType: AnyObject {
  func remove(_ token: EventEmitterCancellable)
}

/// Instead of Combine
public final class EventEmitter<Event>: EventEmitterType, @unchecked Sendable {
  
  private var __publisher: Any?
  
  /**
   The reason why we use array against dictionary, the subscribers does not often remove.
   */
  private var subscribers: VergeConcurrency.UnfairLockAtomic<[(EventEmitterCancellable, (Event) -> Void)]> = .init([])
  
  private let queue: VergeConcurrency.UnfairLockAtomic<ContiguousArray<Event>> = .init(.init())
        
  private let flag = VergeConcurrency.AtomicInt(initialValue: 0)

  private var deinitHandlers: VergeConcurrency.UnfairLockAtomic<[() -> Void]> = .init([])
  
  public init() {

  }

  deinit {
    deinitHandlers.value.forEach {
      $0()
    }
  }
      
  public func accept(_ event: Event) {
    
    /**
     https://github.com/VergeGroup/Verge/pull/220
     https://github.com/VergeGroup/Verge/issues/221
     https://github.com/VergeGroup/Verge/pull/222
     */
        
    // delivers a given event for subscribers at this point.
    let capturedSubscribers = subscribers.value
    
    queue.modify {
      $0.append(event)
    }
        
    if flag.compareAndSet(expect: 0, newValue: 1) {
            
      while queue.value.isEmpty == false {
        let event = queue.modify { $0.removeFirst() }
        for subscriber in capturedSubscribers {
          subscriber.1(event)
        }
      }
      flag.compareAndSet(expect: 1, newValue: 0)
    } else {
      // enqueue only
    }
              
  }
  
  @discardableResult
  public func add(_ eventReceiver: @escaping (Event) -> Void) -> EventEmitterCancellable {
    let token = EventEmitterCancellable(owner: self)
    subscribers.modify {
      $0.append((token, eventReceiver))
    }
    return token
  }
  
  func remove(_ token: EventEmitterCancellable) {
    subscribers.modify {
      guard let index = $0.firstIndex(where: { $0.0 == token }) else { return }
      $0.remove(at: index)
    }
  }

  public func onDeinit(_ onDeinit: @escaping () -> Void) {
    deinitHandlers.modify {
      $0.append(onDeinit)
    }
  }
  
  private func drain() {
    
  }
  
}

#if canImport(Combine)

import Combine

extension EventEmitter {
  
  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  public struct Publisher: Combine.Publisher {
           
    public typealias Output = Event
    
    public typealias Failure = Never
    
    private let eventEmitter: EventEmitter<Event>
    
    public init(eventEmitter: EventEmitter<Event>) {
      self.eventEmitter = eventEmitter
    }

    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
      
      let anySubscriber = AnySubscriber(subscriber)
      let subscription = Subscription(subscriber: anySubscriber, eventEmitter: eventEmitter)
      subscriber.receive(subscription: subscription)      
    }
    
  }
  
  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  public struct Subscription: Combine.Subscription {
        
    public let combineIdentifier: CombineIdentifier = .init()
    
    private let subscriber: AnySubscriber<Event, Never>
    private let eventEmitterSubscription: EventEmitterCancellable
    private weak var eventEmitter: EventEmitter<Event>?
    
    init(subscriber: AnySubscriber<Event, Never>, eventEmitter: EventEmitter<Event>) {
      
      self.subscriber = subscriber
      self.eventEmitter = eventEmitter
      
      self.eventEmitterSubscription = eventEmitter.add { (event) in
        _ = subscriber.receive(event)
      }
    }

    public func request(_ demand: Subscribers.Demand) {
      
    }
    
    public func cancel() {
      eventEmitter?.remove(eventEmitterSubscription)
    }
            
  }
  
}

extension EventEmitter {
  
  @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
  public var publisher: Publisher {
    if let publisher = __publisher as? Publisher {
      return publisher
    }
    let newPublisher = Publisher(eventEmitter: self)
    __publisher = newPublisher
    return newPublisher
  }
  
}

#endif
