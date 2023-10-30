import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(VergeMacrosPlugin)
import VergeMacrosPlugin

final class WriterMacroTests: XCTestCase {

  func test_() {

    assertMacroExpansion(
      #"""
      @Writing
      struct MyState {

        let constant_has_initial_value: Int = 0

        var variable_has_initial_value: String = ""

        let constant_no_initial_value: Int

        var variable_no_initial_value: String

        var computed_read_only: Int {
          constant_has_initial_value
        }

        var computed_read_only2: Int {
          get {
            constant_has_initial_value
          }
        }

        var computed_readwrite: String {
          get {
            variable_no_initial_value
          }
          set {
            variable_no_initial_value = newValue
          }
        }

        @MyPropertyWrapper
        var stored_property_wrapper: String = ""

      }
      """#,
      expandedSource: #"""
        struct MyState {

          let constant_has_initial_value: Int = 0

          var variable_has_initial_value: String = ""

          let constant_no_initial_value: Int

          var variable_no_initial_value: String

          var computed_read_only: Int {
            constant_has_initial_value
          }

          var computed_read_only2: Int {
            get {
              constant_has_initial_value
            }
          }

          var computed_readwrite: String {
            get {
              variable_no_initial_value
            }
            set {
              variable_no_initial_value = newValue
            }
          }

          @MyPropertyWrapper
          var stored_property_wrapper: String = ""

        }

        extension MyState: StateModifyingType {
        }

        extension MyState {

          public struct Modifying: MyStateModifyingType {

            private let pointer: UnsafeMutablePointer<MyState >

            init(pointer: UnsafeMutablePointer<MyState >) {
              self.pointer = pointer
            }

            public var constant_has_initial_value: Int  {
              _read {
                yield pointer.pointee.constant_has_initial_value
              }
              _modify {
                yield &pointer.pointee.constant_has_initial_value
              }
            }
            public var variable_has_initial_value: String  {
              _read {
                yield pointer.pointee.variable_has_initial_value
              }
              _modify {
                yield &pointer.pointee.variable_has_initial_value
              }
            }
            public var constant_no_initial_value: Int {
              _read {
                yield pointer.pointee.constant_no_initial_value
              }
              _modify {
                yield &pointer.pointee.constant_no_initial_value
              }
            }
            public var variable_no_initial_value: String {
              _read {
                yield pointer.pointee.variable_no_initial_value
              }
              _modify {
                yield &pointer.pointee.variable_no_initial_value
              }
            }
            public var computed_read_only: Int  {
              _read {
                yield pointer.pointee.computed_read_only
              }
            }
            public var computed_read_only2: Int  {
              _read {
                yield pointer.pointee.computed_read_only2
              }
            }
            public var computed_readwrite: String  {
              _read {
                yield pointer.pointee.computed_readwrite
              }
            }
            public var stored_property_wrapper: String  {
              _read {
                yield pointer.pointee.stored_property_wrapper
              }
              _modify {
                yield &pointer.pointee.stored_property_wrapper
              }
            }
          }
        }
        """#,
      macros: ["Writing": WriterMacro.self]
    )

  }

}

#endif
