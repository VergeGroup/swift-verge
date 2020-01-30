//
//  GetterBuilder.swift
//  VergeCore
//
//  Created by muukii on 2020/01/14.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

public struct GetterBuilder<Input, ComparingKey, Output> {
  
  public let equalityComparerBuilder: EqualityComputerBuilder<Input, ComparingKey>
  public let map: (Input) -> Output
  
  public init(
    preFilter: EqualityComputerBuilder<Input, ComparingKey>,
    map: @escaping (Input) -> Output
  ) {
    
    self.equalityComparerBuilder = preFilter
    self.map = map
    
  }
  
}

extension GetterBuilder where Input : Equatable {
  
  public static func make<Output>(map: @escaping (Input) -> Output) -> GetterBuilder<Input, Input, Output> {
    .init(preFilter: .init(keySelector: { $0 }, comparer: ==), map: map)
  }
      
}

extension GetterBuilder {
     
}

