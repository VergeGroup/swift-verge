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

struct RootState {
     
  var sessions: [Env : SessionState] = [:]
  
  var activeSessionState: SessionState?
  
  var count: Int = 0
  
}

final class RootReducer: ReducerType {
  typealias TargetState = RootState
  
  func createSession(env: Env) -> Action<Future<Void, Never>> {
    .init { context in
      Future.init { (promise) in
        demoDelay {
          
          let session = SessionState(env: env)
          context.commit { $0.addSession(session, for: env) }
          context.commit { $0.activateSession(session) }
          
          promise(.success(()))
        }
      }
    }
  }

  private func addSession(_ session: SessionState, for env: Env) -> Mutation {
    .init {
      $0.sessions[env] = session
    }
  }
  
  private func activateSession(_ session: SessionState) -> Mutation {
    return .init {
      $0.activeSessionState = session
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
  
}

