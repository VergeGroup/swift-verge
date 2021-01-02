//
// Copyright (c) 2019 muukii
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

#if canImport(Combine)

import Combine

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension Store {

  /// A publisher that repeatedly emits the changes when state updated
  ///
  /// Guarantees to emit the first event on started subscribing.
  ///
  /// - Parameter startsFromInitial: Make the first changes object's hasChanges always return true.
  /// - Returns:
  public func statePublisher(startsFromInitial: Bool = true) -> AnyPublisher<Changes<State>, Never> {
    if startsFromInitial {
      return _backingStorage.valuePublisher.dropFirst()
        .merge(with: Just(_backingStorage.value.droppedPrevious()))
        .eraseToAnyPublisher()
    } else {
      return _backingStorage.valuePublisher
    }
  }

  /// A publisher that repeatedly emits the changes when state updated
  ///
  /// Guarantees to emit the first event on started subscribing.
  ///
  /// - Parameter startsFromInitial: Make the first changes object's hasChanges always return true.
  /// - Returns:
  @available(*, deprecated, renamed: "statePublisher")
  public func changesPublisher(startsFromInitial: Bool = true) -> AnyPublisher<Changes<State>, Never> {
    if startsFromInitial {
      return _backingStorage.valuePublisher.dropFirst()
        .merge(with: Just(_backingStorage.value.droppedPrevious()))
        .eraseToAnyPublisher()
    } else {
      return _backingStorage.valuePublisher
    }
  }

  public var activityPublisher: EventEmitter<Activity>.Publisher {
    _activityEmitter.publisher
  }

}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension DispatcherBase: ObservableObject {

}

#endif
