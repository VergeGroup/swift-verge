import XCTest
import Foundation
import VergeORM
import HashTreeCollections


final class DictionaryPerformance: XCTestCase {

  func test_dictionary_copying_insertion() {
    measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
      var tree = [Int : String]()
      for i in 0..<10000 {
        var previous = tree
        previous[i] = "value\(i)"
        tree = previous
      }
    }
  }

  func test_tree_copying_insertion() {
    measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
      var tree = TreeDictionary<Int, String>()
      for i in 0..<10000 {
        var previous = tree
        previous[i] = "value\(i)"
        tree = previous
      }
    }
  }
}

