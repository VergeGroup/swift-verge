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

public final class EventEmitterSubscribeToken: Hashable {
  public static func == (lhs: EventEmitterSubscribeToken, rhs: EventEmitterSubscribeToken) -> Bool {
    lhs === rhs
  }
  
  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }
}

public final class EventEmitter<Event> {
  
  private var lock = os_unfair_lock_s()
  
  private var subscribers: [EventEmitterSubscribeToken : (Event) -> Void] = [:]
  
  public init() {
    
  }
      
  public func accept(_ event: Event) {
    var targets: [(Event) -> Void]
    os_unfair_lock_lock(&lock)
    targets = subscribers.map { $0.value }
    os_unfair_lock_unlock(&lock)
    targets.forEach {
      $0(event)
    }
  }
  
  @discardableResult
  public func add(_ eventReceiver: @escaping (Event) -> Void) -> EventEmitterSubscribeToken {
    let token = EventEmitterSubscribeToken()
    os_unfair_lock_lock(&lock)
    subscribers[token] = eventReceiver
    os_unfair_lock_unlock(&lock)
    return token
  }
  
  public func remove(_ token: EventEmitterSubscribeToken) {
    os_unfair_lock_lock(&lock)
    subscribers.removeValue(forKey: token)
    os_unfair_lock_unlock(&lock)
  }
}
