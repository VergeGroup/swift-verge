//
//  Service.swift
//  SpotifyDemo
//
//  Created by muukii on 2020/01/18.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation
import Combine

import Moya
import VergeStore

protocol LoggedInServiceStateType: StateType {
  var service: LoggedInServiceState { get set }
  init(auth: AuthResponse)
}

struct LoggedInServiceState {
  let auth: AuthResponse
  
  init(auth: AuthResponse) {
    self.auth = auth
  }
}

final class LoggedInService<State: LoggedInServiceStateType>: DispatcherBase<State, Never> {

  private let apiProvider: MoyaProvider<Templates.JSONResponse.Auth.Request>
  
  override init(targetStore: Store<State, Never>) {
                
    let token = targetStore.state.service.auth.accessToken
    let authPlugin = AccessTokenPlugin { _ in token }
    self.apiProvider = .init(plugins: [authPlugin])
    super.init(targetStore: targetStore)
  }
  
  func fetchMe() {          
    apiProvider.request(APIRequests.me()) { (result) in
      print(result)
    }
  }
  
}

final class LoggedInStore<State: LoggedInServiceStateType>: Store<State, Never> {
  
}

final class LoggedInStack<State: LoggedInServiceStateType>: ObservableObject {
  
  var objectWillChange: ObservableObjectPublisher {
    store.objectWillChange
  }
  
  let store: LoggedInStore<State>
  let service: LoggedInService<State>
  
  init(initialState: State) {
    
    let _store = LoggedInStore.init(initialState: initialState, logger: DefaultStoreLogger.shared)
    self.store = _store
    self.service = .init(targetStore: _store)
    
  }
}
