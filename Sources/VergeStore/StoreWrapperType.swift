//
//  StoreWrapperType.swift
//  VergeStore
//
//  Created by muukii on 2020/04/16.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

public protocol StoreWrapperType: AnyObject, DispatcherType where Scope == WrappedStore.State {
    
}

extension StoreWrapperType {
  
  public typealias Scope = WrappedStore.State
    
  public var changes: Changes<WrappedStore.State> {
    store.asStore().changes
  }
  
  public var state: WrappedStore.State {
    store.state
  }
  
  @discardableResult
  public func subscribeStateChanges(_ receive: @escaping (Changes<WrappedStore.State>) -> Void) -> ChangesSubscription {
    store.asStore().subscribeStateChanges(receive)
  }
  
  @discardableResult
  public func subscribeActivity(_ receive: @escaping (WrappedStore.Activity) -> Void) -> ActivitySusbscription  {
    store.asStore().subscribeActivity(receive)
  }
  
  public func removeStateChangesSubscription(_ subscription: ChangesSubscription) {
    store.asStore().removeStateChangesSubscription(subscription)
  }
  
  public func removeActivitySubscription(_ subscription: ActivitySusbscription) {
    store.asStore().removeActivitySubscription(subscription)
  }
  
}

