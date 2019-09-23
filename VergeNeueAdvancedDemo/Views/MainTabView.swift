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
  
  @ObservedObject var store: Store<LoggedInReducer>
  
  var body: some View {
    
    TabView {
      FeedView(store: store)
        .tabItem {
          Text("Home")
      }
      
      ActivityView(store: store)
        .tabItem {
          Text("Activity")
      }
      
      MyPageView(store: store)
        .tabItem {
          Text("MyPage")
      }
    }
    
  }
}
