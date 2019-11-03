//
//  SwiftUI.swift
//  VergeNeue
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

#if canImport(Combine)
import Combine

private var _associated: Void?

@available(iOS 13.0, *)
extension Storage: ObservableObject {
  
  public var objectWillChange: ObservableObjectPublisher {
    if let associated = objc_getAssociatedObject(self, &_associated) as? ObservableObjectPublisher {
      return associated
    } else {
      let associated = ObservableObjectPublisher()
      objc_setAssociatedObject(self, &_associated, associated, .OBJC_ASSOCIATION_RETAIN)
      
      add { _ in
        if Thread.isMainThread {
          associated.send()
        } else {
          DispatchQueue.main.async {
            associated.send()
          }
        }
      }
      
      return associated
    }
  }
}

@available(iOS 13.0, *)
extension Store: ObservableObject {
  
  public var objectWillChange: ObservableObjectPublisher {
    storage.objectWillChange
  }
}

@available(iOS 13.0, *)
extension ScopedStore: ObservableObject {
  
  public var objectWillChange: ObservableObjectPublisher {
    storage.objectWillChange
  }
}

#endif
