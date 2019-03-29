//
//  CycleViewModel.swift
//  Verge-Demo
//
//  Created by muukii on 11/10/17.
//  Copyright © 2017 muukii. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxFuture

import Verge

class RootViewModel : VergeType {

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

class ViewModel : ModularVergeType {

  typealias Parent = RootViewModel

  enum Activity {
    case didReachBigNumber
  }

  struct State {

    // Stored
    fileprivate var count: Int = 0 {
      didSet {
        subCount = count + 1
      }
    }

    fileprivate(set) var subCount: Int = 0

    // Computed
    var countText: String {
      return count.description
    }
  }

  private let disposeBag = DisposeBag()

  let state: Storage<State> = .init(.init())

  init() {

    set(logger: VergeLogger.instance)
  }

  func increment(number: Int) {

    dispatch("increment") { (context) in

      Single.just(())
        .delay(0.5, scheduler: MainScheduler.instance)
        .do(onSuccess: {

            context.commit { (state) in
              state.count += number
            }

            if context.currentState.count > 10 {
              context.emit(.didReachBigNumber)
            }
        })
        .start()

      }
  }

  func decrement(number: Int) {

    dispatch("decrement") { context -> RxFuture<Void> in
      context.commit { (state) in
        state.count -= number
      }
      return Single<Void>.just(()).start()
    }

  }
}
