//
//  GetterBuilder.swift
//  VergeCore
//
//  Created by muukii on 2020/01/14.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

public struct EqualityComparerBuilder<Input, ComparingKey> {
  
  public static var alwaysDifferent: EqualityComparerBuilder<Input, Input> {
    .init(selector: { $0 }, predicate: { _, _ in false })
  }
  
  let selector: (Input) -> ComparingKey
  let predicate: (ComparingKey, ComparingKey) -> Bool
  
  public init(
    selector: @escaping (Input) -> ComparingKey,
    predicate: @escaping (ComparingKey, ComparingKey) -> Bool
  ) {
    self.selector = selector
    self.predicate = predicate
  }
  
  public func build() -> HistoricalComparer<Input> {
    .init(selector: selector, comparer: AnyComparerFragment.init(predicate))
  }
}

public struct GetterBuilder<Input, ComparingKey, Output> {
  
  public let equalityComparerBuilder: EqualityComparerBuilder<Input, ComparingKey>
  public let map: (Input) -> Output
  
  public init(
    equalityComparerBuilder: EqualityComparerBuilder<Input, ComparingKey>,
    map: @escaping (Input) -> Output
  ) {
    
    self.equalityComparerBuilder = equalityComparerBuilder
    self.map = map
    
  }
  
}

