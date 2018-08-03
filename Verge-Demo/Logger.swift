//
//  Logger.swift
//  Verge-Demo
//
//  Created by muukii on 11/24/17.
//  Copyright © 2017 muukii. All rights reserved.
//

import Foundation

import Verge

final class VergeLogger : VergeLogging {

  static let instance = VergeLogger()

  init() {

  }

  func didEmit(activity: Any, file: StaticString, function: StaticString, line: UInt, on verge: AnyVergeType) {
    print("\(verge) => DidEmit", activity)
  }

  func didChange(root: Any) {
    print("\(root) => DidChange")
  }

  func didChange(value: Any, for keyPath: AnyKeyPath, root: Any) {

  }

  func didReplace(root: Any) {
    print("\(root) => DidReplace")
  }

  func willDispatch(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on verge: AnyVergeType) {
    print("\(verge) => WillDispatch \(name)", file, function, line)
  }

  func didDispatch(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on verge: AnyVergeType) {
    print("\(verge) => DidDispatch \(name)", file, function, line)
  }


  func willMutate(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on verge: AnyVergeType) {
    print("\(verge) => WillMutate \(name)", file, function, line)
  }

  func didMutate(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on verge: AnyVergeType) {
    print("\(verge) => DidMutate \(name)", file, function, line)
  }
}
