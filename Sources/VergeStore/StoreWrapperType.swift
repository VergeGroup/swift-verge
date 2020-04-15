//
//  StoreWrapperType.swift
//  VergeStore
//
//  Created by muukii on 2020/04/16.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

public protocol StoreWrapperType: DispatcherType {
      
  var store: StoreBase<State, Activity> { get }
}

extension StoreWrapperType {

  public var target: StoreBase<State, Activity> { store }
  public var scope: WritableKeyPath<State, State> { \State.self }
  public var metadata: DispatcherMetadata { .init() }
}
