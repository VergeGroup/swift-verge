import Verge
import XCTest
import SwiftUI

final class MacroTests: XCTestCase {

  func testChanges()  {

    let state: Changes<DemoState> = .init(old: nil, new: .init(name: "hello"))

    #IfChanged(state, \.name) { name in
      print(name)
    }

    #IfChanged(state, \.name, \.count) { name, count in
      print(name, count)
    }

    #IfChanged(state, \.name, \.count, onChanged: { name, count in
      print(name, count)
    })

  }

}
