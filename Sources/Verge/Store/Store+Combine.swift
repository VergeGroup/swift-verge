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
  @_spi(Package)
  public func _statePublisher() -> some Combine.Publisher<Value, Never> {

//    return valuePublisher
//      .dropFirst()
//      .associate(resource: self, retains: keepsAliveForSubscribers)
//      .merge(with: Just(state))
    
    return publisher
      .associate(resource: self, retains: keepsAliveForSubscribers)
      .flatMap { event in
        guard case .state(.didUpdate(let stateWrapper)) = event else {
          return Empty<State, Never>().eraseToAnyPublisher()
        }
        return Just(stateWrapper.state).eraseToAnyPublisher()
      }
      .merge(with: Just(state))
  }

//  @_spi(Package)
  public func _activityPublisher() -> some Combine.Publisher<Activity, Never> {

    return publisher
      .associate(resource: self, retains: keepsAliveForSubscribers)
      .flatMap { event in
        guard case .activity(let a) = event else {
          return Empty<Activity, Never>().eraseToAnyPublisher()
        }
        return Just(a).eraseToAnyPublisher()
      }
  }

}

extension Publisher {

  func associate(resource: AnyObject, retains: Bool) -> some Publisher<Output, Failure> {

    let box = ResourceBox(object: resource, retains: retains)

    return handleEvents(receiveCancel: {
      // retain self until subscription finsihed
      withExtendedLifetime(box) {}
    })
  }

}

fileprivate final class ResourceBox {

  private let object: AnyObject?

  init(object: AnyObject, retains: Bool) {
    if retains {
      self.object = object
    } else {
      self.object = nil
    }
  }
}

#endif
