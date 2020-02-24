//
//  StateFragment.swift
//  VergeCore
//
//  Created by muukii on 2020/01/13.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

@propertyWrapper
public struct Fragment<State> {
  
  private(set) public var counter: UpdatedMarker = .init()
  
  public init(wrappedValue: State) {
    self.wrappedValue = wrappedValue
  }
  
  public var wrappedValue: State {
    didSet {
      counter.markAsUpdated()
    }
  }
  
  public var projectedValue: Fragment<State> {
    self
  }
  
}
