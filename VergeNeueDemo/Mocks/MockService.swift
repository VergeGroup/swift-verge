//
//  Service.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

final class MockService {
  
  let database: MockDatabase
  let apiProvider: MockAPIProvider
  
  init(env: Env) {
    
    self.database = .init()
    self.apiProvider = .init()
    
  }
}
