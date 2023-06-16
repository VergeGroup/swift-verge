import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct _Macro: AttachedMacro {

}


@main
struct VergeMacroPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    DatabaseStateMacro.self,
  ]
}
