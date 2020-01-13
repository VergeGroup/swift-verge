//
//  StateFragment.swift
//  VergeCore
//
//  Created by muukii on 2020/01/13.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

@dynamicMemberLookup
public struct Fragment<State> {
  
  private(set) public var counter: UpdatedMarker = .init()
  
  public init(_ state: State) {
    self.state = state
  }
  
  public var state: State {
    didSet {
      counter.markAsUpdated()
    }
  }
  
  public subscript <T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
    _read {
      yield state[keyPath: keyPath]
    }
  }
  
  public subscript <T>(dynamicMember keyPath: WritableKeyPath<State, T>) -> T {
    _read {
      yield state[keyPath: keyPath]
    }
    _modify {
      yield &state[keyPath: keyPath]
    }
  }
}
