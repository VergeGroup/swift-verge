//
//  NotificationsView.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import SwiftUI

struct NotificationsView: View {
  
  @EnvironmentObject var sessionStore: SessionStateReducer.StoreType
  
  var body: some View {
    NavigationView {
      VStack {
        List(sessionStore.state.notifications) { (notification) in
          Text(notification.body)
        }
        Button(action: {
          self.sessionStore.dispatch { $0.addManyNotification() }
        }) {
          Text("Add Notification")
        }
      }
      .navigationBarTitle("Notifications")
    }
    .onAppear {
      self.sessionStore.dispatch { $0.fetchPhotos() }
    }
  }
}

