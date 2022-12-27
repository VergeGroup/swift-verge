//
//  DemoStateReader2.swift
//  StateReaderDemo
//
//  Created by Muukii on 2022/12/27.
//  Copyright © 2022 muukii. All rights reserved.
//

import Foundation
import SwiftUI
import Verge

struct DemoStateReader2: View {
  
  @StateObject var viewModel = ViewModel()
  @State var localCountOuter = 0
  @State var localCountInner = 0
  @State var flag = false
  
  var body: some View {
    
    VStack {
      Button("Increment local count outer") {
        localCountOuter += 1
      }
      Button("Increment local count inner") {
        localCountInner += 1
      }
      Button("Increment store count") {
        viewModel.commit {
          $0.count += 1
        }
      }
      Button("Increment store fake count") {
        viewModel.commit {
          $0.dummyCount += 1
        }
      }
      
      Text("\(localCountOuter)")
      
      StoreReader(debug: true, viewModel) { state in
        
        VStack {
          Toggle(isOn: $flag) {
            Text("mode")
          }
          
          if flag {
            
            Text("VM.count: \(state.count)")
          } else {
            
            Text("VM.dummyCount: \(state.dummyCount)")
          }
          
          Text("Local: \(localCountInner)")
        }
        
      }
    }
    
  }
}
