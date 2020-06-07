
import Foundation
import Combine

public final class BackendStackManager: ObservableObject {

  public static let shared = BackendStackManager()

  private init() {}

  @Published public var current: BackendStack?

  private let userDefaults = UserDefaults.standard

  public func resume() -> BackendStack? {

    guard let identifier = currentIdentifier() else {
      return nil
    }

    return makeAndActivate(identifier: identifier)
  }

  @discardableResult
  public func makeAndActivate() -> BackendStack {
    makeAndActivate(identifier: Int(Date().timeIntervalSince1970).description)
  }

  func makeAndActivate(identifier: String) -> BackendStack {
    setCurrentIdentifier(identifier)
    let stack = BackendStack(identifier: identifier)
    current = stack
    return stack
  }

  private func setCurrentIdentifier(_ identifier: String?) {
    userDefaults.set(identifier, forKey: "current_identifier")
  }

  private func currentIdentifier() -> String? {
    userDefaults.string(forKey: "current_identifier")
  }

  public func deactivate(stack: LoggedInStack) {

    let _equalsStack = current.map { v -> Bool in
      switch v.stack {
      case .loggedIn(let loggedInStack):
        return loggedInStack === stack
      case .loggedOut(_):
        return true
      }
    }

    guard let equalsStack = _equalsStack else {
      assertionFailure("no current active stack was found")
      return
    }

    guard equalsStack else {
      assertionFailure("the stack attempted to logout is not current active.")
      return
    }

    setCurrentIdentifier(nil)

    current = nil

    makeAndActivate()
  }

}
