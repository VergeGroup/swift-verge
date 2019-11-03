//
//  MyPageView.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import SwiftUI

struct MyPageView: View {
  
  @EnvironmentObject var sessionStore: SessionStateReducer.StoreType
  
  var body: some View {
    NavigationView {
      Form {
        Section {
          Button(action: {
            // TODO: Special
            rootStore.dispatch { $0.logout() }
          }) {
            Text("Logout")
          }
          Button(action: {
            // TODO: Special
            rootStore.dispatch { $0.suspend() }
          }) {
            Text("Suspend")
          }
        }
      }
    }
  }
}

