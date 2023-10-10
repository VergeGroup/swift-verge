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
          @TableAccessor
          let user: String
          @TableAccessor(hoge)
          let user: String

            @TableAccessor var _$user: String

            @TableAccessor(hoge) var _$user: String
        }

        extension MyDatabase {
          static func compare(lhs: Self, rhs: Self) -> Bool {

            return true
          }
        }

        extension MyDatabase {

        }

        extension MyDatabase: NormalizedStorageType {
        }

        extension MyDatabase: Equatable {
        }

        extension MyDatabase {
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
          let user: String

            var _$user: String
        }

        extension MyDatabase {
          static func compare(lhs: Self, rhs: Self) -> Bool {

            return true
          }
        }

        extension MyDatabase {

        }

        extension MyDatabase: NormalizedStorageType {
        }

        extension MyDatabase: Equatable {
        }

        extension MyDatabase {
        }
        """#,
      macros: macros
    )


  }

}

#endif
