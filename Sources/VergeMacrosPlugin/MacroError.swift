
import SwiftDiagnostics

public struct MacroError: Error, DiagnosticMessage {
  
  public var message: String
  
  public var diagnosticID: SwiftDiagnostics.MessageID {
    .init(domain: "Verge", id: "MacroError")
  }

  public var severity: SwiftDiagnostics.DiagnosticSeverity = .error

  init(message: String) {
    self.message = message
  }
}
