//
//  VergeViewModel.swift
//  VergeViewModel
//
//  Created by muukii on 2019/11/24.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import VergeStore

public protocol VergeViewModelType {
  
  associatedtype State
  associatedtype Activity
  
  var state: State { get }
  var storage: Storage<State> { get }
  var emitter: EventEmitter<Activity> { get }
  
}

extension VergeViewModelType {
  /// Commit
  ///
  /// - Parameters:
  ///   - name:
  ///   - description:
  ///   - file:
  ///   - function:
  ///   - line:
  ///   - mutate:
  /// - Throws:
  public func commit(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ mutate: (inout State) throws -> Void
  ) rethrows {
    
    try storage.update(mutate)
  }
  
  /// Dispatch
  ///
  /// - Parameters:
  ///   - name:
  ///   - description:
  ///   - file:
  ///   - function:
  ///   - line:
  ///   - action:
  /// - Returns:
  /// - Throws:
  @discardableResult
  public func dispatch<Return>(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: (DispatchingContext<Self>) throws -> Return
  ) rethrows -> Return {
    
    let context = DispatchingContext.init(
      actionName: name,
      source: self
    )
    
    let returnValue = try action(context)
    
    return returnValue
    
  }
  
  fileprivate func emit(
    _ activity: Activity,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
  ) {
    
    emitter.accept(activity)
  }
  
}

open class VergeViewModelBase<State, Activity, StoreState>: VergeViewModelType {
    
  public var state: State {
    storage.value
  }
  
  /// You shouldn't access unless special-case
  public let storage: Storage<State>
  
  /// You shouldn't access unless special-case
  public let emitter: EventEmitter<Activity> = .init()
  
  public let store: VergeDefaultStore<StoreState>
  private var subscription: StorageSubscribeToken?
  
  public init(initialState: State, store: VergeDefaultStore<StoreState>) {
    self.storage = .init(initialState)
    self.store = store
    self.subscription = store.backingStorage.add { [weak self] (state) in
      guard let self = self else { return }
      self.updateState(storeState: state)
    }
  }
  
  deinit {
    if let subscription = self.subscription {
      store.backingStorage.remove(subscriber: subscription)
    }
  }
    
  /// Tells you Store's state has been updated.
  /// It also called when initialized
  ///
  /// - Parameter storeState:
  open func updateState(storeState: StoreState) {
    
  }
  
}

public final class DispatchingContext<VergeViewModel : VergeViewModelType> {
  
  private let source: VergeViewModel
  private let actionName: String
  
  public var state: VergeViewModel.State {
    return source.state
  }
  
  init(actionName: String, source: VergeViewModel) {
    self.source = source
    self.actionName = actionName
  }
  
  deinit {
    
  }
  
  public func commit(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ mutate: (inout VergeViewModel.State) throws -> Void
  ) rethrows {
    
    try source.commit(name, description, file, function, line, mutate)
  }
    
  @discardableResult
  public func dispatch<Return>(
    _ name: String = "",
    _ description: String = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: (DispatchingContext<VergeViewModel>) throws -> Return
  ) rethrows -> Return {
    
    try source.dispatch(name, description, file, function, line, action)
    
  }
  
  public func emit(
    _ activity: VergeViewModel.Activity,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
  ) {
    source.emit(activity, file: file, function: function, line: line)
  }
  
}
