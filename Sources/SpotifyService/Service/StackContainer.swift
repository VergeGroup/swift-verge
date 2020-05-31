
import Foundation

import Combine
import VergeStore

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
  
  public func receiveAuthCode(_ code: Auth.AuthCode) {
    
    guard case .loggedOut(let stack) = stack else {
      return
    }
    
    stack.service.fetchToken(code: code)
      .sink(receiveCompletion: { (completion) in
        switch completion {
        case .failure(let error):
          assertionFailure("\(error)")
        case .finished:
          break
        }
      }) { (auth) in

        self.store.commit {
          $0.loggedIn = .init(auth: auth)
        }
        self.stack = .loggedIn(.init(store: self.store))
    }
    .store(in: &subscriptions)

  }
}

