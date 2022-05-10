//
//  ComparerTests.swift
//  VergeTests
//
//  Created by Muukii on 2022/05/11.
//  Copyright © 2022 muukii. All rights reserved.
//

import Foundation
import Verge
import XCTest

@available(iOS 13, *)
final class ComparerTests: XCTestCase {
  
  func testPerfomance() {
    
    let base = Comparer<String> { $0 == $1 }
    
    measure(metrics: [XCTMemoryMetric()]) {
      _ = base.equals("A", "B")
    }
  }
  
}
