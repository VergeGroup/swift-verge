import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum StateMacroError: Error {
  case foundMultiBindingsStoredProperty
  case foundNotStructType
}

public struct StateMacro {

}

extension StateMacro: ExtensionMacro {
  public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol, conformingTo protocols: [SwiftSyntax.TypeSyntax], in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {

    // Decode the expansion arguments.
    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      context.addDiagnostics(from: StateMacroError.foundNotStructType, node: node)
      return []
    }

    if let inheritedTypes = structDecl.inheritanceClause?.inheritedTypes,
       inheritedTypes.contains(where: { inherited in
         inherited.type.trimmedDescription == "StateType"
       })
    {
      return []
    }

    let stateTypeExtension: DeclSyntax =
      """
      extension \(type.trimmed): StateType {}
      """

    guard let extensionDecl = stateTypeExtension.as(ExtensionDeclSyntax.self) else {
      return []
    }
    
    return [extensionDecl]

  }

}

extension StateMacro: MemberAttributeMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
    providingAttributesFor member: some SwiftSyntax.DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.AttributeSyntax] {

    if let variableDecl = member.as(VariableDeclSyntax.self) {

      let isGenerated = variableDecl
        .bindings
        .allSatisfy {
          $0.cast(PatternBindingSyntax.self).pattern.cast(IdentifierPatternSyntax.self).identifier
            .description.hasPrefix("_$")
        }

      if isGenerated {
        return []
      }

      if isComputedProperty(from: variableDecl) {
        return []
      }

      return [
        "@StateMember"
      ]

    }

    return []

  }

}

extension StateMacro: MemberMacro {

  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.DeclSyntax] {

    let v = StoredPropertyCollector(viewMode: .fixedUp)
    v.onFoundMultipleBindings = {
      context.addDiagnostics(from: StateMacroError.foundMultiBindingsStoredProperty, node: node)
    }
    v.walk(declaration.memberBlock)

    let storageMembers = v.storedProperties.map {

      let rename = RenamingVisitor()
      let renamed = rename.visit($0)

      return renamed
    }

    return storageMembers + [
      """
      public var accessedIdentifiers: Set<String> = .init()
      public var modifiedIdentifiers: Set<String> = .init()
      """,
    ]
  }
}

final class RenamingVisitor: SyntaxRewriter {

  init() {}

  override func visit(_ node: IdentifierPatternSyntax) -> PatternSyntax {
    return "_$\(node.identifier)"
  }

  override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {

    // TODO: make variable private
    return super.visit(node)
  }
}

final class StoredPropertyCollector: SyntaxVisitor {

  var storedProperties: [VariableDeclSyntax] = []

  var onFoundMultipleBindings: () -> Void = {}

  override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {

    if node.bindingSpecifier == "let" {
      storedProperties.append(node)
      return super.visit(node)
    }

    if node.bindings.count > 1 {
      // let a,b,c = 0
      // it's stored
      onFoundMultipleBindings()
      return super.visit(node)
    }

    if node.bindings.first?.accessorBlock == nil {
      storedProperties.append(node)
      return super.visit(node)
    }

    // computed property

    return .visitChildren
  }

}
