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
    
    viewModel.rx
      .stateObservable
      .changed(\.displayNumber)
      .observeOn(MainScheduler.instance)
      .bind { [weak self] number in
        self?.label.text = number
    }
    .disposed(by: disposeBag)
        
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

final class ViewModel: RootStore.ViewModelBase<ViewModelState, ViewModelActivity> {
  
  let rootStore: RootStore
  
  init(parent: RootStore) {
    self.rootStore = parent
    super.init(initialState: .init(), parent: parent, logger: nil)
  }
  
  override func updateState(state: inout ViewModelState, by storeState: RootState) {
    state.count = storeState.count
  }
  
  override func receiveParentActivity(_ activity: RootActivity) {
    dispatchInline { context in
      switch activity {
      case .bomb:
        context.send(.somethingHappen)
      }
    }
  }
  
  func increment() {
    
    rootStore.dispatch { $0.incrementWithNotification() }
    
  }
      
}
