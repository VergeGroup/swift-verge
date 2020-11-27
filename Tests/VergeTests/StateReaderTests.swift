//
//  StateReaderTests.swift
//  VergeStoreTests
//
//  Created by muukii on 2020/10/08.
//  Copyright © 2020 muukii. All rights reserved.
//

import Foundation

import SwiftUI
import XCTest
import Verge

/** Not working */
@available(iOS 13, *)
final class StateReaderTests: XCTestCase {

  struct HandlerView: View {

    private let onBody: () -> Void
    private let onInit: () -> Void

    init(onInit: @escaping () -> Void, onBody: @escaping () -> Void) {
      self.onInit = onInit
      self.onBody = onBody
      onInit()
    }

    var body: some View {
      onBody()
      return EmptyView()
    }
  }

  final class Record {
    var outerCount = 0
    var innerCount = 0
  }

  struct RootView: View {

    let store: DemoStore
    let record: Record
    @State var count1 = 0
    @State var count2 = 0

    var body: some View {
      VStack {
        HandlerView(onInit: {
          record.outerCount += 1
        }, onBody: {

        })
        Text(count1.description)
        StateReader(store).content { state in
          VStack {
            HandlerView(onInit: {
              record.innerCount += 1
            }, onBody: {

            })
            Text(state.name)
          }
        }
      }
    }
  }

  final class TestingController<Content: View>: UIHostingController<Content> {

  }

  func testBasic() {

    let store = DemoStore()
    let record = Record()
    let rootView = RootView(store: store, record: record)

    let window = UIWindow(frame: .init(x: 0, y: 0, width: 300, height: 300))
    let hostingView = TestingController(rootView: rootView)
    window.rootViewController = hostingView
    window.makeKeyAndVisible()
    window.setNeedsLayout()
    window.layoutIfNeeded()

    XCTAssertEqual(record.outerCount, 1)
    XCTAssertEqual(record.innerCount, 1)

    store.commit {
      $0.name = "h"
    }

    // FIXME:

    withExtendedLifetime(hostingView) {}
    withExtendedLifetime(window) {}

  }

}
