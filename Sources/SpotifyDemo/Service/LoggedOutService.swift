//
//  LoggedOutService.swift
//  SpotifyDemo
//
//  Created by muukii on 2020/01/19.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation
import Combine

import JAYSON
import Moya
import VergeStore

protocol LoggedOutServiceStateType: StateType {
  var service: LoggedOutServiceState { get set }
  init()
}

struct LoggedOutServiceState {
  
}

final class LoggedOutService<State: LoggedOutServiceStateType>: DispatcherBase<State, Never> {
  
  let apiProvider = MoyaProvider<MultiTarget>()
  
  func fetchToken(code: Auth.AuthCode) -> Future<AuthResponse, MoyaError> {
    dispatch { _ in
      Future<AuthResponse, MoyaError> { (promise) in
        self.apiProvider.request(.init(APIRequests.token(code: code))) { (result) in
          switch result {
          case .success(let response):
            let auth = try! AuthResponse.init(from: try! JSON(data: response.data))
            promise(.success(auth))
          case .failure(let error):
            promise(.failure(error))
          }
        }
      }
    }
  }
}

final class LoggedOutStore<State: LoggedOutServiceStateType>: StoreBase<State, Never> {
  
}

final class LoggedOutStack<State: LoggedOutServiceStateType>: ObservableObject {
  
  var objectWillChange: ObservableObjectPublisher {
    store.objectWillChange
  }
  
  let store: LoggedOutStore<State>
  let service: LoggedOutService<State>
  
  init(initialState: State) {
    
    let _store = LoggedOutStore.init(initialState: initialState, logger: DefaultStoreLogger.shared)
    self.store = _store
    self.service = .init(target: _store)
    
  }
}
