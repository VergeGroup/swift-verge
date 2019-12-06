//
//  Actions.swift
//  VergeStore
//
//  Created by muukii on 2019/12/04.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

/// An object to provide a group of Actions
/// ```
/// extension Actions where Base == MyDispatcher {
///
///   func continuousIncrement() {
///
///     descriptor.dispatch { c in
///       c.commit.increment()
///       c.commit.increment()
///     }
///   }
///}
///```
///
public struct Actions<Base: Dispatching> {
  
  public let base: Base
  public var descriptor: ActionDescriptor<Base> {
    .init(base: base, parentContext: parentContext)
  }
  let parentContext: VergeStoreDispatcherContext<Base>?
  
  init(base: Base, parentContext: VergeStoreDispatcherContext<Base>?) {
    self.base = base
    self.parentContext = parentContext
  }
    
}

/// An object to describe the Action
/// The reason why we need this object,
/// Since we have several methods to run Action, to hide these from outside of Dispatcher.
public struct ActionDescriptor<Base: Dispatching> {
  
  public let base: Base
  let parentContext: VergeStoreDispatcherContext<Base>?
  
  init(base: Base, parentContext: VergeStoreDispatcherContext<Base>?) {
    self.base = base
    self.parentContext = parentContext
  }
  
  @discardableResult
  public func dispatch<ReturnType>(
    _ name: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ inlineAction: (VergeStoreDispatcherContext<Base>) throws -> ReturnType
  ) rethrows -> ReturnType {
    
    let metadata = ActionMetadata(name: name, file: file, function: function, line: line)
    
    let context = VergeStoreDispatcherContext<Base>(
      dispatcher: base,
      metadata: metadata,
      parent: parentContext
    )
    
    let result = try inlineAction(context)
    
    base.dispatchTarget.logger?.didDispatch(
      store: base.dispatchTarget,
      state: base.dispatchTarget.state,
      action: metadata,
      context: context
    )
    
    return result
    
  }
  
}

