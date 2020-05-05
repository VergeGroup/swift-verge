//
//  Sample.swift
//  VergeStoreTests
//
//  Created by muukii on 2020/04/18.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation
import UIKit

import VergeStore

enum Sample {
  
  struct State: StateType {
    var name: String = ""
    var age: Int = 0
  }
  
  enum Activity {
    case somethingHappen
  }
  
  class ViewController: UIViewController {
    
    private let nameLabel: UILabel = .init()
    private let ageLabel: UILabel = .init()
    
    let store = Store<State, Activity>(initialState: .init(), logger: nil)
    
    var subscriptions = Set<VergeAnyCancellable>()
    
    override func viewDidLoad() {
      super.viewDidLoad()
      
      store.sinkChanges { [weak self] (changes) in
        self?.update(changes: changes)
      }
      .store(in: &subscriptions)
    
    }
    
    private func update(changes: Changes<State>) {
      
      changes.ifChanged(\.name) { (name) in
        nameLabel.text = name
      }
      
      changes.ifChanged(\.age) { (age) in
        ageLabel.text = age.description
      }
      
    }
    
  }
}
