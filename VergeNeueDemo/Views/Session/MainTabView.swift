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
  
  @State private var count: Int = 0
      
  var body: some View {
    ZStack {
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
      
      // How do I put the button on the right bottom?
      VStack {
        Spacer()
        HStack {
          Spacer()
          Button(action: {
//            self.count += 1
            self.sessionStore.commit { $0.increment() }
          }) {
            Text("Floating \(self.count)")
              .padding(8)
              .background(Color.orange)
              .cornerRadius(8)
          }
        }
      }
      
    }
  }
}
