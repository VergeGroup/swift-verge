//
//  ContentView.swift
//  ConcurrencyApp
//
//  Created by Muukii on 2021/11/03.
//  Copyright © 2021 muukii. All rights reserved.
//

import SwiftUI

struct ContentView: View {
  var body: some View {
    Button("Run") {
      Task.init {
        await perform()
      }
    }
  }

  @MainActor
  private func perform() async {
    assert(Thread.isMainThread)
    print("perform", Thread.current)
    Task {
      assert(Thread.isMainThread)
      sleep(2)
      print("after sleep")
    }
    print("1")
    print("2")
    print("3")
    print("4")
    await longTask()
  }

  private func longTask() async {
    assert(Thread.isMainThread)
    _ = await Task {
      assert(Thread.isMainThread == false)
      sleep(2)
    }
    .result
    print("done")
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
