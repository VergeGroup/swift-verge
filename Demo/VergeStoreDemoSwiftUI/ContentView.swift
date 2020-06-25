//
//  ContentView.swift
//  VergeStoreDemoSwiftUI
//
//  Created by muukii on 2019/12/08.
//  Copyright © 2019 muukii. All rights reserved.
//

import SwiftUI

struct ContentView: View {
  
  var session: Session
  
  var body: some View {
    TabView {
      AllPostsView(session: session)
        .tabItem {
          Text("All Post")
      }
      UserListView(session: session)
        .tabItem {
          Text("Users")
      }
      DualDisplayView(session: session)
        .tabItem {
          Text("Dual")
      }
    }    
  }
}
