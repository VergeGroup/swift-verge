//
//  HomeView.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import SwiftUI

struct HomeView: View {
  
  @EnvironmentObject var sessionStore: SessionStateReducer.ScopedStoreType<RootState>
  
  var body: some View {
    NavigationView {
      Text("")
        .navigationBarTitle(sessionStore.state.env.id)
    }
  }
}

