import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum WriterMacroError: Error {
  case foundMultiBindingsStoredProperty
  case propertyNeed
  case foundNotStructType
}

public struct WriterMacro {

}

extension WriterMacro: ExtensionMacro {

  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
    providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
    conformingTo protocols: [SwiftSyntax.TypeSyntax],
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {

    // Decode the expansion arguments.
    guard let structDecl = declaration.as(StructDeclSyntax.self) else {
      context.addDiagnostics(from: WriterMacroError.foundNotStructType, node: node)
      return []
    }

    let c = PropertyCollector(viewMode: .all)
    c.onError = { node, error in
      context.addDiagnostics(from: error, node: node)
    }
    c.walk(structDecl.memberBlock)

    let decls = c.properties.map { prop in

      switch prop {
      case .storedConstant(let b):
        """
        public var \(b.pattern): \(b.typeAnnotation!.type) {
          _read {
            yield pointer.pointee.\(b.pattern)
          }
        }
        """
      case .storedVaraiable(let b):
        """
        public var \(b.pattern): \(b.typeAnnotation!.type) {
          _read {
            yield pointer.pointee.\(b.pattern)
          }
          _modify {
            modifiedIdentifiers.insert("\(b.pattern)")
            yield &pointer.pointee.\(b.pattern)
          }
        }
        """
      case .computedGetOnly(let b, let accessorBlock):
        """
        public var \(b.pattern): \(b.typeAnnotation!.type)
        \(accessorBlock.trimmed { _ in true })
        """
      case .computed(let b, let accessorBlock):
        """
        public var \(b.pattern): \(b.typeAnnotation!.type)
        \(accessorBlock)
        """
      }

    }

    let modifyingStructDecl = """
      public struct Modifying /* want to be ~Copyable */ {

        public var modifiedIdentifiers: Set<String> = .init()

        private let pointer: UnsafeMutablePointer<ModifyingTarget>

        init(pointer: UnsafeMutablePointer<ModifyingTarget>) {
          self.pointer = pointer
        }

        \(raw: decls.joined(separator: "\n\n"))
      }
      """ as DeclSyntax

    let modifyingDecl =
      ("""
      extension \(type.trimmed): StateModifyingType {

        typealias ModifyingTarget = Self

        @discardableResult
        public static func modify(source: inout Self, modifier: (inout Modifying) throws -> Void) rethrows -> ModifyingResult {

          try withUnsafeMutablePointer(to: &source) { pointer in
            var modifying = Modifying(pointer: pointer)
            try modifier(&modifying)
            return ModifyingResult(modifiedIdentifiers: modifying.modifiedIdentifiers)
          }
        }

      \(modifyingStructDecl)
      }
      """ as DeclSyntax)

    return [
      modifyingDecl
        .formatted(
          using: .init(
            indentationWidth: .spaces(2),
            initialIndentation: [],
            viewMode: .fixedUp
          )
        )
        .cast(ExtensionDeclSyntax.self)
    ]

  }

}

final class PropertyCollector: SyntaxVisitor {

  enum Property {
    case storedConstant(PatternBindingListSyntax.Element)
    case storedVaraiable(PatternBindingListSyntax.Element)
    case computedGetOnly(PatternBindingListSyntax.Element, AccessorBlockSyntax)
    case computed(PatternBindingListSyntax.Element, AccessorBlockSyntax)
  }

  var properties: [Property] = []

  var onError: (any SyntaxProtocol, Error) -> Void = { _, _ in }

  override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    // walk only toplevel variables
    return .skipChildren
  }

  override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    return .skipChildren
  }

  override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {

    guard node.bindings.count == 1 else {
      // let a,b,c = 0
      // it's stored
      onError(node, WriterMacroError.foundMultiBindingsStoredProperty)
      return .skipChildren
    }

    guard let binding: PatternBindingListSyntax.Element = node.bindings.first else {
      fatalError()
    }

    guard let _ = binding.typeAnnotation else {
      onError(node, MacroError(message: "Requires a type annotation, such as `identifier: Type`"))
      return .skipChildren
    }

    let isConstant = node.bindingSpecifier == "let"

    if isConstant {
      properties.append(.storedConstant(binding))
      return .skipChildren
    }

    guard let accessorBlock = binding.accessorBlock else {
      properties.append(.storedVaraiable(binding))
      return .skipChildren
    }

    // computed property

    switch accessorBlock.accessors {
    case .accessors(let x):
      let hasSetter = x.contains {
        $0.accessorSpecifier == "set" || $0.accessorSpecifier == "_modify"
      }
      if hasSetter {
        properties.append(.computed(binding, accessorBlock))
      } else {
        properties.append(.computedGetOnly(binding, accessorBlock))
      }
    case .getter:
      properties.append(.computedGetOnly(binding, accessorBlock))
      return .skipChildren
    }

    return .skipChildren
  }

}

