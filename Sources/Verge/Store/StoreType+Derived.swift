//
// Copyright (c) 2020 Hiroshi Kimura(Muukii) <muukii.app@gmail.com>
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

import class Foundation.NSString

extension DispatcherType {
  
  public func derived<Pipeline: PipelineType>(
    _ pipeline: Pipeline,
    queue: some TargetQueueType = .passthrough
  ) -> Derived<Pipeline.Output> where Pipeline.Input == Changes<State> {
    
    vergeSignpostEvent("Store.derived.new", label: "\(type(of: State.self)) -> \(type(of: Pipeline.Output.self))")

    let derived = Derived<Pipeline.Output>(
      get: pipeline,
      set: { _ in

      },
      initialUpstreamState: store.asStore().state,
      subscribeUpstreamState: { callback in
        store.asStore()._primitive_sinkState(
          keepsAliveSource: false,
          dropsFirst: true,
          queue: queue,
          receive: callback
        )
      },
      retainsUpstream: nil
    )

    store.asStore().onDeinit { [weak derived] in
      derived?.invalidate()
    }

    return derived
  }


}
