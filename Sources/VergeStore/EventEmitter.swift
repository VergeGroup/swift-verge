//
//  EventEmitter.swift
//  VergeViewModel
//
//  Created by muukii on 2019/11/24.
//  Copyright © 2019 muukii. All rights reserved.
//

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
