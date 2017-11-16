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

  enum Action {
    case increment(number: Int)
    case decrement(number: Int)
  }

  typealias Mutation = Action

  var activity: Signal<Activity> {
    return _activity.asSignal()
  }

  lazy var state: Storage<State> = _state.asStateStorage()

  private let _state: MutableStorage<State> = .init(.init())
  private let _activity = PublishRelay<Activity>()

  func receiveError(error: Error) {

  }
    
  func reduce(state: MutableStorage<State>, action: Action) -> ReduceSequence {
    switch action {
    case .increment(let number):

      return Observable.just(number)
        .map { state.value.count + $0 }
        .applyIfChanged(on: state, keyPath: \.count)
        .do(onNext: { [weak self] _ in
          if state.value.count > 10 {
            self?._activity.accept(.didReachBigNumber)
          }
        })

    case .decrement(let number):

      return Observable.just(number)
        .map { state.value.count - $0 }
        .applyIfChanged(on: state, keyPath: \.count)

    }
  }
  
}
