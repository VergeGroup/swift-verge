//
//  AppContainer.swift
//  VergeNeueAdvancedDemo
//
//  Created by muukii on 2019/09/22.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

import VergeNeue

enum AppContainer {
  
  static let service = Service()
  
  static let store = Store(
    reducer: LoggedInReducer(service: AppContainer.service)
  )
//    .addAdapter(ExternalDataIntegrationAdapter())
}
