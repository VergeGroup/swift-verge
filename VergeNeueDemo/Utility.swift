//
//  Utility.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

func demoDelay(on queue: DispatchQueue = .main, _ perform: @escaping () -> Void) {
  DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    perform()
  }
}
