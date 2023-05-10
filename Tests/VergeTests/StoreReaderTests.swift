
import XCTest
import SwiftUI
import Verge
import ViewInspector

@available(iOS 14, *)
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
  
  @MainActor
  func test_computed_property_equatable() async throws {
    
    let store = Store<State, Never>(initialState: .init())
    
    var count = 0
    
    let view = ComputedContent(store: store, onUpdate: {
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
  func test_single_value() async throws {
        
    struct _Content: View {
      
      let store: Store<Int, Never>
      let onUpdate: @MainActor () -> Void
      
      init(
        store: Store<Int, Never>,
        onUpdate: @escaping @MainActor () -> Void
      ) {
        self.store = store
        self.onUpdate = onUpdate
      }
      
      var body: some View {
        VStack {
          StoreReader(store) { state in
            
            let _: Void = {
              onUpdate()
            }()
            
            Text(state[dynamicMember: \.self].description)
          }
        }
      }
      
    }
    
    let store = Store<Int, Never>(initialState: .init())
    
    var count = 0
    
    let view = _Content(store: store, onUpdate: {
      count += 1
    })
    
    ViewHosting.host(view: view)
    
    XCTAssertEqual(count, 1)
    
    try await Task.sleep(nanoseconds: 1)
    
    store.commit {
      $0.wrapped += 1
    }
    
    try await Task.sleep(nanoseconds: 1)
    
    XCTAssertEqual(count, 2)
    
    store.commit {
      $0.wrapped += 1
    }
    
    try await Task.sleep(nanoseconds: 1)
    
    XCTAssertEqual(count, 3)
    
    store.commit {
      $0.wrapped += 1
    }
    
    try await Task.sleep(nanoseconds: 1)
    XCTAssertEqual(count, 4)
    
  }
  
  @MainActor
  func test_enire_value() async throws {
    
    struct _Content: View {
      
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
          StoreReader(store) { state in
            
            let _: Void = {
              onUpdate()
            }()
            
            Text(String(describing: state[dynamicMember: \.self]))
          }
        }
      }
      
    }
    
    let store = Store<State, Never>(initialState: .init())
    
    var count = 0
    
    let view = _Content(store: store, onUpdate: {
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
  func test_computed_property() async throws {
    
    let store = Store<State, Never>(initialState: .init())
    
    var count = 0
    
    let view = NonEquatableComputedContent(store: store, onUpdate: {
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
  
  private struct NonEquatableBox<Value> {
    let value: Value
  }
  
  private struct State: Equatable {
    var count_1 = 0
    var count_2 = 0
    
    var computed_count_equatable: Int {
      count_1 + count_2
    }
    
    var computed_count: NonEquatableBox<Int> {
      .init(value: count_1 + count_2)
    }
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
  
  private struct ComputedContent: View {
    
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
        StoreReader(store) { state in
          
          let _: Void = {
            onUpdate()
          }()
          
          Text(state.computed_count_equatable.description)
        }
      }
    }
    
  }
  
  private struct NonEquatableComputedContent: View {
    
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
        StoreReader(store) { state in
          
          let _: Void = {
            onUpdate()
          }()
          
          Text("\(state.computed_count.value)")
        }
      }
    }
    
  }
}
