import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(VergeMacrosPlugin)
import VergeMacrosPlugin

fileprivate let macros: [String : Macro.Type] = [
  "NormalizedStorage": NormalizedStorageMacro.self
]

final class DatabaseMacroTests: XCTestCase {

  func test_table() {

    assertMacroExpansion(
      #"""
      @NormalizedStorage
      struct MyDatabase {
        @TableAccessor
        let user: String
       @TableAccessor(hoge)
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
      @NormalizedStorage
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
