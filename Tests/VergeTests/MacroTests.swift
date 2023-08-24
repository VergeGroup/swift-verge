import Verge
import XCTest

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

}
