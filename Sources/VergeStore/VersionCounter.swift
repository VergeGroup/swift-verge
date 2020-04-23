//
//  Counter.swift
//  VergeCore
//
//  Created by muukii on 2020/01/13.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

/// A container manages raw value to describe mark as updated.
public struct VersionCounter: Hashable {
  
  private(set) public var version: UInt64 = 0
  
  public init() {}
  
  public mutating func markAsUpdated() {
    version &+= 1
  }
  
}
