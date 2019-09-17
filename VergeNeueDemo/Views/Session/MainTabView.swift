//
//  MainTabbedView.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import SwiftUI

struct MainTabView: View {
  
  @EnvironmentObject var sessionStore: SessionStateReducer.ScopedStoreType<RootReducer>
      
  var body: some View {
    TabView {
      HomeView()
        .tabItem {
          Text("Home")
      }
      
      NotificationsView()
        .tabItem {
          Text("Notification")
      }
      
      MyPageView()
        .tabItem {
          Text("MyPage")
      }
    }
  }
}
