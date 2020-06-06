
import Foundation

import Combine

import SpotifyService

final class Session: ObservableObject {
  
  var objectWillChange: ObservableObjectPublisher = .init()
      
  let stack: BackendStack
  
  private var subscriptions = Set<AnyCancellable>()
  
  init() {
    
    self.stack = .init(identifier: "Container.Demo")
    
    stack.$stack.sink { [weak self] _ in
      self?.objectWillChange.send()
    }
    .store(in: &subscriptions)
        
  }
  
  func receiveAuthCode(_ code: Auth.AuthCode) {
    stack.receiveAuthCode(code)
  }
}
