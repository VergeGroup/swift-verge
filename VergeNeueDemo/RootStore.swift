//
//  RootStore.swift
//  VergeNeueDemo
//
//  Created by muukii on 2019/09/17.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation
import VergeNeue

let rootStore = Store(
  state: RootState(),
  reducer: RootReducer()
)
