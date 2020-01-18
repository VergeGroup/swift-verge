//
//  Sources.swift
//  VergeStoreDemoUIKit
//
//  Created by muukii on 2020/01/14.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import VergeStore

struct RootState {
  
  var count: Int = 0
}

enum RootActivity {
  case bomb
}

final class RootStore: StoreBase<RootState, RootActivity> {
  
  init() {
    super.init(initialState: .init(), logger: DefaultStoreLogger.shared)
  }
  
  func increment() {
    commit {
      $0.count += 1
    }
  }
  
  func incrementWithNotification() -> Action<Void> {
    return .action { context in
      
      /// This is sample async task
      DispatchQueue.main.async {
        
        context.commit { $0.increment() }
        if context.state.count > 10 {
          context.send(.bomb)
        }
        
      }
           
    }
  }
  
}

final class CompositionRoot {
  
  let rootStore = RootStore()
  
  lazy var viewModel = ViewModel(parent: rootStore)
      
  static let demo = CompositionRoot()
}
