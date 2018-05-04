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

class RootViewModel : CyclerType {

  enum Activity {
  }

  struct State {

  }

  let state: Storage<State> = .init(.init())

  init() {

  }

  func hey() {

//    dispatch { c in
      print("hey")
//    }
  }

}

class ViewModel : ModularCyclerType {

  typealias Parent = RootViewModel

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
    set(parent: RootViewModel(), retain: true)
  }

  func increment(number: Int) {

    forward { (parent) in
      parent.hey()
    }

    dispatch("increment") { (context) in

      Single.just(())
        .delay(0.5, scheduler: MainScheduler.instance)
        .do(onNext: {

            context.commit { (state) in
              state.count += number
            }

            if context.currentState.count > 10 {
              context.emit(.didReachBigNumber)
            }
        })
        .subscribe(with: context)

      }
  }

  func decrement(number: Int) {

    dispatch("decrement") { context in
      context.commit { (state) in
        state.count -= number
      }
      context.complete()
    }

  }
}
