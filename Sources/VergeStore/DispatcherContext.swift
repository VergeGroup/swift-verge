//
//  DispatcherContext.swift
//  VergeStore
//
//  Created by muukii on 2019/11/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public final class VergeStoreDispatcherContext<Dispatcher: DispatcherType> {
  
  public typealias State = Dispatcher.State
  
  public let dispatcher: Dispatcher
  public let metadata: ActionMetadata
  private let parent: VergeStoreDispatcherContext<Dispatcher>?
  
  public var state: State {
    return dispatcher.dispatchTarget.state
  }
  
  init(
    dispatcher: Dispatcher,
    metadata: ActionMetadata,
    parent: VergeStoreDispatcherContext<Dispatcher>?
  ) {
    self.dispatcher = dispatcher
    self.metadata = metadata
    self.parent = parent
  }
     
}

extension VergeStoreDispatcherContext {
  
  public func `do`(_ get: (Dispatcher) -> Dispatcher.Mutation) {
    dispatcher.`do`(get)
  }
  
  public func `do`<Return>(_ get: (Dispatcher) -> Dispatcher.Action<Return>) -> Return {
    let action = get(dispatcher)
    let context = VergeStoreDispatcherContext<Dispatcher>.init(
      dispatcher: dispatcher,
      metadata: action.metadata,
      parent: self
    )
    return action._action(context)
  }
}

extension VergeStoreDispatcherContext: CustomReflectable {
  
  public var customMirror: Mirror {
    Mirror(
      self,
      children: [
        "metadata": metadata,
        "parent" : parent as Any
      ],
      displayStyle: .struct
    )
  }
}

extension VergeStoreDispatcherContext where Dispatcher : ScopedDispatching {
  
  public var scopedState: Dispatcher.Scoped {
    state[keyPath: Dispatcher.scopedStateKeyPath]
  }
  
}
