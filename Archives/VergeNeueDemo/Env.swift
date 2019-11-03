//
//  Env.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/18.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

struct Env: Hashable {
  let id: String
}

extension Env {
  
  static let stage: Env = .init(id: "stage")
  static let production: Env = .init(id: "production")
}
