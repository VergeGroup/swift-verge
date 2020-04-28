//
//  DemoState.swift
//  VergeStoreTests
//
//  Created by muukii on 2020/04/21.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import VergeStore

struct DemoState: ExtendedStateType {
  
  var name: String = ""
  var count: Int = 0
  var items: [Int] = []
  
  struct Extended: ExtendedType {
    
    static let instance = Extended()
    
    let nameCount = Field.Computed<Int> {
      $0.name.count
    }
    .dropsInput {
      $0.noChanges(\.name)
    }

  }
  
}

final class DemoStore: VergeStore.Store<DemoState, Never> {
  
  init() {
    super.init(initialState: .init(), logger: nil)
  }
}
