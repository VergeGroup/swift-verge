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
enum Sample2 {
  
  struct State: StateType {
    var count: Int = 0
  }
  
  enum Activity {
    case happen
  }
  
  final class MyStore: Store<State, Activity> {
    
    init() {
      super.init(initialState: .init(), logger: DefaultStoreLogger.shared)
    }
    
    func increment() {
      return commit {
        $0.count += 0
      }
    }
    
    func delayedIncrement() {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        self.increment()        
        self.send(.happen)
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
      .mapWithoutPreFilter { $0 }
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
