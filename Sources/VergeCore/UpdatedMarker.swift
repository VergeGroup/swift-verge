//
//  Counter.swift
//  VergeCore
//
//  Created by muukii on 2020/01/13.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

/// A container manages raw value to describe mark as updated.
public struct UpdatedMarker: Hashable {
  
  private(set) public var rawValue: UInt64 = 0
  
  public init() {}
  
  public mutating func markAsUpdated() {
    guard rawValue < UInt64.max else {
      rawValue &= 0
      return
    }
    rawValue &+= 1
  }
  
}
