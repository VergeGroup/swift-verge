//
//  SyntaxTests.swift
//  VergeStoreTests
//
//  Created by muukii on 2020/05/24.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import Verge
import VergeMacros

enum SyntaxTests {

  static func code() {

    let changes: Changes<DemoState> = .init(old: nil, new: .init())

    changes.ifChanged(\.name).do { name in

    }

//    changes.ifChanged({ ($0.name, $0.name) }) { args in
//    }

    changes.ifChanged({ $0.nonEquatable }, comparator: .alwaysFalse()).do { name in

    }

    changes.ifChanged({ $0.name }).do { name in

    }

    changes.ifChanged(\.name, \.count).do { name, count in

    }

  }
}
