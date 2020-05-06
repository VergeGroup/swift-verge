//: [Previous](@previous)

import Foundation

import UIKit
import VergeStore

struct State {
  var name: String = ""
  var age: Int = 0
}

class Store: VergeStore.Store<State, Never> {
  
  init() {
    super.init(initialState: State(), logger: nil)
  }
}

class ViewA: DemoUIView {
  
  // MARK: Components
  
  let nameLabel = UILabel()
  let ageLabel = UILabel()
  
  // MARK: State
  
  let store: Store
  private var cancellable: VergeAnyCancellable?
  
  // MARK: - Initializers
  
  init(store: Store) {
    self.store = store
    
    super.init()
    
    cancellable = store.sinkChanges { [weak self] (changes) in
      
      guard let self = self else { return }
      
      changes.ifChanged(\.name) { name in
        self.nameLabel.text = name
      }
      
      changes.ifChanged(\.age) { age in
        self.ageLabel.text = age.description
      }
      
    }
    
  }
  
  private func updateName() {
    store.commit {
      $0.name = "Muukii"
    }
  }
  
}
//: [Next](@next)
