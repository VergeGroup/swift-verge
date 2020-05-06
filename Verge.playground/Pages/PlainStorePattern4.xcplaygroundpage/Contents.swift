//: [Previous](@previous)

import Foundation

import UIKit

struct State {
  var name: String = ""
  var age: Int = 0
}

class Store {
  
  // State type should be struct type to call didSet
  var state: State {
    didSet {
      // notify a update to subscribers
    }
  }
  
  init(_ state: State) {
    self.state = state
  }
  
  func onDidUpdate(_ closure: @escaping (State) -> Void) {
    // implement to notfy updates
  }
}

class ViewA: DemoUIView {
    
  // MARK: Components
  
  let nameLabel = UILabel()
  let ageLabel = UILabel()
      
  // MARK: State
  
  let store: Store
  
  // MARK: - Initializers
  
  init(store: Store) {
    self.store = store
    
    super.init()
    
    store.onDidUpdate { [weak self] state in
      
      guard let self = self else { return }
      
      self.ageLabel.text = state.age.description
      self.nameLabel.text = state.name
    }
  }
  
  private func updateName() {
    store.state.name = "Muukii"
    // then, nameLabel updates to "Muukii" by store.onDidUpdate.
  }
  
}

class ViewB: DemoUIView {
  
  // MARK: Components
  
  let nameLabel = UILabel()
  let ageLabel = UILabel()
  
  // MARK: State
  
  let store: Store
  
  // MARK: - Initializers
  
  init(store: Store) {
    self.store = store
    
    super.init()
    
    store.onDidUpdate { [weak self] state in
      
      guard let self = self else { return }
      
      self.ageLabel.text = state.age.description
      self.nameLabel.text = state.name
    }
  }
    
}
//: [Next](@next)
