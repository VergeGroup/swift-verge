import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import MacroTesting

#if canImport(VergeMacrosPlugin)
import VergeMacrosPlugin

final class DatabaseMacroTests: XCTestCase {

  override func invokeTest() {
    withMacroTesting(
      isRecording: false,
      macros: [ "NormalizedStorage": NormalizedStorageMacro.self]
    ) {
      super.invokeTest()
    }
  }

  func test_table() {

    assertMacro {
      #"""
      @NormalizedStorage
      struct MyDatabase {
        @TableAccessor
        let user: String
        @TableAccessor(hoge)
        let user: String
      }
      """#
    } expansion: {
      """
      struct MyDatabase {
        @TableAccessor
        let user: String
        @TableAccessor(hoge)
        let user: String

        @TableAccessor var _$user: String

        @TableAccessor(hoge) var _$user: String
      }

      extension MyDatabase {
        public static func compare(lhs: Self, rhs: Self) -> Bool {

          return true
        }
      }

      extension MyDatabase {

      }

      extension MyDatabase: NormalizedStorageType {
      }

      extension MyDatabase: Sendable {
      }

      extension MyDatabase: Equatable {
      }

      extension MyDatabase {
      }
      """
    }

  }

  func test_member() {
    
    assertMacro {
      #"""
      @NormalizedStorage
      struct MyDatabase {
        let user: String
      }
      """#
    } expansion: {
      """
      struct MyDatabase {
        let user: String

        var _$user: String
      }

      extension MyDatabase {
        public static func compare(lhs: Self, rhs: Self) -> Bool {

          return true
        }
      }

      extension MyDatabase {

      }

      extension MyDatabase: NormalizedStorageType {
      }

      extension MyDatabase: Sendable {
      }

      extension MyDatabase: Equatable {
      }

      extension MyDatabase {
      }
      """
    }


  }

}

#endif
