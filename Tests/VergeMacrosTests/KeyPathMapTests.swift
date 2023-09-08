import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(VergeMacrosPlugin)
import VergeMacrosPlugin

final class KeyPathMapTests: XCTestCase {

  func test_() {

    assertMacroExpansion(
      #"""
      #keyPathMap(\.foo)
      """#,
      expandedSource: #"""
        {
            ($0.foo)
        }
        """#,
      macros: ["keyPathMap": KeyPathMap.self]
    )

    assertMacroExpansion(
      #"""
      #keyPathMap(\.foo, \.aaa)
      """#,
      expandedSource: #"""
        {
            ($0.foo, $0.aaa)
        }
        """#,
      macros: ["keyPathMap": KeyPathMap.self]
    )

    assertMacroExpansion(
      #"""
      #keyPathMap(\State.foo, \.aaa)
      """#,
      expandedSource: #"""
        {
            ($0.foo, $0.aaa)
        }
        """#,
      macros: ["keyPathMap": KeyPathMap.self]
    )
  }

}

#endif
