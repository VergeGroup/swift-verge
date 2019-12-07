//
//  Action.swift
//  VergeStoreDemoSwiftUI
//
//  Created by muukii on 2019/12/08.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public struct AnyAction<Dispatcher: DispatcherType, Return> {
  
  let _action: (VergeStoreDispatcherContext<Dispatcher>) -> Return
  public let metadata: ActionMetadata
  
  public init(
    _ name: StaticString = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: @escaping (VergeStoreDispatcherContext<Dispatcher>) -> Return
  ) {
    
    self.metadata = .init(name: name, file: file, function: function, line: line)
    self._action = action
    
  }
}

extension AnyAction {
  
  public static func dispatch(
    _ name: StaticString = "",
    _ file: StaticString = #file,
    _ function: StaticString = #function,
    _ line: UInt = #line,
    _ action: @escaping (VergeStoreDispatcherContext<Dispatcher>) -> Return
  ) -> Self {
    self.init(name, file, function, line, action)
  }
  
}
