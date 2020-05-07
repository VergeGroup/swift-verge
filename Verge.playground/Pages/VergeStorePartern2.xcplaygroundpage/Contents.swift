//: [Previous](@previous)
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
  
  func incrementAge() {
    commit {
      $0.age += 1
    }
  }
  
  func updateName(_ name: String) {
    commit {
      $0.name = name
    }
  }
}

class ViewA: DemoUIView {
    
  let nameLabel = UILabel()
  let ageLabel = UILabel()
      
  let store: Store
  private var cancellable: VergeAnyCancellable?
      
  init(store: Store) {
    self.store = store
    
    super.init()
    
    cancellable = store.sinkChanges { [weak self] (changes) in
      self?.updateUI(changes: changes)
    }
    
  }
  
  private func updateUI(changes: Changes<State>) {
    
    changes.ifChanged(\.name) { name in
      nameLabel.text = name
    }
    
    changes.ifChanged(\.age) { age in
      ageLabel.text = age.description
    }
  }
    
}

//: [Next](@next)
