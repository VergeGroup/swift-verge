import Foundation

extension Store {

  public func poll(in runLoop: RunLoop = .main, receive: @escaping (Changes<State>) -> Void) -> VergeAnyCancellable {

    var latestState: Changes<State>? = nil

    let subscription = RunLoopActivityObserver.addObserver(acitivity: .beforeWaiting, in: runLoop) {

      let newState = self.state

      guard (latestState?.version ?? 0) < newState.version else {
        return
      }

      latestState = newState

      let state: Changes<State>

      if let latestState {
        state = newState.replacePrevious(latestState)
      } else {
        state = newState.droppedPrevious()
      }

      receive(state)

    }

    return .init {
      RunLoopActivityObserver.remove(subscription)
    }
  }

}

private enum RunLoopActivityObserver {

  struct Subscription {
    let mode: CFRunLoopMode
    let observer: CFRunLoopObserver?
    weak var targetRunLoop: RunLoop?
  }

  static func addObserver(acitivity: CFRunLoopActivity, in runLoop: RunLoop, callback: @escaping () -> Void) -> Subscription {

    let o = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, acitivity.rawValue, true, Int.max, { observer, activity in
      callback()
    });

    assert(o != nil)

    let mode = CFRunLoopMode.defaultMode!
    let cfRunLoop = runLoop.getCFRunLoop()

    CFRunLoopAddObserver(cfRunLoop, o, mode);

    return .init(mode: mode, observer: o, targetRunLoop: runLoop)
  }

  static func remove(_ subscription: Subscription) {

    guard let observer = subscription.observer, let targetRunLoop = subscription.targetRunLoop else {
      return
    }

    CFRunLoopRemoveObserver(targetRunLoop.getCFRunLoop(), observer, subscription.mode);
  }

}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

#Preview {
  Content()
}

private struct StoreState: StateType {
  var count: Int = 0
}

private struct Content: View {

  let store = Store<_, Never>(initialState: StoreState())

  @State var subscription: VergeAnyCancellable?

  var body: some View {
    VStack {
      Button("Up") {
        store.commit {
          $0.count += 1
        }
      }
      Button("Run") {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 19))
      }
    }
      .onAppear {
        subscription = store.poll { state in
          print(state.count)
        }
      }
  }

}
#endif

