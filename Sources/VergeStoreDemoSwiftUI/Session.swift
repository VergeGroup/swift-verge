//
//  Session.swift
//  VergeStoreDemoSwiftUI
//
//  Created by muukii on 2019/12/08.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import VergeStore
import VergeORM

final class Session {
  
  let store = SessionStore()
  
  init() {
    
  }
    
}

struct SessionState: StateType {
  
  struct Database: DatabaseType {
    
    static func makeEmtpy() -> SessionState.Database {
      .init()
    }
    
    mutating func merge(database: SessionState.Database) {
      
    }
    
  }
}

final class SessionStore: StoreBase<SessionState> {
      
  init() {
    super.init(initialState: .init(), logger: DefaultLogger.shared)
  }
}

final class SessionDispatcher: DispatcherBase<SessionStore> {
  
}

extension Mutations where Base : SessionDispatcher {
  
}
