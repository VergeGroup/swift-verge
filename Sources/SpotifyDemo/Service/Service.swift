//
//  Service.swift
//  SpotifyDemo
//
//  Created by muukii on 2020/01/18.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import Moya

import VergeStore

protocol ServiceStateType: StateType {
  var service: ServiceState { get set }
}

struct ServiceState {
  
}

final class LoggedOutService<State: ServiceStateType>: DispatcherBase<State, Never> {
  
  let apiProvider = MoyaProvider<MultiTarget>()
  
  func fetchToken(code: Auth.AuthCode) {
    dispatchInline { _ in
      self.apiProvider.request(.init(APIRequests.token(code: code))) { (result) in
        print(result)
      }
    }
  }
}

final class Service<State: ServiceStateType>: DispatcherBase<State, Never> {
    
}
