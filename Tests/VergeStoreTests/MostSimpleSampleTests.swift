//
//  MostSimpleSampleTests.swift
//  VergeStoreTests
//
//  Created by muukii on 2020/01/16.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import VergeStore

import SwiftUI

@available(iOS 13.0, *)
enum Sample {
  
  struct State: StateType {
    var count: Int = 0
  }
  
  enum Activity {
    case happen
  }
  
  final class MyStore: StoreBase<State, Activity> {
    
    init() {
      super.init(initialState: .init(), logger: DefaultStoreLogger.shared)
    }
    
    func increment() -> Mutation<Void> {
      return .mutation {
        $0.count += 0
      }
    }
    
    func delayedIncrement() -> Action<Void> {
      return .action { context in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          context.commit { $0.increment() }
          
          context.send(.happen)
        }
      }
    }
    
  }
  
  static func usage() {
    
    let store = MyStore()
    
    store.commit { $0.increment() }
    
    store.dispatch { $0.delayedIncrement() }
    
    // Get value from current State
    let count = store.state.count
    
    // Subscribe state
    store.makeGetter()
      .sink { state in
        
    }
    
  }
  
  struct MyView: View {
    
    @EnvironmentObject var store: MyStore
    
    var body: some View {
      Group {
        Text(store.state.count.description)
        Button(action: {
          self.store.commit { $0.increment() }
        }) {
          Text("Increment")
        }
      }
    }
  }

  
}
