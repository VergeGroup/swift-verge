
import XCTest
import SwiftUI
import Verge
import ViewInspector

@available(iOS 14, tvOS 14, *)
final class StoreReaderTests: XCTestCase {
  
  @MainActor
  func test_constant() throws {
    
    let store = Store<ConstantState, Never>(initialState: .init(value: 0))
    
    var count = 0
    
    let view = ConstantContent(store: store, onUpdate: {
      count += 1
    })
    
    let inspect = try view.inspect()
    
    XCTAssertEqual(count, 0)
    
    XCTAssertEqual(try inspect.find(viewWithId: "value").text().string(), "0")
    
    print(count)
    
    store.commit {
      $0 = .init(value: 100)
    }
    
    XCTAssertEqual(try inspect.find(viewWithId: "value").text().string(), "100")
    
  }
    
  @MainActor
  func test_replacing_itself() throws {
    
    let store = Store<State, Never>(initialState: .init())
    
    var count = 0
    
    let view = Content(store: store, onUpdate: {
      count += 1
    })
    
    let inspect = try view.inspect()
    
    XCTAssertEqual(count, 0)
    
    XCTAssertEqual(try inspect.find(viewWithId: "count_1").text().string(), "0")
    
    print(count)
    
    var anotherState = State()
    anotherState.count_1 = 100
    
    store.commit {
      $0 = anotherState
    }
    
    XCTAssertEqual(try inspect.find(viewWithId: "count_1").text().string(), "100")
    print(count)
  }
  
  @MainActor
  func test_increment_counter() throws {
    
    let store = Store<State, Never>(initialState: .init())
    
    var count = 0

    let view = Content(store: store, onUpdate: {
      count += 1
    })
    
    let inspect = try view.inspect()
        
    XCTAssertEqual(count, 0)
            
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
    
    try await Task.sleep(nanoseconds: 5_000_000)

    store.commit {
      $0.count_1 += 1
    }
    
    try await Task.sleep(nanoseconds: 5_000_000)

    XCTAssertEqual(count, 2)

    store.commit {
      $0.count_1 += 1
    }
    
    try await Task.sleep(nanoseconds: 5_000_000)

    XCTAssertEqual(count, 3)

    store.commit {
      $0.count_1 += 1
    }
    
    try await Task.sleep(nanoseconds: 5_000_000)
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
    
    try await Task.sleep(nanoseconds: 1_000_000_000)

    store.commit {
      $0.count_1 += 1
    }
    
    try await Task.sleep(nanoseconds: 1_000_000_000)

    XCTAssertEqual(count, 2)

    do {

      store.commit {
        $0.count_2 += 1
      }

      try await Task.sleep(nanoseconds: 1_000_000_000)


      // not change because count_2 never read anyone.
      XCTAssertEqual(count, 2)

      store.commit {
        $0.count_2 += 1
      }

      try await Task.sleep(nanoseconds: 1_000_000_000)

      // not change because count_2 never read anyone.
      XCTAssertEqual(count, 2)
    }

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
    
    try await Task.sleep(nanoseconds: 5_000_000)

    store.commit {
      $0.count_1 += 1
    }
    
    try await Task.sleep(nanoseconds: 5_000_000)

    XCTAssertEqual(count, 2)

    store.commit {
      $0.count_1 += 1
    }
    
    try await Task.sleep(nanoseconds: 5_000_000)

    XCTAssertEqual(count, 3)

    store.commit {
      $0.count_1 += 1
    }
    
    try await Task.sleep(nanoseconds: 5_000_000)
    XCTAssertEqual(count, 4)

  }
  
  @Tracking
  struct SingleValueState {
    var count: Int = 0
  }
  
  @MainActor
  func test_single_value() async throws {
    
    struct _Content: View {
      
      let store: Store<SingleValueState, Never>
      let onUpdate: @MainActor () -> Void
      
      init(
        store: Store<SingleValueState, Never>,
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
            
            Text(String(describing: state))
          }
        }
      }
      
    }
    
    let store = Store<SingleValueState, Never>(initialState: .init())
    
    var count = 0
    
    let view = _Content(store: store, onUpdate: {
      count += 1
    })
    
    ViewHosting.host(view: view)
    
    XCTAssertEqual(count, 1)
    
    try await Task.sleep(nanoseconds: 1_000_000_000)

    store.commit {
      $0.count += 1
    }
    
    try await Task.sleep(nanoseconds: 1_000_000_000)

    XCTAssertEqual(count, 2)

    store.commit {
      $0.count += 1
    }
    
    try await Task.sleep(nanoseconds: 1_000_000_000)

    XCTAssertEqual(count, 3)

    store.commit {
      $0.count += 1
    }
    
    try await Task.sleep(nanoseconds: 1_000_000_000)
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
            
            Text(String(describing: state))
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
    
    try await Task.sleep(nanoseconds: 1_000_000_000)

    store.commit {
      $0.count_1 += 1
    }
    
    try await Task.sleep(nanoseconds: 1_000_000_000)

    XCTAssertEqual(count, 2)

    store.commit {
      $0.count_1 += 1
    }
    
    try await Task.sleep(nanoseconds: 1_000_000_000)

    XCTAssertEqual(count, 3)

    store.commit {
      $0.count_1 += 1
    }
    
    try await Task.sleep(nanoseconds: 1_000_000_000)
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
    
    try await Task.sleep(nanoseconds: 1_000_000_000)

    store.commit {
      $0.count_1 += 1
    }
    
    try await Task.sleep(nanoseconds: 1_000_000_000)

    XCTAssertEqual(count, 2)

    store.commit {
      $0.count_1 += 1
    }
    
    try await Task.sleep(nanoseconds: 1_000_000_000)

    XCTAssertEqual(count, 3)

    store.commit {
      $0.count_1 += 1
    }
    
    try await Task.sleep(nanoseconds: 1_000_000_000)
    XCTAssertEqual(count, 4)

  }
  
  @Tracking
  private struct NonEquatableBox<Value> {
    let value: Value
  }
  
  @Tracking
  private struct State: Equatable {
    var count_1: Int = 0
    var count_2: Int = 0
    
    var computed_count_equatable: Int {
      count_1 + count_2
    }
    
    var computed_count: NonEquatableBox<Int> {
      .init(value: count_1 + count_2)
    }
  }
  
  @Tracking
  private struct ConstantState {
    let value: Int
    
    init(value: Int) {
      self.value = value
    }
  }
  
  private struct ConstantContent: View {
    
    let store: Store<ConstantState, Never>
    let onUpdate: @MainActor () -> Void
    
    init(
      store: Store<ConstantState, Never>,
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
          
          Text("\(state.value)")
            .id("value")
        }
        .id("StoreReader")
      }
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
