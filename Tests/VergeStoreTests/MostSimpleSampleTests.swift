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
    
    func increment() {
      return commit {
        $0.count += 0
      }
    }
    
    func delayedIncrement() {
      dispatch { context in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          self.increment()
          
          context.send(.happen)
        }
      }
    }
    
  }
  
  static func usage() {
    
    let store = MyStore()
    
    store.increment()
    
    store.delayedIncrement()
    
    // Get value from current State
    let count = store.state.count
    
    print(count)
    
    // Subscribe state
    _ = store.getterBuilder()
      .noMap()
      .build()
      .sink { state in
        
    }
    
  }
  
  struct MyView: View {
    
    @EnvironmentObject var store: MyStore
    
    var body: some View {
      Group {
        Text(store.state.count.description)
        Button(action: {
          self.store.increment()
        }) {
          Text("Increment")
        }
      }
    }
  }

  
}
