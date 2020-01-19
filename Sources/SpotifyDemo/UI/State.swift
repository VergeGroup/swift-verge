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

struct LoggedOutSessionState: LoggedOutServiceStateType {
  
  var service: LoggedOutServiceState = .init()
}

struct LoggedInSessionState: LoggedInServiceStateType {
  
  var service: LoggedInServiceState
  
  init(auth: AuthResponse) {
    self.service = .init(auth: auth)
  }
}

