
import Foundation

import Combine
import VergeStore
import CombineExt
import Moya

public enum BackendError: Swift.Error {
  case unknown
}

public final class BackendStack: ObservableObject {
  
  public enum Stack {
    case loggedIn(LoggedInStack)
    case loggedOut(LoggedOutStack)
  }
  
  @Published public private(set) var stack: Stack
  
  private var subscriptions = Set<AnyCancellable>()
  public let store: BackendStore
  
  public init(auth: AuthResponse?) {

    self.store = .init(initialState: .init(), logger: DefaultStoreLogger.shared)
    
    switch auth {
    case .none:
      self.stack = .loggedOut(.init(store: store))
    case .some(let auth):
      store.commit {
        $0.loggedIn = .init(auth: auth)
      }
      self.stack = .loggedIn(.init(store: store))
    }
    
  }
  
  public func receiveAuthCode(_ code: Auth.AuthCode) -> Future<Void, Error> {
    
    guard case .loggedOut(let loggedOutStack) = stack else {
      return .failure(BackendError.unknown)
    }

    loggedOutStack.service.commit {
      $0.isLoginProcessing = true
    }

    return loggedOutStack.service.fetchToken(code: code)
      .map { auth -> LoggedInStack in
        self.store.commit {
          $0.loggedIn = .init(auth: auth)
        }
        let loggedInStack = LoggedInStack(store: self.store)
        return loggedInStack
    }
    .mapError { $0 as Error }
    .flatMap { stack in
      stack.service.fetchMe()
        .mapError { $0 as Error }
        .map { _ in stack }
    }
    .handleEvents(
      receiveOutput: { stack in
        self.stack = .loggedIn(stack)
    }, receiveCompletion: { comp in
      loggedOutStack.service.commit {
        $0.isLoginProcessing = false
      }
    })
      .map { _ in }
      .start()

  }
}

