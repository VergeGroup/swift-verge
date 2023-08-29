import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(VergeMacrosPlugin)
import VergeMacrosPlugin

fileprivate let macros: [String : Macro.Type] = [
  "Database": DatabaseMacro.self
]

final class DatabaseMacroTests: XCTestCase {

  func test_table() {

    assertMacroExpansion(
      #"""
      @Database
      struct MyDatabase {
        let user: String
      }
      """#,
      expandedSource: #"""
        struct MyDatabase {
          @Table
          let user: String
        }
        """#,
      macros: macros
    )

  }

  func test_member() {
    
    assertMacroExpansion(
      #"""
      @Database
      struct MyDatabase {
        let user: String
      }
      """#,
      expandedSource: #"""
        struct MyDatabase {
          @Table
          let user: String
        }
        """#,
      macros: macros
    )


  }

}

#endif
