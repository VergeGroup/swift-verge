//
//  SyntaxTests.swift
//  VergeStoreTests
//
//  Created by muukii on 2020/05/24.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import Verge

enum SyntaxTests {

  static func code() {

    let changes: Changes<DemoState> = .init(old: nil, new: .init())

    changes.ifChanged(\.name) { name in

    }

    changes.ifChanged(\.$nonEquatable) { name in

    }


    changes.ifChanged(\.name) { name in

    }

    changes.ifChanged(.map(using: { $0.name }, transform: { $0.count })) { a in

    }
    
  }
}
