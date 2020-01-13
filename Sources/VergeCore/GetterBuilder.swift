//
//  GetterBuilder.swift
//  VergeCore
//
//  Created by muukii on 2020/01/14.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

public struct GetterBuilder<Input, Output> {
  
  public let filter: (Input) -> Bool
  public let map: (Input) -> Output
  
  public init(
    filter: @escaping (Input) -> Bool,
    map: @escaping (Input) -> Output
  ) {
    
    self.filter = filter
    self.map = map
    
  }
  
}

#if canImport(Combine)
extension ValueContainerType {
  
  @available(iOS 13, *)
  public func makeGetter<Output>(from: GetterBuilder<Value, Output>) -> GetterSource<Value, Output> {
    getter(filter: from.filter, map: from.map)
  }
}
#endif
