//
//  GetterBuilder.swift
//  VergeCore
//
//  Created by muukii on 2020/01/14.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

public struct GetterComponents<Input, Output> {
  
  public let onPreFilterWillReceive: ((Input) -> Void)
  public let onTransformWillReceive: ((Input) -> Void)
  public let onPostFilterWillEmit: ((Output) -> Void)
  
  public let preFilter: Comparer<Input>
  public let transform: (Input) -> Output
  public let postFilter: Comparer<Output>
    
  public init(
    onPreFilterWillReceive: @escaping ((Input) -> Void),
    preFilter: Comparer<Input>,
    onTransformWillReceive: @escaping ((Input) -> Void),
    transform: @escaping (Input) -> Output,
    postFilter: Comparer<Output>,
    onPostFilterWillEmit: @escaping ((Output) -> Void)
  ) {
    
    self.onPreFilterWillReceive = onPreFilterWillReceive
    self.onTransformWillReceive = onTransformWillReceive
    self.onPostFilterWillEmit = onPostFilterWillEmit
    
    self.preFilter = preFilter
    self.transform = transform
    self.postFilter = postFilter
    
  }
        
}
