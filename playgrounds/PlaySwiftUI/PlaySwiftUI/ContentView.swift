//
//  ContentView.swift
//  PlaySwiftUI
//
//  Created by Muukii on 2025/02/13.
//

import SwiftUI
import Verge

@Tracking
struct ContentState {
  
  @Tracking
  struct Info {
    
    let constant: String
    var name: String
    
    init(name: String = "Init") {
      self.constant = name
      self.name = name
    }
  }

  var info = Info()
  
  var count: Int = 0
}

enum AppContainer {
  static let store = Store<_, Never>(initialState: ContentState())
}

struct ContentView: View {
  
  let store = AppContainer.store
  
  var body: some View {
    VStack {
      
      Button("Update Name") {
        store.commit {
          $0.info.name = UUID().uuidString
        }
      }
      
      Button("Increment") {
        store.commit {
          $0.count += 1
        }
      }      
      
      Button("Replace info") {
        store.commit {
          $0.info = .init(name: "Replaced")
        }
      } 
      
      StoreReader(store) { (state: ContentState) in
        Text(state.info.name)
        Text(state.count.description)
      }
      
      StoreReader(store) { (state: ContentState) in
        Text(state.info.constant)
      }
      
    }
    .padding()
  }
}

#Preview {
  ContentView()
}
