import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct TableMacro: Macro {

}

extension TableMacro: PeerMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
    return []
  }

}

extension TableMacro: AccessorMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.AccessorDeclSyntax] {

    func identifier(from node: VariableDeclSyntax) -> TokenSyntax {
      node.bindings.first!.cast(PatternBindingSyntax.self).pattern.cast(IdentifierPatternSyntax.self).identifier
    }

    let id = identifier(from: declaration.cast(VariableDeclSyntax.self))

    return [
      //      """
      //      get {
      //        _$\(id)
      //      }
      //      """,
      //      """
      //      set {
      //        _$\(id) = newValue
      //      }
      //      """ ,
    ]
  }

}
