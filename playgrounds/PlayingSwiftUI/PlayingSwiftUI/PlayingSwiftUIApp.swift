//
//  PlayingSwiftUIApp.swift
//  PlayingSwiftUI
//
//  Created by Muukii on 2025/01/20.
//

import SwiftData
import SwiftUI

@main
struct PlayingSwiftUIApp: App {

  var body: some Scene {
    WindowGroup {
      ContentView(store: .init(initialState: .init()))
    }
  }
}
