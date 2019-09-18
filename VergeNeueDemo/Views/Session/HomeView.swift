//
//  HomeView.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import SwiftUI
import VergeNeue

struct HomeView: View {
  
  @EnvironmentObject var sessionStore: SessionStateReducer.ScopedStoreType<RootReducer>
      
  var body: some View {
    NavigationView {
      List(sessionStore.state.photosForHome) { (photo) in
        Text(photo.id)
      }
      .navigationBarTitle("Home")
    }
    .onAppear {
      self.sessionStore.dispatch { $0.fetchPhotos() }
    }
  }
}

