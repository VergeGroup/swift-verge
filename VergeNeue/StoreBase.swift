//
//  StoreBase.swift
//  VergeNeue
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public protocol StoreType {
  associatedtype Reducer: ModularReducerType
  typealias State = Reducer.TargetState
  
  func dispatch<ReturnType>(_ makeAction: (Reducer) -> Reducer.Action<ReturnType>) -> ReturnType
  func commit(_ makeMutation: (Reducer) -> Reducer.Mutation)
}

open class StoreBase<Reducer: ModularReducerType>: StoreType {
  
  public typealias State = Reducer.TargetState
  
  open var state: Reducer.TargetState {
    fatalError("abstract")
  }
  
  @discardableResult
  public func dispatch<ReturnType>(_ makeAction: (Reducer) -> _Action<Reducer, ReturnType>) -> ReturnType {
    fatalError("abstract")
  }
  
  public func commit(_ makeMutation: (Reducer) -> _Mutation<Reducer.TargetState>) {
    fatalError("abstract")
  }
  
  private var stores: [String : Any] = [:]
  private let lock = NSLock()
  private var _deinit: () -> Void = {}
  
  private var registrationToken: RegistrationToken?
  
  @discardableResult
  public func register<O: ModularReducerType>(store: StoreBase<O>, for key: String) -> RegistrationToken {
    
    let key = StoreKey<O>.init(from: store, additionalKey: key).rawKey
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

public struct StoreKey<Reducer: ModularReducerType> : Hashable {
  
  public let rawKey: String
  
  public init(additionalKey: String = "") {
    //    let baseKey = "\(String(reflecting: State.self)):\(String(reflecting: Operations.self))"
    let baseKey = "\(String(reflecting: StoreKey<Reducer>.self))"
    let key = baseKey + additionalKey
    self.rawKey = key
  }
  
  public init(from store: StoreBase<Reducer>, additionalKey: String = "") {
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
