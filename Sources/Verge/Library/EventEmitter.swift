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
  
  private let subscribersLock = VergeConcurrency.RecursiveLock()
  
  /**
   The reason why we use array against dictionary, the subscribers does not often remove.
   */
  private var subscribers: [(EventEmitterCancellable, (Event) -> Void)] = []
  
  private var eventQueue: ContiguousArray<Event> = .init()
  
  private let queueLock = VergeConcurrency.RecursiveLock()
    
  private var isCurrentlyEventEmitting: VergeConcurrency.RecursiveLockAtomic<Int> = .init(0)

  private var deinitHandlers: VergeConcurrency.UnfairLockAtomic<[() -> Void]> = .init([])
  
  public init() {

  }

  deinit {
    deinitHandlers.value.forEach {
      $0()
    }
  }
      
  public func accept(_ event: Event) {
    withLocking(queueLock) {
      eventQueue.append(event)
    }
    drain()
  }
  
  @discardableResult
  public func add(_ eventReceiver: @escaping (Event) -> Void) -> EventEmitterCancellable {
    let token = EventEmitterCancellable(owner: self)
    withLocking(subscribersLock) {
      subscribers.append((token, eventReceiver))
    }
    return token
  }
  
  func remove(_ token: EventEmitterCancellable) {
    withLocking(subscribersLock) {
      guard let index = subscribers.firstIndex(where: { $0.0 == token }) else { return }
      subscribers.remove(at: index)
    }
  }

  public func onDeinit(_ onDeinit: @escaping () -> Void) {
    deinitHandlers.modify {
      $0.append(onDeinit)
    }
  }
  
  private func drain() {
    
    /**
     https://github.com/VergeGroup/Verge/pull/220
     */
          
    assertion: do {
      #if DEBUG
      let _isRunning = isCurrentlyEventEmitting.value
      assert(_isRunning == 0 || _isRunning == 1, "\(_isRunning)")
      #endif
    }
                 
    /**
     Increments the flag atomically if it can start to emit the events.
     */
    let canStartToEmitEvents: Bool = isCurrentlyEventEmitting.modify {
      guard $0 == 0 else {
        return false
      }
      $0 &+= 1
      return true
    }
   
    guard canStartToEmitEvents else {
      /**
       Currently, EventEmitter is under the emitting events lately registered.
       This operation would be queued until finished current operations.
       */
      return
    }
                       
    let scheduledEvents: ContiguousArray<Event> = withLocking(queueLock) {
      let events = eventQueue
      eventQueue = []
      return events
    }
            
    guard !scheduledEvents.isEmpty else {
      /**
       Decrements the flag atomically.
       */
      isCurrentlyEventEmitting.modify {
        $0 &-= 1
        assert($0 == 0, "\(isCurrentlyEventEmitting.value)")
      }
      return
    }
                          
    let signpost = VergeSignpostTransaction("EventEmitter.emits")
        
    withLocking(subscribersLock) {
                  
      let targets = subscribers
      
      /// Delivers events
      scheduledEvents.forEach { event in
        targets.forEach {
          signpost.event(name: "EventEmitter.oneEmit")
          $0.1(event)
        }
      }
      
      /**
       Decrements the flag atomically.
       */
      isCurrentlyEventEmitting.modify {
        $0 &-= 1
        assert($0 == 0, "\(isCurrentlyEventEmitting.value)")
      }
    }
         
    signpost.end()
  
    drain()
    
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
