//
//  StoreBase.swift
//  VergeNeue
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public protocol StoreType where Reducer.TargetState == State {
  associatedtype State
  associatedtype Reducer: ReducerType
  
  func dispatch<ReturnType>(_ makeAction: (Reducer) -> Reducer.Action<ReturnType>) -> ReturnType
  func commit(_ makeMutation: (Reducer) -> Reducer.Mutation)
}

public class StoreBase<State, Reducer: ReducerType>: StoreType where Reducer.TargetState == State {
  
  @discardableResult
  public func dispatch<ReturnType>(_ makeAction: (Reducer) -> _Action<Reducer.TargetState, Reducer, ReturnType>) -> ReturnType {
    fatalError()
  }
  
  public func commit(_ makeMutation: (Reducer) -> _Mutation<Reducer.TargetState>) {
    fatalError()
  }
  
  private var stores: [String : Any] = [:]
  private let lock = NSLock()
  
  private var registrationToken: RegistrationToken?
  
  public func register<S, O: ReducerType>(store: StoreBase<S, O>, for key: String) -> RegistrationToken where O.TargetState == S {
    
    let key = StoreKey<S, O>.init(from: store).rawKey
    lock.lock()
    stores[key] = store
    
    let token = RegistrationToken { [weak self] in
      guard let self = self else { return }
      self.lock.lock()
      self.stores.removeValue(forKey: key)
      self.lock.unlock()
    }
    
    store.registrationToken = token
    lock.unlock()
    
    return token
  }
  
  public func reserveRelease() {
    registrationToken?.unregister()
  }
  
}

public struct StoreKey<State, Reducer: ReducerType> : Hashable where Reducer.TargetState == State {
  
  public let rawKey: String
  
  public init(additionalKey: String = "") {
    //    let baseKey = "\(String(reflecting: State.self)):\(String(reflecting: Operations.self))"
    let baseKey = "\(String(reflecting: StoreKey<State, Reducer>.self))"
    let key = baseKey + additionalKey
    self.rawKey = key
  }
  
  public init(from store: StoreBase<State, Reducer>, additionalKey: String = "") {
    self = StoreKey.init(additionalKey: additionalKey)
  }
  
  public init<Store: StoreType>(from store: Store, additionalKey: String = "") {
    self = StoreKey.init(additionalKey: additionalKey)
  }
}

public struct RegistrationToken {
  
  private let _unregister: () -> Void
  
  init(_ unregister: @escaping () -> Void) {
    self._unregister = unregister
  }
  
  public func unregister() {
    self._unregister()
  }
}
