
import Foundation

import Combine

import SpotifyService

final class Session: ObservableObject {
  
  var objectWillChange: ObservableObjectPublisher = .init()
      
  let stack: BackendStack
  
  private var subscriptions = Set<AnyCancellable>()
  
  init(stack: BackendStack) {
    
    self.stack = stack
    
    stack.$stack.sink { [weak self] _ in
      self?.objectWillChange.send()
    }
    .store(in: &subscriptions)
        
  }

  deinit {
    Log.debug("deinit \(self)")
  }
  
  func receiveAuthCode(_ code: Auth.AuthCode) {
    stack.receiveAuthCode(code)
  }
}
