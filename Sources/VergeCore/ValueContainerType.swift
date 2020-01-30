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
  func makeGetter<ComparingKey, Output>(
    from builder: GetterBuilder<Value, ComparingKey, Output>
  ) -> GetterSource<Value, Output>
  
  #endif
}

#if canImport(Combine)
extension ValueContainerType {
  
  @available(iOS 13, macOS 10.15, *)
  public func makeGetter() -> GetterSource<Value, Value> {
    makeGetter(from: .init(equalityComparerBuilder: .alwaysDifferent, map: { $0 }))
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
  
  public func makeGetter<ComparingKey, Output>(
    from builder: GetterBuilder<Value, ComparingKey, Output>
  ) -> GetterSource<Value, Output> {
    
    let comparer = builder.equalityComparerBuilder.build()
    let pipe = publisher
      .filter { value in
        !comparer.equals(input: value)
    }
    .map(builder.map)
    
    let makeGetter = GetterSource<Value, Output>.init(input: pipe)
    
    return makeGetter
  }
   
  #endif
}
