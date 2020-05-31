//
//  DemoState.swift
//  VergeStoreTests
//
//  Created by muukii on 2020/04/21.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import VergeStore

struct NonEquatable {}

struct DemoState: ExtendedStateType, Equatable {
  
  var name: String = ""
  var count: Int = 0
  var items: [Int] = []

  @Fragment var nonEquatable: NonEquatable = .init()
  
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
  
  func increment() {
    commit {
      $0.count += 1
    }
  }
  
  func empty() {
    commit { _ in
    }
  }
}
