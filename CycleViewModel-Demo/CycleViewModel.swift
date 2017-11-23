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

  struct State {
    fileprivate(set) var count: Int = 0
    fileprivate(set) var countOfActions: Int = 0
  }

  enum Activity {
    case didReachBigNumber
  }

  typealias Mutation = AnyMutation<State>

  var activity: Signal<Activity> {
    return _activity.asSignal()
  }

  let state: Storage<State> = .init(.init())

  private let _activity = PublishRelay<Activity>()

  func receiveError(error: Error) {
    print(error)
  }

  func increment(number: Int) {
    commit("increment") { (state) in
      state.updateIfChanged(state.value.count + number, \.count)
    }
    if state.value.count > 10 {
      self._activity.accept(.didReachBigNumber)
    }
  }

  func decrement(number: Int) {
    commit("decrement") { (state) in
      state.updateIfChanged(state.value.count - number, \.count)
    }
  }
  
}
