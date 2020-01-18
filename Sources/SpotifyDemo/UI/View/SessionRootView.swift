//
//  SessionRootView.swift
//  SpotifyDemo
//
//  Created by muukii on 2020/01/18.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import SwiftUI

struct SessionRootView: View {
  
  @EnvironmentObject var session: Session
  
  var body: some View {
    LoginView()
  }
}

struct LoginView: View {
  
  @State private var isConnecting = false
  
  var body: some View {
    VStack {
      Text("Hello, World!")
      Button(action: {
        self.isConnecting = true
      }) {
        Text("Connect with Spotify")
      }
    }
    .sheet(isPresented: $isConnecting) {
      SafariView(url: Auth.authorization())
    }
  }
}

