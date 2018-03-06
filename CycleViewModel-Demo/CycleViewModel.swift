//
//  CycleViewModel.swift
//  Cycler-Demo
//
//  Created by muukii on 11/10/17.
//  Copyright © 2017 muukii. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

import Cycler

class ViewModel : CyclerType {

  enum Activity {
    case didReachBigNumber
  }

  struct State {

    // Stored
    fileprivate var count: Int = 0

    // Computed
    var countText: String {
      return count.description
    }
  }

  private let disposeBag = DisposeBag()

  let state: Storage<State> = .init(.init(count: 0))

  init() {

    set(logger: CyclerLogger.instance)
  }

  func increment(number: Int) {

    dispatch("increment") { (context) in

      Observable.just(())
        .delay(0.1, scheduler: MainScheduler.instance)
        .do(onNext: {

            context.commit { (state) in
              state.updateIfChanged(state.value.count, \.count)
            }

            if context.currentState.count > 10 {
              context.emit(.didReachBigNumber)
            }
        })
        .subscribe()

      }
      .disposed(by: disposeBag)
  }

  func decrement(number: Int) {

    dispatch("decrement") { _ in
      commit { (state) in
        state.updateIfChanged(state.value.count - number, \.count)

      }
    }

  }
}
