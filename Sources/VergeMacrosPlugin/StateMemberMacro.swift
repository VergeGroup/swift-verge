import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct StateMemberMacro {

}

extension StateMemberMacro: AccessorMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.AccessorDeclSyntax] {

    let id = identifier(from: declaration.cast(VariableDeclSyntax.self))

    return [
      """
      get {
        _$\(id)
      }
      """,
      """
      set {
        self.modifiedIdentifiers.insert("\(id)")        
        _$\(id) = newValue
      }
      """ ,
    ]
  }
}

public enum StateMemberMacroError: Error {
  case foundMultiBindingsStoredProperty
}
