//
//  StoreSlice.swift
//  VergeStore
//
//  Created by muukii on 2020/04/21.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

public final class StoreSlice<State> {
    
  /// A current state.
  public var state: State {
    innerStore.state
  }
  
  /// A current changes state.
  public var changes: Changes<State> {
    innerStore.changes
  }
  
  private let innerStore: Store<State, Never>
  
  public init<Source: StoreType>(
    slice: @escaping (Changes<Source.State>) -> State,
    from source: Source
  ) {
    
    let store = Store<State, Never>.init(initialState: slice(source.asStore().changes), logger: nil)
    
    source.asStore().subscribeStateChanges(dropsFirst: true) { [weak store] (changes) in
      store?.commit {
        $0 = slice(changes)
      }
    }
    
    self.innerStore = store
  }
  
  /// Subscribe the state changes
  ///
  /// - Returns: Token to remove suscription if you need to do explicitly. Subscription will be removed automatically when Store deinit
  @discardableResult
  public func subscribeStateChanges(_ receive: @escaping (Changes<State>) -> Void) -> ChangesSubscription {
    
    innerStore.subscribeStateChanges { (changes) in
      receive(changes)
    }
  }
  
}
