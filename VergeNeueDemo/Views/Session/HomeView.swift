//
//  HomeView.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import SwiftUI
import VergeNeue

let tmp = Store<HomeReducer>(
  state: .init(),
  reducer: HomeReducer(service: .init(env: .stage)),
  registerParent: rootStore
)

struct HomeView: View {
  
//  @EnvironmentObject var sessionStore: SessionStateReducer.ScopedStoreType<RootReducer>
    
  // It's just for testing. This is bad approach. it will create every time.
  @ObservedObject var store = tmp
  
  var body: some View {
    NavigationView {
      List(store.state.photos) { (photo) in
        Text(photo.id)
      }
      .navigationBarTitle("Home")
    }
    .onAppear {
      self.store.dispatch { $0.load() }
    }
  }
}

