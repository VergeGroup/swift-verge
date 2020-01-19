//
//  Session.swift
//  SpotifyDemo
//
//  Created by muukii on 2020/01/18.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import Combine

typealias AppLoggedInStack = LoggedInStack<LoggedInSessionState>
typealias AppLoggedOutStack = LoggedOutStack<LoggedOutSessionState>

final class Session: ObservableObject {
  
  var objectWillChange: ObservableObjectPublisher = .init()
      
  let stackContainer: StackContainer<LoggedInSessionState, LoggedOutSessionState>
  
  private var subscriptions = Set<AnyCancellable>()
  
  init() {
    
    self.stackContainer = .init(auth: nil)
    
    stackContainer.$stack.sink { [weak self] _ in
      self?.objectWillChange.send()
    }
    .store(in: &subscriptions)
        
  }
  
  func receiveAuthCode(_ code: Auth.AuthCode) {
    stackContainer.receiveAuthCode(code)
  }
}
