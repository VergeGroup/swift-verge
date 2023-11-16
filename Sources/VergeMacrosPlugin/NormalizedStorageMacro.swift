import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct NormalizedStorageMacro: Macro {

}

extension NormalizedStorageMacro: ExtensionMacro {

  struct Table {
    let node: VariableDeclSyntax
    let typeAnnotation: TypeAnnotationSyntax
  }

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

    let tables: [Table] = structDecl.memberBlock.members
      .compactMap {
        $0.decl.as(VariableDeclSyntax.self)
      }
      .filter {
        $0.attributes.contains {
          switch $0 {
          case .attribute(let attribute):
            return attribute.attributeName.description == "Table"
          case .ifConfigDecl:
            return false
          }
        }
      }
      .filter {
        guard $0.bindings.count == 1 else {
          context.addDiagnostics(
            from: MacroError(message: "@Table macro does not support multiple binding, such as `let a, b = 0`"),
            node: $0
          )
          return false
        }
        guard $0.bindings.first!.typeAnnotation != nil else {
          context.addDiagnostics(
            from: MacroError(message: "@Table macro requires a type annotation, such as `identifier: Type`"),
            node: $0
          )
          return false
        }
        return true
      }
      .map {
        return Table.init(node: $0, typeAnnotation: $0.bindings.first!.typeAnnotation!)
      }

    let comparatorExtension = {

      let markerComparators = tables.map { member in
        member.node.bindings.first!.pattern.trimmed
      }
      .map { name in
        "guard lhs.\(name).updatedMarker == rhs.\(name).updatedMarker else { return lhs == rhs }"
      }

      return ("""
      extension \(structDecl.name.trimmed) {
        public static func compare(lhs: Self, rhs: Self) -> Bool {
          \(raw: markerComparators.joined(separator: "\n"))
          return true
        }
      }
      """ as DeclSyntax).cast(ExtensionDeclSyntax.self)

    }()

    let selectorsExtension = {

      let decls = tables.map { member in
      """
      public struct TableSelector_\(member.node.bindings.first!.pattern.trimmed): TableSelector {
        public typealias _Table = \(member.node.bindings.first!.typeAnnotation!.type.description)
        public typealias Entity = _Table.Entity
        public typealias Storage = \(structDecl.name.trimmed)

        public let identifier: String = "\(member.node.bindings.first!.pattern.trimmed)"

        public func select(storage: Storage) -> _Table {
          storage.\(member.node.bindings.first!.pattern.trimmed)
        }

        public init() {}
      }
      """
      }

      return ("""
      extension \(structDecl.name.trimmed) {
        \(raw: decls.joined(separator: "\n"))
      }
      """ as DeclSyntax).cast(ExtensionDeclSyntax.self)
    }()
    
    return [
      comparatorExtension,
      selectorsExtension,
      ("""
      extension \(structDecl.name.trimmed): NormalizedStorageType {}
      """ as DeclSyntax).cast(ExtensionDeclSyntax.self),
      ("""
      extension \(structDecl.name.trimmed): Sendable {}
      """ as DeclSyntax).cast(ExtensionDeclSyntax.self),
      ("""
      extension \(structDecl.name.trimmed): Equatable {}
      """ as DeclSyntax).cast(ExtensionDeclSyntax.self),
      ("""
      extension \(structDecl.name.trimmed) {
      }
      """ as DeclSyntax).cast(ExtensionDeclSyntax.self)
    ]
  }

}

#if false
/// Add @Table
extension NormalizedStorageMacro: MemberAttributeMacro {

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
        "@Table"
      ]

    }

    return []

  }

}

#endif

/// Add member
extension NormalizedStorageMacro: MemberMacro {

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
