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
  
  private var loggedInStack: AppLoggedInStack? {
    switch session.stackContainer.stack {
    case .loggedIn(let stack):
      return stack
    case .loggedOut:
      return nil
    }
  }
  
  private var loggedOutStack: AppLoggedOutStack? {
    switch session.stackContainer.stack {
    case .loggedIn:
      return nil
    case .loggedOut(let stack):
      return stack
    }
  }
  
  var body: some View {
    ZStack {
      if loggedInStack != nil {
        LoggedInView()
          .environmentObject(loggedInStack!)
      }
      if loggedOutStack != nil {
        LoggedOutView()
          .environmentObject(loggedOutStack!)
      }
    }
  }
  
}

struct LoggedOutView: View {
  
  @EnvironmentObject var stack: AppLoggedOutStack
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

struct LoggedInView: View {
  
  @EnvironmentObject var stack: AppLoggedInStack
    
  var body: some View {
    Text("Logged In!")
      .onAppear {
        self.stack.service.fetchMe()
    }
  }
}


