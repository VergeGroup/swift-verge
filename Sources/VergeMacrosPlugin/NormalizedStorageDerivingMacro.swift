import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct NormalizedStorageDerivingMacro: Macro {

}

extension NormalizedStorageDerivingMacro: ExtensionMacro {

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
            from: MacroError(
              message: "@Table macro does not support multiple binding, such as `let a, b = 0`"
            ),
            node: $0
          )
          return false
        }
        guard $0.bindings.first!.typeAnnotation != nil else {
          context.addDiagnostics(
            from: MacroError(
              message: "@Table macro requires a type annotation, such as `identifier: Type`"
            ),
            node: $0
          )
          return false
        }
        return true
      }
      .map {
        return Table.init(node: $0, typeAnnotation: $0.bindings.first!.typeAnnotation!)
      }

    let tablesExtension = {

      let members = tables.map { member in

        let typedSelectorName = "TableSelector_\(member.node.bindings.first!.pattern.trimmed)"

        return """
          public var \(member.node.bindings.first!.pattern.trimmed): NormalizedStorageTablePath<Store, _StorageSelector, \(typedSelectorName)> {
            self.table(\(typedSelectorName)())
          }
          """
      }

      return
        (#"""
      extension \#(structDecl.name.trimmed): NormalizedStorageDerivingType {

        /**
         The entrypoint to make Derived object from the storage
         */
        public struct NormalizedStoragePath<
          Store: DerivedMaking & AnyObject,
          _StorageSelector: StorageSelector
        >: NoromalizedStoragePathType where Store.State == _StorageSelector.Source, _StorageSelector.Storage == \#(structDecl.name.trimmed) {

          public typealias Storage = _StorageSelector.Storage
          unowned let store: Store
          let storageSelector: _StorageSelector

          public init(
            store: Store,
            storageSelector: _StorageSelector
          ) {

            self.store = store
            self.storageSelector = storageSelector
          }

          public func table<Selector: TableSelector>(
            _ selector: Selector
          ) -> NormalizedStorageTablePath<Store, _StorageSelector, Selector> where Selector.Storage == _StorageSelector.Storage {
            return .init(
              store: store,
              storageSelector: storageSelector,
              tableSelector: selector
            )
          }

      \#(raw: members.joined(separator: "\n"))

          /**
           Make a new Derived of a composed object from the storage.
           This is an effective way to resolving relationship entities into a single object. it's like SQLite's view.

           ```
           store.normalizedStorage(.keyPath(\.db)).derived {
             MyComposed(
               book: $0.book.find(...)
               author: $0.author.find(...)
             )
           }
           ```

           This Derived makes a new composed object if the storage has updated.
           There is not filters for entity tables so that Derived possibly makes a new object if not related entity has updated.
           */
          public func derived<Composed: Equatable>(query: @escaping @Sendable (Self.Storage) -> Composed) -> Derived<Composed> {
            return store.derived(QueryPipeline(storageSelector: storageSelector, query: query), queue: .passthrough)
          }
        }
      }
      """# as DeclSyntax)
    }()

    let superextensions = try NormalizedStorageMacro.expansion(
      of: node,
      attachedTo: declaration,
      providingExtensionsOf: type,
      conformingTo: protocols,
      in: context
    )

    return
      ([
        tablesExtension,
      ] as [SyntaxProtocol])
      .map {
        $0.formatted(using: .init(indentationWidth: .spaces(2)))
          .cast(ExtensionDeclSyntax.self)
      } + superextensions
  }

}

#if false
/// Add @Table
extension NormalizedStorageDerivingMacro: MemberAttributeMacro {

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
extension NormalizedStorageDerivingMacro: MemberMacro {

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
