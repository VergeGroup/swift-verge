//
//  Adapter.swift
//  VergeNeue
//
//  Created by muukii on 2019/09/22.
//  Copyright © 2019 muukii. All rights reserved.
//

import Foundation

open class AdapterBase<Reducer: ModularReducerType> {
  
  weak var store: Store<Reducer>?
  
  public init() {}
  
  public final func run(_ perform: (Store<Reducer>) -> Void) {
    guard let store = store else { return }
    perform(store)
  }
}
