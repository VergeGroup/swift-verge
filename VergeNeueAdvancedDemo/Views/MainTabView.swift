//
//  TabView.swift
//  VergeNeueAdvancedDemo
//
//  Created by muukii on 2019/09/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import SwiftUI

import VergeNeue

struct MainTabView: View {
  
  @ObservedObject var store: LoggedInStore
  
  var body: some View {
    
    TabView {
      FeedView(store: store.feedStore)
        .tabItem {
          Text("Home")
      }
      
      ActivityView()
        .tabItem {
          Text("Activity")
      }
      
      MyPageView(store: store.mypageStore)
        .tabItem {
          Text("MyPage")
      }
    }
    
  }
}
