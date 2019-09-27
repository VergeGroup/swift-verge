//
//  ActivityView.swift
//  VergeNeueAdvancedDemo
//
//  Created by muukii on 2019/09/23.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import SwiftUI

import VergeNeue

struct ActivityView: View {
  
  @EnvironmentObject var rootStore: LoggedInStore
    
  var body: some View {
    NavigationView {
      Text("")
        .navigationBarTitle("Activity")
    }
  }
}
