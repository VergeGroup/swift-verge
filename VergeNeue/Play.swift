//
//  Play.swift
//  VergeNeue
//
//  Created by muukii on 2019/11/03.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

open class VergeStore<State, Module> {
  
  public final var state: State {
    stateStorage.value
  }
    
  let moduleStorage: Storage<Module>
  let stateStorage: Storage<State>
  
  public init(state: State, module: Module) {
    self.stateStorage = .init(state)
    self.moduleStorage = .init(module)
  }
    
}
