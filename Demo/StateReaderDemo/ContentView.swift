//
//  ContentView.swift
//  StateReaderDemo
//
//  Created by muukii on 2020/10/08.
//  Copyright © 2020 muukii. All rights reserved.
//

import SwiftUI
import Verge

final class ViewModel: StoreComponentType, ObservableObject {

  struct State: Equatable {
    var count = 0
    var dummyCount = 0
  }

  let store = DefaultStore(initialState: .init())

  init() {
    print("init")
  }
}

import Combine

let vm = ViewModel()
var bag = Set<AnyCancellable>()

struct ContentView: View {

  @StateObject var viewModel = ViewModel()

  init() {

  }

  var body: some View {
    RootView(viewModel: viewModel)
  }
}

struct RootView: View {

  let viewModel: ViewModel
  @State var localCountOuter = 0
  @State var localCountInner = 0

  var body: some View {

    VStack {
      Button("Increment local count outer") {
        localCountOuter += 1
      }
      Button("Increment local count inner") {
        localCountInner += 1
      }
      Button("Increment store count") {
        viewModel.commit {
          $0.count += 1
        }
      }
      Button("Increment store fake count") {
        viewModel.commit {
          $0.dummyCount += 1
        }
      }
      Text("Local count outer \(localCountOuter)")
      
      StateReader(viewModel.derived(.map(\.count))) { state in
        VStack {
          Text("Store count \(state.primitive)")
          Text("Local count inner \(localCountInner)")
        }
      }
      
      StateReader(viewModel.store) { state in
        VStack {
          Text("Store count \(state.count)")
          Text("Local count inner \(localCountInner)")
        }
      }

      StateReader(viewModel.derived(.map(\.count))).content { state in
        VStack {
          Text("Store count \(state.primitive)")
          Text("Local count inner \(localCountInner)")
        }
      }

      StateReader(viewModel.store).content { state in
        VStack {
          Text("Store count \(state.count)")
          Text("Local count inner \(localCountInner)")
        }
      }
    }

  }

}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
