//
//  JSONDescribing.swift
//  VergeCore
//
//  Created by muukii on 2020/02/19.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

public protocol JSONDescribing {
  
  func jsonDescriptor() -> [String : Any]?
  
}
