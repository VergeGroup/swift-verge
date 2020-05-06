//: [Previous](@previous)
import UIKit

class ViewA: DemoUIView {
  
  // MARK: Components
  
  let nameLabel = UILabel()
  let ageLabel = UILabel()
  
  // MARK: State
  
  struct State {
    var name: String = ""
    var age: Int = 0
  }
  
  var state: State {
    didSet {
      self.nameLabel.text = state.name
      self.ageLabel.text = state.age.description
    }
  }
    
}
//: [Next](@next)
