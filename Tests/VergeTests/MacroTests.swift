import Verge
import XCTest
import SwiftUI

final class MacroTests: XCTestCase {

  func testChanges()  {

    let state: Changes<DemoState> = .init(old: nil, new: .init(name: "hello"))

    #IfChanged(state, \.name) { name in
      print(name)
    }



    let r = if false {
      0
    } else {
      1
    }

    #IfChanged(state, \.name, \.count) { name, count in
      print(name, count)
    }

    #IfChanged(state, \.name, \.count, onChanged: { name, count in
      print(name, count)
    })

  }

  func testSink() {

    let store = Store<DemoState, Never>(initialState: .init())

    store.sinkState { state in

      #IfChanged(state, \.count) { count in
        print(count)
      }

    }

  }

}
