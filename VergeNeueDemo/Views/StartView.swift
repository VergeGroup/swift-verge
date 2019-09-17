//
//  StartView.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import SwiftUI
import Combine
import VergeNeue

struct StartView: View {
  
  @ObservedObject private var store: Store<RootState, RootStateReducer> = rootStore
  @State private var isProcessing: Bool = false
  @State private var subscriptions: Set<AnyCancellable> = .init()
  
  var body: some View {
    
    Group {
      
      if store.state.activeSessionState != nil {
        
        SessionContainerView(
          sessionStore: store.makeScoped(
            scope: \.activeSessionState!,
            reducer: SessionStateReducer(service: MockService(env: store.state.activeSessionState!.env))
          )
        )
        
      } else {
        
        NavigationView {
          ZStack {
            Form {
              Section {
                Button(action: {
                  
                  self.isProcessing = true
                  
                  self.store.dispatch { $0.createSession(env: .stage) }
                    .sink(
                      receiveCompletion: { (_) in
                      self.isProcessing = false
                    },
                      receiveValue: {})
                    .store(in: &self.subscriptions)
                }) {
                  Text("Stage")
                }
              }
              Section {
                Button(action: {
                  self.isProcessing = true
                  
                  self.store.dispatch { $0.createSession(env: .production) }
                    .sink(
                      receiveCompletion: { (_) in
                        self.isProcessing = false
                    },
                      receiveValue: {})
                    .store(in: &self.subscriptions)
                }) {
                  Text("Production")
                }
              }
            }
            
            if isProcessing {
              IndicatorView(isAnimating: .constant(true))
            }
            
          }
          .navigationBarTitle("Start")
        }
      }
    }
  }
}
