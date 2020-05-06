import UIKit

class ViewA: DemoUIView {
  
  // MARK: Components
  
  let nameLabel = UILabel()
  
  // MARK: State
  
  var name: String = "" {
    didSet {
      self.nameLabel.text = name
    }
  }
         
}

//: [Next](@next)

