//
//  SessionState.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import VergeNeue

struct SessionState {
  
  let env: Env
  
}

final class SessionStateReducer: ReducerType {
  typealias TargetState = SessionState
  
  let service: MockService
  
  init(service: MockService) {
    self.service = service
  }
}
