//
//  EqualityComputer+.swift
//  VergeRx
//
//  Created by muukii on 2020/01/09.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import RxSwift

#if !COCOAPODS
import VergeCore
#endif

extension ObservableType {
  
  public func distinctUntilChanged(_ computer: EqualityComputer<Element>) -> RxSwift.Observable<Self.Element> {
    filter {
      !computer.isEqual(value: $0)
    }
  }

}
