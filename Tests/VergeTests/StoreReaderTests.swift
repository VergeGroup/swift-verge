
import XCTest
import SwiftUI
import Verge
import ViewInspector

@MainActor
final class StoreReaderTests: XCTestCase {
        
  func test_increment_counter() throws {
    
    let store = Store<State, Never>(initialState: .init())
    
    var count = 0

    let view = Content(store: store, onUpdate: {
      count += 1
    })
    
    let inspect = try view.inspect()
        
    XCTAssertEqual(count, 0)
    
    // POC
    XCTAssertEqual(try inspect.vStack()[0].text().string(), "Hello")
            
    XCTAssertEqual(try inspect.find(viewWithId: "count_1").text().string(), "0")
    
    print(count)
    
    store.commit {
      $0.count_1 += 1
    }
    
    XCTAssertEqual(try inspect.find(viewWithId: "count_1").text().string(), "1")
    print(count)
  }
  
  @MainActor
  func test_increments_updated_count() async throws {
    
    let store = Store<State, Never>(initialState: .init())
    
    var count = 0
    
    let view = Content(store: store, onUpdate: {
      count += 1
    })
            
    ViewHosting.host(view: view)
    
    XCTAssertEqual(count, 1)
    
    try await Task.sleep(nanoseconds: 1)
        
    store.commit {
      $0.count_1 += 1
    }
    
    try await Task.sleep(nanoseconds: 1)
    
    XCTAssertEqual(count, 2)
        
    store.commit {
      $0.count_1 += 1
    }
    
    try await Task.sleep(nanoseconds: 1)
    
    XCTAssertEqual(count, 3)
    
    store.commit {
      $0.count_1 += 1
    }
    
    try await Task.sleep(nanoseconds: 1)
    XCTAssertEqual(count, 4)
  }
  
  @MainActor
  func test_not_increments_updated_count() async throws {
    
    let store = Store<State, Never>(initialState: .init())
    
    var count = 0
    
    let view = Content(store: store, onUpdate: {
      count += 1
    })
    
    ViewHosting.host(view: view)
    
    XCTAssertEqual(count, 1)
    
    try await Task.sleep(nanoseconds: 1)
    
    store.commit {
      $0.count_1 += 1
    }
    
    try await Task.sleep(nanoseconds: 1)
        
    XCTAssertEqual(count, 2)
    
    store.commit {
      $0.count_2 += 1
    }
    
    try await Task.sleep(nanoseconds: 1)
    
    // not change because count_2 never read anyone.
    XCTAssertEqual(count, 2)
    
    store.commit {
      $0.count_2 += 1
    }
    
    try await Task.sleep(nanoseconds: 1)
    
    // not change because count_2 never read anyone.
    XCTAssertEqual(count, 2)
       
  }
  
  private struct State: Equatable {
    var count_1 = 0
    var count_2 = 0
  }
  
  private struct Content: View {
    
    let store: Store<State, Never>
    let onUpdate: @MainActor () -> Void
    
    init(
      store: Store<State, Never>,
      onUpdate: @escaping @MainActor () -> Void
    ) {
      self.store = store
      self.onUpdate = onUpdate
    }
    
    var body: some View {
      VStack {
        Text("Hello")
        
        StoreReader(store) { state in
          
          let _: Void = {
            onUpdate()
          }()
          
          Text("\(state.count_1)")
            .id("count_1")
        }
        .id("StoreReader")
      }
    }
    
  }
}
