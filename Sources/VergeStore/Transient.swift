//
//  Transient.swift
//  SpotifyDemo
//
//  Created by muukii on 2020/01/19.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

public protocol TransientType {
  associatedtype State
  
  var box: Transient<State> { get set }
  var unsafelyUnwrap: State { get set }
}

public enum Transient<State>: TransientType {
  
  case some(State)
  case none
  
  public var unsafelyUnwrap: State {
    get {
      switch self {
      case .none:
        fatalError()
      case .some(let state):
        return state
      }
    }
    mutating set {
      self = .some(newValue)
    }
  }
  
  public var box: Transient<State> {
    get {
      self
    }
    mutating set {
      self = newValue
    }
  }
}
