//
//  SessionContainerView.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import SwiftUI

struct SessionContainerView: View {
  
  @ObservedObject var sessionStore: SessionStateReducer.ScopedStoreType<RootState, RootReducer>
  
  var body: some View {
    MainTabView().environmentObject(sessionStore)
  }
}

