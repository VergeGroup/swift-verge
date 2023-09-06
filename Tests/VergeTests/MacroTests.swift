import Verge
import XCTest
import SwiftUI

final class MacroTests: XCTestCase {

  func testChanges()  {

    let state: Changes<DemoState> = .init(old: nil, new: .init(name: "hello"))

    #ifChanged(state, \.name) { name in
      print(name)
    }

    #ifChanged(state, \.name, \.count) { name, count in
      print(name, count)
    }

    #ifChanged(state, \.name, \.count, onChanged: { name, count in
      print(name, count)
    })

  }

  func testSink() {

    let store = Store<DemoState, Never>(initialState: .init())

    store.sinkState { state in

      #ifChanged(state, \.count) { count in
        print(count)
      }

    }

  }

}
