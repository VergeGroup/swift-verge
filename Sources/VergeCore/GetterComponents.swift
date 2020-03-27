//
//  GetterBuilder.swift
//  VergeCore
//
//  Created by muukii on 2020/01/14.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

public struct GetterComponents<Input, PreComparingKey, Output, PostComparingKey> {
  
  public let preFilter: EqualityComputerBuilder<Input, PreComparingKey>
  public let transform: (Input) -> Output
  public let postFilter: EqualityComputerBuilder<Output, PostComparingKey>?
    
  public init(
    preFilter: EqualityComputerBuilder<Input, PreComparingKey>,
    transform: @escaping (Input) -> Output,
    postFilter: EqualityComputerBuilder<Output, PostComparingKey>
  ) {
    
    self.preFilter = preFilter
    self.transform = transform
    self.postFilter = postFilter
    
  }
  
}

extension GetterComponents {
  
  public static func make(
    preFilter: EqualityComputerBuilder<Input, PreComparingKey>,
    transform: @escaping (Input) -> Output
  ) -> GetterComponents<Input, PreComparingKey, Output, Output> {
    
    return .init(
      preFilter: preFilter,
      transform: transform,
      postFilter: .noFilter
    )
    
  }
     
}
