//: [Previous](@previous)

import UIKit

class ViewA: DemoUIView {
  
  // MARK: Components
  
  let nameLabel = UILabel()
  let ageLabel = UILabel()
  
  // MARK: State
  
  var name: String = "" {
    didSet {
      self.nameLabel.text = name
    }
  }
  
  var age: Int = 0 {
    didSet {
      self.ageLabel.text = name
    }
  }
  
}

//: [Next](@next)
