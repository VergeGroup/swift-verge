//
//  ViewController.swift
//  VergeStoreDemoUIKit
//
//  Created by muukii on 2020/01/14.
//  Copyright © 2020 muukii. All rights reserved.
//

import UIKit

import RxSwift

class ViewController: UIViewController {
  
  let viewModel = CompositionRoot.demo.viewModel
    
  @IBOutlet weak var label: UILabel!
  
  private let disposeBag = DisposeBag()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    viewModel.rx.activitySignal
      .emit(onNext: { [weak self] activity in
        
        guard let self = self else { return }
        
        switch activity {
        case .somethingHappen:
          
          let alert = UIAlertController(title: "Something happen", message: nil, preferredStyle: .alert)
          alert.addAction(.init(title: "Dismiss", style: .default, handler: nil))
          
          self.present(alert, animated: true, completion: nil)
          
        }
        
      })
      .disposed(by: disposeBag)
    
    viewModel.rx.stateObservable()
      .observeOn(MainScheduler.instance)
      .bind { [weak self] (changes) in
        self?.update(changes: changes)
    }
    .disposed(by: disposeBag)
    
  }
  
  private func update(changes: Changes<ViewModelState>) {
    changes.ifChanged(\.displayNumber) { (number) in
      label.text = number
    }
  }

  @IBAction func onTapButton(_ sender: Any) {
    viewModel.increment()
  }
}

import VergeStore
import VergeRx

struct ViewModelState: StateType {
  
  var displayNumber: String {
    count.description
  }
  
  var count: Int = 0
}

enum ViewModelActivity {
  case somethingHappen
}

final class ViewModel: ViewModelBase<ViewModelState, ViewModelActivity> {
  
  let rootStore: RootStore
  
  private let disposeBag = DisposeBag()
  
  init(parent: RootStore) {
    self.rootStore = parent
    super.init(initialState: .init(), logger: nil)
    
    parent.rx.stateObservable()
      .bind { [weak self] state in
        self?.commit {
          $0.count = state.count
        }
    }
    .disposed(by: disposeBag)
    
    parent.rx.activitySignal
      .emit(onNext: { [weak self] activity in
        guard let self = self else { return }
        switch activity {
        case .bomb:
          self.send(.somethingHappen)
        }
      })
      .disposed(by: disposeBag)
    
  }
      
  func increment() {
    
    rootStore.incrementWithNotification()
    
  }
      
}
