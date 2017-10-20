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

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.

    let vm = NoViewModel()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

import RxSwift
import CycleViewModel

class NoViewModel : Cycler {

  typealias State = NoState
  typealias Action = NoAction
  typealias Mutation = NoMutation
  typealias Activity = NoActivity

  init() {

  }
  
//  func mutate(_ action: NoViewModel.Action) -> NoViewModel.Mutation {
//    fatalError()
//  }
//
//  func reduce(_ mutation: NoViewModel.Mutation) {
//
//  }
}

class MyViewModel : Cycler {

  class State {
    var fetchedPartners: [String] = []
    var likedCount: Int = 0
  }

  enum Activity {
    case didSendLike
  }

  enum Action {
    case sendLike(targetPartner: String)
  }

  typealias Mutation = Action

  var activity: Signal<MyViewModel.Activity> {
    return _activity.asSignal()
  }

  lazy var state: StateStorage<MyViewModel.State> = .init(_state)
  private let _state: MutableStateStorage<State> = .init(.init())
  private let _activity = PublishRelay<Activity>()

  func reduce(_ mutation: Mutation) {

    switch mutation {
    case .sendLike(_):

      _activity.accept(.didSendLike)

      _state.mutate { s in
        s.likedCount += 1
      }

      break
    }
  }
}

