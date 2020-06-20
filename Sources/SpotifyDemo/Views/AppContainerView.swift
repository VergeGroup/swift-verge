
import Foundation

import VergeStore
import SwiftUI
import SpotifyService

final class AppContainerViewModel: StoreWrapperType {

  struct State: Equatable {

    var current: BackendStack? {
      didSet {
        guard current != oldValue else {
          return
        }
        isRunning = false
      }
    }

    var isRunning: Bool = false
  }

  typealias Activity = Never

  private let manager = BackendStackManager.shared

  let store = DefaultStore(initialState: .init(), logger: DefaultStoreLogger.shared)

  private var bag = Set<VergeAnyCancellable>()

  init() {

    manager.$current
      .print()
      .assign(to: assignee(\.current))
      .store(in: &bag)

  }

  func runCurrent() {
    commit {
      $0.isRunning = true
    }
  }

  func prepare() {
    _ = manager.resume() ?? manager.makeAndActivate()
  }

}

struct AppContainerView: View {

  let viewModel: AppContainerViewModel

  init(viewModel: AppContainerViewModel) {
    self.viewModel = viewModel
  }

  var body: some View {
    #if DEBUG
    return Group {
      UseState(viewModel.store) { state in
        if state.primitive.current != nil {
          // FIXME: Avoid to create Session here.
          if state.isRunning {
            SessionRootView(session: .init(stack: state.primitive.current!))
          } else {
            Text("Development Menu")
            Button(action: {
              self.viewModel.runCurrent()
            }, label: {
              Text("Start")
            })
          }
        } else {
          Color(.lightGray)
            .edgesIgnoringSafeArea(.all)
        }
      }
    }
    .onAppear {
      self.viewModel.prepare()
    }
    #else
    return Group {
      if manager.current != nil {
        // FIXME: Avoid to create Session here.
        SessionRootView(session: .init(stack: manager.current!))
      } else {
        Color(.lightGray)
      }
    }
    .edgesIgnoringSafeArea(.all)
    .onAppear {
      _ = self.manager.resume() ?? self.manager.makeAndActivate()
    }
    #endif
  }
}
