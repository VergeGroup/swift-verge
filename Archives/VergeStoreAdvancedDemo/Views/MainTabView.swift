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
  @EnvironmentObject var rootStore: LoggedInStore
  
  var body: some View {
    
    TabView {
      FeedView()
        .tabItem {
          Text("Home")
      }
      
      ActivityView()
        .tabItem {
          Text("Activity")
      }
      
      MyPageView()
        .tabItem {
          Text("MyPage")
      }
    }
    
  }
}
