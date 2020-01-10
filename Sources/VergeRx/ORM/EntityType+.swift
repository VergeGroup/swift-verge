//
//  EntityType+.swift
//  VergeRx
//
//  Created by muukii on 2020/01/10.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

#if !COCOAPODS
import VergeORM
#endif

extension EntityType {
  
  #if COCOAPODS
  public typealias RxGetter = Verge.RxGetter<Self>
  public typealias RxGetterSource<Source> = Verge.RxGetterSource<Source, Self>
  #else
  public typealias RxGetter = VergeRx.RxGetter<Self>
  public typealias RxGetterSource<Source> = VergeRx.RxGetterSource<Source, Self>
  #endif
  
}
