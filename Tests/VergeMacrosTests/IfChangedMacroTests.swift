import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(VergeMacrosPlugin)
import VergeMacrosPlugin

final class IfChangedMacroTests: XCTestCase {

  func test_trailing_closure() {

    assertMacroExpansion(
      #"""
      #ifChanged(state, \.foo) { value in
        print(value)
      }
      """#,
      expandedSource: #"""
        { arg in
          let primitiveState = arg.primitive
          let previousState = arg.previous?.primitive

          guard primitiveState.foo != previousState?.foo else {
            return
          }

          let _: Void = { value in
          print(value)
          }(primitiveState.foo)
        }(state)
        """#,
      macros: ["ifChanged": IfChangedMacro.self]
    )

  }

  func test_parameter_closure() {

    assertMacroExpansion(
      #"""
      #ifChanged(state, \.name, \.count, onChanged: { name, count in
        print(name, count)
      })
      """#,
      expandedSource: #"""
        { arg in
          let primitiveState = arg.primitive
          let previousState = arg.previous?.primitive

          guard primitiveState.name != previousState?.name || primitiveState.count != previousState?.count else {
            return
          }

          let _: Void = { name, count in
          print(name, count)
          }(primitiveState.name, primitiveState.count)
        }(state)
        """#,
      macros: ["ifChanged": IfChangedMacro.self]
    )

  }
}
#endif
