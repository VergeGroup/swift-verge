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

  func testStateObsevableCompletion1() {

    let disposeBag = DisposeBag()

    var store: DemoStore? = DemoStore()
    weak var weakStore: DemoStore? = store

    store?.rx.stateObservable()
      .do(onCompleted: {
      })
      .subscribe()
      .disposed(by: disposeBag)

    XCTAssertNotNil(weakStore)

    store = nil

    XCTAssertNil(weakStore)
    withExtendedLifetime(disposeBag, {})
  }

  func testStateObsevableCompletion() {

    let disposeBag = DisposeBag()

    var store: DemoStore? = DemoStore()
    weak var weakStore: DemoStore? = store

    let exp = expectation(description: "onCompleted")

    store?.rx.stateObservable()
      .do(onCompleted: {
        exp.fulfill()
      })
      .subscribe()
      .disposed(by: disposeBag)

    XCTAssertNotNil(weakStore)

    store = nil

    XCTAssertNil(weakStore)

    wait(for: [exp], timeout: 10)
    withExtendedLifetime(disposeBag, {})
  }

  func testActivityObservableCompletion() {

    let disposeBag = DisposeBag()

    var store: DemoStore? = DemoStore()
    weak var weakStore: DemoStore? = store

    let exp = expectation(description: "onCompleted")

    store?.rx.activitySignal()
      .do(onCompleted: {
        exp.fulfill()
      })
      .emit()
      .disposed(by: disposeBag)

    XCTAssertNotNil(weakStore)

    store = nil

    XCTAssertNil(weakStore)

    wait(for: [exp], timeout: 10)
    withExtendedLifetime(disposeBag, {})
  }

}
