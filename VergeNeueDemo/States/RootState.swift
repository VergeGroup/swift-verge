//
//  RootState.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import VergeNeue
import Combine

enum StoreContainer {
  
  fileprivate static var sessionStores: [Env : SessionStateReducer.StoreType] = [:]
  
  static func store(for env: Env) -> SessionStateReducer.StoreType {
    sessionStores[env]!
  }
}

struct RootState {
       
  var activeEnv: Env?
  
  var count: Int = 0
  
}

final class RootReducer: ReducerType {
  typealias TargetState = RootState
  
  func makeInitialState() -> RootState {
    .init()
  }
    
  func createSession(env: Env) -> Action<Future<Void, Never>> {
    .init { context in
      Future.init { (promise) in
        demoDelay {
          
          guard StoreContainer.sessionStores[env] == nil else {
            context.commit { $0.activate(env: env) }
            promise(.success(()))
            return
          }
          
          let service = MockService(env: env)
          
          StoreContainer.sessionStores[env] = SessionStateReducer.StoreType(
            reducer: .init(service: service),
            logger: MyStoreLogger.default
          )
          
          context.commit { $0.activate(env: env) }
                              
          promise(.success(()))
        }
      }
    }
  }
    
  func syncIncrement() -> Mutation {
    return .init {
      $0.count += 1
    }
  }
  
  func asyncIncrement() -> Action<Void> {
    return .init { context in
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        context.commit { $0.syncIncrement() }
      }
    }
  }
  
  func logout() -> Action<Void> {
    return .init { context in
      
      if let env = context.state.activeEnv {
        StoreContainer.sessionStores.removeValue(forKey: env)
      }
      
      context.commit { $0.deactivateUsingEnv() }
    }
  }
  
  func suspend() -> Action<Void> {
    return .init { context in         
      context.commit { $0.deactivateUsingEnv() }
    }
  }
  
  private func activate(env: Env) -> Mutation {
    return .init {
      $0.activeEnv = env
    }
  }
  
  private func deactivateUsingEnv() -> Mutation {
    return .init {
      $0.activeEnv = nil
    }
  }
  
}

