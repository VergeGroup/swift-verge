import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DatabaseMacro: Macro {

}

extension DatabaseMacro: ExtensionMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
    providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
    conformingTo protocols: [SwiftSyntax.TypeSyntax],
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {

    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      fatalError()
    }

    let tableMembers = structDecl.memberBlock.members
      .compactMap {
        $0.decl.as(VariableDeclSyntax.self)
      }
      .filter {
        guard $0.bindings.count == 1 else {
          return false
        }
        guard $0.bindings.first!.typeAnnotation != nil else {
          return false
        }
        return true
      }
      .filter {
        $0.attributes.contains {
          switch $0 {
          case .attribute(let attribute):
            return attribute.attributeName.description == "TableAccessor"
          case .ifConfigDecl:
            return false
          }
        }
      }

    let decls = tableMembers.map { member in
      """
      struct \(member.bindings.first!.pattern.trimmed): TableSelector {
          typealias _Table = \(member.bindings.first!.typeAnnotation!.type.description)
          typealias Entity = _Table.Entity
          typealias Storage = \(structDecl.name.trimmed)

          func select(storage: Storage) -> Table<Entity> {
            storage.\(member.bindings.first!.pattern.trimmed)
          }

      }
      """
    }

    let ext = ("""
      extension \(structDecl.name.trimmed) {
        \(raw: decls.joined(separator: "\n"))
      }
      """ as DeclSyntax).cast(ExtensionDeclSyntax.self)


    return [
      ext,
      ("""
      extension \(structDecl.name.trimmed): NormalizedStorageType {}
      """ as DeclSyntax).cast(ExtensionDeclSyntax.self),
      ("""
      extension \(structDecl.name.trimmed): Equatable {}
      """ as DeclSyntax).cast(ExtensionDeclSyntax.self),
      ("""
      extension \(structDecl.name.trimmed) {
        typealias BBB = String
        struct Context {}
      }
      """ as DeclSyntax).cast(ExtensionDeclSyntax.self)
    ]
  }

}

/// Add @Table
extension DatabaseMacro: MemberAttributeMacro {

  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
    providingAttributesFor member: some SwiftSyntax.DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.AttributeSyntax] {

    /**
     Add macro attribute to member only Table type.
     */

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

//            if isComputedProperty(from: variableDecl) {
//              return []
//            }

      return [
        "@TableAccessor"
      ]

    }

    return []

  }

}

/// Add member
extension DatabaseMacro: MemberMacro {

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

  static func makeVariableFromConstant(_ node: VariableDeclSyntax) -> VariableDeclSyntax {
    var modified = node
    modified.bindingSpecifier = "var"
    return modified
  }

  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.DeclSyntax] {


    let v = StoredPropertyCollector(viewMode: .fixedUp)
    v.onFoundMultipleBindings = {
      context.addDiagnostics(from: MacroError(message: "Cannot use multiple bindings"), node: node)
    }
    v.walk(declaration.memberBlock)

    let storageMembers = v.storedProperties
      .map(makeVariableFromConstant)
      .map {

      let rename = RenamingVisitor()
      let renamed = rename.visit($0)

      return renamed
    }

    return storageMembers

  }

}

public struct DatabaseTableMacro: Macro {

}

extension DatabaseTableMacro: AccessorMacro {
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
      """
      get {
        _$\(id)
      }
      """,
      """
      set {
        _$\(id) = newValue
      }
      """ ,
    ]
  }

}

public struct DatabaseIndexMacro: Macro {

}
