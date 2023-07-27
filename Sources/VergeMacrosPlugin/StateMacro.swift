import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct StateMacro {

}

extension StateMacro: MemberMacro {

  public static func expansion<Declaration, Context>(
    of node: SwiftSyntax.AttributeSyntax,
    providingMembersOf declaration: Declaration,
    in context: Context
  ) throws -> [SwiftSyntax.DeclSyntax]
  where Declaration: SwiftSyntax.DeclGroupSyntax, Context: SwiftSyntaxMacros.MacroExpansionContext {

  }

}
