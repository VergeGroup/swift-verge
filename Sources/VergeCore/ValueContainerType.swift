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
    from builder: GetterComponents<Value, PreComparingKey, Output, PostComparingKey>
  ) -> GetterSource<Value, Output>
  
  #endif
}

#if canImport(Combine)
import Combine
extension ValueContainerType {
     
  public func getterBuilder() -> GetterBuilderMethodChain<GetterBuilderTrait.Combine, Self> {
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
    from components: GetterComponents<Value, PreComparingKey, Output, PostComparingKey>
  ) -> GetterSource<Value, Output> {
    
    let preComparer = components.preFilter.build()
    let postComparer = components.postFilter?.build()
    
    let base = valuePublisher
      .handleEvents(receiveOutput: { [closure = components.onPreFilterWillReceive] value in
        closure(value)
      })
      .filter { value in
        !preComparer.equals(input: value)
    }
    .handleEvents(receiveOutput: { [closure = components.onTransformWillReceive] value in
      closure(value)
    })
    .map(components.transform)
    
    let pipe: AnyPublisher<Output, Never>
    
    if let comparer = postComparer {
      pipe = base.filter { value in
        !comparer.equals(input: value)
      }
      .handleEvents(receiveOutput: { [closure = components.onPostFilterWillEmit] value in
        closure(value)
      })
      .eraseToAnyPublisher()
    } else {
      pipe = base.eraseToAnyPublisher()
    }
       
    let getterBuilder = GetterSource<Value, Output>.init(input: pipe)
    
    return getterBuilder
  }
   
  #endif
}
