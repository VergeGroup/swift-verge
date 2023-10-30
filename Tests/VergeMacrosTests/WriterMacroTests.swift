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

          typealias ModifyingTarget = Self

          @discardableResult
          public static func modify(source: inout Self, modifier: (inout Modifying) throws -> Void) rethrows -> ModifyingResult {

            try withUnsafeMutablePointer(to: &source) { pointer in
              var modifying = Modifying(pointer: pointer)
              try modifier(&modifying)
              return ModifyingResult(modifiedIdentifiers: modifying.modifiedIdentifiers)
            }
          }

          public struct Modifying /* want to be ~Copyable */ {

            public var modifiedIdentifiers: Set<String> = .init()

            private let pointer: UnsafeMutablePointer<ModifyingTarget>

            init(pointer: UnsafeMutablePointer<ModifyingTarget>) {
              self.pointer = pointer
            }

            public var constant_has_initial_value: Int  {
            _read {
              yield pointer.pointee.constant_has_initial_value
            }
            _modify {
              modifiedIdentifiers.insert("constant_has_initial_value")
              yield &pointer.pointee.constant_has_initial_value
            }
          }

          public var variable_has_initial_value: String  {
            _read {
              yield pointer.pointee.variable_has_initial_value
            }
            _modify {
              modifiedIdentifiers.insert("variable_has_initial_value")
              yield &pointer.pointee.variable_has_initial_value
            }
          }

          public var constant_no_initial_value: Int {
            _read {
              yield pointer.pointee.constant_no_initial_value
            }
            _modify {
              modifiedIdentifiers.insert("constant_no_initial_value")
              yield &pointer.pointee.constant_no_initial_value
            }
          }

          public var variable_no_initial_value: String {
            _read {
              yield pointer.pointee.variable_no_initial_value
            }
            _modify {
              modifiedIdentifiers.insert("variable_no_initial_value")
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
              modifiedIdentifiers.insert("stored_property_wrapper")
              yield &pointer.pointee.stored_property_wrapper
            }
          }
          }ss
        
        }
        """#,
      macros: ["Writing": WriterMacro.self]
    )

  }

}

#endif
