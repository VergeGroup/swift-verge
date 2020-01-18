//
//  Store.swift
//  SpotifyDemo
//
//  Created by muukii on 2020/01/18.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import VergeStore
import VergeORM

struct SessionState: ServiceStateType {
  
  var service: ServiceState = .init()
}

final class SessionStore: StoreBase<SessionState, Never> {
  
  init() {
    super.init(initialState: .init(), logger: DefaultStoreLogger.shared)
  }
}
