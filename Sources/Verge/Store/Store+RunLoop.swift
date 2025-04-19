import Foundation

extension Store {

  /// Push an event to run event loop.
  public func updateMainLoop() {
    RunLoop.main.perform(inModes: [.common]) {}
  }

  /**
   Subscribes state updates in given run-loop.
   */
  @MainActor
  public func pollMainLoop(receive: @escaping @MainActor (Changes<State>) -> Void) -> VergeAnyCancellable {

    var latestStateWrapper: StateWrapper<State>? = nil

    let subscription = RunLoopActivityObserver.addObserver(acitivity: .beforeWaiting, in: .main) {

      MainActor.assumeIsolated {
        let newState = self.stateWrapper

        guard (latestStateWrapper?.version ?? 0) < newState.version else {
          return
        }

        let state: Changes<State>

        if let latestStateWrapper {
          state = .init(old: latestStateWrapper.state, new: newState.state)
        } else {
          state = .init(old: nil, new: newState.state)
        }

        latestStateWrapper = newState

        receive(state)
      }

    }

    latestStateWrapper = stateWrapper

    receive(.init(old: nil, new: stateWrapper.state))

    return .init {
      RunLoopActivityObserver.remove(subscription)
    }
  }

}

enum RunLoopActivityObserver {

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

    let mode = CFRunLoopMode.commonModes!
    let cfRunLoop = runLoop.getCFRunLoop()

    CFRunLoopAddObserver(cfRunLoop, o, mode);

    return .init(mode: mode, observer: o, targetRunLoop: runLoop)
  }

  static func remove(_ subscription: consuming Subscription) {

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

@Tracking
private struct StoreState {
  var count: Int = 0
}

private struct Content: View {

  let store = Store<_, Never>(initialState: StoreState())

  @State var subscription: VergeAnyCancellable?
  @State var timer: Timer?

  var body: some View {
    VStack {
      Button("Up") {
        store.commit {
          $0.count += 1
        }
      }
      Button("Background Up") {

        for _ in 0..<10 {
          store.commit {
            $0.count += 1
          }
        }

      }
      Button("Run") {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 19))
      }
    }
      .onAppear {
        subscription = store.pollMainLoop { state in
          print(state.count)
        }
      }
  }

}
#endif

