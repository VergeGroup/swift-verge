//
//  MigrationFromClassicTests.swift
//  VergeRxTests
//
//  Created by muukii on 2020/04/20.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import Verge
import VergeRx
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
      
      public struct State: Equatable {
        
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
      
      let _: ViewModel.State = viewModel.primitiveState
            
      let _: Changes<ViewModel.State> = viewModel.state
      
      _ = viewModel.sinkState { (changes: Changes<ViewModel.State>) in
        
      }
      
      _ = viewModel.sinkActivity { (activity: ViewModel.Activity) in
        
      }
      
      rx: do {
        
        let _: Observable<Changes<ViewModel.State>> = viewModel.rx.stateObservable()
                
        let _: Signal<ViewModel.Activity> = viewModel.rx.activitySignal
      }
      
      combine: do {
        if #available(iOS 13, *) {
          let _: AnyPublisher<Changes<ViewModel.State>, Never> = viewModel.statePublisher()
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
      
      _ = viewModel.primitiveState
      _ = viewModel.state
      if #available(iOS 13, *) {
        _ = viewModel.statePublisher()
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
      
      _ = viewModel.rx.stateObservable()
      
    }
    
    
  }
  
}
