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

    changes.ifChanged(\.nonEquatable, .alwaysFalse) { name in

    }


    changes.ifChanged({ $0.name }) { name in

    }

    changes.ifChanged(\.name, \.count) { name, count in

    }

  }
}
