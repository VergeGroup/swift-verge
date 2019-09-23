//
//  AppContainer.swift
//  VergeNeueAdvancedDemo
//
//  Created by muukii on 2019/09/22.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

enum AppContainer {
  
  static let service = Service()
  
  static let store = LoggedInStore(service: service)
//    .addAdapter(ExternalDataIntegrationAdapter())
}
