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
        {
            ($0.count, $0.a)
        }
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
        {
            ($0.count, $0.a)
        }
        """#,
      macros: ["ifChanged": IfChangedMacro.self]
    )

  }
}
#endif
