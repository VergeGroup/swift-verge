//
//  StoreWrapperType.swift
//  VergeStore
//
//  Created by muukii on 2020/04/16.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

public protocol StoreWrapperType: DispatcherType {
      
  var store: Store<State, Activity> { get }
}

extension StoreWrapperType {

  public var target: Store<State, Activity> { store }
  public var scope: WritableKeyPath<State, State> { \State.self }
  public var metadata: DispatcherMetadata { .init() }
  
  public var changes: Changes<State> {
    store.changes
  }
  
  public var state: State {
    store.state
  }
  
  @discardableResult
  public func subscribeStateChanges(_ receive: @escaping (Changes<State>) -> Void) -> ChangesSubscription {
    store.subscribeStateChanges(receive)
  }
  
  @discardableResult
  public func subscribeActivity(_ receive: @escaping (Activity) -> Void) -> ActivitySusbscription  {
    store.subscribeActivity(receive)
  }
  
  public func removeStateChangesSubscription(_ subscription: ChangesSubscription) {
    store.removeStateChangesSubscription(subscription)
  }
  
  public func removeActivitySubscription(_ subscription: ActivitySusbscription) {
    store.removeActivitySubscription(subscription)
  }
  
}

