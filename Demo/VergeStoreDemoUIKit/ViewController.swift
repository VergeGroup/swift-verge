//
//  ViewController.swift
//  VergeStoreDemoUIKit
//
//  Created by muukii on 2020/01/14.
//  Copyright © 2020 muukii. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {
  
  let viewModel = CompositionRoot.demo.viewModel
    
  @IBOutlet weak var label: UILabel!
  
  private var cancellables = Set<VergeAnyCancellable>()
  
  override func viewDidLoad() {
    super.viewDidLoad()

    viewModel.sinkActivity { [weak self] activity in

      guard let self = self else { return }

      switch activity {
      case .somethingHappen:

        let alert = UIAlertController(title: "Something happen", message: nil, preferredStyle: .alert)
        alert.addAction(.init(title: "Dismiss", style: .default, handler: nil))

        self.present(alert, animated: true, completion: nil)

      }

    }
    .store(in: &cancellables)

    viewModel.sinkState { [weak self] state in
      self?.update(changes: state)
    }
    .store(in: &cancellables)

  }
  
  private func update(changes: Changes<ViewModel.State>) {
    changes.ifChanged(\.displayNumber) { (number) in
      label.text = number
    }
  }

  @IBAction func onTapButton(_ sender: Any) {
    viewModel.increment()
  }
}

import Verge

final class ViewModel: StoreComponentType {

  struct State: Equatable {

    var displayNumber: String {
      count.description
    }

    var count: Int = 0
  }

  enum Activity {
    case somethingHappen
  }
  
  let rootStore: RootStore
  
  private var cancellables = Set<VergeAnyCancellable>()

  let store = DefaultStore(initialState: .init())
  
  init(parent: RootStore) {
    self.rootStore = parent

    parent.sinkState { [weak self] state in
      self?.commit {
        $0.count = state.count
      }
    }
    .store(in: &cancellables)

    parent.sinkActivity { [weak self] activity in
      guard let self = self else { return }
      switch activity {
      case .bomb:
        self.send(.somethingHappen)
      }
    }
    .store(in: &cancellables)

  }
      
  func increment() {
    
    rootStore.incrementWithNotification()
    
  }
      
}
