//
//  Sample.swift
//  VergeStore
//
//  Created by muukii on 2019/09/24.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

#if DEBUG

final class MyStore: StoreBase<MyStore.State> {
  
  struct State {
    var count: Int = 0
  }
  
  init() {
    super.init(initialState: .init(), logger: nil)
  }
  
  func increment() {
    commit {
      $0.count += 1
    }
  }
  
  func asyncIncrement() {
    dispatch { context in
      DispatchQueue.main.async {
        context.commit {
          $0.count += 1
        }
      }
    }
  }
  
}

#endif
