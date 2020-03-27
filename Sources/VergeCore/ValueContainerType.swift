//
//  ValueContainerType.swift
//  VergeCore
//
//  Created by muukii on 2019/12/16.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public protocol ValueContainerType: AnyObject {
  associatedtype Value
  
  var wrappedValue: Value { get }
  
  func lock()
  func unlock()
  
  #if canImport(Combine)
     
  @available(iOS 13, macOS 10.15, *)
  func makeGetter<PreComparingKey, Output, PostComparingKey>(
    from builder: GetterBuilder<Value, PreComparingKey, Output, PostComparingKey>
  ) -> GetterSource<Value, Output>
  
  #endif
}

#if canImport(Combine)
import Combine
extension ValueContainerType {
     
  // TODO: Rename getterBuilder()
  public func makeGetter() -> GetterBuilderMethodChain<GetterBuilderTrait.Combine, Self> {
    .init(target: self)
  }
      
}
#endif

extension Storage: ValueContainerType {
  
  public func lock() {
    _lock.lock()
  }

  public func unlock() {
    _lock.unlock()
  }
  
  #if canImport(Combine)
  
  @available(iOS 13, macOS 10.15, *)
  
  public func makeGetter<PreComparingKey, Output, PostComparingKey>(
    from builder: GetterBuilder<Value, PreComparingKey, Output, PostComparingKey>
  ) -> GetterSource<Value, Output> {
    
    let preComparer = builder.preFilter.build()
    let postComparer = builder.postFilter?.build()
    
    let base = publisher
      .filter { value in
        !preComparer.equals(input: value)
    }
    .map(builder.transform)
    
    let pipe: AnyPublisher<Output, Never>
    
    if let comparer = postComparer {
      pipe = base.filter { value in
        !comparer.equals(input: value)
      }
      .eraseToAnyPublisher()
    } else {
      pipe = base.eraseToAnyPublisher()
    }
       
    let makeGetter = GetterSource<Value, Output>.init(input: pipe)
    
    return makeGetter
  }
   
  #endif
}
