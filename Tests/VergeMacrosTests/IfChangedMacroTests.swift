import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(VergeMacrosPlugin)
import VergeMacrosPlugin

final class IfChangedMacroTests: XCTestCase {

  func test_1() {

    assertMacroExpansion(
      #"""
      #property(\String.count, \.a)
      """#,
      expandedSource: #"""
        {
            ($0.count, $0.a)
        }
        """#,
      macros: ["property": IfChangedMacro.self]
    )

  }
}
#endif
