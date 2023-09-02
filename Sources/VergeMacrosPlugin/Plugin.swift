import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct Plugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    DatabaseStateMacro.self,
    IfChangedMacro.self,

    NormalizedStorageMacro.self,
    TableMacro.self,
    DatabaseIndexMacro.self
  ]
}
