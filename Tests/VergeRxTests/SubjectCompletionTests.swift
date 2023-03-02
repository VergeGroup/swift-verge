//
//  SubjectCompletionTests.swift
//  VergeRxTests
//
//  Created by Muukii on 2021/04/06.
//  Copyright © 2021 muukii. All rights reserved.
//

import Foundation
import RxSwift
import Verge
import VergeRx
import XCTest

final class SubjectCompletionTests: XCTestCase {

  func testStateObsevableCompletion() {

    var subscription: Disposable?

    var store: DemoStore? = DemoStore()
    weak var weakStore: DemoStore? = store

    subscription = store?.rx.stateObservable()
      .subscribe()

    XCTAssertNotNil(weakStore)

    store = nil

    subscription?.dispose()

    XCTAssertNil(weakStore)
  }

  func testActivityObservableCompletion() {

    var subscription: Disposable?

    var store: DemoStore? = DemoStore()
    weak var weakStore: DemoStore? = store

    subscription = store?.rx.activitySignal()
      .emit()

    XCTAssertNotNil(weakStore)

    store = nil

    subscription?.dispose()

    XCTAssertNil(weakStore)
  }

}
