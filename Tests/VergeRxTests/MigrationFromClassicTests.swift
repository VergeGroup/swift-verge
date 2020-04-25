//
//  MigrationFromClassicTests.swift
//  VergeRxTests
//
//  Created by muukii on 2020/04/20.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import VergeStore
import VergeRx
import VergeCore
import VergeClassic

import Combine

enum MigrationExample {
  
  enum Classic {
    
    public final class ViewModel : VergeType {
      
      public enum Activity {
        
      }
      
      public struct State {
        
        var state1: String = ""
        var state2: String = ""
        var state3: String = ""
      }
      
      public let state: Storage<ViewModel.State>
      
      public init() {
        self.state = .init(.init())
      }
      
      func setSomeData() {
        
        commit { s in
          s.state1 = "hello"
        }
      }
    }
    
  }
  
  enum New_1 {
    
    public final class ViewModel : StoreWrapperType {
                  
      public enum Activity {
        
      }
      
      public struct State {
        
        var state1: String = ""
        var state2: String = ""
        var state3: String = ""
      }
      
      public let store: Store<State, Activity>
      
      public init() {
        self.store = .init(initialState: .init(), logger: nil)
      }
      
      func setSomeData() {
        
        commit { s in
          s.state1 = "hello"
        }
      }
    }
    
    static func sample() {
      
      let viewModel = ViewModel()
      
      let _: ViewModel.State = viewModel.state
            
      let _: Changes<ViewModel.State> = viewModel.changes
      
      viewModel.subscribeStateChanges { (changes: Changes<ViewModel.State>) in
        
      }
      
      viewModel.subscribeActivity { (activity: ViewModel.Activity) in
        
      }
      
      rx: do {
        
        let _: Observable<Changes<ViewModel.State>> = viewModel.rx.changesObservable()
        
        let _: Observable<ViewModel.State> = viewModel.rx.stateObservable
        
        let _: Signal<ViewModel.Activity> = viewModel.rx.activitySignal
      }
      
      combine: do {
        if #available(iOS 13, *) {
          let _: AnyPublisher<ViewModel.State, Never> = viewModel.statePublisher
          let _: AnyPublisher<ViewModel.State, Never> = viewModel.changesPublisher
          let _: EventEmitter<ViewModel.Activity>.Publisher = viewModel.activityPublisher
        }
      }
    }
    
  }
  
  enum New_2 {
    
    public final class ViewModel : StoreWrapperType {
      
      public enum Activity {
        
      }
      
      public struct State: StateType {
        
        var state1: String = ""
        var state2: String = ""
        var state3: String = ""
      }
      
      public let store: DefaultStore
      
      public init() {
        self.store = .init(initialState: .init(), logger: nil)
      }
      
      func setSomeData() {
        
        commit { s in
          s.state1 = "hello"
        }
      }
    }
    
  }
  
  enum Extra_1 {
    
    struct MyState: StateType {
      
    }
    
    enum MyActivity {}
    
    final class MyStore: Store<MyState, MyActivity> {}
    
    final class MyViewModel: StoreWrapperType {
      
      var store: MyStore { fatalError() }
      
    }

    static func sample() {
      
      let viewModel = MyViewModel()
      
      _ = viewModel.state
      _ = viewModel.changes
      if #available(iOS 13, *) {
        _ = viewModel.statePublisher
        _ = viewModel.changesPublisher
        _ = viewModel.activityPublisher
      } else {
        // Fallback on earlier versions
      }
      
    }
    
  }
  
  enum Extra_2 {
    
    public final class ViewModel : NSObject, StoreWrapperType {
      
      public enum Activity {
        
      }
      
      public struct State: StateType {
        
        var state1: String = ""
        var state2: String = ""
        var state3: String = ""
      }
      
      public let store: DefaultStore
      
      public override init() {
        self.store = .init(initialState: .init(), logger: nil)
        super.init()
      }
      
      func setSomeData() {
        
        commit { s in
          s.state1 = "hello"
        }
      }
    }
    
    
    static func sample() {
      
      let viewModel = ViewModel()
      
      _ = viewModel.rx.changesObservable
      
    }
    
    
  }
  
}
