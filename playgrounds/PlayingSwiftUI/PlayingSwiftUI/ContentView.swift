//
//  ContentView.swift
//  PlayingSwiftUI
//
//  Created by Muukii on 2025/01/20.
//

import SwiftUI
import Verge

struct State: StateType {
  var count1: Int = 0
  var count2: Int = 0
}

struct ContentView: View {
  
  let store: Store<State, Never>

  var body: some View {
    Button("Up 1") {
      store.commit {
        $0.count1 += 1
      }
    }
    Button("Up 2") {
      store.commit {
        $0.count2 += 1
      }
    }
    StoreReader(store) { state in      
      Cell(name: "1", text: state.count1.description, onTap: {
        store.commit {
          $0.count1 += 1
        }
      })
      Cell(name: "2", text: state.count2.description, onTap: {
        store.commit {
          $0.count2 += 1
        }
      })
    }
  }
  
  struct Cell: View {
    
    let name: String
    let text: String
    
    let onTap: () -> Void
    
    var body: some View {
      let _ = Self._printChanges()
      let _ = print("Rendering Cell on \(name)")  
      HStack {
        CellContent(name: name, text: text)
        Button("Up!") {
          onTap()
        }
      }
    }
    
  }
  
  struct CellContent: View {
    
    let name: String
    let text: String
    
    var body: some View {
      let _ = Self._printChanges()
      let _ = print("Rendering CellContent on \(name)")
      HStack {
        Text(name)
        Text(text)
      }
    }
    
  }
}

#Preview {
  ContentView(store: .init(initialState: .init()))
}
