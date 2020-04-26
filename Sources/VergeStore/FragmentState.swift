//
//  StateFragment.swift
//  VergeCore
//
//  Created by muukii on 2020/01/13.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

public protocol FragmentType {
  associatedtype State
  var version: UInt64 { get }
}

@propertyWrapper
public struct Fragment<State>: FragmentType {
  
  public var version: UInt64 {
    _read {
      yield counter.version
    }
  }
  
  private(set) public var counter: VersionCounter = .init()
  
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

extension Comparer where Input : FragmentType {
  
  public static func versionEquals() -> Comparer<Input> {
    Comparer<Input>.init { $0.version == $1.version }
  }
}
