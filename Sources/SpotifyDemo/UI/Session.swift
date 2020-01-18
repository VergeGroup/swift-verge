//
//  Session.swift
//  SpotifyDemo
//
//  Created by muukii on 2020/01/18.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

final class Session: ObservableObject {
  
  let store: SessionStore
  let service: Service<SessionStore.State>
  let loggedOutService: LoggedOutService<SessionStore.State>
  
  init() {
    
    let _store = SessionStore()
    self.store = _store    
    self.service = .init(target: _store)
    self.loggedOutService = .init(target: _store)
  }
  
  func receiveAuthCode(_ code: Auth.AuthCode) {
    loggedOutService.fetchToken(code: code)
  }
}
