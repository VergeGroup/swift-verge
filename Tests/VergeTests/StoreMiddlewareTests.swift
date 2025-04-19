import Testing

@Suite("StoreMiddlewareTests")
struct StoreMiddlewareTests {

  @Test("Commit Hook")
  func testCommitHook() {
    let store = DemoStore()

    store.add(
      middleware: .modify { @Sendable modifyingState, transaction, current in
        current.ifChanged(\.count).do { _ in
          modifyingState.count += 1
        }
      })

    store.add(
      middleware: .modify { @Sendable modifyingState, transaction, current in
        current.ifChanged(\.name).do { _ in
          modifyingState.count = 100
        }
      })

    #expect(store.state.count == 0)

    store.commit {
      $0.count += 1
    }

    #expect(store.state.count == 2)

    store.commit {
      $0.name = "A"
    }

    if case .graph(let graph) = store.stateWrapper.modification {
      graph.prettyPrint()
      #expect(
        graph.prettyPrint() == """
          VergeTests.DemoState {
            name-(1)+(1)
            count-(1)+(1)
          }
          """)
    }

    #expect(store.state.count == 100)
  }
}
