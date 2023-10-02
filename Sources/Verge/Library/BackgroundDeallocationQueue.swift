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

import Foundation
import DequeModule

actor BackgroundDeallocationQueue {

  private var buffer: Deque<Unmanaged<AnyObject>> = .init()

  func releaseObjectInBackground(object: AnyObject) {

    let innerCurrentRef = Unmanaged.passRetained(object)

    let isFirstEntry = buffer.isEmpty
    buffer.append(innerCurrentRef)

    if isFirstEntry {
      Task {
        // accumulate objects to dealloc for batching
        try? await Task.sleep(nanoseconds: 1_000_000)
        await self.drain()
      }
    }
  }

  func drain() async {

    guard buffer.isEmpty == false else {
      return
    }

    while let pointer = buffer.popFirst() {
      pointer.release()
      await Task.yield()
    }

    await drain()

  }
}
