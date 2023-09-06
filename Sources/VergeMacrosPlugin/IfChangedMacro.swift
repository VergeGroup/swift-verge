import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct IfChangedMacro: Macro {

  public enum Error: Swift.Error {
    case foundNotKeyPathLiteral
    case faildToExpand
  }

}

extension IfChangedMacro: ExpressionMacro {
  public static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> SwiftSyntax.ExprSyntax {

    let onChangedClosure: ClosureExprSyntax

    if let _onChangedClosure: ClosureExprSyntax = node.trailingClosure {
      onChangedClosure = _onChangedClosure
    } else {

      let onChangedParameter = node.argumentList.last!
      let _onChangedClosure = onChangedParameter.expression.cast(ClosureExprSyntax.self)

      onChangedClosure = _onChangedClosure
    }

    let arguments = node.argumentList.filter { $0.label?.text != "onChanged" }

    let stateExpr = arguments.map { $0 }[0].cast(LabeledExprSyntax.self).expression.cast(
      DeclReferenceExprSyntax.self
    ).baseName

    let keyPahts = arguments.dropFirst()

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

    let conditions = names.map { arg in

      return (
        condition: """
            primitiveState\(arg.1) != previousState?\(arg.1)
            """,
        property: """
            let \(arg.0) = primitiveState\(arg.1)
            """,
        accessor: "primitiveState\(arg.1)"
      )
    }

    return
      ("""
      { () -> Void in
        let primitiveState = \(stateExpr).primitive
        let previousState = \(stateExpr).previous?.primitive

        guard \(raw: conditions.map { $0.condition }.joined(separator: " || ")) else {
          return
        }

        let _: Void = \(onChangedClosure)(\(raw: conditions.map { $0.accessor }.joined(separator: ", ")))
      }()
      """ as ExprSyntax)

  }

}
