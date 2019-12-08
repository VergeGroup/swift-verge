//
//  ContentView.swift
//  VergeStoreDemoSwiftUI
//
//  Created by muukii on 2019/12/08.
//  Copyright © 2019 muukii. All rights reserved.
//

import SwiftUI

struct ContentView: View {
  
  @EnvironmentObject var session: Session
  
  var body: some View {
    TabView {
      UserListView()
        .tabItem {
          Text("Users")
      }
      AllPostsView()
        .tabItem {
          Text("All Post")
      }
    }    
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
