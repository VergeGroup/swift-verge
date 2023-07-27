
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct IfChangedMacro: ExpressionMacro {

  public enum Error: Swift.Error {
    case foundNotKeyPathLiteral
    case faildToExpand

  }

  public static func expansion(
    of node: some SwiftSyntax.FreestandingMacroExpansionSyntax,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> SwiftSyntax.ExprSyntax {

    let arguments = node.argumentList

    // validation
    do {

      let passed = arguments.allSatisfy { arg in
        if arg.as(TupleExprElementSyntax.self)?.expression.as(KeyPathExprSyntax.self) != nil {
          return true
        }
        context.addDiagnostics(from: Error.foundNotKeyPathLiteral, node: arg)
        return false
      }

      guard passed else {
        throw Error.faildToExpand
      }

    }


    let tupleExpression = TupleExprElementListSyntax {
      for arg in arguments {
        let components = arg.cast(TupleExprElementSyntax.self).expression.cast(KeyPathExprSyntax.self).components
        let element = TupleExprElementSyntax.init(expression: ExprSyntax.init(stringLiteral: "$0\(components)"))
        element
      }
    }

    return "{ (\(tupleExpression)) }"
  }

}
