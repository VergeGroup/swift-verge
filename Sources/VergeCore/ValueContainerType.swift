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
    
  func getter<Output>(
    selector: @escaping (Value) -> Output,
    equality: EqualityComputer<Value>
  ) -> Getter<Value, Output>
}
