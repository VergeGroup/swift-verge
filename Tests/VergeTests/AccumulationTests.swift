import Verge
import XCTest

final class AccumulationTests: XCTestCase {
  
  @MainActor
  func test_tracking() {
        
    let store = DemoStore()
    
    let expForSelect = expectation(description: "select")
    expForSelect.assertForOverFulfill = true
    expForSelect.expectedFulfillmentCount = 4
    
    let expForDo = expectation(description: "do")
    expForDo.expectedFulfillmentCount = 3
    
    let sub = store.accumulate(queue: .mainIsolated()) { 
      $0.ifChanged {        
        expForSelect.fulfill()
        return "\($0.count) \($0.name)"
      }
      .do { (value: String) in
        expForDo.fulfill()
        print(value)
      }
    }
    
    store.commit {
      $0.items.append(1)
    }
    
    store.commit {
      $0.items.append(1)
    }
    
    store.commit {
      $0.items.append(1)
    }
        
    store.commit {
      $0.count += 1
    }
    
    store.commit {
      $0.name = "name"
    }  
    
    store.commit {
      $0.name = "name"
    }  
    
    wait(for: [expForSelect, expForDo])
    
    let _ = sub
    
  }

  func test_main() {

    let store = DemoStore()

    let expForCount = expectation(description: "count")
    expForCount.expectedFulfillmentCount = 2

    let expForName = expectation(description: "name")
    expForName.expectedFulfillmentCount = 2

    weak var weakStore: DemoStore? = store
    
    let sub = store.accumulate(queue: .mainIsolated()) { [weakStore] in

      $0.ifChanged(\.count).do { value in
        expForCount.fulfill()
        runMain()
      }

      $0.ifChanged(\.name).do { value in
        expForName.fulfill()
      }

      // checks for result builders
      if let _ = weakStore {
        $0.ifChanged(\.name).do { value in
          runMain()
        }
      }

      // checks for result builders
      if true {
        $0.ifChanged(\.name).do { value in
          runMain()
        }
      } else {
        $0.ifChanged(\.name).do { value in
          runMain()
        }
      }

      // checks for result builders
      if true {
        $0.ifChanged(\.name).do { value in
          runMain()
        }
      }

    }

    store.commit {
      $0.count += 1
    }

    store.commit {
      $0.name = "name"
    }

    wait(for: [expForCount, expForName], timeout: 1)

    let _ = sub
  }

  func test_drop() {

    let store = DemoStore()

    let expForCount = expectation(description: "count")
    expForCount.expectedFulfillmentCount = 1

    let sub = store.accumulate(queue: .mainIsolated()) { 

      $0.ifChanged(\.count)
        .dropFirst(2)
        .do { value in
          expForCount.fulfill()
        }

    }

    store.commit {
      $0.count += 1
    }

    store.commit {
      $0.count += 1
    }

    wait(for: [expForCount], timeout: 1)

    let _ = sub
  }

  func test_background() {

    let store = DemoStore()

    let expForCount = expectation(description: "count")
    expForCount.expectedFulfillmentCount = 2

    let expForName = expectation(description: "name")
    expForName.expectedFulfillmentCount = 2
    
    weak var weakStore: DemoStore? = store

    let sub = store.accumulate(queue: .passthrough) { [weakStore] in

      $0.ifChanged(\.count).do { value in
        expForCount.fulfill()
      }

      $0.ifChanged(\.name).do { value in
        expForName.fulfill()
      }

      // checks for result builders
      if let _ = weakStore {
        $0.ifChanged(\.name).do { value in
        }
      }

      // checks for result builders
      if true {
        $0.ifChanged(\.name).do { value in
        }
      } else {
        $0.ifChanged(\.name).do { value in
        }
      }

      // checks for result builders
      if true {
        $0.ifChanged(\.name).do { value in
        }
      }

    }

    store.commit {
      $0.count += 1
    }

    store.commit {
      $0.name = "name"
    }

    wait(for: [expForCount, expForName], timeout: 1)

    let _ = sub
  }
}

@MainActor
private func runMain() {

}
