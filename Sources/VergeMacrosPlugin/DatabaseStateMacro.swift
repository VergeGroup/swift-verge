import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DatabaseStateMacro {

}

extension DatabaseStateMacro: ExtensionMacro {

  public static func expansion(of node: AttributeSyntax, attachedTo declaration: some DeclGroupSyntax, providingExtensionsOf type: some TypeSyntaxProtocol, conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax] {

    // Decode the expansion arguments.
    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      //      context.diagnose(OptionSetMacroDiagnostic.requiresStruct.diagnose(at: decl))
      return []
    }

    // If there is an explicit conformance to OptionSet already, don't add one.
    if let inheritedTypes = structDecl.inheritanceClause?.inheritedTypes,
       inheritedTypes.contains(where: { inherited in inherited.type.trimmedDescription == "DatabaseType" }) {
      return []
    }

    let stateTypeExtension: DeclSyntax =
      """
      extension \(type.trimmed): DatabaseType {}
      """

    guard let extensionDecl = stateTypeExtension.as(ExtensionDeclSyntax.self) else {
      return []
    }

    return [extensionDecl]

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
      "var _backingStorage: DatabaseStorage<Schema, Indexes> = .init()"
    ]

  }
}
