import SwiftSyntax
import SwiftSyntaxBuilder

func isComputedProperty(from node: VariableDeclSyntax) -> Bool {
  if node.bindingSpecifier == "let" {
    return false
  }

  if node.bindings.count > 1 {
    // let a,b,c = 0
    // it's stored
    return false
  }

  if node.bindings.first?.accessorBlock == nil {
    return false
  }

  return true
}

func identifier(from node: VariableDeclSyntax) -> TokenSyntax {
  node.bindings.first!.cast(PatternBindingSyntax.self).pattern.cast(IdentifierPatternSyntax.self).identifier
}
