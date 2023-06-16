import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DatabaseStateMacro {

}

extension DatabaseStateMacro: ConformanceMacro {
  public static func expansion<Declaration, Context>(
    of node: SwiftSyntax.AttributeSyntax,
    providingConformancesOf declaration: Declaration,
    in context: Context
  ) throws -> [(SwiftSyntax.TypeSyntax, SwiftSyntax.GenericWhereClauseSyntax?)]
  where Declaration: SwiftSyntax.DeclGroupSyntax, Context: SwiftSyntaxMacros.MacroExpansionContext {
    
    // Decode the expansion arguments.
    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
//      context.diagnose(OptionSetMacroDiagnostic.requiresStruct.diagnose(at: decl))
      return []
    }

    // If there is an explicit conformance to OptionSet already, don't add one.
    if let inheritedTypes = structDecl.inheritanceClause?.inheritedTypeCollection,
       inheritedTypes.contains(where: { inherited in inherited.typeName.trimmedDescription == "DatabaseType" }) {
      return []
    }
    
    return [("DatabaseType", nil)]
  }

}

extension DatabaseStateMacro: MemberMacro {

  public static func expansion<Declaration, Context>(
    of node: SwiftSyntax.AttributeSyntax,
    providingMembersOf declaration: Declaration,
    in context: Context
  ) throws -> [SwiftSyntax.DeclSyntax]
  where Declaration: SwiftSyntax.DeclGroupSyntax, Context: SwiftSyntaxMacros.MacroExpansionContext {

    return [
      "var _backingStorage: BackingStorage = .init()"
    ]

  }
}
