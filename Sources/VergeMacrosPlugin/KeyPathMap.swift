import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct KeyPathMap: Macro {


}

extension KeyPathMap: ExpressionMacro {

  public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> SwiftSyntax.ExprSyntax {

    let keyPahts = node.argumentList

    let names: [(String, KeyPathComponentListSyntax)] = {
      return keyPahts.map { keyPath in
        let components = keyPath.cast(LabeledExprSyntax.self).expression.cast(
          KeyPathExprSyntax.self
        ).components

        let name =
        components
          .map {
            $0.cast(KeyPathComponentSyntax.self).component.cast(
              KeyPathPropertyComponentSyntax.self
            ).declName.baseName.description
          }
          .joined(separator: "_")

        return (name, components)
      }
    }()

    let line = names.map { arg in
      "$0\(arg.1)"
    }
    .joined(separator: ", ")

    return "{ (\(raw: line)) }"
  }

}
