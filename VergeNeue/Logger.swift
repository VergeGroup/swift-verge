//
//  Logger.swift
//  VergeNeue
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

public protocol StoreLogger {
  
  func willCommit(store: Any, state: Any)
  func didCommit(store: Any, state: Any)
  func didDispatch(store: Any, state: Any)
}
