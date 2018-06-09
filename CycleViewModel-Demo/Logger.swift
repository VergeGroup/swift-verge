//
//  Logger.swift
//  Cycler-Demo
//
//  Created by muukii on 11/24/17.
//  Copyright © 2017 muukii. All rights reserved.
//

import Foundation

import Cycler

final class CyclerLogger : CycleLogging {

  static let instance = CyclerLogger()

  init() {

  }

  func didEmit(activity: Any, file: StaticString, function: StaticString, line: UInt, on cycler: AnyCyclerType) {
    print("\(cycler) => DidEmit", activity)
  }

  func didChange(root: Any) {
    print("\(root) => DidChange")
  }

  func didChange(value: Any, for keyPath: AnyKeyPath, root: Any) {

  }

  func didReplace(root: Any) {
    print("\(root) => DidReplace")
  }

  func willDispatch(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on cycler: AnyCyclerType) {
    print("\(cycler) => WillDispatch \(name)", file, function, line)
  }

  func didDispatch(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on cycler: AnyCyclerType) {
    print("\(cycler) => DidDispatch \(name)", file, function, line)
  }


  func willMutate(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on cycler: AnyCyclerType) {
    print("\(cycler) => WillMutate \(name)", file, function, line)
  }

  func didMutate(name: String, description: String, file: StaticString, function: StaticString, line: UInt, on cycler: AnyCyclerType) {
    print("\(cycler) => DidMutate \(name)", file, function, line)
  }
}
