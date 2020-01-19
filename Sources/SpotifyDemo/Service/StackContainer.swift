//
//  Service.swift
//  SpotifyDemo
//
//  Created by muukii on 2020/01/19.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import Combine

final class StackContainer<LoggedInState: LoggedInServiceStateType, LoggedOutState: LoggedOutServiceStateType>: ObservableObject {
  
  enum Stack {
    case loggedIn(LoggedInStack<LoggedInState>)
    case loggedOut(LoggedOutStack<LoggedOutState>)
  }
  
  @Published private(set) var stack: Stack
  
  private var subscriptions = Set<AnyCancellable>()
  
  init(auth: AuthResponse?) {
    
    switch auth {
    case .none:
      self.stack = .loggedOut(.init(initialState: .init()))
    case .some(let auth):
      self.stack = .loggedIn(.init(initialState: .init(auth: auth)))
    }
    
  }
  
  func receiveAuthCode(_ code: Auth.AuthCode) {
    
    guard case .loggedOut(let stack) = stack else {
      return
    }
    
    stack.service.fetchToken(code: code)
      .sink(receiveCompletion: { (completion) in
        switch completion {
        case .failure(let error):
          assertionFailure("\(error)")
        case .finished:
          break
        }
      }) { (auth) in
        
        self.stack = .loggedIn(.init(initialState: .init(auth: auth)))
    }
    .store(in: &subscriptions)

  }
}

