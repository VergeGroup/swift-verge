//
//  Getter+Rx.swift
//  RxVergeStore
//
//  Created by muukii on 2019/12/25.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

#if !COCOAPODS
import VergeCore
#endif

fileprivate var getter_subject: Void?

extension GetterBase {
  
  private var subject: BehaviorRelay<Output> {
    
    if let associated = objc_getAssociatedObject(self, &getter_subject) as? BehaviorRelay<Output> {
      
      return associated
      
    } else {
      
      let associated = BehaviorRelay<Output>.init(value: value)
      objc_setAssociatedObject(self, &getter_subject, associated, .OBJC_ASSOCIATION_RETAIN)
      
      addDidUpdate(subscriber: { (value) in
        associated.accept(value)
      })
      
      return associated
    }
  }
  
  public func asObservable() -> Observable<Output> {
    subject.asObservable()
  }
}
