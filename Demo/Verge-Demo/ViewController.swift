//
//  ViewController.swift
//  CycleViewModel-Demo
//
//  Created by muukii on 10/18/17.
//  Copyright © 2017 muukii. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

class ViewController: UIViewController {

  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var subLabel: UILabel!
  @IBOutlet weak var decrementButton: UIButton!
  @IBOutlet weak var incrementButton: UIButton!

  private let viewModel: ViewModel = .init() // Should be injected

  private let disposeBag: DisposeBag = .init()

  override func viewDidLoad() {
    super.viewDidLoad()

    bind: do {

      viewModel
        .state
        .changedDriver(\.countText)
        .drive(label.rx.text)
        .disposed(by: disposeBag)

      viewModel
        .state
        .changedDriver(\.subCount.description)
        .drive(subLabel.rx.text)
        .disposed(by: disposeBag)

      viewModel
        .activity
        .emit(onNext: { [weak self] activity in

          guard let `self` = self else { return }

          switch activity {
          case .didReachBigNumber:

            let a = UIAlertController.init(title: "Whoa🚀", message: nil, preferredStyle: .alert)
            a.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
            self.present(a, animated: true, completion: nil)
          }
        })
        .disposed(by: disposeBag)

      decrementButton
        .rx
        .tap
        .bind { [weak self] in
          self?.viewModel.decrement(number: 1)
        }
        .disposed(by: disposeBag)

      incrementButton
        .rx
        .tap
        .bind { [weak self] in
          self?.viewModel.increment(number: 1)
        }
        .disposed(by: disposeBag)

    }
  }
}
