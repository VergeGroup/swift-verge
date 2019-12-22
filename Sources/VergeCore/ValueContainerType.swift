//
//  ValueContainerType.swift
//  VergeCore
//
//  Created by muukii on 2019/12/16.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public protocol ValueContainerType {
  associatedtype Value
  
  func getter<Key, Destination>(
    selector: @escaping (Value) -> Destination,
    equality: EqualityComputer<Value, Key>
  ) -> Getter<Value, Destination>
}
